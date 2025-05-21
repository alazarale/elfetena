import 'dart:ffi';
import 'dart:math';

import 'package:chapasdk/domain/constants/app_colors.dart';
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
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';
import 'circle_progress.dart';// Import your database helper and models

class ChapterAnalysis extends StatefulWidget {
  ChapterAnalysis({Key? key, this.exam_title, this.exam_id, this.exam_time})
    : super(key: key);

  String? exam_title;
  int? exam_id;
  int? exam_time;

  @override
  State<ChapterAnalysis> createState() => _ChapterAnalysisState();
}

class _ChapterAnalysisState extends State<ChapterAnalysis> {
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
  List<Map<String, dynamic>> res_chapter = [];
  List<Map<String, dynamic>> res_wrong = [];

  Map<String, double> dataMap = {'none': 3, 'none2': 5};
  Map<String, String> chapterMap = {};
  Map<int, Map<String, dynamic>> questionMap = {}; // Store questions by ID
  int touchedIndex = -1;
  late List<Color> colors;

  // Map to group chapter results by unit
  Map<String, List<Map<String, dynamic>>> groupedChapterResults = {};

  // Map to store subchapter analysis data per chapter: {chapterId: [{subchapter analysis}]}
  Map<int, List<Map<String, dynamic>>> subchapterAnalysis = {};
  // Map to store subchapter info: {subchapterId: {name: '...', chapter: '...'}}
  Map<int, Map<String, dynamic>> subchapterMap = {};

  // Map to store user's chosen answer for wrong questions: {questionId: chosenAnswer}
  Map<int, String> userWrongAnswers = {};

  // Flattened list of chapters for ListView.builder
  List<Map<String, dynamic>> flattenedChapters = [];

  // Set to keep track of favorited question IDs in the bottom sheet
  Set<int> _favoritedQuestionIds = {};

