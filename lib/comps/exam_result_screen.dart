import 'dart:ffi';

import '/comps/all_question.dart';
import '/comps/chapter_analysis.dart';
import '/comps/exam_result.dart';
import '/comps/home_nav.dart';
import '/comps/wrong_answer.dart';
import '/models/exam_model.dart';
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

class ExamResultScreen extends StatefulWidget {
  const ExamResultScreen({Key? key}) : super(key: key);

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  bool isLoading = true;
  int? _resultId;
  var _results;
  List _rights = [];
  ExamModel? _exam;
  int? examId;
  int? _examId;
  int? _examTime;
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
    _examId = arguments['exam_id'];
    _examTime = arguments['time'];

    getResults(_resultId);
  }

  getResults(resultId) async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);
    final List<Map<String, dynamic>> _r_maps =
        await db.query('result', where: 'id=${resultId}');

    _results = _r_maps[0];
    _rights = _results['right'].toString().split(',');
    _rights.remove('0');

    examId = _results['exam'];
    final List<Map<String, dynamic>> ques =
        await db.query('question', where: 'exam=${examId}');

    _totalQuestion = ques.length;

    res_wrong = await db.query('resultwrong', where: 'result=${resultId}');

    res_chapter = await db.query('resultchapter', where: 'result=${resultId}');

    final List<Map<String, dynamic>> chapters = await db.query(
      'chapter',
    );

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

    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 255, 255, 255)),
                child: IconButton(
                  icon: const Icon(
                    Icons.home,
                    size: 20,
                    color: Color(0xff0081B9),
                  ),
                  onPressed: () => Navigator.pushAndRemoveUntil<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => HomeNavigator(),
                    ),
                    (route) =>
                        false, //if you want to disable back feature set to false
                  ),
                ),
              ),
            ),
            elevation: 0,
            backgroundColor: Color(0xffF2F5F8),
            title: Center(
                child: Text(
              "${_examTitle}",
              style: TextStyle(
                color: Color(0xff21205A),
                fontWeight: FontWeight.bold,
              ),
            )),
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xff0081B9),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  color: Color(0xff0081B9)),
              tabs: [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Result"),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Chapter"),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Wrong"),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("All"),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Color(0xffF2F5F8),
          body: TabBarView(
            children: [
              ExamResult(exam_id: _examId, exam_time: _examTime, exam_title: _examTitle,),
              ChapterAnalysis(exam_id: _examId, exam_time: _examTime, exam_title: _examTitle,),
              WrongAnswer(exam_id: _examId, exam_time: _examTime, exam_title: _examTitle,),
              AllQuestion(exam_id: _examId, exam_time: _examTime, exam_title: _examTitle,)
            ],
          ),
        ),
      ),
    );
  }
}
