import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';

import '../../models/exam_model.dart';
import '../provider/strored_ref.dart';
import 'package:eltest_exit/theme/app_theme.dart';
import '../service/common.dart';
import 'package:flutter_tex/flutter_tex.dart';

class RandomQuestionScreen extends StatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  State<RandomQuestionScreen> createState() => _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends State<RandomQuestionScreen> {
  late Database db;
  Map<int, List> exam_sorted = {};
  List final_questions = [];
  List<QuestionModel> questions = [];
  List<RadioModel> questionData = <RadioModel>[];
  List<Result> result = [];
  List<ResultWrong> res_wrong = [];
  List<ResultTime> res_time = [];
  List<Favourite> res_fav = [];
  List<ResultChapter> res_chapter = [];
  int? _chapterId;
  String? _chapterTitle;
  int? _examTime;
  var isLoading = true;
  int q_no = 30;

  final ScrollController cont1 = ScrollController();
  final ScrollController cont2 = ScrollController();

  int ques_no = 0;

  var final_data = {};
  var chapter_count = {};
  var right_ans = [];
  var wrong_ans = {};
  var unans_ans = [];
  var fav_list = [];
  var ques_time = {};

  var c_time;
  var start_time;
  var end_time;

  List sel_chap = [];

  @override
  void initState() {
    super.initState();
    Provider.of<RefData>(context, listen: false).tryNotIncluded().then((value) {
      sel_chap = Provider.of<RefData>(context, listen: false).not_include;
    });
    Provider.of<RefData>(context, listen: false).tryNoQues().then((value) {
      q_no = Provider.of<RefData>(context, listen: false).no_ques!;
    });

    dbstat();

    // This widget is the root of your application.
  }

  dbstat() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    db = await openDatabase(path, version: 1);
    List<Map<String, dynamic>> chaps = await db.query('question');
    chaps = List.from(chaps.reversed);
    List<Map<String, dynamic>> maps = [];

    chaps.forEach((element) {
      sel_chap.contains(element['chapter']) ? null : maps.add(element);
    });

    for (var element in maps) {
      if (exam_sorted.keys.contains(element['chapter'])) {
        exam_sorted[element['chapter']]!.add(element);
      } else {
        exam_sorted[element['chapter']] = [element];
      }
    }

    if (exam_sorted.isNotEmpty) {
      int qN = (q_no / exam_sorted.length).floor();
      if (qN > 0) {
        for (int i = 0; i < qN; i++) {
          exam_sorted.forEach((key, value) {
            final_questions.add((value..shuffle()).first);
          });
        }
        if (final_questions.length < q_no) {
          List? elem;
          int? k;
          for (int i = 0; i < q_no - final_questions.length; i++) {
            k = (exam_sorted.keys.toList()..shuffle()).first;
            elem = exam_sorted[k];
            exam_sorted.remove(k);
            final_questions.add((elem!..shuffle()).first);
          }
        }
      } else {
        List? elem;
        int? k;
        for (int i = 0; i < q_no; i++) {
          k = (exam_sorted.keys.toList()..shuffle()).first;
          elem = exam_sorted[k];
          exam_sorted.remove(k);
          final_questions.add((elem!..shuffle()).first);
        }
      }

      List.generate(final_questions.length, (i) {
        questions.add(
          QuestionModel(
            final_questions[i]["id"],
            final_questions[i]["ques"],
            final_questions[i]["a"],
            final_questions[i]["b"],
            final_questions[i]["c"],
            final_questions[i]["d"],
            final_questions[i]["ans"],
            final_questions[i]["image"],
            final_questions[i]["chapter"],
          ),
        );
      });
      if (questions != []) {
        assignQues();
        print(questions);
        setState(() {
          isLoading = true;
        });
        start_time = Duration(minutes: 120);
      }
      _examTime = final_questions.length * 2;
    }

