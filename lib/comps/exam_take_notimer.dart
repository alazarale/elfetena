// ignore_for_file: prefer_const_constructors

import 'package:eltest_exit/comps/provider/auth.dart';
import 'package:eltest_exit/comps/provider/strored_ref.dart';
import 'package:eltest_exit/comps/service/database_manipulation.dart';
import 'package:eltest_exit/comps/take_exam_gemini_dialog.dart';
import 'package:flutter/material.dart';
import 'package:eltest_exit/theme/app_theme.dart';

import 'package:flutter/services.dart'; // Keep sqflite import for getDatabasesPath
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Removed SlideCountdown import
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:http/http.dart' as http; // Import for making HTTP requests
import 'package:provider/provider.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

// Import the models and DatabaseHelper from your SQLite CRUD Canvas
// Adjust the import path

import 'service/common.dart'; // Assuming this contains necessary common services

class TakeStudyExam extends StatefulWidget {
  const TakeStudyExam({Key? key}) : super(key: key);

  @override
  State<TakeStudyExam> createState() => _TakeStudyExamState();
}

class _TakeStudyExamState extends State<TakeStudyExam> {
  // Use the Question model from your CRUD classes
  List<Question> questions = [];
  List<RadioModel> questionData = <RadioModel>[];

  // Lists to hold data before saving to database
  Map<int, String> final_data = {}; // Stores question ID and selected answer
  Map<int?, int> chapter_question_count =
      {}; // Stores chapter ID and question count
  Map<int?, int> chapter_right_count =
      {}; // Stores chapter ID and right answer count
  Map<int?, int> chapter_wrong_count =
      {}; // Stores chapter ID and wrong answer count
  List<int?> right_ans_ids = []; // Stores IDs of correctly answered questions
  Map<int?, String> wrong_ans_data =
      {}; // Stores wrong answer question ID and chosen option
  List<int?> unans_ans_ids = []; // Stores IDs of unanswered questions
  List<int?> fav_list = []; // Stores IDs of favorited questions

  int? _examId;
  String? _examTitle;
  int? _examTime;
  var isLoading = true;

  int ques_no = 0;

  bool _showExplanation = false;
  bool _showAns = false;

  // --- GEMINI API CONFIGURATION ---
  // TODO: IMPORTANT! Replace 'YOUR_GEMINI_API_KEY' with your actual Gemini API Key.
  // TODO: For production, store this securely (e.g., using environment variables compiled from CI/CD, or a backend proxy).
  // DO NOT commit your actual API key to version control if it's hardcoded here during development.
  String _geminiApiKey = 'none'; // <--- REPLACE THIS
  final String _geminiModel = 'gemini-2.0-flash';

  bool _isGeminiLoading = false;

  // --- STATE FOR LOCAL EXPLANATION ---

  final ScrollController cont1 = ScrollController();
  final ScrollController cont2 = ScrollController();