  @override
  void initState() {
    super.initState();
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
      await favoriteModel.delete(); // Assuming delete() uses the instance's ID
      setState(() {
        _favoritedQuestionIds.remove(questionId);
      });
      // You might want to show a message like "Removed from favorites"
      print('Removed question $questionId from favorites');
    } else {
      // Question is not favorited, add it
      final newFavorite = Favorite(question: questionId);
      await newFavorite.save();
      setState(() {
        _favoritedQuestionIds.add(questionId);
      });
      // You might want to show a message like "Added to favorites"
      print('Added question $questionId to favorites');
    }
  }

  List<Color> _generateColors(int numberOfColors) {
    final List<Color> colorList = [];
    final Random random = Random();
    for (int i = 0; i < numberOfColors; i++) {
      // Generate a random color with good saturation and brightness
      // This helps in getting visually distinct colors
      HSLColor hslColor = HSLColor.fromAHSL(
        1.0, // Alpha
        random.nextDouble() * 360, // Hue (0-360)
        0.7 + random.nextDouble() * 0.3, // Saturation (0.7-1.0)
        0.5 + random.nextDouble() * 0.3, // Lightness (0.5-0.8)
      );
      colorList.add(hslColor.toColor());
    }
    return colorList;
  }

  List<PieChartSectionData> showingSections() {
    int index = 0;
    return dataMap.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 60 : 50;
      // Use modulo to cycle through generated colors if data count exceeds color count
      final color = colors[index % colors.length];

      final value = entry.value;
      // Format the title to show both the domain and the value
      final title = '${entry.key}\n${value.toStringAsFixed(1)}';

      // Increment index for the next section
      index++;

      return PieChartSectionData(
        color: color,
        value: value,
        title: title,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text for better contrast on colors
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2),
          ], // Text shadow for readability
        ),
        // Set showTitle to true only if the section is touched
        showTitle: isTouched,
        // You can add badgeWidget here for more complex indicators if needed
      );
    }).toList();
  }

  getResults(resultId) async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);

    // Fetch result and exam info
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

    // Fetch questions for the exam
    final List<Map<String, dynamic>> ques = await db.query(
      'question',
      where: 'exam=${examId}',
    );

    // Populate questionMap with all questions from the exam
    ques.forEach((element) {
      questionMap[element['id']] = element;
    });

    // Filter questions to only include those present in the current result
    final List<Map<String, dynamic>> resultQuestions =
        ques
            .where(
              (question) => _allAnsweredQuestionIds.contains(question['id']),
            )
            .toList();

    _totalQuestion = resultQuestions.length; // Total questions in this result

    // Fetch wrong answers for the result
    res_wrong = await db.query('resultwrong', where: 'result=${resultId}');

    // Populate userWrongAnswers map
    userWrongAnswers.clear();
    res_wrong.forEach((wrongAnswer) {
      userWrongAnswers[wrongAnswer['question']] = wrongAnswer['choosen'];
    });

    // Debugging: Print userWrongAnswers map
    print('User Wrong Answers: $userWrongAnswers');

    // Fetch chapter results for the result
    res_chapter = await db.query('resultchapter', where: 'result=${resultId}');

    // Fetch chapters and subchapters
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

    if (_totalQuestion > 0) {
      dataMap.clear();
      groupedChapterResults.clear();
      subchapterAnalysis.clear();
      flattenedChapters.clear(); // Clear flattened list

      // Populate dataMap and groupedChapterResults by unit using res_chapter
      res_chapter.forEach((element) {
        final chapterId = element['chapter'].toString();
        final chapterInfo = chapterMap[chapterId];
        if (chapterInfo != null) {
          final unit = chapterInfo.split(':')[0].trim(); // Extract unit

          // Update dataMap for pie chart (questions per unit)
          dataMap[unit] == null
              ? dataMap[unit] = element['no_questions'].toDouble()
              : dataMap[unit] =
                  dataMap[unit]!.toDouble() +
                  element['no_questions'].toDouble();

          // Group chapter results by unit
          if (!groupedChapterResults.containsKey(unit)) {
            groupedChapterResults[unit] = [];
          }
          groupedChapterResults[unit]!.add(element);
        }
      });

      // Calculate total questions and wrong answers per subchapter for the *current result's questions*
      Map<int, int> totalQuestionsPerSubchapter = {};
      Map<int, int> wrongAnswersPerSubchapter = {};
      Map<int, int> rightAnswersPerSubchapter = {}; // New map for right answers

      resultQuestions.forEach((question) {
        final int? subchapterId = question['subchapter'];
        if (subchapterId != null) {
          totalQuestionsPerSubchapter[subchapterId] =
              (totalQuestionsPerSubchapter[subchapterId] ?? 0) + 1;
        }
      });

      // Filter wrong answers to only include those from the current result
      final List<Map<String, dynamic>> resultWrongAnswers =
          res_wrong
              .where(
                (wrongAnswer) =>
                    _allAnsweredQuestionIds.contains(wrongAnswer['question']),
              )
              .toList();

      resultWrongAnswers.forEach((wrongAnswer) {
        final int? questionId = wrongAnswer['question'];
        if (questionId != null && questionMap.containsKey(questionId)) {
          final question = questionMap[questionId];
          final int? subchapterId = question!['subchapter'];
          if (subchapterId != null) {
            wrongAnswersPerSubchapter[subchapterId] =
                (wrongAnswersPerSubchapter[subchapterId] ?? 0) + 1;
          }
        }
      });

      // Calculate right answers per subchapter by checking _rightQuestionIds
      _rightQuestionIds.forEach((questionId) {
        if (questionMap.containsKey(questionId) &&
            _allAnsweredQuestionIds.contains(questionId)) {
          final question = questionMap[questionId];
          final int? subchapterId = question!['subchapter'];
          if (subchapterId != null) {
            rightAnswersPerSubchapter[subchapterId] =
                (rightAnswersPerSubchapter[subchapterId] ?? 0) + 1;
          }
        }
      });

      // Populate subchapterAnalysis per chapter, only for subchapters present in resultQuestions
      Map<int, List<int>> chapterToSubchapterIdsInResult = {};
      resultQuestions.forEach((question) {
        final int? chapterId = question['chapter'];
        final int? subchapterId = question['subchapter'];
        if (chapterId != null && subchapterId != null) {
          if (!chapterToSubchapterIdsInResult.containsKey(chapterId)) {
            chapterToSubchapterIdsInResult[chapterId] = [];
          }
          if (!chapterToSubchapterIdsInResult[chapterId]!.contains(
            subchapterId,
          )) {
            chapterToSubchapterIdsInResult[chapterId]!.add(subchapterId);
          }
        }
      });

      chapterToSubchapterIdsInResult.forEach((chapterId, subchapterIds) {
        subchapterAnalysis[chapterId] = [];
        subchapterIds.forEach((subchapterId) {
          final subchapterInfo = subchapterMap[subchapterId];
          if (subchapterInfo != null) {
            final String subchapterName = subchapterInfo['name'];
            final int totalQ = totalQuestionsPerSubchapter[subchapterId] ?? 0;
            final int wrongA = wrongAnswersPerSubchapter[subchapterId] ?? 0;
            // Use the calculated right answers directly
            final int rightA = rightAnswersPerSubchapter[subchapterId] ?? 0;

            double percentage = 0.0;
            if (totalQ > 0) {
              percentage = (rightA / totalQ) * 100;
            }

            subchapterAnalysis[chapterId]!.add({
              'id': subchapterId,
              'name': subchapterName,
              'total_questions': totalQ,
              'right': rightA,
              'wrong': wrongA,
              'percentage': percentage,
            });
          }
        });
        // Sort subchapters by name within each chapter
        subchapterAnalysis[chapterId]!.sort(
          (a, b) => a['name'].compareTo(b['name']),
        );
      });

      // Flatten groupedChapterResults for ListView.builder
      groupedChapterResults.forEach((unit, chapters) {
        // Add a dummy entry for the unit header
        flattenedChapters.add({'type': 'unit', 'name': unit});
        // Add chapter entries
        flattenedChapters.addAll(
          chapters.map((chapter) => {'type': 'chapter', ...chapter}),
        );
      });

      setState(() {
        perc = (_rightQuestionIds.length / _totalQuestion) * 100;
        wrongRes =
            res_wrong; // Keep res_wrong for other potential uses if needed
        colors = _generateColors(dataMap.length);
        isLoading =
            false; // Set loading to false after data is fetched and processed
      });
    } else {
      setState(() {
        isLoading = false; // Set loading to false even if no questions
      });
    }
  }

  // Function to show the bottom sheet with questions
  void _showQuestionsBottomSheet({
    String? unitName,
    int? chapterId,
    int? subchapterId,
    String? title, // Title for the bottom sheet
  }) {
    List<Map<String, dynamic>> questionsToShow = [];

    // Determine which questions to show based on the provided parameters
    if (unitName != null) {
      // Show questions for a specific unit
      groupedChapterResults[unitName]?.forEach((chapterResult) {
        final int currentChapterId = chapterResult['chapter'];
        questionMap.values.forEach((question) {
          if (question['chapter'] == currentChapterId &&
              _allAnsweredQuestionIds.contains(question['id'])) {
            questionsToShow.add(question);
          }
        });
      });
    } else if (chapterId != null) {
      // Show questions for a specific chapter
      questionMap.values.forEach((question) {
        if (question['chapter'] == chapterId &&
            _allAnsweredQuestionIds.contains(question['id'])) {
          questionsToShow.add(question);
        }
      });
    } else if (subchapterId != null) {
      // Show questions for a specific subchapter
      questionMap.values.forEach((question) {
        if (question['subchapter'] == subchapterId &&
            _allAnsweredQuestionIds.contains(question['id'])) {
          questionsToShow.add(question);
        }
      });
    }

    // Sort questions by ID for consistent order
    questionsToShow.sort((a, b) => a['id'].compareTo(b['id']));

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the bottom sheet to take up almost full height
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage the expanded state of explanations and favorite status
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Map to track expanded state of explanations for questions in this bottom sheet
            Map<int, bool> explanationExpandedState = {};

            return DraggableScrollableSheet(
              initialChildSize: 0.75, // Initial height of the bottom sheet
              maxChildSize: 0.95, // Maximum height
              expand: false, // Don't expand to full screen by default
              builder: (
                BuildContext context,
                ScrollController scrollController,
              ) {
                return Container(
                  // Added BoxDecoration for curved corners
                  decoration: BoxDecoration(
                    color:
                        AppTheme.white, // Background color for the bottom sheet
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Handle for dragging the sheet
                      Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(bottom: 16.0),
                      ),
                      Text(
                        title ?? 'Questions', // Display the title
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.color21205A,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: questionsToShow.length,
                          itemBuilder: (context, index) {
                            final question = questionsToShow[index];
                            final int questionId = question['id'];
                            final String correctAnswer = question['ans'];
                            final String? userChosenAnswer =
                                userWrongAnswers[questionId]; // Get user's answer if wrong

                            // Determine the status of the question
                            String status = 'Unanswered';
                            Color statusColor = Color(
                              0xffFDF1D9,
                            ); // Unanswered color

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
                            String displayedQuestionText =
                                'Question ${index + 1}: ';
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Status Label
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
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
                                            // Toggle favorite status and update modal state
                                            _toggleFavoriteStatus(
                                              questionId,
                                            ).then((_) {
                                              setModalState(() {
                                                // Update the local state within the modal
                                              });
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.0),
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
                                      _rightQuestionIds.contains(questionId),
                                      _wrongQuestionIds.contains(questionId),
                                    ),
                                    _buildChoiceText(
                                      'B',
                                      question['b'],
                                      correctAnswer,
                                      userChosenAnswer,
                                      _rightQuestionIds.contains(questionId),
                                      _wrongQuestionIds.contains(questionId),
                                    ),
                                    _buildChoiceText(
                                      'C',
                                      question['c'],
                                      correctAnswer,
                                      userChosenAnswer,
                                      _rightQuestionIds.contains(questionId),
                                      _wrongQuestionIds.contains(questionId),
                                    ),
                                    _buildChoiceText(
                                      'D',
                                      question['d'],
                                      correctAnswer,
                                      userChosenAnswer,
                                      _rightQuestionIds.contains(questionId),
                                      _wrongQuestionIds.contains(questionId),
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
                                            isExplanationExpanded,
                                        onExpansionChanged: (bool expanded) {
                                          // Update the state map when the expansion changes
                                          setModalState(() {
                                            explanationExpandedState[questionId] =
                                                expanded;
                                          });
                                        },
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
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
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper function to build choice text with highlighting
  Widget _buildChoiceText(
    String choice,
    String? text,
    String correctAnswer,
    String? userChosenAnswer,
    bool isCorrect,
    bool isWrong,
  ) {
    Color textColor = Colors.black87; // Default text color
    FontWeight fontWeight = FontWeight.normal;

    // Highlight correct answer in green if answered correctly or if the user was wrong
    if (choice == correctAnswer) {
      textColor = Color.fromARGB(255, 24, 111, 68); // Updated green color
      fontWeight = FontWeight.bold;
    }

    // Highlight user's wrong answer in red if the user was wrong
    if (isWrong && choice == userChosenAnswer) {
      textColor = Color.fromARGB(255, 155, 27, 27); // Updated red color
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
      backgroundColor: AppTheme.colorF2F5F8,
      // Added floatingActionButton and floatingActionButtonLocation
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
          foregroundColor: MaterialStateProperty.all<Color>(AppTheme.white),
          backgroundColor: MaterialStateProperty.all<Color>(
            AppTheme.color0081B9,
          ),
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
        // Wrapped the entire body content in SingleChildScrollView
        child: Visibility(
          visible: !isLoading, // Show content only when not loading
          replacement: Center(
            child: CircularProgressIndicator(),
          ), // Show loading indicator
          child: Column(
            children: [
              SizedBox(height: 20),
              const Center(
                child: Text(
                  'Analysis By Topic',
                  style: TextStyle(
                    color: AppTheme.color21205A,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 1.3, // Aspect ratio for the chart container
                child: PieChart(
                  PieChartData(
                    // Configure touch interactions
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          // Check if a section is touched
                          if (pieTouchResponse != null &&
                              pieTouchResponse.touchedSection != null) {
                            final newIndex =
                                pieTouchResponse
                                    .touchedSection!
                                    .touchedSectionIndex;
                            // If the touched section is the same as the currently touched one, un-pop it
                            if (newIndex == touchedIndex) {
                              touchedIndex = -1;
                            } else {
                              // Otherwise, pop the newly touched section
                              touchedIndex = newIndex;
                            }
                          } else {
                            // If no section is touched (e.g., released finger), do NOT reset touchedIndex
                            // touchedIndex remains as it was, keeping the last touched section popped
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(
                      show: false, // Hide the border around the chart
                    ),
                    sectionsSpace: 0, // No space between pie sections
                    centerSpaceRadius: 40, // Radius of the central empty space
                    sections:
                        showingSections(), // Provide the generated sections
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppTheme.white,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align content to the start
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Detail Analysis',
                        style: TextStyle(
                          color: AppTheme.color21205A,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Iterate through the flattened list of units and chapters
                    ...flattenedChapters.map((item) {
                      if (item['type'] == 'unit') {
                        // Render Unit Header
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name'], // Display unit name
                                style: TextStyle(
                                  color: AppTheme.color21205A,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                // Eye icon for Unit
                                icon: Icon(Icons.remove_red_eye_outlined),
                                color: Color(0xff28A164), // Updated color
                                onPressed: () {
                                  _showQuestionsBottomSheet(
                                    unitName: item['name'],
                                    title:
                                        'Questions for Unit: ${item['name']}',
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Render Chapter Card
                        final int chapterId = item['chapter'];
                        final chapterInfo = chapterMap[chapterId.toString()];
                        final chapterName =
                            chapterInfo != null
                                ? chapterInfo.split(':')[1].trim()
                                : 'Unknown Chapter';
                        final rightAnswers = item['right'];
                        final totalQuestions = item['no_questions'];
                        final percentage =
                            totalQuestions > 0
                                ? (rightAnswers / totalQuestions) * 100
                                : 0.0;

                        // Get subchapter analysis for this chapter and result
                        final List<Map<String, dynamic>> subchaptersForResult =
                            subchapterAnalysis[chapterId] ?? [];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  // Chapter Name and Percentage
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: Text(
                                        chapterName,
                                        maxLines: 2,
                                        textAlign: TextAlign.justify,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppTheme.color21205A,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${percentage.toStringAsFixed(1)}%",
                                        style: TextStyle(
                                          color: AppTheme.color0081B9,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // Linear Percent Indicator (full width)
                                LinearPercentIndicator(
                                  width:
                                      devWidth -
                                      64, // Full width minus card padding
                                  animation: true,
                                  lineHeight: 12.0,
                                  animationDuration: 1000,
                                  percent:
                                      totalQuestions > 0
                                          ? rightAnswers / totalQuestions
                                          : 0.0,
                                  barRadius: Radius.circular(10),
                                  progressColor: AppTheme.color0081B9,
                                  backgroundColor: AppTheme.colorE1E9F9,
                                ),
                                SizedBox(
                                  height: 8,
                                ), // Space between line bar and scored row
                                Row(
                                  // Scored Text and View Button (Eye Icon)
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      // Scored Text
                                      children: [
                                        Text(
                                          "Scored: ",
                                          style: TextStyle(
                                            color: AppTheme.color0081B9,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          "${rightAnswers}/${totalQuestions}",
                                          style: TextStyle(
                                            color: AppTheme.color0081B9,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      // Eye icon for Chapter
                                      icon: Icon(Icons.remove_red_eye_outlined),
                                      color: Color(0xff28A164), // Updated color
                                      onPressed: () {
                                        _showQuestionsBottomSheet(
                                          chapterId: chapterId,
                                          title:
                                              'Questions for Chapter: $chapterName',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (subchaptersForResult.isNotEmpty)
                                  ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                      'SubTopic Breakdown',
                                      style: TextStyle(
                                        color: AppTheme.color0081B9,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    children:
                                        subchaptersForResult.map((subchapter) {
                                          final int subchapterId =
                                              subchapter['id'];
                                          final String subchapterName =
                                              subchapter['name'];
                                          final int subTotalQuestions =
                                              subchapter['total_questions'];
                                          final int subRightAnswers =
                                              subchapter['right'];
                                          final double subPercentage =
                                              subchapter['percentage'];

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 4.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  // Subchapter Name
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        subchapterName,
                                                        style: TextStyle(
                                                          color:
                                                              AppTheme
                                                                  .color0081B9,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                // Linear Percent Indicator (full width within nested padding)
                                                LinearPercentIndicator(
                                                  width:
                                                      devWidth -
                                                      100, // Full width minus card and nested padding
                                                  animation: true,
                                                  lineHeight: 7.0,
                                                  animationDuration: 1000,
                                                  percent:
                                                      subTotalQuestions > 0
                                                          ? subRightAnswers /
                                                              subTotalQuestions
                                                          : 0.0,
                                                  barRadius: Radius.circular(
                                                    10,
                                                  ),
                                                  progressColor: AppTheme
                                                      .color0081B9
                                                      .withOpacity(0.6),
                                                  backgroundColor:
                                                      AppTheme.colorE1E9F9,
                                                ),
                                                SizedBox(
                                                  height: 4,
                                                ), // Space between line bar and scored/percentage row
                                                Row(
                                                  // Scored/Percentage Text and View Button (Eye Icon)
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      // Scored and Percentage Text
                                                      children: [
                                                        Text(
                                                          "Scored: ",
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .color0081B9,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${subRightAnswers}/${subTotalQuestions}",
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .color0081B9,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(width: 16),
                                                        Text(
                                                          "Percentage: ",
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .color0081B9,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${subPercentage.toStringAsFixed(1)}%",
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .color0081B9,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    IconButton(
                                                      // Eye icon for Subchapter
                                                      icon: Icon(
                                                        Icons
                                                            .remove_red_eye_outlined,
                                                      ),
                                                      color: Color(
                                                        0xff28A164,
                                                      ).withOpacity(
                                                        0.8,
                                                      ), // Updated color with slight opacity
                                                      onPressed: () {
                                                        _showQuestionsBottomSheet(
                                                          subchapterId:
                                                              subchapterId,
                                                          title:
                                                              'Questions for Subchapter: $subchapterName',
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    }).toList(),
                    SizedBox(
                      height: 80,
                    ), // Added space at the bottom to prevent content from being hidden by the FAB
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
