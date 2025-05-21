
import 'package:flutter/material.dart';
import 'package:eltest_exit/theme/app_theme.dart';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';

// Import the necessary models and DatabaseHelper from your database_manipulation.dart file
import 'service/database_manipulation.dart';
import 'service/common.dart'; // Assuming this contains necessary common services

class ChapTakeExam extends StatefulWidget {
  const ChapTakeExam({Key? key}) : super(key: key);

  @override
  State<ChapTakeExam> createState() => _ChapTakeExamState();
}

class _ChapTakeExamState extends State<ChapTakeExam> {
  // Use the Question model from your database_manipulation.dart
  List<Question> questions = [];
  List<RadioModel> questionData = <RadioModel>[];

  // Lists to hold data before saving to database
  Map<int?, String> final_data = {}; // Stores question ID and selected answer
  // We will now track counts by either chapter or subchapter ID
  Map<int?, int> entity_question_count = {}; // Stores Chapter/Subchapter ID and question count
  Map<int?, int> entity_right_count = {}; // Stores Chapter/Subchapter ID and right answer count
  Map<int?, int> entity_wrong_count = {}; // Stores Chapter/Subchapter ID and wrong answer count

  List<int?> right_ans_ids = []; // Stores IDs of correctly answered questions
  Map<int?, String> wrong_ans_data =
      {}; // Stores wrong answer question ID and chosen option
  List<int?> unans_ans_ids = []; // Stores IDs of unanswered questions
  List<int?> fav_list = []; // Stores IDs of favorited questions
  Map<int?, Duration> ques_time = {}; // Stores question ID and time spent

  // Variables to hold filtering criteria from arguments
  String? _filterType; // 'dept', 'topic', or 'subtopic'
  dynamic _filterValue; // The unit, chapter name, or subchapter name (String) for the selected filter
  int? _typenameGradeSubjectId; // The TypeNameGradeSubject ID
  String? _screenTitle; // Title to display in the AppBar

  int? _examTime; // Estimated exam time based on number of questions
  var isLoading = true;

  int ques_no = 0;

  Duration? c_time;
  Duration? start_time;
  Duration? end_time;

  final ScrollController cont1 = ScrollController();
  final ScrollController cont2 = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;

