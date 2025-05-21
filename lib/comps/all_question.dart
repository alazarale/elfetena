import 'dart:ffi';
import 'dart:math';

import 'package:chapasdk/domain/constants/app_colors.dart'; // Assuming this contains AppTheme
import 'package:eltest_exit/comps/service/database_manipulation.dart';
import '../models/exam_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';

import '../theme/app_theme.dart'; // Assuming AppTheme is here
import 'circle_progress.dart';
import 'feedback_dialog.dart';
import 'service/common.dart'; // Import your database helper and models

class AllQuestion extends StatefulWidget {
  AllQuestion({Key? key, this.exam_title, this.exam_id, this.exam_time})
    : super(key: key);

  String? exam_title;
  int? exam_id;
  int? exam_time;

  @override
  State<AllQuestion> createState() => _AllQuestionState();
}

class _AllQuestionState extends State<AllQuestion> {
  bool isLoading = true;
  int? _resultId;
  var _results;
  List<int> _rightQuestionIds = []; // Store right question IDs as integers
  List<int> _wrongQuestionIds = []; // Store wrong question IDs as integers
  List<int> _unansweredQuestionIds =
      []; // Store unanswered question IDs as integers
  List<int> _allAnsweredQuestionIds =
      []; // Store all question IDs from the result

  ExamModel? _exam;
  int? examId;
  int _totalQuestion = 0;
  double perc = 0;
  List wrongRes = [];
  String? _examTitle;
  var fav_list = []; // Keep if needed for other purposes
  List<Map<String, dynamic>> res_chapter =
      []; // Keep if needed for other analysis
  List<Map<String, dynamic>> res_wrong =
      []; // Keep if needed for other analysis

  Map<String, double> dataMap = {
    'none': 3,
    'none2': 5,
  }; // Keep if needed for other analysis
  Map<String, String> chapterMap =
      {}; // Map chapter ID (string) to "Unit: Name"
  Map<int, Map<String, dynamic>> questionMap = {}; // Store all questions by ID
  List<Map<String, dynamic>> _allQuestions =
      []; // List to hold all questions for the exam

  // Set to keep track of favorited question IDs
  Set<int> _favoritedQuestionIds = {};

  // Map to track expanded state of explanations for questions
  Map<int, bool> explanationExpandedState = {};

  // Declare and initialize userWrongAnswers map at the class level
  Map<int, String> userWrongAnswers = {};

  // Map to store subchapter info: {subchapterId: {name: '...', chapter: '...'}}
  Map<int, Map<String, dynamic>> subchapterMap = {};

  @override
  void initState() {
    super.initState();
    // Explicitly initialize userWrongAnswers in initState
    userWrongAnswers = {};
    _loadFavoritedQuestions(); // Load favorited questions when the widget initializes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _resultId = arguments['result_id'];
    _examTitle = arguments['title'];

    getResults(_resultId);
  }

  // Function to load favorited questions from the database
  Future<void> _loadFavoritedQuestions() async {
    final favoriteModel = Favorite();
    final favoritedList = await favoriteModel.getAll();
    setState(() {
      _favoritedQuestionIds = favoritedList.map((fav) => fav.question!).toSet();
    });
  }

  // Function to add or remove a question from favorites
  Future<void> _toggleFavoriteStatus(int questionId) async {
    final favoriteModel = Favorite();
    final existingFavorite = await favoriteModel.query(
      where: 'question = ?',
      whereArgs: [questionId],
    );

    if (existingFavorite.isNotEmpty) {
      // Question is already favorited, remove it
      // Assuming the query returns a list of Favorite objects, we need the ID to delete
      if (existingFavorite.first.id != null) {
        await Favorite(id: existingFavorite.first.id).delete();
        setState(() {
          _favoritedQuestionIds.remove(questionId);
        });
        print('Removed question $questionId from favorites');
      }
    } else {
      // Question is not favorited, add it
      final newFavorite = Favorite(question: questionId);
      await newFavorite.save();
      setState(() {
        _favoritedQuestionIds.add(questionId);
      });
      print('Added question $questionId to favorites');
    }
  }

