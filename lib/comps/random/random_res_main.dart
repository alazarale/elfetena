import 'dart:ffi';

import 'package:eltest_exit/comps/all_question.dart';
import 'package:eltest_exit/comps/chapter/result_analysis.dart';
import 'package:eltest_exit/comps/chapter_analysis.dart';
import 'package:eltest_exit/comps/exam_result.dart';
import 'package:eltest_exit/comps/home_nav.dart';
import 'package:eltest_exit/comps/random/random%20analysis.dart';
import 'package:eltest_exit/comps/random/random_all.dart';
import 'package:eltest_exit/comps/wrong_answer.dart';
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

class RandomExamResultScreen extends StatefulWidget {
  const RandomExamResultScreen({Key? key}) : super(key: key);

  @override
  State<RandomExamResultScreen> createState() => _RandomExamResultScreenState();
}

class _RandomExamResultScreenState extends State<RandomExamResultScreen> {
  bool isLoading = true;

  List? _rights;
  int? _chapterId;
  int _totalQuestion = 0;
  double perc = 0;
  Map? wrongRes;
  String? _chapterTitle;
  List<Map<String, dynamic>> maps = [];
  List<QuestionModel> questions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // ignore: todo
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _rights = arguments['rights'];
    wrongRes = arguments['wrong'];
    questions = arguments['questions'];
    print(_rights);
    print(wrongRes);
    print(questions);
  }

  getResults() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");
    var db = await openDatabase(path, version: 1);
    maps = await db.query('question', where: 'chapter=$_chapterId');
    print(maps.length);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 2,
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
            backgroundColor: const Color(0xffF2F5F8),
            title: const Center(
                child: Text(
              "Random Question Exam",
              style: TextStyle(
                color: Color(0xff21205A),
                fontWeight: FontWeight.bold,
              ),
            )),
            bottom: const TabBar(
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
                    child: Text("All"),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xffF2F5F8),
          body: TabBarView(
            children: [
              RandomResultMainScreen(
                right: _rights!,
                wrong: wrongRes!,
                questions: questions,
              ),
              RandomQuestionAllScreen(
                right: _rights!,
                wrong: wrongRes!,
                questions: questions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
