// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:eltest_exit/theme/app_theme.dart';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Removed SlideCountdown import
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:http/http.dart' as http; // Import for making HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding
import 'package:provider/provider.dart'; // Import for accessing provider

// Import the necessary models and DatabaseHelper from your database_manipulation.dart file
import 'service/database_manipulation.dart';
import 'service/common.dart'; // Assuming this contains necessary common services
import 'provider/strored_ref.dart'; // Import your RefData provider
import 'take_exam_gemini_dialog.dart'; // Import the API key dialog

class ChapStudyMode extends StatefulWidget {
  const ChapStudyMode({Key? key}) : super(key: key);

  @override
  State<ChapStudyMode> createState() => _ChapStudyModeState();
}

class _ChapStudyModeState extends State<ChapStudyMode> {
  // Use the Question model from your database_manipulation.dart
  List<Question> questions = [];
  List<RadioModel> questionData = <RadioModel>[];

  // Lists to hold data for analysis screen
  Map<int?, String> final_data = {}; // Stores question ID and selected answer
  // We will now track counts by either chapter or subchapter ID
  Map<int?, int> entity_question_count =
      {}; // Stores Chapter/Subchapter ID and question count
  Map<int?, int> entity_right_count =
      {}; // Stores Chapter/Subchapter ID and right answer count
  Map<int?, int> entity_wrong_count =
      {}; // Stores Chapter/Subchapter ID and wrong answer count

  List<int?> right_ans_ids = []; // Stores IDs of correctly answered questions
  Map<int?, String> wrong_ans_data =
      {}; // Stores wrong answer question ID and chosen option
  List<int?> unans_ans_ids = []; // Stores IDs of unanswered questions
  List<int?> fav_list = []; // Stores IDs of favorited questions
  // Removed ques_time map

  // Variables to hold filtering criteria from arguments
  String? _filterType; // 'dept', 'topic', or 'subtopic'
  dynamic _filterValue; // The unit or name (String) for the selected filter
  int? _typenameGradeSubjectId; // The TypeNameGradeSubject ID
  String? _screenTitle; // Title to display in the AppBar

  // Removed _examTime as there's no timer
  var isLoading = true;

  int ques_no = 0;

  // State variables for study mode features
  bool _showAns =
      false; // Controls highlighting and visibility of local explanation tile
  bool _showExplanation =
      false; // Controls expanded state of local explanation tile

  // State variables for Gemini explanation
  // TODO: IMPORTANT! Replace 'YOUR_GEMINI_API_KEY' with your actual Gemini API Key.
  // TODO: For production, store this securely (e.g., using environment variables compiled from CI/CD, or a backend proxy).
  // DO NOT commit your actual API key to version control if it's hardcoded here during development.
  String _geminiApiKey = 'none'; // <--- REPLACE THIS
  final String _geminiModel =
      'gemini-2.0-flash'; // Using Flash model as discussed

  bool _isGeminiLoading = false;
  String? _geminiExplanation; // Stores the explanation from Gemini

  final ScrollController cont1 = ScrollController();
  final ScrollController cont2 = ScrollController();

