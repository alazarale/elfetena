import 'dart:collection';
import 'dart:async'; // Import for Future
import 'dart:io';
import 'dart:math'; // Import dart:math for the max function
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';
import '../models/exam_model.dart'; // Assuming SubjectModel is in this file
import 'package:eltest_exit/comps/service/database_manipulation.dart'; // Updated import path

// --- Data Models for Analysis Screen ---

/// Represents a summary of an exam result within a chapter.
class ExamResultSummary {
  final int resultId;
  final String examName;
  final int rightAnswers;
  final int totalQuestions;
  final double percentage;
  final double avgTime;

  ExamResultSummary({
    required this.resultId,
    required this.examName,
    required this.rightAnswers,
    required this.totalQuestions,
    required this.percentage,
    required this.avgTime,
  });
}

/// Represents the analysis data for a single chapter.
class ChapterAnalysisData {
  final int chapterId;
  final String chapterName;
  final String unitName; // Added unit name
  final List<ExamResultSummary> examResults;
  final List<LineChartBarData>
  resultProgressBars; // Changed to list of LineChartBarData
  final List<LineChartBarData>
  timeProgressBars; // Added list of LineChartBarData for time

  ChapterAnalysisData({
    required this.chapterId,
    required this.chapterName,
    required this.unitName, // Added unit name
    required this.examResults,
    required this.resultProgressBars, // Changed to list of LineChartBarData
    required this.timeProgressBars, // Added list of LineChartBarData for time
  });
}

