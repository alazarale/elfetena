// ignore_for_file: prefer_const_constructors


import 'package:eltest_exit/comps/service/database_manipulation.dart';
import 'package:flutter/material.dart';
import 'package:eltest_exit/theme/app_theme.dart';

import 'package:flutter/services.dart';// Keep sqflite import for getDatabasesPath
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';

// Import the models and DatabaseHelper from your SQLite CRUD Canvas
 // Adjust the import path

import 'service/common.dart'; // Assuming this contains necessary common services

class TakeExam extends StatefulWidget {
  const TakeExam({Key? key}) : super(key: key);

  @override
  State<TakeExam> createState() => _TakeExamState();
}

class _TakeExamState extends State<TakeExam> {
  // Use the Question model from your CRUD classes
  List<Question> questions = [];
  List<RadioModel> questionData = <RadioModel>[];

  // Lists to hold data before saving to database
  Map<int, String> final_data = {}; // Stores question ID and selected answer
  Map<int?, int> chapter_question_count = {}; // Stores chapter ID and question count
  Map<int?, int> chapter_right_count = {}; // Stores chapter ID and right answer count
  Map<int?, int> chapter_wrong_count = {}; // Stores chapter ID and wrong answer count
  List<int?> right_ans_ids = []; // Stores IDs of correctly answered questions
  Map<int?, String> wrong_ans_data = {}; // Stores wrong answer question ID and chosen option
  List<int?> unans_ans_ids = []; // Stores IDs of unanswered questions
  List<int?> fav_list = []; // Stores IDs of favorited questions
  Map<int?, Duration> ques_time = {}; // Stores question ID and time spent