  @override
  void initState() {
    super.initState();
    // Access Gemini API key from provider
    // Ensure context is available before accessing provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geminiApiKey = Provider.of<RefData>(context, listen: false).geminiApi;
      // No need to call setState here as getData will trigger a rebuild
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if questions are already loaded to prevent unnecessary re-fetching
    if (questions.isEmpty && isLoading) {
      Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;

      if (arguments != null) {
        _filterType =
            arguments['type'] as String?; // 'dept', 'topic', or 'subtopic'
        _filterValue =
            arguments['value']; // The unit, chapter name, or subchapter name
        _typenameGradeSubjectId = arguments['typenameGradeSubjectId'] as int?;
        _screenTitle =
            arguments['title'] as String?; // Get the title from arguments

        if (_filterType != null &&
            _filterValue != null &&
            _typenameGradeSubjectId != null) {
          getData(_filterType!, _filterValue!, _typenameGradeSubjectId!);
        } else {
          print("Missing arguments for filtering.");
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        }
      } else {
        print("No arguments passed to ChapStudyMode.");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  // Fetches questions based on filter type, filter value (unit/name), and TypeNameGradeSubject ID
  getData(
    String filterType,
    dynamic filterValue, // Expecting the name (String) for filtering
    int typenameGradeSubjectId,
  ) async {
    if (mounted) {
      setState(() {
        isLoading = true; // Set loading to true while fetching
      });
    }
    questions.clear();

    try {
      final dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> maps = [];

      // Define the base joins needed for all filtering types
      final baseJoins = [
        Join(table: 'exam', on: 'question.exam = exam.id'),
        Join(
          table: 'typenamegradesubjectexam',
          on: 'exam.id = typenamegradesubjectexam.exam',
        ),
        Join(
          table: 'typenamegradesubject',
          on:
              'typenamegradesubjectexam.typenamegradesubject = typenamegradesubject.id',
        ),
      ];

      String whereClause;
      List<Object?> whereArgs;
      List<Join> currentJoins = List.from(baseJoins); // Start with base joins

      switch (filterType) {
        case 'dept': // Filtering by Chapter Unit (Department) - using Unit Name
          currentJoins.add(
            Join(table: 'chapter', on: 'question.chapter = chapter.id'),
          );
          whereClause = 'chapter.unit = ? AND typenamegradesubject.id = ?';
          whereArgs = [
            filterValue as String,
            typenameGradeSubjectId,
          ]; // Ensure filterValue is String (Unit Name)
          break;
        case 'topic': // Filtering by Chapter (Topic) - using Chapter Name
          currentJoins.add(
            Join(table: 'chapter', on: 'question.chapter = chapter.id'),
          );
          whereClause = 'chapter.name = ? AND typenamegradesubject.id = ?';
          whereArgs = [
            filterValue as String,
            typenameGradeSubjectId,
          ]; // Ensure filterValue is String (Chapter Name)
          break;
        case 'subtopic': // Filtering by Subchapter (Subtopic) - using Subchapter Name
          currentJoins.add(
            Join(
              table: 'subchapter',
              on: 'question.subchapter = subchapter.id',
            ),
          );
          currentJoins.add(
            Join(table: 'chapter', on: 'question.chapter = chapter.id'),
          ); // Subchapter is linked to chapter
          whereClause = 'subchapter.name = ? AND typenamegradesubject.id = ?';
          whereArgs = [
            filterValue as String,
            typenameGradeSubjectId,
          ]; // Ensure filterValue is String (Subchapter Name)
          break;
        default:
          print("Unknown filter type: $filterType");
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          return;
      }

      // Perform the joined query using the DatabaseHelper
      maps = await dbHelper.performJoinedQuery(
        selectColumns: [
          'question.*', // Select all columns from the question table
          // Include chapter and subchapter IDs for analysis
          'question.chapter',
          'question.subchapter',
        ],
        fromTable: 'question',
        joins: currentJoins,
        where: whereClause,
        whereArgs: whereArgs,
        distinct: true, // Ensure unique questions
      );

      if (maps.isNotEmpty) {
        questions = List.generate(
          maps.length,
          (i) => Question().fromMap(maps[i]),
        );
        // Shuffle questions for study mode
        questions.shuffle();
        assignQues();
        if (mounted) {
          setState(() {
            isLoading = false; // Set loading to false after fetching
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false; // Set loading to false even if no questions
          });
        }
        print(
          "No questions found for filter type: $filterType, value: $filterValue, TypeNameGradeSubject ID: $typenameGradeSubjectId",
        );
      }
    } catch (e) {
      print("Error fetching questions: $e");
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading to false on error
        });
      }
      // Optionally show an error message to the user
    }
  }

  // Assigns question data for the current question number
  assignQues() {
    if (questions.isEmpty || ques_no >= questions.length) {
      if (mounted) {
        setState(() {
          isLoading =
              false; // Handle case where ques_no might exceed bounds after data load
        });
      }
      return;
    }
    questionData.clear();
    // Check if the current question ID has a saved answer in final_data
    String? savedAnswer = final_data[questions[ques_no].id];

    questionData.add(
      RadioModel(savedAnswer == 'A', 'A', '${questions[ques_no].a}'),
    );
    questionData.add(
      RadioModel(savedAnswer == 'B', 'B', '${questions[ques_no].b}'),
    );
    questionData.add(
      RadioModel(savedAnswer == 'C', 'C', '${questions[ques_no].c}'),
    );
    questionData.add(
      RadioModel(savedAnswer == 'D', 'D', '${questions[ques_no].d}'),
    );

    // Reset study mode specific state variables when question changes
    if (mounted) {
      setState(() {
        _showAns = false; // Hide local explanation and highlighting
        _showExplanation = false; // Collapse local explanation tile
        _isGeminiLoading = false; // Hide Gemini loading
        _geminiExplanation = null; // Clear previous Gemini explanation
      });
    }
  }