// --- Analysis Screen Widget ---

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<SubjectModel> subjects = [];
  int _selectedSubjectId = 2; // Default subject ID
  bool isLoading = true;
  // Group chapters by unit for display
  Map<String, List<ChapterAnalysisData>> groupedChapterAnalysis = {};
  List<String> _unitNames = []; // List to hold unique unit names
  String _selectedUnitName = 'All'; // Currently selected unit, default is 'All'

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  /// Loads initial data including subjects and analysis for the default subject.
  Future<void> _loadAnalysisData() async {
    setState(() {
      isLoading = true;
    });
    await _loadSubjects();
    await _loadChapterAnalysis(_selectedSubjectId);
    setState(() {
      isLoading = false;
    });
  }

  /// Loads the list of subjects from the database.
  Future<void> _loadSubjects() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> subs = await db.query('subject');
    setState(() {
      subjects = List.generate(subs.length, (i) {
        return SubjectModel(subs[i]['id'], subs[i]['name']);
      });
    });
  }

  /// Loads chapter analysis data for a given subject ID.
  Future<void> _loadChapterAnalysis(int subjectId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Fetch exams for the selected subject
    final List<Map<String, dynamic>> exams = await db.query(
      'exam',
      where: 'subject=?',
      whereArgs: [subjectId],
    );

    if (exams.isEmpty) {
      setState(() {
        groupedChapterAnalysis = {}; // Clear list if no exams found
        _unitNames = []; // Clear unit names
      });
      return;
    }

    // Get exam IDs for the query
    final List<int> examIds = exams.map((e) => e['id'] as int).toList();
    final String examIdsString = examIds.join(',');

    // Fetch results for these exams
    final List<Map<String, dynamic>> results = await db.query(
      'result',
      where: 'exam IN ($examIdsString)',
    );

    if (results.isEmpty) {
      setState(() {
        groupedChapterAnalysis = {}; // Clear list if no results found
        _unitNames = []; // Clear unit names
      });
      return;
    }

    // Get result IDs for the query
    final List<int> resultIds = results.map((r) => r['id'] as int).toList();
    final String resultIdsString = resultIds.join(',');

    // Fetch resultchapter data for these results
    final List<Map<String, dynamic>> resultChapters = await db.query(
      'resultchapter',
      where: 'result IN ($resultIdsString)',
    );

    // Fetch chapters for the selected subject
    final List<Map<String, dynamic>> chapters = await db.query(
      'chapter',
      where: 'subject=?',
      whereArgs: [subjectId],
    );

    // Create maps for quick lookup
    final Map<int, String> examNameMap = {
      for (var e in exams) e['id'] as int: e['name'] as String,
    };
    final Map<int, int> resultToExamMap = {
      for (var r in results) r['id'] as int: r['exam'] as int,
    };
    final Map<int, Map<String, dynamic>> chapterInfoMap = {
      for (var c in chapters)
        c['id'] as int: {'unit': c['unit'], 'name': c['name']},
    };

    // Group resultchapter data by chapter
    final Map<int, List<Map<String, dynamic>>> groupedResultChapters = {};
    for (var rc in resultChapters) {
      final chapterId = rc['chapter'] as int;
      if (!groupedResultChapters.containsKey(chapterId)) {
        groupedResultChapters[chapterId] = [];
      }
      groupedResultChapters[chapterId]!.add(rc);
    }

    // Process grouped data to create ChapterAnalysisData list and group by unit
    final Map<String, List<ChapterAnalysisData>> tempGroupedAnalysis = {};
    final Map<String, int> unitQuestionCounts =
        {}; // To store total questions per unit

    groupedResultChapters.forEach((chapterId, rcList) {
      final chapterInfo = chapterInfoMap[chapterId];
      if (chapterInfo != null) {
        final unitName = chapterInfo['unit'] as String;
        final chapterName = chapterInfo['name'] as String;

        final List<ExamResultSummary> examResults = [];
        final List<LineChartBarData> resultProgressBars =
            []; // List to hold colored segments for result
        final List<LineChartBarData> timeProgressBars =
            []; // List to hold colored segments for time

        // Sort result chapters by result ID to ensure correct order for charts
        rcList.sort(
          (a, b) => (a['result'] as int).compareTo(b['result'] as int),
        );

        int totalQuestionsInChapter =
            0; // Calculate total questions for the chapter

        for (int i = 0; i < rcList.length; i++) {
          final rc = rcList[i];
          final resultId = rc['result'] as int;
          final examIdForResult = resultToExamMap[resultId];
          final examName =
              examIdForResult != null
                  ? examNameMap[examIdForResult] ?? 'Unknown Exam'
                  : 'Unknown Exam';
          final rightAnswers = rc['right'] as int;
          final totalQuestions = rc['no_questions'] as int;
          final avgTime =
              rc['avg_time'] != null
                  ? double.parse(rc['avg_time'].toString().replaceAll("-", ""))
                  : 0.0;

          totalQuestionsInChapter +=
              totalQuestions; // Add to total questions for the chapter

          final percentage =
              totalQuestions > 0 ? (rightAnswers / totalQuestions) * 100 : 0.0;

          examResults.add(
            ExamResultSummary(
              resultId: resultId,
              examName: examName,
              rightAnswers: rightAnswers,
              totalQuestions: totalQuestions,
              percentage: double.parse(
                percentage.toStringAsFixed(1),
              ), // Format percentage
              avgTime: double.parse(
                avgTime.toStringAsFixed(1),
              ), // Format avg time
            ),
          );

          // Create segments for result progress chart
          if (i > 0) {
            final previousPercentage = double.parse(
              examResults[i - 1].percentage.toStringAsFixed(1),
            );
            final currentPercentage = percentage;

            Color segmentColor;
            if (currentPercentage > previousPercentage) {
              segmentColor = Color(0xff28A164); // Green (Going up)
            } else if (currentPercentage < previousPercentage) {
              segmentColor = Color(0xffF35555); // Red (Going down)
            } else {
              segmentColor = Color(0xffF0A714); // Orange (Staying the same)
            }

            resultProgressBars.add(
              LineChartBarData(
                spots: [
                  FlSpot((i - 1).toDouble(), previousPercentage),
                  FlSpot(i.toDouble(), currentPercentage),
                ],
                isCurved: false, // Segments are straight lines
                color: segmentColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false), // Hide dots on segments
                belowBarData: BarAreaData(show: false),
              ),
            );

            // Create segments for time progress chart
            final previousAvgTime = double.parse(
              examResults[i - 1].avgTime.toStringAsFixed(1),
            );
            final currentAvgTime = avgTime;

            Color timeSegmentColor;
            if (currentAvgTime < previousAvgTime) {
              // Time going down is good
              timeSegmentColor = Color(0xff28A164); // Green
            } else if (currentAvgTime > previousAvgTime) {
              // Time going up is bad
              timeSegmentColor = Color(0xffF35555); // Red
            } else {
              // Time staying the same
              timeSegmentColor = Color(0xffF0A714); // Orange
            }

            timeProgressBars.add(
              LineChartBarData(
                spots: [
                  FlSpot((i - 1).toDouble(), previousAvgTime),
                  FlSpot(i.toDouble(), currentAvgTime),
                ],
                isCurved: false, // Segments are straight lines
                color: timeSegmentColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false), // Hide dots on segments
                belowBarData: BarAreaData(show: false),
              ),
            );
          } else if (rcList.length == 1) {
            // Handle case with only one data point - draw a single point or short segment for result
            resultProgressBars.add(
              LineChartBarData(
                spots: [
                  FlSpot(0.0, percentage),
                  FlSpot(
                    0.01,
                    percentage,
                  ), // Draw a very short segment to show the point
                ],
                isCurved: false,
                color: Color(0xffF0A714), // Default color for a single point
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true), // Show dot for a single point
                belowBarData: BarAreaData(show: false),
              ),
            );
            // Handle case with only one data point - draw a single point or short segment for time
            timeProgressBars.add(
              LineChartBarData(
                spots: [
                  FlSpot(0.0, avgTime),
                  FlSpot(
                    0.01,
                    avgTime,
                  ), // Draw a very short segment to show the point
                ],
                isCurved: false,
                color: Color(0xffF0A714), // Default color for a single point
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true), // Show dot for a single point
                belowBarData: BarAreaData(show: false),
              ),
            );
          }
        }

        // Add dots for all points in the result progress chart
        if (examResults.isNotEmpty) {
          resultProgressBars.add(
            LineChartBarData(
              spots: List.generate(
                examResults.length,
                (i) => FlSpot(
                  i.toDouble(),
                  double.parse(examResults[i].percentage.toStringAsFixed(1)),
                ),
              ),
              isCurved: false,
              color: Colors.transparent, // Transparent line
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.color0081B9, // Color of the dots
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          );
          // Add dots for all points in the time progress chart
          timeProgressBars.add(
            LineChartBarData(
              spots: List.generate(
                examResults.length,
                (i) => FlSpot(
                  i.toDouble(),
                  double.parse(examResults[i].avgTime.toStringAsFixed(1)),
                ),
              ),
              isCurved: false,
              color: Colors.transparent, // Transparent line
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.color0081B9.withOpacity(
                      0.7,
                    ), // Color of the dots (slightly different)
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }

        // Sort exam results by resultId for consistent display
        examResults.sort((a, b) => a.resultId.compareTo(b.resultId));

        final chapterAnalysis = ChapterAnalysisData(
          chapterId: chapterId,
          chapterName: chapterName,
          unitName: unitName, // Added unit name
          examResults: examResults,
          resultProgressBars:
              resultProgressBars, // Used the list of colored bars
          timeProgressBars:
              timeProgressBars, // Used the list of colored bars for time
        );

        // Group by unit name
        if (!tempGroupedAnalysis.containsKey(unitName)) {
          tempGroupedAnalysis[unitName] = [];
          unitQuestionCounts[unitName] =
              0; // Initialize question count for the unit
        }
        tempGroupedAnalysis[unitName]!.add(chapterAnalysis);
        unitQuestionCounts[unitName] =
            (unitQuestionCounts[unitName] ?? 0) +
            totalQuestionsInChapter; // Accumulate total questions for the unit
      }
    });

    // Sort chapters by name within each unit
    tempGroupedAnalysis.forEach((unit, chapters) {
      chapters.sort((a, b) => a.chapterName.compareTo(b.chapterName));
    });

    // Sort unit names based on total question count in descending order
    final sortedUnitNames =
        unitQuestionCounts.keys.toList()..sort(
          (a, b) => unitQuestionCounts[b]!.compareTo(unitQuestionCounts[a]!),
        );

    setState(() {
      groupedChapterAnalysis = tempGroupedAnalysis;
      _unitNames =
          ['All'] + sortedUnitNames; // Add 'All' and use the sorted unit names
      _selectedUnitName =
          'All'; // Reset selected unit to 'All' when subject changes
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    // Filter chapters based on selected unit
    final chaptersToDisplay =
        _selectedUnitName == 'All'
            ? groupedChapterAnalysis.entries
                .toList() // Show all units and their chapters
            : groupedChapterAnalysis.entries
                .where((entry) => entry.key == _selectedUnitName)
                .toList(); // Show only the selected unit

    return Scaffold(
      backgroundColor: AppTheme.colorF2F5F8,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Selection
          SubjectSelector(
            subjects: subjects,
            selectedSubjectId: _selectedSubjectId,
            onSubjectSelected: (subjectId) {
              setState(() {
                _selectedSubjectId = subjectId;
                isLoading = true; // Set loading true when changing subject
                _selectedUnitName = 'All'; // Reset unit selection
              });
              _loadChapterAnalysis(subjectId).then((_) {
                setState(() {
                  isLoading = false; // Set loading false after data is loaded
                });
              });
            },
          ),
          // Chapter Unit Selection
          if (_unitNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
              child: Text(
                'Choose By Topic',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color.fromARGB(255, 78, 93, 102),
                ),
              ),
            ), //  // Only show unit selector if there are units
          UnitSelector(
            unitNames: _unitNames,
            selectedUnitName: _selectedUnitName,
            onUnitSelected: (unitName) {
              setState(() {
                _selectedUnitName = unitName;
              });
            },
          ),
          Expanded(
            child: Visibility(
              visible: !isLoading,
              replacement: Center(
                child: CircularProgressIndicator(color: AppTheme.color0081B9),
              ),
              child:
                  groupedChapterAnalysis.isEmpty
                      ? Center(
                        child: Text(
                          'No analysis data available for this subject.',
                        ),
                      )
                      : ListView.builder(
                        itemCount: chaptersToDisplay.length,
                        itemBuilder: (BuildContext context, int unitIndex) {
                          final unitEntry = chaptersToDisplay[unitIndex];
                          final unitName = unitEntry.key;
                          final chaptersInUnit = unitEntry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display unit header only if 'All' is selected or it's the selected unit
                              if (_selectedUnitName == 'All' ||
                                  unitName == _selectedUnitName)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    unitName,
                                    style: TextStyle(
                                      color: AppTheme.color21205A,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: chaptersInUnit.length,
                                itemBuilder: (
                                  BuildContext context,
                                  int chapterIndex,
                                ) {
                                  final chapterAnalysis =
                                      chaptersInUnit[chapterIndex];
                                  return ChapterAnalysisCard(
                                    chapterAnalysisData: chapterAnalysis,
                                    deviceWidth:
                                        deviceWidth, // Pass device width for responsiveness
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Widgets ---

/// Widget for displaying the horizontal list of subjects.
class SubjectSelector extends StatelessWidget {
  final List<SubjectModel> subjects;
  final int selectedSubjectId;
  final ValueChanged<int> onSubjectSelected;

  const SubjectSelector({
    Key? key,
    required this.subjects,
    required this.selectedSubjectId,
    required this.onSubjectSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 60, // Increased height
        child: ListView.builder(
          itemCount: subjects.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (BuildContext context, int index) {
            final subject = subjects[index];
            final isSelected = selectedSubjectId == subject.id;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSubjectSelected(subject.id),
                child: Card(
                  shape: RoundedRectangleBorder(
                    // Added rounded corners
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  color:
                      isSelected
                          ? AppTheme.color0081B9
                          : Colors
                              .white, // Highlight selected with blue background
                  elevation:
                      isSelected ? 4.0 : 1.0, // Add subtle elevation change
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ), // Increased padding
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon on the left
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                            ), // Space between icon and text
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppTheme
                                            .color0081B9, // White icon background when selected, blue otherwise
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.book, // Using a generic book icon
                                  color:
                                      isSelected
                                          ? AppTheme.color0081B9
                                          : Colors
                                              .white, // Blue icon color when selected, white otherwise
                                  size: 20, // Slightly larger icon
                                ),
                              ),
                            ),
                          ),
                          // Text on the right
                          Text(
                            subject.name,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors
                                          .grey[700], // White text when selected, darker grey otherwise
                              fontWeight: FontWeight.bold,
                              fontSize: 15, // Slightly larger text
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget for displaying the horizontal list of chapter units.
class UnitSelector extends StatelessWidget {
  final List<String> unitNames;
  final String selectedUnitName;
  final ValueChanged<String> onUnitSelected;

  const UnitSelector({
    Key? key,
    required this.unitNames,
    required this.selectedUnitName,
    required this.onUnitSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 10.0,
      ), // Adjusted padding
      child: SizedBox(
        height: 60, // Increased height to match subject buttons
        child: ListView.builder(
          itemCount: unitNames.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (BuildContext context, int index) {
            final unitName = unitNames[index];
            final isSelected = selectedUnitName == unitName;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onUnitSelected(unitName),
                child: Card(
                  shape: RoundedRectangleBorder(
                    // Added rounded corners
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  color:
                      isSelected
                          ? AppTheme.color0081B9
                          : Colors
                              .white, // Highlight selected with blue background
                  elevation:
                      isSelected ? 4.0 : 1.0, // Add subtle elevation change
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ), // Increased padding
                    child: Center(
                      child: Row(
                        // Use Row for icon and text
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon on the left (using a generic folder icon for units)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                            ), // Space between icon and text
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppTheme
                                            .color0081B9, // White icon background when selected, blue otherwise
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.folder, // Using a generic folder icon
                                  color:
                                      isSelected
                                          ? AppTheme.color0081B9
                                          : Colors
                                              .white, // Blue icon color when selected, white otherwise
                                  size: 20, // Slightly larger icon
                                ),
                              ),
                            ),
                          ),
                          // Text on the right
                          Text(
                            unitName,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors
                                          .grey[700], // White text when selected, darker grey otherwise
                              fontWeight: FontWeight.bold,
                              fontSize: 15, // Slightly larger text
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget for displaying the analysis card for a single chapter.
class ChapterAnalysisCard extends StatelessWidget {
  final ChapterAnalysisData chapterAnalysisData;
  final double deviceWidth;

  const ChapterAnalysisCard({
    Key? key,
    required this.chapterAnalysisData,
    required this.deviceWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine max time for Y-axis dynamically
    double maxTime = 0.0;
    if (chapterAnalysisData.timeProgressBars.isNotEmpty) {
      // Find the maximum y-value across all segments
      maxTime = chapterAnalysisData.timeProgressBars
          .expand((barData) => barData.spots)
          .map((spot) => spot.y)
          .reduce((a, b) => a > b ? a : b);
    }
    // Add a buffer to the max time for better visualization
    maxTime = maxTime * 1.2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Card(
        elevation: 4.0, // Increased elevation for better visual separation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Name
              Text(
                chapterAnalysisData.chapterName,
                style: TextStyle(
                  color: AppTheme.color21205A,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              // Collapsible list of Exam Results for the Chapter
              ExpansionTile(
                tilePadding: EdgeInsets.zero, // Remove default padding
                title: Text(
                  'Exam Results', // Title for the collapsible section
                  style: TextStyle(
                    color: AppTheme.color0081B9,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initiallyExpanded: false, // Collapsed by default
                children: [
                  ListView.builder(
                    itemCount: chapterAnalysisData.examResults.length,
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
                    itemBuilder: (BuildContext context, int ind) {
                      final examResult = chapterAnalysisData.examResults[ind];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                // Use Expanded to prevent overflow
                                child: Text(
                                  examResult.examName,
                                  style: TextStyle(
                                    color: AppTheme.color3275a8,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // Handle long exam names
                                ),
                              ),
                              Text(
                                '${examResult.percentage.toStringAsFixed(1)} %',
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          LinearPercentIndicator(
                            width:
                                deviceWidth -
                                72, // Adjusted width for card padding
                            animation: true,
                            lineHeight: 10.0,
                            animationDuration: 1000,
                            percent:
                                examResult.totalQuestions > 0
                                    ? examResult.rightAnswers /
                                        examResult.totalQuestions
                                    : 0.0,
                            barRadius: Radius.circular(10),
                            progressColor: AppTheme.color0081B9,
                            backgroundColor: AppTheme.colorE1E9F9,
                          ),
                          SizedBox(height: 10),
                          Column(
                            // Use Column to stack Scored and Avg Time vertically
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Scored: ${examResult.rightAnswers}/${examResult.totalQuestions}",
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "AVG. time / question: ${examResult.avgTime.toStringAsFixed(1)} s",
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20), // Space between exam results
                        ],
                      );
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ), // Space between collapsible section and charts
              // Result Progress Chart
              if (chapterAnalysisData
                  .resultProgressBars
                  .isNotEmpty) // Check if there are any bars
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      height: 150, // Fixed height for the chart
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            // Left titles (Y-axis): Percentage
                            leftTitles: AxisTitles(
                              axisNameWidget: Text(
                                'Percentage (%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.color21205A,
                                ),
                              ), // Y-axis label
                              axisNameSize: 20,
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval:
                                    20, // Show percentage intervals (0, 20, 40, 60, 80, 100)
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      '${value.toInt()}%',
                                      style: TextStyle(fontSize: 10),
                                    ),
                              ),
                            ),
                            // Bottom titles (X-axis): Exam Number
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text(
                                'Exam Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.color21205A,
                                ),
                              ), // X-axis label
                              axisNameSize: 20,
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1, // Show every exam number
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      '${value.toInt()}',
                                      style: TextStyle(fontSize: 10),
                                    ), // Show just the exam number
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: const Color(0xff37434d),
                              width: 1,
                            ),
                          ), // Add border
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval:
                                1, // Vertical grid lines at each exam number
                            horizontalInterval:
                                20, // Horizontal grid lines at percentage intervals
                          ),
                          minY: 0, // Start Y-axis from 0%
                          maxY: 100, // Max Y-axis is 100%
                          minX: 0, // Start X-axis from 0
                          maxX:
                              chapterAnalysisData.examResults.length
                                          .toDouble() >
                                      0
                                  ? chapterAnalysisData.examResults.length
                                          .toDouble() -
                                      1 +
                                      1
                                  : 1, // Max X is number of exams -1 (for 0-based index) + a little buffer, or 1 if no exams
                          lineBarsData:
                              chapterAnalysisData
                                  .resultProgressBars, // Use the list of colored bars
                          // Add tooltip for interactivity
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (List<FlSpot> touchedSpots) {
                                return touchedSpots.map((FlSpot touchedSpot) {
                                  // Tooltip shows Exam number (x) and Percentage (y)
                                  return LineTooltipItem(
                                    'Exam ${(touchedSpot.x).toInt()}: ${touchedSpot.y.toStringAsFixed(1)}%',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Result Progress (% Correct)',
                        style: TextStyle(
                          color: AppTheme.color0081B9,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 30),
              // Time/Question Progress Chart
              if (chapterAnalysisData
                  .timeProgressBars
                  .isNotEmpty) // Check if there are any bars
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      height: 150, // Fixed height for the chart
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            // Left titles (Y-axis): Time in seconds
                            leftTitles: AxisTitles(
                              axisNameWidget: Text(
                                'Time (s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.color21205A,
                                ),
                              ), // Y-axis label
                              axisNameSize: 20,
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxTime / 4).roundToDouble().clamp(
                                  5,
                                  double.infinity,
                                ), // Dynamic interval based on max time, minimum 5
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      '${value.toInt()}s',
                                      style: TextStyle(fontSize: 10),
                                    ),
                              ),
                            ),
                            // Bottom titles (X-axis): Exam Number
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text(
                                'Exam Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.color21205A,
                                ),
                              ), // X-axis label
                              axisNameSize: 20,
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1, // Show every exam number
                                getTitlesWidget:
                                    (value, meta) => Text(
                                      '${value.toInt()}',
                                      style: TextStyle(fontSize: 10),
                                    ), // Show just the exam number
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: const Color(0xff37434d),
                              width: 1,
                            ),
                          ), // Add border
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval:
                                1, // Vertical grid lines at each exam number
                            horizontalInterval: (maxTime / 4).roundToDouble().clamp(
                              5,
                              double.infinity,
                            ), // Horizontal grid lines based on dynamic interval
                          ),
                          minY: 0, // Start Y-axis from 0
                          maxY:
                              maxTime, // Max Y-axis is the determined max time with buffer
                          minX: 0, // Start X-axis from 0
                          maxX:
                              chapterAnalysisData.examResults.length
                                          .toDouble() >
                                      0
                                  ? chapterAnalysisData.examResults.length
                                          .toDouble() -
                                      1 +
                                      1
                                  : 1, // Max X is number of exams -1 (for 0-based index) + a little buffer, or 1 if no exams
                          lineBarsData:
                              chapterAnalysisData
                                  .timeProgressBars, // Use the list of colored bars for time
                          // Add tooltip for interactivity
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (List<FlSpot> touchedSpots) {
                                return touchedSpots.map((FlSpot touchedSpot) {
                                  // Tooltip shows Exam number (x) and Time (y)
                                  return LineTooltipItem(
                                    'Exam ${(touchedSpot.x).toInt()}: ${touchedSpot.y.toStringAsFixed(1)}s',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Time/Question Progress (seconds)',
                        style: TextStyle(
                          color: AppTheme.color0081B9,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 10), // Space at the bottom of the card
            ],
          ),
        ),
      ),
    );
  }
}