  getResults(resultId) async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);
    final List<Map<String, dynamic>> _r_maps = await db.query(
      'result',
      where: 'id=${resultId}',
    );

    if (_r_maps.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return; // Exit if result not found
    }

    _results = _r_maps[0];

    // Parse question IDs from the result strings
    _rightQuestionIds =
        _results['right']
            .toString()
            .split(',')
            .where((id) => id.isNotEmpty)
            .map((id) => int.parse(id))
            .toList();
    _wrongQuestionIds =
        _results['wrong']
            .toString()
            .split(',')
            .where((id) => id.isNotEmpty)
            .map((id) => int.parse(id))
            .toList();
    _unansweredQuestionIds =
        _results['unanswered']
            .toString()
            .split(',')
            .where((id) => id.isNotEmpty)
            .map((id) => int.parse(id))
            .toList();
    _allAnsweredQuestionIds = [
      ..._rightQuestionIds,
      ..._wrongQuestionIds,
      ..._unansweredQuestionIds,
    ];

    examId = _results['exam'];

    // Fetch all questions for the exam
    final List<Map<String, dynamic>> ques = await db.query(
      'question',
      where: 'exam=${examId}',
    );

    // Populate questionMap with all questions from the exam
    ques.forEach((element) {
      questionMap[element['id']] = element;
    });

    // Store all questions in _allQuestions list
    _allQuestions = ques;

    // Fetch wrong answers for the result to get user's chosen answer
    res_wrong = await db.query('resultwrong', where: 'result=${resultId}');

    // Populate userWrongAnswers map
    userWrongAnswers.clear();
    res_wrong.forEach((wrongAnswer) {
      userWrongAnswers[wrongAnswer['question']] = wrongAnswer['choosen'];
    });

    // Fetch chapters and subchapters to get names
    final List<Map<String, dynamic>> chapters = await db.query('chapter');
    final List<Map<String, dynamic>> subchapters = await db.query('subchapter');

    // Populate chapterMap and subchapterMap
    chapters.forEach((element) {
      chapterMap[element['id'].toString()] =
          element['unit'] + ': ' + element['name'];
    });
    subchapters.forEach((element) {
      subchapterMap[element['id']] = {
        'name': element['name'],
        'chapter': element['chapter'],
      };
    });

    setState(() {
      isLoading =
          false; // Set loading to false after data is fetched and processed
    });
  }

  // Helper function to build choice text with highlighting
  Widget _buildChoiceText(
    String choice,
    String? text,
    String correctAnswer,
    String? userChosenAnswer,
    bool isQuestionAnswered,
  ) {
    Color textColor = Colors.black87; // Default text color
    FontWeight fontWeight = FontWeight.normal;

    // Highlight correct answer in green
    if (choice == correctAnswer) {
      textColor = Color.fromARGB(255, 24, 111, 68); // Green color
      fontWeight = FontWeight.bold;
    }

    // Highlight user's wrong answer in red if the question was answered and the user was wrong
    if (isQuestionAnswered &&
        userChosenAnswer != null &&
        choice == userChosenAnswer &&
        choice != correctAnswer) {
      textColor = Color.fromARGB(255, 155, 27, 27); // Red color
      fontWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$choice. ${text ?? ''}',
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xffF2F5F8),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Select Mode'),
                content: Column(
                  // Use a Column to arrange buttons vertically
                  mainAxisSize:
                      MainAxisSize.min, // Make the column take minimum space
                  children: <Widget>[
                    // Button for Study Mode
                    ElevatedButton(
                      onPressed: () {
                        // Return a value indicating Study Mode was selected
                        Navigator.pushNamed(
                          context,
                          '/take-study',
                          arguments: {
                            "exam_id": widget.exam_id,
                            'title': widget.exam_title, 
                            'time': widget.exam_time,
                          },
                        );
                        
                      },
                      child: const Text('Study Mode'),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Add some spacing between buttons
                    // Button for Exam Mode
                    ElevatedButton(
                      onPressed: () {
                        // Return a value indicating Exam Mode was selected
                        Navigator.pushNamed(
                          context,
                          '/take',
                          arguments: {
                            "exam_id": widget.exam_id,
                            'title': widget.exam_title, 
                            'time': widget.exam_time,
                          },
                        );
                      },
                      child: const Text('Exam Mode'),
                    ),
                  ],
                ),
                // Optional: Add a close button in actions if needed, but popping on button press is common
                // actions: <Widget>[
                //   TextButton(
                //     child: const Text('Cancel'),
                //     onPressed: () {
                //       Navigator.of(context).pop(); // Close the dialog without returning a value
                //     },
                //   ),
                // ],
              );
            },
          );
        },
        child: Text("Retake Exam"),
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(
            Color.fromARGB(255, 255, 255, 255),
          ),
          backgroundColor: MaterialStateProperty.all<Color>(Color(0xff0081B9)),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Position the button
      body: SingleChildScrollView(
        child: Visibility(
          visible: !isLoading, // Show content only when not loading
          replacement: Center(
            child: CircularProgressIndicator(),
          ), // Show loading indicator
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to the start
              children: [
                const Center(
                  child: Text(
                    'All Questions',
                    style: TextStyle(
                      color: Color(0xff21205A),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Display total number of questions
                Text(
                  'Total Questions: ${_allQuestions.length}',
                  style: TextStyle(
                    color: AppTheme.color21205A,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20), // Add some space
                // Use ListView.builder to display all questions
                ListView.builder(
                  shrinkWrap:
                      true, // Use shrinkWrap to make it work inside SingleChildScrollView
                  physics:
                      NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
                  itemCount: _allQuestions.length,
                  itemBuilder: (context, index) {
                    final question = _allQuestions[index];
                    final int questionId = question['id'];
                    final String correctAnswer = question['ans'];

                    // Determine the status of the question
                    String status = 'Unanswered';
                    Color statusColor = Color(0xffFDF1D9); // Unanswered color
                    bool isQuestionAnswered = _allAnsweredQuestionIds.contains(
                      questionId,
                    );
                    String? userChosenAnswer =
                        userWrongAnswers[questionId]; // Get user's answer (only exists for wrong answers)

                    if (_rightQuestionIds.contains(questionId)) {
                      status = 'Right';
                      statusColor = Color(0xffDDF0E6); // Right color
                    } else if (_wrongQuestionIds.contains(questionId)) {
                      status = 'Wrong';
                      statusColor = Color(0xffFDE4E4); // Wrong color
                    }

                    // Get the current expanded state for this question
                    bool isExplanationExpanded =
                        explanationExpandedState[questionId] ?? false;

                    // Determine the question text to display (including note if available)
                    String displayedQuestionText = 'Question ${index + 1}: ';
                    if (question['note'] != null &&
                        question['note'].isNotEmpty) {
                      displayedQuestionText +=
                          '${question['note']}\n${question['ques']}';
                    } else {
                      displayedQuestionText += question['ques'];
                    }

                    // Check if the question is favorited
                    bool isFavorited = _favoritedQuestionIds.contains(
                      questionId,
                    );

                    // Get chapter and subchapter names for the path
                    String chapterUnitName = 'Unknown Unit';
                    String chapterName = 'Unknown Chapter';
                    String subchapterName = 'Unknown Subchapter';

                    if (question['chapter'] != null) {
                      final chapterInfo =
                          chapterMap[question['chapter'].toString()];
                      if (chapterInfo != null) {
                        final parts = chapterInfo.split(':');
                        if (parts.length == 2) {
                          chapterUnitName = parts[0].trim();
                          chapterName = parts[1].trim();
                        }
                      }
                    }

                    if (question['subchapter'] != null) {
                      final subchapterInfo =
                          subchapterMap[question['subchapter']];
                      if (subchapterInfo != null) {
                        subchapterName = subchapterInfo['name'];
                      }
                    }

                    String chapterPath =
                        '$chapterUnitName > $chapterName > $subchapterName';

                    return Card(
                      // Wrap each question in a Card
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 1.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              // Row for Status Label and Favorite Icon
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status Label
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          AppTheme
                                              .color21205A, // Or a color that contrasts well with the background
                                    ),
                                  ),
                                ),
                                // Favorite Icon
                                IconButton(
                                  icon: Icon(
                                    isFavorited
                                        ? Icons.favorite
                                        : Icons
                                            .favorite_border, // Filled or outlined heart
                                    color:
                                        isFavorited
                                            ? Colors.red
                                            : Colors
                                                .grey, // Red if favorited, grey otherwise
                                  ),
                                  onPressed: () {
                                    // Toggle favorite status and update state
                                    _toggleFavoriteStatus(questionId).then((_) {
                                      setState(() {
                                        // Update the local state
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            // Display Chapter Path
                            Text(
                              chapterPath,
                              style: TextStyle(
                                color: Color(0xff0081B9), // Specified color
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 8.0,
                            ), // Space between path and question text
                            Text(
                              displayedQuestionText, // Use the determined question text
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.color21205A,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            // Display choices with highlighting
                            _buildChoiceText(
                              'A',
                              question['a'],
                              correctAnswer,
                              userChosenAnswer,
                              isQuestionAnswered,
                            ),
                            _buildChoiceText(
                              'B',
                              question['b'],
                              correctAnswer,
                              userChosenAnswer,
                              isQuestionAnswered,
                            ),
                            _buildChoiceText(
                              'C',
                              question['c'],
                              correctAnswer,
                              userChosenAnswer,
                              isQuestionAnswered,
                            ),
                            _buildChoiceText(
                              'D',
                              question['d'],
                              correctAnswer,
                              userChosenAnswer,
                              isQuestionAnswered,
                            ),
                            // Add ExpansionTile for Explanation if explanation is available
                            if (question['explanation'] != null &&
                                question['explanation'].isNotEmpty)
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Show Explanation',
                                  style: TextStyle(
                                    color:
                                        AppTheme
                                            .color0081B9, // Color to indicate clickability
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Control the expanded state using the state map
                                initiallyExpanded:
                                    explanationExpandedState[questionId] ??
                                    false,
                                onExpansionChanged: (bool expanded) {
                                  // Update the state map when the expansion changes
                                  setState(() {
                                    explanationExpandedState[questionId] =
                                        expanded;
                                  });
                                },
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      question['explanation'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 80,
                ), // Added space at the bottom to prevent content from being hidden by the FAB
              ],
            ),
          ),
        ),
      ),
    );
  }
}