  @override
  void initState() {
    super.initState();
    _geminiApiKey = Provider.of<RefData>(context, listen: false).geminiApi;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoading) {
      // Prevents re-fetching on every rebuild if not necessary
      Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
      _examId = arguments['exam_id'];
      _examTitle = arguments['title'];
      _examTime = arguments['time'];
      getData(_examId);
    }
  }

  getData(int? examId) async {
    // ... (getData logic remains the same)
    if (examId == null) {
      print("Exam ID is null. Cannot fetch questions.");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    questions.clear();

    try {
      final questionModel = Question();
      questions = await questionModel.query(
        where: 'exam = ?',
        whereArgs: [examId],
      );

      if (mounted) {
        setState(() {
          if (questions.isNotEmpty) {
            assignQues();
          } else {
            print("No questions found for exam ID: $examId");
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching questions: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  assignQues() {
    if (questions.isEmpty || ques_no >= questions.length) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }
    questionData.clear();
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

    // Reset _showExplanation when question changes
    if (mounted) {
      setState(() {
        _showAns = false;
      });
    }
  }

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

    // If local explanation is shown, apply highlighting
    if (_showAns) {
      if (correctAnswer != null &&
          choice.toLowerCase() == correctAnswer.toLowerCase()) {
        textColor = Color.fromARGB(255, 24, 111, 68);
        fontWeight = FontWeight.bold;
        letterBgColor = Color.fromARGB(255, 24, 111, 68);
        letterColor = Colors.white;
        borderColor = Color.fromARGB(255, 24, 111, 68);
      }

      if (userChosenAnswer != null &&
          choice.toLowerCase() == userChosenAnswer.toLowerCase() &&
          (correctAnswer == null ||
              choice.toLowerCase() != correctAnswer.toLowerCase())) {
        textColor = Color.fromARGB(255, 155, 27, 27);
        fontWeight = FontWeight.bold;
        letterBgColor = Color.fromARGB(255, 155, 27, 27);
        letterColor = Colors.white;
        borderColor = Color.fromARGB(255, 155, 27, 27);
      }
    } else {
      // If local explanation is NOT shown, highlight only the user's selection
      if (userChosenAnswer != null &&
          choice.toLowerCase() == userChosenAnswer.toLowerCase()) {
        textColor = AppTheme.color0081B9;
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

  Future<String> _getGeminiExplanationAsHtml(Question question) async {
    // ... (this function remains the same as in the previous response)
    if (mounted) {
      setState(() {
        _isGeminiLoading = true;
      });
    }

    if (_geminiApiKey == 'none' || _geminiApiKey.isEmpty) {
      if (mounted) setState(() => _isGeminiLoading = false);
      return "<p><strong>Error:</strong> Gemini API Key not configured.</p>";
    }

    final String prompt =
        """Please explain the key terms and concepts in the following multiple-choice question and its options.
    Provide a detailed educational note or context about the general topic.
    Format your entire response using html tags.
    Use appropriate HTML tags like <h2> for sections, <p> for paragraphs, <ul> and <li> for lists, <strong> for emphasis.
    Do NOT include \`\`\`html ... \`\`\` markdown wrappers around the HTML code. Just provide the raw HTML.

    Question:
    <p>${question.note} ${question.ques}</p>

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
          
          return data['candidates'][0]['content']['parts'][0]['text']
                  .replaceAll('```html', '')
                  .trim();
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

  void _showGeminiExplanationBottomSheet(
    BuildContext context,
    String htmlContent,
  ) {
    // ... (this function remains the same as in the previous response)
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

  void _showApiKeyDialog(BuildContext context) async {
    final String? enteredApiKey = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const ApiKeyDialog();
      },
    );

    if (enteredApiKey != null || enteredApiKey != 'none') {
      Provider.of<RefData>(context, listen: false).setGeminiApi(enteredApiKey!);
      setState(() {
        _geminiApiKey = enteredApiKey;
        _isGeminiLoading = false;
      });
    } else {
      print('Dialog cancelled or no API key entered.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    if (isLoading || questions.isEmpty || ques_no >= questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_examTitle ?? 'Loading Exam...'),
          backgroundColor: const Color(0xffF2F5F8),
          elevation: 0,
          foregroundColor: Color(0xff0081B9),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child:
              isLoading
                  ? CircularProgressIndicator()
                  : Text(
                    questions.isEmpty
                        ? 'No questions available for this exam.'
                        : 'Error loading question.',
                  ),
        ),
      );
    }

    String? userChosenAnswerForCurrentQues = final_data[questions[ques_no].id!];
    String? correctAnswerForCurrentQues = questions[ques_no].ans;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          // ... (appBar setup remains the same)
          backgroundColor: const Color(0xffF2F5F8),
          elevation: 0,
          foregroundColor: Color(0xff0081B9),
          title: Center(
            child: Text(
              '${_examTitle}',
              style: TextStyle(color: Color.fromARGB(255, 78, 93, 102)),
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    fav_list.contains(questions[ques_no].id)
                        ? fav_list.remove(questions[ques_no].id)
                        : fav_list.add(questions[ques_no].id);
                  });
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
                GestureDetector(
                  // "Ask Gemini" Button
                  onTap:
                      _geminiApiKey == 'none' || _geminiApiKey.isEmpty
                          ? () {
                            _showApiKeyDialog(context);
                          }
                          : _isGeminiLoading
                          ? null
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
                    // ... (button styling remains the same)
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _isGeminiLoading ? Colors.grey : AppTheme.color0081B9,
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
                                  'Ask Gemini', // Kept it short
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                // Question Display Card
                Padding(
                  // ... (question card UI remains the same)
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Center(
                    child: SizedBox(
                      height: 220,
                      child: Card(
                        color: Color(0xff0081B9),
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
                                      color: Colors.white,
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
                                        color: Colors.white,
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

                // Choices Display
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
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: questionData.length,
                            itemBuilder: (BuildContext context, int index) {
                              final choice = questionData[index].buttonText;
                              final text = questionData[index].text;
                              return InkWell(
                                splashColor: Color(0xff0081B9),
                                onTap: () {
                                  // Allow selection only if local explanation is not being shown
                                  // This prevents changing answer while reviewing with local explanation
                                  if (!_showAns) {
                                    setState(() {
                                      questionData.forEach(
                                        (element) => element.isSelected = false,
                                      );
                                      questionData[index].isSelected = true;
                                      final_data[questions[ques_no].id!] =
                                          questionData[index].buttonText;
                                    });
                                  }
                                },
                                child: _buildChoiceText(
                                  choice,
                                  text,
                                  correctAnswerForCurrentQues,
                                  userChosenAnswerForCurrentQues,
                                  devWidth,
                                ),
                              );
                            },
                          ),

                          // --- REINSTATED ExpansionTile for Local DB Explanation ---
                          if (questions[ques_no].explanation != null &&
                              questions[ques_no].explanation!.isNotEmpty &&
                              _showAns)
                            Padding(
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
                                initiallyExpanded: _showExplanation,
                                onExpansionChanged: (bool expanded) {
                                  if (mounted) {
                                    setState(() {
                                      _showExplanation = expanded;
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
                          SizedBox(height: 70), // For FAB
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
            FloatingActionButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    if (ques_no > 0) ques_no--;
                    assignQues(); // This will also reset _showExplanation
                  });
                }
              },
              child: Text('Prev.'),
              backgroundColor: Color(0xff0081B9),
              heroTag: 'prevButton',
            ),
            FloatingActionButton(
              onPressed: () {
                // ... (AwesomeDialog logic for ending exam)
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
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        SizedBox(height: 10),
                        Text(
                          'You are going to finish the exam and get information about your score. Do you want to continue?',
                          style: TextStyle(
                            color: Color(0xff0081B9),
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
                    analyse();
                  },
                )..show();
              },
              child: Text('End'),
              backgroundColor: Colors.green,
              heroTag: 'endButton',
            ),
            // --- "Show" FloatingActionButton for Local Explanation ---
            if (questions[ques_no].explanation != null &&
                questions[ques_no].explanation!.isNotEmpty)
              FloatingActionButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showAns = !_showAns;
                      // If Gemini explanation was shown via bottom sheet, it remains independent.
                      // This button only controls the local ExpansionTile.
                    });
                  }
                },
                child: Text(
                  _showAns ? 'Hide' : 'Show',
                ), // Text changes based on state
                backgroundColor: AppTheme.colorF0A714,
                heroTag: 'showLocalExplanationButton',
              ),
            FloatingActionButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    if (ques_no < questions.length - 1) ques_no++;
                    assignQues(); // This will also reset _showExplanation
                  });
                }
              },
              child: Text('Next'),
              backgroundColor: Color(0xff0081B9),
              heroTag: 'nextButton',
            ),
          ],
        ),
      ),
    );
  }

  analyse() {
    // ... (analyse logic remains the same)
    right_ans_ids.clear();
    wrong_ans_data.clear();
    unans_ans_ids.clear();
    chapter_question_count.clear();
    chapter_right_count.clear();
    chapter_wrong_count.clear();

    for (var i = 0; i < questions.length; i++) {
      int? questionId = questions[i].id;
      int? chapterId = questions[i].chapter;
      String correctAnswer = questions[i].ans?.toLowerCase() ?? '';
      String? chosenAnswer = final_data[questionId]?.toLowerCase();

      chapter_question_count[chapterId] =
          (chapter_question_count[chapterId] ?? 0) + 1;

      if (chosenAnswer != null) {
        if (chosenAnswer == correctAnswer) {
          right_ans_ids.add(questionId);
          chapter_right_count[chapterId] =
              (chapter_right_count[chapterId] ?? 0) + 1;
        } else {
          wrong_ans_data[questionId] = final_data[questionId]!;
          chapter_wrong_count[chapterId] =
              (chapter_wrong_count[chapterId] ?? 0) + 1;
        }
      } else {
        unans_ans_ids.add(questionId);
      }
    }

    finalToDatabase();
  }

  finalToDatabase() async {
    // ... (finalToDatabase logic remains the same)
    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    try {
      String rightAnsString = right_ans_ids
          .map((id) => id.toString())
          .join(',');
      String wrongAnsString = wrong_ans_data.keys
          .map((id) => id.toString())
          .join(',');
      String unansAnsString = unans_ans_ids
          .map((id) => id.toString())
          .join(',');

      if (_examId == null) {
        print("Exam ID is null. Cannot save result.");
        return;
      }

      Result result = Result(
        exam: _examId,
        right: rightAnsString.isNotEmpty ? rightAnsString : '0',
        wrong: wrongAnsString.isNotEmpty ? wrongAnsString : '0',
        unanswered: unansAnsString.isNotEmpty ? unansAnsString : '0',
        date: DateTime.now().toIso8601String(),
        uploaded: 0,
      );

      int resultId = await result.save();

      for (var entry in wrong_ans_data.entries) {
        ResultWrong resultWrong = ResultWrong(
          result: resultId,
          question: entry.key,
          choosen: entry.value,
        );
        await resultWrong.save();
      }

      for (var chapterId in chapter_question_count.keys) {
        if (chapterId != null) {
          int totalQuestions = chapter_question_count[chapterId] ?? 0;
          int rightQuestions = chapter_right_count[chapterId] ?? 0;
          int wrongQuestions = chapter_wrong_count[chapterId] ?? 0;
          int unansweredQuestions =
              totalQuestions - rightQuestions - wrongQuestions;

          ResultChapter resultChapter = ResultChapter(
            result: resultId,
            chapter: chapterId,
            no_questions: totalQuestions,
            right: rightQuestions,
            wrong: wrongQuestions,
            unanswered: unansweredQuestions,
            avg_time: '0',
          );
          await resultChapter.save();
        }
      }

      for (var questionId in fav_list) {
        if (questionId != null) {
          Favorite favorite = Favorite(question: questionId);
          await favorite.save();
        }
      }

      print('Exam results saved successfully with Result ID: $resultId');

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/result',
          arguments: {
            "result_id": resultId,
            'title': _examTitle,
            'exam_id': _examId,
            'time': _examTime,
          },
        );
      }
    } catch (e) {
      print('Error saving exam results: $e');
    }
  }
}

class RadioModel {
  bool isSelected;
  final String buttonText;
  final String text;

  RadioModel(this.isSelected, this.buttonText, this.text);
}