    setState(() {});
  }

  assignQues() {
    questionData.clear();
    if (final_data[questions[ques_no].id] == null) {
      questionData.add(RadioModel(false, 'A', questions[ques_no].choiceA));
      questionData.add(RadioModel(false, 'B', questions[ques_no].choiceB));
      questionData.add(RadioModel(false, 'C', questions[ques_no].choiceC));
      questionData.add(RadioModel(false, 'D', questions[ques_no].choiceD));
    } else {
      questionData.add(
        RadioModel(
          final_data[questions[ques_no].id] == 'A' ? true : false,
          'A',
          questions[ques_no].choiceA,
        ),
      );
      questionData.add(
        RadioModel(
          final_data[questions[ques_no].id] == 'B' ? true : false,
          'B',
          questions[ques_no].choiceB,
        ),
      );
      questionData.add(
        RadioModel(
          final_data[questions[ques_no].id] == 'C' ? true : false,
          'C',
          questions[ques_no].choiceC,
        ),
      );
      questionData.add(
        RadioModel(
          final_data[questions[ques_no].id] == 'D' ? true : false,
          'D',
          questions[ques_no].choiceD,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          foregroundColor: Color(0xff0081B9),
          title: Center(child: Text('Random Question Exam')),
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
        body: SingleChildScrollView(
          child: Visibility(
            visible: isLoading,
            child: Padding(
              padding: const EdgeInsets.all(5),
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
                      ques_time[questions[ques_no].id] == null
                          ? ques_time[questions[ques_no].id] =
                              end_time - start_time
                          : ques_time[questions[ques_no].id] =
                              ques_time[questions[ques_no].id] +
                              (end_time - start_time);
                      Future.delayed(Duration(seconds: 2), () {
                        //analyse();
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
                  TeXView(
                    child: TeXViewColumn(
                      children: [
                        TeXViewDocument(
                          questions[ques_no].imageN == null
                              ? "<h3>Question ${ques_no + 1}/${questions.length}</h2><br>" +
                                  questions[ques_no].ques
                              : "<h3>Question ${ques_no + 1}/${questions.length}</h2><br>" +
                                  questions[ques_no].ques +
                                  '<br><img src="${main_url}${questions[ques_no].imageN}" style="width: ${devWidth - 100}px">',
                          style: const TeXViewStyle.fromCSS(
                            'height: 200px; overflow-y: scroll; padding: 15px; color: white; background: #0081B9; border-radius: 10px;',
                          ),
                        ),
                        TeXViewGroup(
                          children: [
                            TeXViewGroupItem(
                              rippleEffect: false,
                              id: 0.toString(),
                              child: TeXViewDocument(
                                questionData[0].isSelected
                                    ? "<div style='display: flex; color: #0081B9;'><span style='border: 1px solid #0081B9; color: white ;padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #0081B9'>${questionData[0].buttonText}</span>" +
                                        questionData[0].text +
                                        "</div>"
                                    : "<div style='display: flex;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>${questionData[0].buttonText}</span>" +
                                        questionData[0].text +
                                        "</div>",
                                style: const TeXViewStyle(
                                  padding: TeXViewPadding.all(10),
                                ),
                              ),
                            ),
                            TeXViewGroupItem(
                              rippleEffect: false,
                              id: 1.toString(),
                              child: TeXViewDocument(
                                questionData[1].isSelected
                                    ? "<div style='display: flex; color: #0081B9;'><span style='border: 1px solid #0081B9; color: white ;padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #0081B9'>${questionData[1].buttonText}</span>" +
                                        questionData[1].text +
                                        "</div>"
                                    : "<div style='display: flex;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>${questionData[1].buttonText}</span>" +
                                        questionData[1].text +
                                        "</div>",
                                style: const TeXViewStyle(
                                  padding: TeXViewPadding.all(10),
                                ),
                              ),
                            ),
                            TeXViewGroupItem(
                              rippleEffect: false,
                              id: 2.toString(),
                              child: TeXViewDocument(
                                questionData[2].isSelected
                                    ? "<div style='display: flex; color: #0081B9;'><span style='border: 1px solid #0081B9; color: white ;padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #0081B9'>${questionData[2].buttonText}</span>" +
                                        questionData[2].text +
                                        "</div>"
                                    : "<div style='display: flex;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>${questionData[2].buttonText}</span>" +
                                        questionData[2].text +
                                        "</div>",
                                style: const TeXViewStyle(
                                  padding: TeXViewPadding.all(10),
                                ),
                              ),
                            ),
                            TeXViewGroupItem(
                              rippleEffect: false,
                              id: 3.toString(),
                              child: TeXViewDocument(
                                questionData[3].isSelected
                                    ? "<div style='display: flex; color: #0081B9;'><span style='border: 1px solid #0081B9; color: white ;padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #0081B9'>${questionData[3].buttonText}</span>" +
                                        questionData[3].text +
                                        "</div>"
                                    : "<div style='display: flex;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>${questionData[3].buttonText}</span>" +
                                        questionData[3].text +
                                        "</div>",
                                style: const TeXViewStyle(
                                  padding: TeXViewPadding.all(10),
                                ),
                              ),
                            ),
                          ],
                          selectedItemStyle: TeXViewStyle(
                            contentColor: Colors.white,
                            backgroundColor: Colors.blue,
                            borderRadius: const TeXViewBorderRadius.all(10),
                            margin: const TeXViewMargin.all(10),
                          ),
                          normalItemStyle: const TeXViewStyle(
                            margin: TeXViewMargin.all(10),
                          ),
                          onTap: (id) {
                            setState(() {
                              questionData.forEach(
                                (element) => element.isSelected = false,
                              );
                              questionData[int.parse(id)].isSelected = true;
                              print(questionData);
                              final_data[questions[ques_no].id] =
                                  questionData[int.parse(id)].buttonText;
                            });
                          },
                        ),
                      ],
                    ),
                    style: const TeXViewStyle(
                      margin: TeXViewMargin.all(5),
                      padding: TeXViewPadding.all(10),
                      borderRadius: TeXViewBorderRadius.all(10),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  // Padding(
                  //   padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  //   child: Center(
                  //     child: SizedBox(
                  //       height: 220,
                  //       child: Card(
                  //         color: Color(0xff0081B9),
                  //         shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(10)),
                  //         child: Container(
                  //           width: devWidth - 30,
                  //           height: 200,
                  //           child: Scrollbar(
                  //             thumbVisibility: true,
                  //             controller: cont1,
                  //             interactive: true,
                  //             thickness: 5,
                  //             radius: Radius.circular(20),
                  //             trackVisibility: true,
                  //             child: SingleChildScrollView(
                  //               child: Column(
                  //                 crossAxisAlignment: CrossAxisAlignment.start,
                  //                 children: [
                  //                   Padding(
                  //                     padding: const EdgeInsets.fromLTRB(
                  //                         15, 10, 15, 10),
                  //                     child: Text(
                  //                       'Question ${ques_no + 1}/${questions.length}',
                  //                       style: TextStyle(
                  //                           color: Color.fromARGB(
                  //                               255, 255, 255, 255),
                  //                           fontSize: 20,
                  //                           fontFamily: "Inter",
                  //                           fontWeight: FontWeight.bold),
                  //                     ),
                  //                   ),
                  //                   Padding(
                  //                     padding:
                  //                         EdgeInsets.fromLTRB(15, 10, 15, 10),
                  //                     child: Column(
                  //                       children: [
                  //                         Html(
                  //                           data:
                  //                               "<p>${questions[ques_no].ques}</p>",
                  //                           style: {
                  //                             "p": Style(
                  //                                 color: Color.fromARGB(
                  //                                     255, 255, 255, 255),
                  //                                 fontSize: FontSize(18)),
                  //                           },
                  //                         ),

                  //                         SizedBox(
                  //                           height: 10,
                  //                         ),
                  //                         SizedBox(
                  //                           height: 150,
                  //                           child: questions[ques_no].imageN !=
                  //                                   null
                  //                               ? Image.network(
                  //                                   '${main_url}${questions[ques_no].imageN}')
                  //                               : Text(''),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Scrollbar(
                  //   thumbVisibility: true,
                  //   controller: cont2,
                  //   radius: Radius.circular(20),
                  //   thickness: 5,
                  //   trackVisibility: true,
                  //   interactive: true,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(10),
                  //     child: SizedBox(
                  //       height: deviceHeight - 450,
                  //       width: devWidth - 30,
                  //       child: ListView.builder(
                  //         itemCount: questionData.length,
                  //         itemBuilder: (BuildContext context, int index) {
                  //           return InkWell(
                  //             //highlightColor: Colors.red,
                  //             splashColor: Color(0xff0081B9),
                  //             onTap: () {
                  //               setState(() {
                  //                 questionData.forEach(
                  //                     (element) => element.isSelected = false);
                  //                 questionData[index].isSelected = true;

                  //                 final_data[questions[ques_no].id] =
                  //                     questionData[index].buttonText;
                  //               });
                  //             },
                  //             child: Container(
                  //               margin: EdgeInsets.all(5),
                  //               child: Row(
                  //                 mainAxisSize: MainAxisSize.max,
                  //                 children: <Widget>[
                  //                   Container(
                  //                     height: 35.0,
                  //                     width: 35.0,
                  //                     child: Center(
                  //                       child: Text(
                  //                           questionData[index].buttonText,
                  //                           style: TextStyle(
                  //                               color: questionData[index]
                  //                                       .isSelected
                  //                                   ? Colors.white
                  //                                   : Color.fromARGB(
                  //                                       255, 117, 117, 117),
                  //                               //fontWeight: FontWeight.bold,
                  //                               fontSize: 18.0)),
                  //                     ),
                  //                     decoration: BoxDecoration(
                  //                       color: questionData[index].isSelected
                  //                           ? Color(0xff0081B9)
                  //                           : Colors.transparent,
                  //                       border: Border.all(
                  //                           width: 1.0,
                  //                           color:
                  //                               questionData[index].isSelected
                  //                                   ? Color(0xff0081B9)
                  //                                   : Color.fromARGB(
                  //                                       255, 117, 117, 117)),
                  //                       borderRadius: const BorderRadius.all(
                  //                           const Radius.circular(2.0)),
                  //                     ),
                  //                   ),
                  //                   SizedBox(
                  //                     width: devWidth - 110,
                  //                     child: Container(
                  //                       margin: EdgeInsets.only(left: 10.0),
                  //                       child: Html(
                  //                         data:
                  //                             "<p>${questionData[index].text}</p>",
                  //                         style: {
                  //                           "p": Style(
                  //                               color: questionData[index]
                  //                                       .isSelected
                  //                                   ? Color(0xff0081B9)
                  //                                   : Color.fromARGB(
                  //                                       255, 117, 117, 117),
                  //                               fontSize: FontSize(16)),
                  //                         },
                  //                       ),
                  //                     ),
                  //                   )
                  //                 ],
                  //               ),
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                end_time = c_time;
                ques_time[questions[ques_no].id] == null
                    ? ques_time[questions[ques_no].id] = end_time - start_time
                    : ques_time[questions[ques_no].id] =
                        ques_time[questions[ques_no].id] +
                        (end_time - start_time);
                setState(() {
                  ques_no > 0 ? ques_no-- : null;
                  assignQues();
                  start_time = c_time;
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
                    ques_time[questions[ques_no].id] == null
                        ? ques_time[questions[ques_no].id] =
                            end_time - start_time
                        : ques_time[questions[ques_no].id] =
                            ques_time[questions[ques_no].id] +
                            (end_time - start_time);
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
                ques_time[questions[ques_no].id] == null
                    ? ques_time[questions[ques_no].id] = end_time - start_time
                    : ques_time[questions[ques_no].id] =
                        ques_time[questions[ques_no].id] +
                        (end_time - start_time);
                setState(() {
                  ques_no < questions.length - 1 ? ques_no++ : null;
                  assignQues();
                  start_time = c_time;
                });
                print(fav_list);
              },
              child: Text('Next'),
              backgroundColor: Color(0xff0081B9),
              heroTag: 'mapGoToHome',
            ),
          ],
        ),
      ),
    );
  }

  analyse() {
    int? chapter;
    int? sc;
    for (var dt in final_data.keys) {
      print(dt);
      questions.forEach((element) {
        element.id == dt
            ? final_data[dt].toLowerCase() == element.ans
                ? !right_ans.contains(dt)
                    ? right_ans.add(dt)
                    : null
                : wrong_ans[dt] = final_data[dt]
            : null;
      });
    }
    finalToDatabase();
  }

  finalToDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);

    for (int i = 0; i < fav_list.length; i++) {
      await db.insert('favorite', {'question': fav_list[i]});
    }

    Navigator.pushNamed(
      context,
      '/random-res',
      arguments: {
        "rights": right_ans,
        'wrong': wrong_ans,
        'questions': questions,
      },
    );
  }
}

class RadioModel {
  bool isSelected;
  final String buttonText;
  final String text;

  RadioModel(this.isSelected, this.buttonText, this.text);
}