    if (arguments != null) {
      _filterType = arguments['type'] as String?; // 'dept', 'topic', or 'subtopic'
      _filterValue = arguments['value']; // The unit, chapter name, or subchapter name
      _typenameGradeSubjectId = arguments['typenameGradeSubjectId'] as int?;
      _screenTitle =
          arguments['title'] as String?; // Get the title from arguments

      if (_filterType != null && _filterValue != null && _typenameGradeSubjectId != null) {
        getData(_filterType!, _filterValue!, _typenameGradeSubjectId!);
      } else {
        print("Missing arguments for filtering.");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print("No arguments passed to ChapTakeExam.");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetches questions based on filter type, filter value (unit/name), and TypeNameGradeSubject ID
  getData(
    String filterType,
    dynamic filterValue, // Expecting the name (String) for filtering
    int typenameGradeSubjectId,
  ) async {
    isLoading = true; // Set loading to true while fetching
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
          setState(() {
            isLoading = false;
          });
          return;
      }

      // Perform the joined query using the DatabaseHelper
      maps = await dbHelper.performJoinedQuery(
        selectColumns: [
          'question.*',
        ], // Select all columns from the question table
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
        assignQues();
        setState(() {
          isLoading = false; // Set loading to false after fetching
        });
        // Estimate exam time based on the number of questions (e.g., 2 minutes per question)
        _examTime = questions.length * 2;
        start_time = Duration(minutes: _examTime ?? 0);
      } else {
        setState(() {
          isLoading = false; // Set loading to false even if no questions
        });
        print(
          "No questions found for filter type: $filterType, value: $filterValue, TypeNameGradeSubject ID: $typenameGradeSubjectId",
        );
      }
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        isLoading = false; // Set loading to false on error
      });
      // Optionally show an error message to the user
    }
  }

  assignQues() {
    questionData.clear();
    // Check if the current question ID has a saved answer in final_data
    String? savedAnswer = final_data[questions[ques_no].id];

    questionData.add(
      new RadioModel(savedAnswer == 'A', 'A', '${questions[ques_no].a}'),
    );
    questionData.add(
      new RadioModel(savedAnswer == 'B', 'B', '${questions[ques_no].b}'),
    );
    questionData.add(
      new RadioModel(savedAnswer == 'C', 'C', '${questions[ques_no].c}'),
    );
    questionData.add(
      new RadioModel(savedAnswer == 'D', 'D', '${questions[ques_no].d}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffF2F5F8),
          elevation: 0,
          foregroundColor: AppTheme.color0081B9,
          automaticallyImplyLeading: false,
          title: Center(
            child: Text(
              '${_screenTitle ?? "Exam"}',
              style: TextStyle(color: Color.fromARGB(255, 78, 93, 102)),
            ),
          ), // Use the screen title
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    // Use the question ID for favoriting
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
        body:
            !isLoading &&
                    questions
                        .isNotEmpty // Only show content if not loading and questions exist
                ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        if (_examTime !=
                            null) // Only show countdown if exam time is set
                          SlideCountdownSeparated(
                            onDone: () {
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.info,
                                animType: AnimType.rightSlide,
                                title: 'Time is UP',
                              )..show();
                              end_time = c_time;
                              // Record time spent on the current question
                              ques_time[questions[ques_no].id] =
                                  (ques_time[questions[ques_no].id] ??
                                      Duration.zero) +
                                  (start_time! - end_time!);
                              Future.delayed(Duration(seconds: 2), () {
                                analyse();
                              });
                            },
                            onChanged: (value) {
                              c_time = value;
                            },
                            duration: Duration(minutes: _examTime!),
                            icon: Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.alarm,
                                color: AppTheme.color6E3434,
                                size: 20,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),

                        // TeXView(child: TeXViewColumn(children: ques_tex)),
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              15,
                                              10,
                                              15,
                                              10,
                                            ),
                                            child: Text(
                                              'Question ${ques_no + 1}/${questions.length}',
                                              style: TextStyle(
                                                color: AppTheme.white,
                                                fontSize: 20,
                                                fontFamily: "Inter",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              15,
                                              10,
                                              15,
                                              10,
                                            ),
                                            child: Column(
                                              children: [
                                                questions[ques_no].note != null
                                                    ? Html(
                                                      data:
                                                          "<p>${questions[ques_no].note}</p><p>${questions[ques_no].ques}</p>",
                                                      style: {
                                                        "p": Style(
                                                          color: Color.fromARGB(
                                                            255,
                                                            255,
                                                            255,
                                                            255,
                                                          ),
                                                          fontSize: FontSize(
                                                            16,
                                                          ),
                                                        ),
                                                      },
                                                    )
                                                    : Html(
                                                      data:
                                                          "<p>${questions[ques_no].ques}</p>",
                                                      style: {
                                                        "p": Style(
                                                          color: Color.fromARGB(
                                                            255,
                                                            255,
                                                            255,
                                                            255,
                                                          ),
                                                          fontSize: FontSize(
                                                            16,
                                                          ),
                                                        ),
                                                      },
                                                    ),
                                                SizedBox(height: 10),
                                                SizedBox(
                                                  height: 150,
                                                  // Use the image property from the Question model
                                                  child:
                                                      questions[ques_no]
                                                                  .image !=
                                                              null
                                                          ? Image.network(
                                                            '${main_url}${questions[ques_no].image}',
                                                          )
                                                          : Text(''),
                                                ),
                                              ],
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
                        Scrollbar(
                          thumbVisibility: true,
                          controller: cont2,
                          radius: Radius.circular(20),
                          thickness: 5,
                          trackVisibility: true,
                          interactive: true,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              height:
                                  deviceHeight -
                                  (_examTime != null
                                      ? 450
                                      : 380), // Adjust height if no timer
                              width: devWidth - 30,
                              child: ListView.builder(
                                itemCount: questionData.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return InkWell(
                                    //highlightColor: Colors.red,
                                    splashColor: AppTheme.color0081B9,
                                    onTap: () {
                                      setState(() {
                                        questionData.forEach(
                                          (element) =>
                                              element.isSelected = false,
                                        );
                                        questionData[index].isSelected = true;

                                        // Store the selected answer
                                        final_data[questions[ques_no].id!] =
                                            questionData[index].buttonText;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: <Widget>[
                                          Container(
                                            height: 35.0,
                                            width: 35.0,
                                            child: Center(
                                              child: Text(
                                                questionData[index].buttonText,
                                                style: TextStyle(
                                                  color:
                                                      questionData[index]
                                                              .isSelected
                                                          ? AppTheme.white
                                                          : AppTheme
                                                              .color757575,
                                                  //fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                ),
                                              ),
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  questionData[index].isSelected
                                                      ? AppTheme.color0081B9
                                                      : Colors.transparent,
                                              border: Border.all(
                                                width: 1.0,
                                                color:
                                                    questionData[index]
                                                            .isSelected
                                                        ? AppTheme.color0081B9
                                                        : AppTheme.color757575,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    const Radius.circular(2.0),
                                                  ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: devWidth - 110,
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                left: 10.0,
                                              ),
                                              child: Html(
                                                data:
                                                    "<p>${questionData[index].text}</p>",
                                                style: {
                                                  "p": Style(
                                                    color:
                                                        questionData[index]
                                                                .isSelected
                                                            ? AppTheme
                                                                .color0081B9
                                                            : AppTheme
                                                                .color757575,
                                                    fontSize: FontSize(16),
                                                  ),
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Center(
                  // Show a message if no questions are loaded or while loading
                  child: Text(
                    isLoading
                        ? 'Loading questions...'
                        : 'No questions available for this selection.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
        floatingActionButton:
            !isLoading &&
                    questions
                        .isNotEmpty // Only show buttons if not loading and questions are loaded
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: () {
                        // Only record time if timer is active
                        if (_examTime != null) {
                          end_time = c_time;
                          ques_time[questions[ques_no].id] =
                              (ques_time[questions[ques_no].id] ??
                                  Duration.zero) +
                              (start_time! - end_time!);
                        }
                        setState(() {
                          ques_no > 0 ? ques_no-- : null;
                          assignQues();
                          if (_examTime != null) {
                            start_time =
                                c_time; // Reset start time for the new question
                          }
                        });
                      },
                      child: Text('Prev.'),
                      backgroundColor: AppTheme.color0081B9,
                      heroTag: 'mapZoomIn',
                    ),
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
                                final_data.length < questions.length
                                    ? Text(
                                      'There are ${questions.length - final_data.length} Unanswered Questions',
                                      style: TextStyle(
                                        color: AppTheme.red,
                                        fontSize: 14,
                                      ),
                                    )
                                    : Text(''),
                                SizedBox(height: 10),
                                Text(
                                  'Your are going to finish the exam and get information about your score. Do you want to continue?',
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
                            // Only record time if timer is active
                            if (_examTime != null) {
                              end_time = c_time;
                              ques_time[questions[ques_no].id] =
                                  (ques_time[questions[ques_no].id] ??
                                      Duration.zero) +
                                  (start_time! - end_time!);
                            }
                            analyse();
                          },
                        )..show();
                      },
                      child: Text('End'),
                      backgroundColor: Colors.green,
                      heroTag: 'showUserLocation',
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        // Only record time if timer is active
                        if (_examTime != null) {
                          end_time = c_time;
                          ques_time[questions[ques_no].id] =
                              (ques_time[questions[ques_no].id] ??
                                  Duration.zero) +
                              (start_time! - end_time!);
                        }
                        setState(() {
                          ques_no < questions.length - 1 ? ques_no++ : null;
                          assignQues();
                          if (_examTime != null) {
                            start_time =
                                c_time; // Reset start time for the new question
                          }
                        });
                        print(fav_list);
                      },
                      child: Text('Next'),
                      backgroundColor: AppTheme.color0081B9,
                      heroTag: 'mapGoToHome',
                    ),
                  ],
                )
                : null, // Don't show buttons if no questions are loaded
      ),
    );
  }

  // Analyzes the results and prepares data for saving
  analyse() {
    right_ans_ids.clear();
    wrong_ans_data.clear();
    unans_ans_ids.clear();
    entity_question_count.clear();
    entity_right_count.clear();
    entity_wrong_count.clear();

    for (var i = 0; i < questions.length; i++) {
      int? questionId = questions[i].id;
      // Get the relevant entity ID (chapter or subchapter) based on filter type
      int? entityId;
      if (_filterType == 'dept' || _filterType == 'topic') {
        entityId = questions[i].chapter; // Use chapter ID for 'dept' and 'topic'
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
         unans_ans_ids.add(questionId); // Treat as unanswered if entity ID is missing
      }
    }

    finalToDatabase();
  }

  // Saves the exam results to the database using the CRUD classes
  finalToDatabase() async {
    final dbHelper = DatabaseHelper();
    // Ensure the database is initialized before saving
    await dbHelper.database;

    try {
      // Save Favorite
      for (var questionId in fav_list) {
        if (questionId != null) {
          Favorite favorite = Favorite(question: questionId);
          await favorite.save();
        }
      }

      // Navigate to the result screen for filtered questions
      // Pass all necessary data for the result screen to display analysis
      Navigator.pushNamed(
        context,
        '/result-chapt', // You might need a new route for filtered results
        arguments: {
          "filter_type": _filterType, // Pass the filter type ('dept', 'topic', 'subtopic')
          "filter_value": _filterValue, // Pass the filter value (name)
          "typename_grade_subject_id": _typenameGradeSubjectId,
          "screen_title": _screenTitle,
          "questions": questions, // Pass the list of questions
          "final_data": final_data, // Pass user's answers
          "ques_time": ques_time, // Pass time spent per question
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
    } catch (e) {
      print('Error saving exam results: $e');
      // Optionally show an error message to the user
    }
  }
}

class RadioModel {
  bool isSelected;
  final String buttonText;
  final String text;

  RadioModel(this.isSelected, this.buttonText, this.text);
}

