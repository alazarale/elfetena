import 'package:eltest_exit/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


import '../../models/exam_model.dart'; // Assuming QuestionModel is in this file
import '../feedback_dialog.dart';
import '../service/common.dart';
import '../service/database_manipulation.dart'; 

class ChapterQuesResultAllScreen extends StatefulWidget {
  ChapterQuesResultAllScreen({
    Key? key,
    required this.rightAnsIds,
    required this.wrongAnsData,
    required this.unansAnsIds,
    required this.questions, // Pass the list of questions
    this.filterType, // Added filter type
    this.filterValue, // Added filter value (name)
    required this.chapterMap, // Receive chapter map
    required this.subchapterMap, // Receive subchapter map
  }) : super(key: key);

  final List<int?> rightAnsIds;
  final Map<int?, String> wrongAnsData;
  final List<int?> unansAnsIds;
  final List<Question> questions; // List of questions for this entity
  final String? filterType;
  final dynamic filterValue; // Filter value (name)
  final Map<String, String> chapterMap; // Chapter map
  final Map<int, Map<String, dynamic>> subchapterMap; // Subchapter map


  @override
  State<ChapterQuesResultAllScreen> createState() =>
      _ChapterQuesResultAllScreenState();
}

class _ChapterQuesResultAllScreenState
    extends State<ChapterQuesResultAllScreen> {
  bool isLoading = true;
  // We no longer need ques_tex or q_count as we iterate directly over widget.questions
  // List<TeXViewWidget> ques_tex = [];
  // int q_count = 0; // Question counter for display

  // Set to keep track of favorited question IDs
  Set<int> _favoritedQuestionIds = {};

  // Map to track expanded state of explanations for questions
  Map<int?, bool> explanationExpandedState = {};


  @override
  void initState() {
    super.initState();
    _loadFavoritedQuestions(); // Load favorited questions when the widget initializes
    // No need to call processQuestions here, as we build the UI directly from widget.questions
    // processQuestions();
  }

  // Function to load favorited questions from the database
  Future<void> _loadFavoritedQuestions() async {
    final favoriteModel = Favorite();
    final favoritedList = await favoriteModel.getAll();
    setState(() {
      _favoritedQuestionIds = favoritedList.map((fav) => fav.question!).whereType<int>().toSet();
       isLoading = false; // Set loading to false after fetching favorites
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
      // Assuming the query returns a list of Favorite objects, we need the ID to delete
      if (existingFavorite.first.id != null) {
         await Favorite(id: existingFavorite.first.id).delete();
         setState(() {
            _favoritedQuestionIds.remove(questionId);
         });
         print('Removed question $questionId from favorites');
      }
    } else {
      // Question is not favorited, add it
      final newFavorite = Favorite(question: questionId);
      await newFavorite.save();
      setState(() {
        _favoritedQuestionIds.add(questionId);
      });
      print('Added question $questionId to favorites');
    }
  }


  // Helper function to build choice text with highlighting
  Widget _buildChoiceText(String choice, String? text, String? correctAnswer, String? userChosenAnswer, bool isQuestionAnswered) {
    Color textColor = Colors.black87; // Default text color
    FontWeight fontWeight = FontWeight.normal;
    Color letterBgColor = Colors.transparent;
    Color letterColor = Colors.black87;
    Color borderColor = Colors.black87;

    // Highlight correct answer in green
    if (correctAnswer != null && choice.toLowerCase() == correctAnswer.toLowerCase()) {
      textColor = Color.fromARGB(255, 24, 111, 68); // Green color
      fontWeight = FontWeight.bold;
      letterBgColor = Color.fromARGB(255, 24, 111, 68);
      letterColor = Colors.white;
      borderColor = Color.fromARGB(255, 24, 111, 68);
    }

    // Highlight user's wrong answer in red if the question was answered and the user was wrong
    if (isQuestionAnswered && userChosenAnswer != null && choice.toLowerCase() == userChosenAnswer.toLowerCase() && (correctAnswer == null || choice.toLowerCase() != correctAnswer.toLowerCase())) {
      textColor = Color.fromARGB(255, 155, 27, 27); // Red color
      fontWeight = FontWeight.bold;
       letterBgColor = Color.fromARGB(255, 155, 27, 27);
       letterColor = Colors.white;
       borderColor = Color.fromARGB(255, 155, 27, 27);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             width: 24, // Fixed width for the letter container
             height: 24, // Fixed height
             margin: EdgeInsets.only(right: 8.0),
             decoration: BoxDecoration(
               color: letterBgColor,
               border: Border.all(color: borderColor, width: 1.0),
               borderRadius: BorderRadius.circular(4.0),
             ),
             child: Center(
               child: Text(
                 choice,
                 style: TextStyle(
                   color: letterColor,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 ),
               ),
             ),
           ),
          Expanded( // Use Expanded to prevent overflow
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text ?? '',
                style: TextStyle(
                  color: textColor,
                    fontSize: 14,
                    fontWeight: fontWeight,
                
                  ),
                
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF2F5F8),
      // Removed the Retake Exam button from here as it's not in the provided all_question.dart
      // floatingActionButton: FloatingActionButton.extended(
      //   label: Text('Send Feedback'),
      //   onPressed: () {
      //     // You might need to pass more specific info for feedback based on chapter/subchapter
      //     showDialog(
      //       context: context,
      //       builder: (BuildContext context) {
      //         return FeedbackDialogBox(examTitle: widget.filterType == 'dept' ? 'Unit ${widget.filterValue}' : (widget.filterType == 'topic' ? 'Chapter ${widget.filterValue}' : 'Subchapter ${widget.filterValue}'));
      //       },
      //     );
      //   },
      //   backgroundColor: const Color(0xff0081B9),
      //   foregroundColor: Colors.white,
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Position the button
      body: SingleChildScrollView(
        child: Visibility(
          visible: !isLoading, // Show content only when not loading
          replacement: Center(child: CircularProgressIndicator()), // Show loading indicator
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
              children: [
                const Center(
                  child: const Text(
                    'All Questions',
                    style: const TextStyle(
                      color: Color(0xff21205A),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Display total number of questions
                Text(
                  'Total Questions: ${widget.questions.length}',
                  style: TextStyle(
                    color: AppTheme.color21205A,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 SizedBox(height: 20), // Add some space

                // Use ListView.builder to display all questions
                ListView.builder(
                  shrinkWrap: true, // Use shrinkWrap to make it work inside SingleChildScrollView
                  physics: NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    final int? questionId = question.id;
                    final String? correctAnswer = question.ans;

                    // Determine the status of the question
                    String status = 'Unanswered';
                    Color statusColor = Color(0xffFDF1D9); // Unanswered color (light orange)
                    bool isQuestionAnswered = widget.rightAnsIds.contains(questionId) || widget.wrongAnsData.containsKey(questionId);
                    String? userChosenAnswer = widget.wrongAnsData[questionId]; // Get user's answer (only exists for wrong answers)


                    if (widget.rightAnsIds.contains(questionId)) {
                      status = 'Right';
                      statusColor = Color(0xffDDF0E6); // Right color (light green)
                    } else if (widget.wrongAnsData.containsKey(questionId)) {
                      status = 'Wrong';
                      statusColor = Color(0xffFDE4E4); // Wrong color (light red)
                    }


                     // Get the current expanded state for this question
                    bool isExplanationExpanded = explanationExpandedState[questionId] ?? false;

                    // Determine the question text to display (including note if available)
                    String displayedQuestionText = 'Question ${index + 1}: ';
                    if (question.note != null && question.note!.isNotEmpty) {
                       displayedQuestionText += '${question.note!}\n${question.ques!}';
                    } else {
                       displayedQuestionText += question.ques!;
                    }

                     // Check if the question is favorited
                    bool isFavorited = _favoritedQuestionIds.contains(questionId);

                    // Get chapter and subchapter names for the path
                    String chapterUnitName = 'Unknown Unit';
                    String chapterName = 'Unknown Chapter';
                    String subchapterName = 'Unknown Subchapter';

                    if (question.chapter != null && widget.chapterMap.containsKey(question.chapter.toString())) {
                       final chapterInfo = widget.chapterMap[question.chapter.toString()];
                       if (chapterInfo != null) {
                         final parts = chapterInfo.split(':');
                         if (parts.length == 2) {
                           chapterUnitName = parts[0].trim();
                           chapterName = parts[1].trim();
                         }
                       }
                    }

                    if (question.subchapter != null && widget.subchapterMap.containsKey(question.subchapter)) {
                       final subchapterInfo = widget.subchapterMap[question.subchapter!];
                        if (subchapterInfo != null) {
                          subchapterName = subchapterInfo['name'];
                        }
                    }

                    String chapterPath = '$chapterUnitName > $chapterName > $subchapterName';


                    return Card( // Wrap each question in a Card
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
                             Row( // Row for Status Label and Favorite Icon
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Status Label
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.color21205A, // Or a color that contrasts well with the background
                                      ),
                                    ),
                                  ),
                                  // Favorite Icon
                                  if (questionId != null) // Only show favorite icon if questionId is not null
                                    IconButton(
                                      icon: Icon(
                                        isFavorited ? Icons.favorite : Icons.favorite_border, // Filled or outlined heart
                                        color: isFavorited ? Colors.red : Colors.grey, // Red if favorited, grey otherwise
                                      ),
                                      onPressed: () {
                                        // Toggle favorite status and update state
                                         _toggleFavoriteStatus(questionId).then((_) {
                                            setState(() {
                                              // Update the local state
                                            });
                                         });
                                      },
                                    ),
                                ],
                              ),
                            SizedBox(height: 8.0),
                            // Display Chapter Path
                            Text(
                              chapterPath,
                              style: TextStyle(
                                color: Color(0xff0081B9), // Specified color
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0), // Space between path and question text
                            Text( // Use Html for question text to render potential HTML/TeX
                                displayedQuestionText,
                                style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.color21205A,
                                   
                                )
                            ),

                            // Display question image if available
                            if (question.image != null && question.image!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Image.network('${main_url}${question.image!}'),
                                ),

                            SizedBox(height: 8.0),
                            // Display choices with highlighting
                            _buildChoiceText('A', question.a, correctAnswer, userChosenAnswer, isQuestionAnswered),
                            _buildChoiceText('B', question.b, correctAnswer, userChosenAnswer, isQuestionAnswered),
                            _buildChoiceText('C', question.c, correctAnswer, userChosenAnswer, isQuestionAnswered),
                            _buildChoiceText('D', question.d, correctAnswer, userChosenAnswer, isQuestionAnswered),
                             // Add ExpansionTile for Explanation if explanation is available
                            if (question.explanation != null && question.explanation!.isNotEmpty)
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Show Explanation',
                                  style: TextStyle(
                                    color: AppTheme.color0081B9, // Color to indicate clickability
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Control the expanded state using the state map
                                initiallyExpanded: explanationExpandedState[questionId] ?? false,
                                onExpansionChanged: (bool expanded) {
                                  // Update the state map when the expansion changes
                                  setState(() {
                                    explanationExpandedState[questionId] = expanded;
                                  });
                                },
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text( // Use Html to render explanation
                                       question.explanation!,
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
                 SizedBox(height: 80), // Added space at the bottom to prevent content from being hidden by the FAB
              ],
            ),
          ),
        ),
      ),
       // Add the Send Feedback FAB back, styled like in all_question.dart
      // Position the button
    );
  }
}
