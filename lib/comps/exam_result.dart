import 'dart:ffi';

import 'package:eltest_exit/models/exam_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart';

import 'circle_progress.dart';

class ExamResult extends StatefulWidget {
  ExamResult({Key? key, this.exam_title, this.exam_id, this.exam_time})
    : super(key: key);

  String? exam_title;
  int? exam_id;
  int? exam_time;

  @override
  State<ExamResult> createState() => _ExamResultState();
}

class _ExamResultState extends State<ExamResult> {
  bool isLoading = true;
  int? _resultId;
  var _results;
  List _rights = [];
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
  Map<String, dynamic> questionMap = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _resultId = arguments['result_id'];
    _examTitle = arguments['title'];

    getResults(_resultId);
  }

  getResults(resultId) async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);
    final List<Map<String, dynamic>> _r_maps = await db.query(
      'result',
      where: 'id=${resultId}',
    );

    _results = _r_maps[0];
    _rights = _results['right'].toString().split(',');
    _rights.remove('0');

    examId = _results['exam'];
    final List<Map<String, dynamic>> ques = await db.query(
      'question',
      where: 'exam=${examId}',
    );

    _totalQuestion = ques.length;

    res_wrong = await db.query('resultwrong', where: 'result=${resultId}');

    res_chapter = await db.query('resultchapter', where: 'result=${resultId}');

    final List<Map<String, dynamic>> chapters = await db.query('chapter');

    if (_totalQuestion > 0) {
      dataMap.clear();
      res_chapter.forEach((element) {
        chapters.forEach((elem) {
          element['chapter'] == elem['id']
              ? dataMap[elem['unit']] = element['no_questions'].toDouble()
              : null;
        });
      });

      chapters.forEach((element) {
        chapterMap[element['id'].toString()] =
            element['unit'] + ': ' + element['name'];
      });

      ques.forEach((element) {
        questionMap[element['id'].toString()] = element;
      });

      setState(() {
        perc = (_rights.length / _totalQuestion) * 100;
        wrongRes = res_wrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xffF2F5F8),
      body: SingleChildScrollView(
        child: Visibility(
          visible: isLoading,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: const Text(
                    'Result Statistics',
                    style: const TextStyle(
                      color: Color(0xff21205A),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              CircularProgressForResult(perc, _rights.length, _totalQuestion),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "You have got ${_rights.length} questions Right",
                            style: TextStyle(
                              color: Color(0xff21205A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${((_rights.length / _totalQuestion) * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: LinearPercentIndicator(
                        width: devWidth - 30,
                        animation: true,
                        lineHeight: 10,
                        animationDuration: 1000,
                        percent: _rights.length / _totalQuestion,
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                        backgroundColor: Color.fromARGB(116, 90, 89, 89),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "You have got ${wrongRes.length} questions Wrong",
                            style: TextStyle(
                              color: Color(0xff21205A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${((wrongRes.length / _totalQuestion) * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: LinearPercentIndicator(
                        width: devWidth - 30,
                        animation: true,
                        lineHeight: 10.0,
                        animationDuration: 1000,
                        percent: wrongRes.length / _totalQuestion,
                        barRadius: Radius.circular(10),
                        progressColor: Colors.red,
                        backgroundColor: Color.fromARGB(116, 90, 89, 89),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_totalQuestion - (_rights.length + wrongRes.length)} question left unanswered",
                            style: TextStyle(
                              color: Color(0xff21205A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${(((_totalQuestion - (_rights.length + wrongRes.length)) / _totalQuestion) * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: Color(0xff0081B9),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: LinearPercentIndicator(
                        width: devWidth - 30,
                        animation: true,
                        lineHeight: 10.0,
                        animationDuration: 1000,
                        percent:
                            (_totalQuestion -
                                (_rights.length + wrongRes.length)) /
                            _totalQuestion,
                        barRadius: Radius.circular(10),
                        progressColor: Color(0xff0081B9),
                        backgroundColor: Color.fromARGB(116, 90, 89, 89),
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Select Mode'),
                              content: Column(
                                // Use a Column to arrange buttons vertically
                                mainAxisSize:
                                    MainAxisSize
                                        .min, // Make the column take minimum space
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
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color(0xff0081B9),
                        ),
                      ),
                    ),
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
