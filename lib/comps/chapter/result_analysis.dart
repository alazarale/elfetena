import 'package:eltest_exit/comps/service/database_manipulation.dart'
    show Chapter, DatabaseHelper, Subchapter;
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:io';

import '../circle_progress.dart';

class ChapterResultMainScreen extends StatefulWidget {
  ChapterResultMainScreen({
    Key? key,
    required this.rightAnsIds,
    required this.wrongAnsData,
    required this.unansAnsIds,
    required this.entityQuestionCount, // Receive the map of entity question counts
    this.filterType, // Added filter type
    this.filterValue, // Added filter value (name)
  }) : super(key: key);

  final List<int?> rightAnsIds;
  final Map<int?, String> wrongAnsData;
  final List<int?> unansAnsIds;
  final Map<int?, int>
  entityQuestionCount; // Map of entity ID to total questions
  final String? filterType;
  final dynamic filterValue; // Filter value (name)

  @override
  State<ChapterResultMainScreen> createState() =>
      _ChapterResultMainScreenState();
}

class _ChapterResultMainScreenState extends State<ChapterResultMainScreen> {
  double perc = 0;
  int totalQuestionsForEntity =
      0; // Total questions for the currently displayed entity

  @override
  void initState() {
    super.initState();
    // Find the total questions for the specific entity based on filter type and value
    findTotalQuestionsForEntity();
    // Calculate percentage based on the found total questions
    calculatePercentage();
  }

  // Method to find the total questions for the specific entity
  void findTotalQuestionsForEntity() {
    if (widget.filterType != null && widget.filterValue != null) {
      // Iterate through the entityQuestionCount map to find the matching entity
      widget.entityQuestionCount.forEach((entityId, count) async {
        String? entityName;
        // Need to query database to get the name of the entity (chapter or subchapter) based on ID
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        print('d');
        print(widget.filterType);
        print(widget.filterValue);
        print(widget.entityQuestionCount);
        print(widget.unansAnsIds);
        print(widget.rightAnsIds);
        print(widget.wrongAnsData);
        print('sdfs');

        if (widget.filterType == 'dept' || widget.filterType == 'topic') {
          // It's a chapter ID
          final chapter = await Chapter().getById(entityId!);
          entityName = chapter?.name;
        } else if (widget.filterType == 'subtopic') {
          // It's a subchapter ID
          final subchapter = await Subchapter().getById(entityId!);
          entityName = subchapter?.name;
        }

        // Compare the found name with the filterValue
        
        setState(() {
          totalQuestionsForEntity += count;
          print(totalQuestionsForEntity);
          calculatePercentage(); // Recalculate percentage once total questions are found
        });
      });
    }
  }

  // Method to calculate the percentage
  void calculatePercentage() {
    if (totalQuestionsForEntity > 0) {
      perc = (widget.rightAnsIds.length / totalQuestionsForEntity) * 100;
      print(perc);
    } else {
      perc = 0;
    }
    setState(() {}); // Update the UI
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    // Calculate unanswered count
    final unansweredCount =
        totalQuestionsForEntity -
        (widget.rightAnsIds.length + widget.wrongAnsData.length);

    return Scaffold(
      backgroundColor: Color(0xffF2F5F8),
      body: SingleChildScrollView(
        child: Column(
          // Removed Visibility as isLoading is not used for this widget's content
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
            CircularProgressForResult(
              perc,
              widget.rightAnsIds.length,
              totalQuestionsForEntity,
            ), // Use totalQuestionsForEntity
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
                          "You have got ${widget.rightAnsIds.length} questions Right",
                          style: TextStyle(
                            color: Color(0xff21205A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalQuestionsForEntity > 0
                              ? "${((widget.rightAnsIds.length / totalQuestionsForEntity) * 100).toStringAsFixed(1)}%"
                              : "0.0%", // Calculate percentage using totalQuestionsForEntity
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
                      percent:
                          totalQuestionsForEntity > 0
                              ? widget.rightAnsIds.length /
                                  totalQuestionsForEntity
                              : 0.0, // Calculate percentage using totalQuestionsForEntity
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
                          "You have got ${widget.wrongAnsData.length} questions Wrong",
                          style: TextStyle(
                            color: Color(0xff21205A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalQuestionsForEntity > 0
                              ? "${((widget.wrongAnsData.length / totalQuestionsForEntity) * 100).toStringAsFixed(1)}%"
                              : "0.0%", // Calculate percentage using totalQuestionsForEntity
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
                      percent:
                          totalQuestionsForEntity > 0
                              ? widget.wrongAnsData.length /
                                  totalQuestionsForEntity
                              : 0.0, // Calculate percentage using totalQuestionsForEntity
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
                          "${unansweredCount} question left unanswered", // Use the calculated unanswered count
                          style: TextStyle(
                            color: Color(0xff21205A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalQuestionsForEntity > 0
                              ? "${((unansweredCount / totalQuestionsForEntity) * 100).toStringAsFixed(1)}%"
                              : "0.0%", // Calculate percentage using totalQuestionsForEntity and unanswered count
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
                          totalQuestionsForEntity > 0
                              ? unansweredCount / totalQuestionsForEntity
                              : 0.0, // Calculate percentage using totalQuestionsForEntity and unanswered count
                      barRadius: Radius.circular(10),
                      progressColor: Color(0xff0081B9),
                      backgroundColor: Color.fromARGB(116, 90, 89, 89),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