  int? _examId;
  String? _examTitle;
  int? _examTime;
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
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _examId = arguments['exam_id'];
    _examTitle = arguments['title'];
    _examTime = arguments['time'];
    getData(_examId);
  }

  // Fetches questions for the given exam ID using the Question model
  getData(int? examId) async {
    if (examId == null) {
      print("Exam ID is null. Cannot fetch questions.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    isLoading = true; // Set loading to true while fetching
    questions.clear();

    try {
      // Use the Question model to query questions by exam ID
      final questionModel = Question();
      questions = await questionModel.query(
        where: 'exam = ?',
        whereArgs: [examId],
      );

      if (questions.isNotEmpty) {
        assignQues();
        setState(() {
          isLoading = false; // Set loading to false after fetching
        });
        // Initialize start time with the total exam time
        start_time = Duration(minutes: _examTime ?? 0);
      } else {
         setState(() {
            isLoading = false; // Set loading to false even if no questions
          });
        print("No questions found for exam ID: $examId");
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

  // This function is no longer needed here as chapter information is part of the Question model
  // getChapter(id) async {
  //   var databasesPath = await getDatabasesPath();
  //   var path = Path.join(databasesPath, "data_init.db");
  //   var db = await openDatabase(path, version: 1);
  //   final List<Map<String, dynamic>> subchaps = await db.query(
  //     'subchapter',
  //     where: 'id=${id}',
  //   );

  //   return subchaps;
  // }

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
          foregroundColor: Color(0xff0081B9),
          title: Center(child: Text('${_examTitle}', style: TextStyle(color: Color.fromARGB(255, 78, 93, 102)),)),
          automaticallyImplyLeading: false,
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
        body: !isLoading && questions.isNotEmpty // Only show content if not loading and questions exist
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
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
                          ques_time[questions[ques_no].id] = (ques_time[questions[ques_no].id] ?? Duration.zero) + (start_time! - end_time!);
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
                            color: Color.fromARGB(255, 110, 52, 52),
                            size: 20,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                      // TeXView(child: TeXViewColumn(children: ques_tex)),

                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Center(
                          child: SizedBox(
                            height: 220,
                            child: Card(
                              color: Color(0xff0081B9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 10, 15, 10),
                                          child: Text(
                                            'Question ${ques_no + 1}/${questions.length}',
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 20,
                                                fontFamily: "Inter",
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(15, 10, 15, 10),
                                          child: Column(
                                            children: [
                                              questions[ques_no].note != null ? Html(
                                                data:
                                                    "<p>${questions[ques_no].note}</p><p>${questions[ques_no].ques}</p>",
                                                style: {
                                                  "p": Style(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize: FontSize(16)),
                                                },
                                              ) : Html(
                                                data:
                                                    "<p>${questions[ques_no].ques}</p>",
                                                style: {
                                                  "p": Style(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize: FontSize(16)),
                                                },
                                              ),
                                              
                                              SizedBox(
                                                height: 10,
                                              ),
                                              SizedBox(
                                                height: 150,
                                                // Use the image property from the Question model
                                                child: questions[ques_no].image !=
                                                        null
                                                    ? Image.network(
                                                        '${main_url}${questions[ques_no].image}')
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
                            height: deviceHeight - 450,
                            width: devWidth - 30,
                            child: ListView.builder(
                              itemCount: questionData.length,
                              itemBuilder: (BuildContext context, int index) {
                                return InkWell(
                                  //highlightColor: Colors.red,
                                  splashColor: Color(0xff0081B9),
                                  onTap: () {
                                    setState(() {
                                      questionData.forEach(
                                          (element) => element.isSelected = false);
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
                                                    color: questionData[index]
                                                            .isSelected
                                                        ? Colors.white
                                                        : Color.fromARGB(
                                                            255, 117, 117, 117),
                                                    //fontWeight: FontWeight.bold,
                                                    fontSize: 18.0)),
                                          ),
                                          decoration: BoxDecoration(
                                            color: questionData[index].isSelected
                                                ? Color(0xff0081B9)
                                                : Colors.transparent,
                                            border: Border.all(
                                                width: 1.0,
                                                color:
                                                    questionData[index].isSelected
                                                        ? Color(0xff0081B9)
                                                        : Color.fromARGB(
                                                            255, 117, 117, 117)),
                                            borderRadius: const BorderRadius.all(
                                                const Radius.circular(2.0)),
                                          ),
                                        ),
                                        SizedBox(
                                          width: devWidth - 110,
                                          child: Container(
                                            margin: EdgeInsets.only(left: 10.0),
                                            child: Html(
                                              data:
                                                  "<p>${questionData[index].text}</p>",
                                              style: {
                                                "p": Style(
                                                    color: questionData[index]
                                                            .isSelected
                                                        ? Color(0xff0081B9)
                                                        : Color.fromARGB(
                                                            255, 117, 117, 117),
                                                    fontSize: FontSize(16)),
                                              },
                                            ),
                                          ),
                                        )
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
            : Center( // Show a message if no questions are loaded or while loading
                child: Text(
                  isLoading ? 'Loading questions...' : 'No questions available for this exam.',
                  style: TextStyle(fontSize: 18),
                ),
              ),
        floatingActionButton: !isLoading && questions.isNotEmpty // Only show buttons if not loading and questions are loaded
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FloatingActionButton(
                    onPressed: () {
                      end_time = c_time;
                      // Record time spent on the current question
                      ques_time[questions[ques_no].id] = (ques_time[questions[ques_no].id] ?? Duration.zero) + (start_time! - end_time!);
                      setState(() {
                        ques_no > 0 ? ques_no-- : null;
                        assignQues();
                        start_time = c_time; // Reset start time for the new question
                      });
                    },
                    child: Text('Prev.'),
                    backgroundColor: Color(0xff0081B9),
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
                                      style: TextStyle(color: Colors.red, fontSize: 14),
                                    )
                                  : Text(''),
                              SizedBox(height: 10),
                              Text(
                                'Your are going to finish the exam and get information about your score. Do you want to continue?',
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
                          end_time = c_time;
                          // Record time spent on the current question before ending
                          ques_time[questions[ques_no].id] = (ques_time[questions[ques_no].id] ?? Duration.zero) + (start_time! - end_time!);
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
                      end_time = c_time;
                       // Record time spent on the current question
                      ques_time[questions[ques_no].id] = (ques_time[questions[ques_no].id] ?? Duration.zero) + (start_time! - end_time!);
                      setState(() {
                        ques_no < questions.length - 1 ? ques_no++ : null;
                        assignQues();
                        start_time = c_time; // Reset start time for the new question
                      });
                      print(fav_list);
                    },
                    child: Text('Next'),
                    backgroundColor: Color(0xff0081B9),
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
    chapter_question_count.clear();
    chapter_right_count.clear();
    chapter_wrong_count.clear();

    for (var i = 0; i < questions.length; i++) {
      int? questionId = questions[i].id;
      int? chapterId = questions[i].chapter;
      String correctAnswer = questions[i].ans?.toLowerCase() ?? '';
      String? chosenAnswer = final_data[questionId]?.toLowerCase();

      // Count questions per chapter
      chapter_question_count[chapterId] = (chapter_question_count[chapterId] ?? 0) + 1;

      if (chosenAnswer != null) {
        if (chosenAnswer == correctAnswer) {
          right_ans_ids.add(questionId);
          chapter_right_count[chapterId] = (chapter_right_count[chapterId] ?? 0) + 1;
        } else {
          wrong_ans_data[questionId] = final_data[questionId]!; // Store the original chosen option
          chapter_wrong_count[chapterId] = (chapter_wrong_count[chapterId] ?? 0) + 1;
        }
      } else {
        unans_ans_ids.add(questionId);
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
      // Save Result
      // Convert list of IDs to comma-separated strings
      String rightAnsString = right_ans_ids.map((id) => id.toString()).join(',');
      String wrongAnsString = wrong_ans_data.keys.map((id) => id.toString()).join(',');
      String unansAnsString = unans_ans_ids.map((id) => id.toString()).join(',');

      // Ensure examId is not null before creating Result object
      if (_examId == null) {
         print("Exam ID is null. Cannot save result.");
         return;
      }

      Result result = Result(
        exam: _examId,
        right: rightAnsString.isNotEmpty ? rightAnsString : '0', // Use '0' if no right answers
        wrong: wrongAnsString.isNotEmpty ? wrongAnsString : '0', // Use '0' if no wrong answers
        unanswered: unansAnsString.isNotEmpty ? unansAnsString : '0', // Use '0' if no unanswered
        date: DateTime.now().toIso8601String(), // Save current date/time
        uploaded: 0, // Assuming default uploaded status is 0
      );

      // Save the result and get the inserted row ID
      int resultId = await result.save();

      // Save ResultWrong
      for (var entry in wrong_ans_data.entries) {
        ResultWrong resultWrong = ResultWrong(
          result: resultId, // Link to the saved Result
          question: entry.key,
          choosen: entry.value,
        );
        await resultWrong.save();
      }

      // Save ResultTime
      for (var entry in ques_time.entries) {
         // Ensure question ID is not null
         if (entry.key != null) {
           ResultTime resultTime = ResultTime(
             result: resultId, // Link to the saved Result
             question: entry.key,
             time: entry.value.inSeconds.toString(), // Save time in seconds
           );
           await resultTime.save();
         }
      }

      // Save ResultChapter
      for (var chapterId in chapter_question_count.keys) {
        if (chapterId != null) {
          int totalQuestions = chapter_question_count[chapterId] ?? 0;
          int rightQuestions = chapter_right_count[chapterId] ?? 0;
          int wrongQuestions = chapter_wrong_count[chapterId] ?? 0;
          int unansweredQuestions = totalQuestions - rightQuestions - wrongQuestions; // Calculate unanswered per chapter

          // Calculate average time per question for the chapter
          Duration totalChapterTime = Duration.zero;
          int questionsInChapterWithTime = 0;
          for(var qId in ques_time.keys){
            // Find questions belonging to this chapter to sum their time
            Question? question = questions.firstWhere((q) => q.id == qId, orElse: () => Question());
            if(question.chapter == chapterId && ques_time[qId] != null){
              totalChapterTime += ques_time[qId]!;
              questionsInChapterWithTime++;
            }
          }

          String avgTime = '0';
          if(questionsInChapterWithTime > 0){
             avgTime = (totalChapterTime.inSeconds / questionsInChapterWithTime).toStringAsFixed(2); // Calculate average time
          }


          ResultChapter resultChapter = ResultChapter(
            result: resultId, // Link to the saved Result
            chapter: chapterId,
            no_questions: totalQuestions,
            right: rightQuestions,
            wrong: wrongQuestions,
            unanswered: unansweredQuestions,
            avg_time: avgTime,
          );
          await resultChapter.save();
        }
      }

      // Save Favorite
      for (var questionId in fav_list) {
         if (questionId != null) {
           Favorite favorite = Favorite(question: questionId);
           await favorite.save();
         }
      }

      print('Exam results saved successfully with Result ID: $resultId');

      // Navigate to the result screen
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