import 'dart:ffi';

import 'package:eltest_exit/comps/all_question.dart';
import 'package:eltest_exit/comps/chapter/result_analysis.dart';
import 'package:eltest_exit/comps/chapter_analysis.dart';
import 'package:eltest_exit/comps/exam_result.dart';
import 'package:eltest_exit/comps/home_nav.dart';
import 'package:eltest_exit/comps/service/database_manipulation.dart';
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

import 'result_all.dart';

class ChapterExamResultScreen extends StatefulWidget {
  const ChapterExamResultScreen({Key? key}) : super(key: key);

  @override
  State<ChapterExamResultScreen> createState() =>
      _ChapterExamResultScreenState();
}

class _ChapterExamResultScreenState extends State<ChapterExamResultScreen> {
  bool isLoading = true;

  // Data received from ChapTakeExam
  String? _filterType;
  dynamic _filterValue; // Changed back to dynamic to receive name/value
  String? _screenTitle;
  List<Question> _questions = []; // Initialize as empty list
  Map<int?, String>? _finalData;
  Map<int?, Duration>? _quesTime;
  List<int?>? _favList;
  Map<int?, int>? _entityQuestionCount;
  Map<int?, int>? _entityRightCount;
  Map<int?, int>? _entityWrongCount;
  List<int?>? _rightAnsIds;
  Map<int?, String>? _wrongAnsData;
  List<int?>? _unansAnsIds;

  // Maps to store chapter and subchapter info for displaying path
  Map<String, String> _chapterMap = {}; // Map chapter ID (string) to "Unit: Name"
  Map<int, Map<String, dynamic>> _subchapterMap = {}; // Store subchapter info: {subchapterId: {name: '...', chapter: '...'}}


  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map? arguments = ModalRoute.of(context)?.settings.arguments as Map?;

    if (arguments != null) {
      _filterType = arguments['filter_type'] as String?;
      _filterValue = arguments['filter_value']; // Receive the filter value (name)
      _screenTitle = arguments['screen_title'] as String?;

      // Safely cast the received list to List<Question>
      final receivedQuestions = arguments['questions'];
      if (receivedQuestions != null && receivedQuestions is List) {
        _questions = receivedQuestions.whereType<Question>().toList();
      } else {
         _questions = []; // Assign an empty list if no questions or incorrect type
      }

      _finalData = arguments['final_data'] as Map<int?, String>?;
      _quesTime = arguments['ques_time'] as Map<int?, Duration>?;
      _favList = arguments['fav_list'] as List<int?>?;
      _entityQuestionCount = arguments['entity_question_count'] as Map<int?, int>?;
      _entityRightCount = arguments['entity_right_count'] as Map<int?, int>?;
      _entityWrongCount = arguments['entity_wrong_count'] as Map<int?, int>?;
      _rightAnsIds = arguments['right_ans_ids'] as List<int?>?;
      _wrongAnsData = arguments['wrong_ans_data'] as Map<int?, String>?;
      _unansAnsIds = arguments['unans_ans_ids'] as List<int?>?;

      // Fetch chapter and subchapter data to pass to result_all.dart
      _fetchChapterSubchapterData();


      // We have all the data passed from the previous screen,
      // so we don't need to query the database again here to get the total questions.
      // The total question count for the specific chapter/subchapter is in _entityQuestionCount[_filterId]

      setState(() {
        isLoading = false; // Data is loaded from arguments
      });

    } else {
      print("No arguments passed to ChapterExamResultScreen.");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetches chapter and subchapter data
  Future<void> _fetchChapterSubchapterData() async {
     final dbHelper = DatabaseHelper();
     final db = await dbHelper.database;

     final List<Map<String, dynamic>> chapters = await db.query('chapter');
     final List<Map<String, dynamic>> subchapters = await db.query('subchapter');

     // Populate chapterMap and subchapterMap
     chapters.forEach((element) {
       _chapterMap[element['id'].toString()] =
           element['unit'] + ': ' + element['name'];
     });
     subchapters.forEach((element) {
       _subchapterMap[element['id']] = {'name': element['name'], 'chapter': element['chapter']};
     });
     setState(() {}); // Update state after fetching chapter/subchapter data
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
            title: Center(
                child: Text(
              "$_screenTitle", // Use the screen title from arguments
              style: const TextStyle(
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
              // Pass the relevant data to the result and all questions screens
              ChapterResultMainScreen(
                filterType: _filterType, // Pass filter type
                filterValue: _filterValue, // Pass filter value (name)
                rightAnsIds: _rightAnsIds ?? [],
                wrongAnsData: _wrongAnsData ?? {},
                unansAnsIds: _unansAnsIds ?? [],
                // We need to find the total questions for the specific entity based on _filterType and _filterValue
                // This might require iterating through _entityQuestionCount to find the count for the entity matching the _filterValue
                // For now, let's pass the whole entityQuestionCount map and handle the lookup in ChapterResultMainScreen
                entityQuestionCount: _entityQuestionCount ?? {},
              ),
              ChapterQuesResultAllScreen(
                 filterType: _filterType, // Pass filter type
                 filterValue: _filterValue, // Pass filter value (name)
                 rightAnsIds: _rightAnsIds ?? [],
                 wrongAnsData: _wrongAnsData ?? {},
                 unansAnsIds: _unansAnsIds ?? [],
                 questions: _questions, // Pass the list of questions
                 chapterMap: _chapterMap, // Pass chapter map
                 subchapterMap: _subchapterMap, // Pass subchapter map
              ),
            ],
          ),
        ),
      ),
    );
  }
}