  // Helper function to build choice text with highlighting based on result
  Widget _buildChoiceText(
    String choice,
    String? text,
    String? correctAnswer,
    String? userChosenAnswer,
    double devWidth,
  ) {
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;
    Color letterBgColor = Colors.transparent;
    Color letterColor = Colors.black87;
    Color borderColor = Colors.black87;

    // If local explanation is shown (_showAns is true), apply highlighting
    if (_showAns) {
      if (correctAnswer != null &&
          choice.toLowerCase() == correctAnswer.toLowerCase()) {
        textColor = Color.fromARGB(255, 24, 111, 68); // Green for correct
        fontWeight = FontWeight.bold;
        letterBgColor = Color.fromARGB(255, 24, 111, 68);
        letterColor = Colors.white;
        borderColor = Color.fromARGB(255, 24, 111, 68);
      } else if (userChosenAnswer != null &&
          choice.toLowerCase() == userChosenAnswer.toLowerCase()) {
        // Highlight user's wrong answer in red
        textColor = Color.fromARGB(255, 155, 27, 27); // Red for wrong
        fontWeight = FontWeight.bold;
        letterBgColor = Color.fromARGB(255, 155, 27, 27);
        letterColor = Colors.white;
        borderColor = Color.fromARGB(255, 155, 27, 27);
      }
    } else {
      // If local explanation is NOT shown, highlight only the user's selection
      if (userChosenAnswer != null &&
          choice.toLowerCase() == userChosenAnswer.toLowerCase()) {
        textColor = AppTheme.color0081B9; // Blue for selected
        letterBgColor = AppTheme.color0081B9;
        letterColor = Colors.white;
        borderColor = AppTheme.color0081B9;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            height: 35.0,
            width: 35.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: letterBgColor,
              border: Border.all(width: 1.0, color: borderColor),
              borderRadius: const BorderRadius.all(Radius.circular(2.0)),
            ),
            child: Text(
              choice,
              style: TextStyle(color: letterColor, fontSize: 18.0),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Html(
              data: "<p>${text ?? ''}</p>",
              style: {
                "p": Style(
                  color: textColor,
                  fontSize: FontSize(16),
                  fontWeight: fontWeight,
                  margin: Margins.zero,
                ),
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to call Gemini API and get explanation as HTML
  Future<String> _getGeminiExplanationAsHtml(Question question) async {
    if (mounted) {
      setState(() {
        _isGeminiLoading = true;
      });
    }

    if (_geminiApiKey == 'none' || _geminiApiKey.isEmpty) {
      if (mounted) setState(() => _isGeminiLoading = false);
      return "<p><strong>Error:</strong> Gemini API Key not configured. Please enter your API key.</p>";
    }

    final String prompt =
        """Please explain the key terms and concepts in the following multiple-choice question and its options.
    Provide a detailed educational note or context about the general topic.
    Format your entire response as an HTML.
    Use appropriate HTML tags like <h2> for sections, <p> for paragraphs, <ul> and <li> for lists, <strong> for emphasis.
    Do NOT include \`\`\`html ... \`\`\` markdown wrappers around the HTML code. Just provide the raw HTML.

    Question:
    <p>${question.note} {question.ques}</p>

    Options:
    <ul>
      <li>A) ${question.a}</li>
      <li>B) ${question.b}</li>
      <li>C) ${question.c}</li>
      <li>D) ${question.d}</li>
    </ul>
    """;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
    );
    final headers = {'Content-Type': 'application/json'};
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.7},
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['promptFeedback'] != null &&
            data['promptFeedback']['blockReason'] != null) {
          return "<p><strong>Gemini Error:</strong> Prompt was blocked. Reason: ${data['promptFeedback']['blockReason']}</p>";
        }
        if (data['candidates'] != null &&
            (data['candidates'] as List).isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            (data['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            data['candidates'][0]['content']['parts'][0]['text'] != null) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return "<p><strong>Error:</strong> Could not parse Gemini explanation from response.</p><pre>${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}</pre>";
        }
      } else {
        String errorMsg =
            "<p><strong>Gemini API Error ${response.statusCode}:</strong></p>";
        try {
          final errorData = jsonDecode(response.body);
          errorMsg +=
              "<p>${errorData['error']?['message'] ?? 'Unknown API error.'}</p>";
        } catch (e) {
          errorMsg +=
              "<pre>${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}</pre>";
        }
        return errorMsg;
      }
    } catch (e) {
      return "<p><strong>Error:</strong> Failed to connect to Gemini API. ${e.toString()}</p>";
    } finally {
      if (mounted) setState(() => _isGeminiLoading = false);
    }
  }

  // Function to show Gemini explanation in a bottom sheet
  void _showGeminiExplanationBottomSheet(
    BuildContext context,
    String htmlContent,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Gemini Explanation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Html(
                        data: htmlContent,
                        style: {
                          "body": Style(
                            fontSize: FontSize(15),
                            color: Color.fromARGB(255, 78, 93, 102),
                          ),
                          "h2": Style(
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.color0081B9,
                          ),
                          "p": Style(
                            lineHeight: LineHeight.em(1.5),
                            color: Color.fromARGB(255, 78, 93, 102),
                          ),
                          "ul": Style(
                            padding: HtmlPaddings.only(left: 20),
                            color: Color.fromARGB(255, 78, 93, 102),
                          ),
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Function to show API key dialog
  void _showApiKeyDialog(BuildContext context) async {
    final String? enteredApiKey = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const ApiKeyDialog();
      },
    );

    if (enteredApiKey != null && enteredApiKey != 'none') {
      if (mounted) {
        Provider.of<RefData>(
          context,
          listen: false,
        ).setGeminiApi(enteredApiKey);
        setState(() {
          _geminiApiKey = enteredApiKey;
          _isGeminiLoading = false; // Reset loading state after key is set
        });
      }
    } else {
      print('Dialog cancelled or no API key entered.');
      if (mounted)
        setState(
          () => _isGeminiLoading = false,
        ); // Ensure loading is off if dialog is dismissed
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    // Show loading indicator or empty state message if data is not ready
    if (isLoading || questions.isEmpty || ques_no >= questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_screenTitle ?? 'Loading Exam...'),
          backgroundColor: const Color(0xffF2F5F8),
          elevation: 0,
          foregroundColor: AppTheme.color0081B9,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child:
              isLoading
                  ? CircularProgressIndicator()
                  : Text(
                    questions.isEmpty
                        ? 'No questions available for this selection.'
                        : 'Error loading question.',
                  ),
        ),
      );
    }

    // Get user's chosen answer and correct answer for the current question
    String? userChosenAnswerForCurrentQues = final_data[questions[ques_no].id!];
    String? correctAnswerForCurrentQues = questions[ques_no].ans;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation during exam
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffF2F5F8),
          elevation: 0,
          foregroundColor: AppTheme.color0081B9,
          title: Center(
            child: Text(
              '${_screenTitle ?? "Study Mode"}', // Use the screen title
              style: TextStyle(color: Color.fromARGB(255, 78, 93, 102)),
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      // Use the question ID for favoriting
                      fav_list.contains(questions[ques_no].id)
                          ? fav_list.remove(questions[ques_no].id)
                          : fav_list.add(questions[ques_no].id);
                    });
                  }
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  child: Icon(
                    fav_list.contains(questions[ques_no].id)
                        ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                    size: 20,
                    color: AppTheme.red,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xffF2F5F8),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // --- Gemini Animated Button ---
                GestureDetector(
                  onTap:
                      _geminiApiKey == 'none' || _geminiApiKey.isEmpty
                          ? () => _showApiKeyDialog(
                            context,
                          ) // Show dialog if API key is missing
                          : _isGeminiLoading
                          ? null // Disable button while loading
                          : () async {
                            if (questions.isEmpty ||
                                ques_no >= questions.length)
                              return;
                            final currentQuestion = questions[ques_no];
                            final htmlExplanation =
                                await _getGeminiExplanationAsHtml(
                                  currentQuestion,
                                );
                            if (mounted) {
                              _showGeminiExplanationBottomSheet(
                                context,
                                htmlExplanation,
                              );
                            }
                          },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _isGeminiLoading ||
                                  _geminiApiKey == 'none' ||
                                  _geminiApiKey.isEmpty
                              ? Colors
                                  .grey // Grey out if loading or key is missing
                              : AppTheme.color0081B9,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                        _isGeminiLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _geminiApiKey == 'none' ||
                                          _geminiApiKey.isEmpty
                                      ? 'Enter API Key'
                                      : 'Ask Gemini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                // --- Question Display Card ---
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Center(
                    child: SizedBox(
                      height: 220,
                      child: Card(
                        color: AppTheme.color0081B9,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          width: devWidth - 30,
                          height: 200,
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: cont1,
                            interactive: true,
                            thickness: 5,
                            radius: Radius.circular(20),
                            trackVisibility: true,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ${ques_no + 1}/${questions.length}',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 20,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Html(
                                    data:
                                        "<p>${questions[ques_no].note ?? ''}</p><p>${questions[ques_no].ques ?? 'Question text not available.'}</p>",
                                    style: {
                                      "p": Style(
                                        color: AppTheme.white,
                                        fontSize: FontSize(16),
                                      ),
                                      "body": Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      ),
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  if (questions[ques_no].image != null &&
                                      questions[ques_no].image!.isNotEmpty)
                                    SizedBox(
                                      height: 150,
                                      child: Image.network(
                                        '${main_url}${questions[ques_no].image}', // Ensure main_url is defined
                                        fit: BoxFit.contain,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Text(
                                            'Error loading image',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          );
                                        },
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Choices Display and Local Explanation ---
                Scrollbar(
                  thumbVisibility: true,
                  controller: cont2,
                  radius: Radius.circular(20),
                  thickness: 5,
                  trackVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // ListView.builder for choices
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: questionData.length,
                            itemBuilder: (BuildContext context, int index) {
                              final choice = questionData[index].buttonText;
                              final text = questionData[index].text;
                              return InkWell(
                                splashColor: AppTheme.color0081B9,
                                onTap: () {
                                  // Allow selection only if local explanation is not being shown
                                  if (!_showAns) {
                                    if (mounted) {
                                      setState(() {
                                        questionData.forEach(
                                          (element) =>
                                              element.isSelected = false,
                                        );
                                        questionData[index].isSelected = true;
                                        final_data[questions[ques_no].id!] =
                                            questionData[index].buttonText;
                                      });
                                    }
                                  }
                                },
                                child: _buildChoiceText(
                                  choice,
                                  text,
                                  questions[ques_no].ans, // Pass correct answer
                                  final_data[questions[ques_no]
                                      .id!], // Pass user's chosen answer
                                  devWidth,
                                ),
                              );
                            },
                          ),

                          // --- ExpansionTile for Local DB Explanation (Visible only when _showAns is true) ---
                          Visibility(
                            visible:
                                _showAns &&
                                questions[ques_no].explanation != null &&
                                questions[ques_no].explanation!.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Show Local Explanation',
                                  style: TextStyle(
                                    color: AppTheme.color0081B9,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                initiallyExpanded:
                                    _showExplanation, // Controlled by _showExplanation state
                                onExpansionChanged: (bool expanded) {
                                  if (mounted) {
                                    setState(() {
                                      _showExplanation =
                                          expanded; // Update state when tile is manually expanded/collapsed
                                    });
                                  }
                                },
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Html(
                                      data: questions[ques_no].explanation!,
                                      style: {
                                        "body": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                          fontSize: FontSize(14),
                                          color: Colors.grey[800],
                                        ),
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 70), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // --- Prev Button ---
            FloatingActionButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    if (ques_no > 0) ques_no--;
                    assignQues(); // Reset study mode states for new question
                  });
                }
              },
              child: Text('Prev.'),
              backgroundColor: AppTheme.color0081B9,
              heroTag: 'prevButton', // Unique tag
            ),
            // --- End Button ---
            FloatingActionButton(
              onPressed: () {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.bottomSlide,
                  body: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        if (final_data.length < questions.length)
                          Text(
                            'There are ${questions.length - final_data.length} Unanswered Questions',
                            style: TextStyle(color: AppTheme.red, fontSize: 14),
                          ),
                        SizedBox(height: 10),
                        Text(
                          'You are going to finish the study session and see your analysis. Do you want to continue?',
                          style: TextStyle(
                            color: AppTheme.color0081B9,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  btnCancelOnPress: () {},
                  btnCancelText: 'Back',
                  btnOkText: 'Continue',
                  btnOkOnPress: () {
                    analyse(); // Proceed to analysis
                  },
                )..show();
              },
              child: Text('End'),
              backgroundColor: Colors.green,
              heroTag: 'endButton', // Unique tag
            ),
            // --- "Show" FloatingActionButton for Local Explanation ---
            // This button controls the visibility and highlighting
            if (questions[ques_no].explanation != null &&
                questions[ques_no].explanation!.isNotEmpty)
              FloatingActionButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showAns =
                          !_showAns; // Toggle visibility and highlighting
                      // Optionally, expand the tile automatically when showing
                      if (_showAns) {
                        _showExplanation = true;
                      } else {
                        _showExplanation = false; // Collapse when hiding
                      }
                    });
                  }
                },
                child: Text(
                  _showAns ? 'Hide' : 'Show',
                ), // Text changes based on state
                backgroundColor: AppTheme.colorF0A714, // Orange color
                heroTag: 'showLocalExplanationButton', // Unique tag
              ),
            // --- Next Button ---
            FloatingActionButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    if (ques_no < questions.length - 1) ques_no++;
                    assignQues(); // Reset study mode states for new question
                  });
                }
              },
              child: Text('Next'),
              backgroundColor: AppTheme.color0081B9,
              heroTag: 'nextButton', // Unique tag
            ),
          ],
        ),
      ),
    );
  }

  // Analyzes the results and prepares data for the chapter analysis screen
  analyse() {
    right_ans_ids.clear();
    wrong_ans_data.clear();
    unans_ans_ids.clear();
    entity_question_count.clear();
    entity_right_count.clear();
    entity_wrong_count.clear();
    // Removed ques_time related logic

    for (var i = 0; i < questions.length; i++) {
      int? questionId = questions[i].id;
      // Get the relevant entity ID (chapter or subchapter) based on filter type
      int? entityId;
      if (_filterType == 'dept' || _filterType == 'topic') {
        entityId =
            questions[i].chapter; // Use chapter ID for 'dept' and 'topic'
      } else if (_filterType == 'subtopic') {
        entityId = questions[i].subchapter; // Use subchapter ID for 'subtopic'
      }

      String correctAnswer = questions[i].ans?.toLowerCase() ?? '';
      String? chosenAnswer = final_data[questionId]?.toLowerCase();

      // Count questions per entity (chapter or subchapter)
      if (entityId != null) {
        entity_question_count[entityId] =
            (entity_question_count[entityId] ?? 0) + 1;

        if (chosenAnswer != null) {
          if (chosenAnswer == correctAnswer) {
            right_ans_ids.add(questionId);
            entity_right_count[entityId] =
                (entity_right_count[entityId] ?? 0) + 1;
          } else {
            wrong_ans_data[questionId] =
                final_data[questionId]!; // Store the original chosen option
            entity_wrong_count[entityId] =
                (entity_wrong_count[entityId] ?? 0) + 1;
          }
        } else {
          unans_ans_ids.add(questionId);
        }
      } else {
        // Handle questions without a valid chapter/subchapter ID if necessary
        print("Question ${questionId} has no valid entity ID for analysis.");
        unans_ans_ids.add(
          questionId,
        ); // Treat as unanswered if entity ID is missing
      }
    }

    finalToAnalysisScreen(); // Navigate to analysis screen
  }

  // Prepares data and navigates to the chapter analysis screen
  finalToAnalysisScreen() async {
    // Save Favorite questions
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Ensure database is initialized
    for (var questionId in fav_list) {
      if (questionId != null) {
        Favorite favorite = Favorite(question: questionId);
        await favorite.save();
      }
    }

    print('Study session analysis complete. Navigating to analysis screen.');

    // Navigate to the result screen for filtered questions
    // Pass all necessary data for the analysis screen to display analysis
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/result-chapt', // Route for chapter analysis screen
        arguments: {
          "filter_type":
              _filterType, // Pass the filter type ('dept', 'topic', 'subtopic')
          "filter_value": _filterValue, // Pass the filter value (name)
          "typename_grade_subject_id": _typenameGradeSubjectId,
          "screen_title": _screenTitle,
          "questions": questions, // Pass the list of questions
          "final_data": final_data, // Pass user's answers
          // Removed ques_time
          "fav_list": fav_list, // Pass favorited questions
          // Pass calculated right/wrong/unanswered counts per entity (chapter/subchapter)
          "entity_question_count": entity_question_count,
          "entity_right_count": entity_right_count,
          "entity_wrong_count": entity_wrong_count,
          "unans_ans_ids": unans_ans_ids, // Unanswered IDs
          "right_ans_ids": right_ans_ids, // Right Answer IDs
          "wrong_ans_data": wrong_ans_data, // Wrong Answer Data
        },
      );
    }
  }
}

class RadioModel {
  bool isSelected;
  final String buttonText;
  final String text;

  RadioModel(this.isSelected, this.buttonText, this.text);
}

// ignore_for_file: prefer_const_constructors
