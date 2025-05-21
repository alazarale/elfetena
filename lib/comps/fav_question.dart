import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_html/flutter_html.dart'; // Assuming flutter_html is needed for question/explanation text

// Assuming these models are defined in your database_manipulation.dart or similar file
// import '../service/database_manipulation.dart'; // Import your database helper and models
import '../theme/app_theme.dart'; // Assuming you have an AppTheme file for colors

class FavoriteQuestionScreen extends StatefulWidget {
  const FavoriteQuestionScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteQuestionScreen> createState() => _FavoriteQuestionScreenState();
}

class _FavoriteQuestionScreenState extends State<FavoriteQuestionScreen> {
  late Database db;
  bool isLoading = true;
  // Nested map to organize questions: Subject Name -> Chapter Unit -> Subchapter Name -> List of Question Maps
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> organizedQuestions = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteQuestions();
  }

  // Loads favorite questions and organizes them hierarchically
  _loadFavoriteQuestions() async {
    setState(() {
      isLoading = true;
      organizedQuestions.clear(); // Clear previous data
    });

    try {
      // Get the database path and open the database
      var databasesPath = await getDatabasesPath();
      var path = Path.join(databasesPath, "elexam.db");
      db = await openDatabase(path, version: 1);

      // 1. Fetch all favorite question IDs from the 'favorite' table
      final List<Map<String, dynamic>> favs = await db.query('favorite');
      if (favs.isEmpty) {
        // No favorite questions, stop loading and return
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Extract question IDs from the favorite entries
      List<int> favQuestionIds = favs.map<int>((fav) => fav['question'] as int).toList();

      // 2. Fetch all questions corresponding to these favorite IDs from the 'question' table
      String favIdsString = favQuestionIds.join(',');
      final List<Map<String, dynamic>> questions = await db.query(
        'question',
        where: 'id IN ($favIdsString)',
      );

      if (questions.isEmpty) {
         // No question details found for the favorite IDs
         setState(() {
            isLoading = false;
          });
         return;
      }

      // 3. Get unique chapter, subchapter, and subject IDs from the fetched questions
      Set<int> chapterIds = questions.map<int>((q) => q['chapter'] as int).toSet();
      Set<int> subchapterIds = questions.map<int>((q) => q['subchapter'] as int).toSet();
      // We'll get subject IDs from chapter details in the next step

      // 4. Fetch details for these unique chapter, subchapter, and subject IDs
      // Create lookup maps for efficient access by ID
      Map<int, Map<String, dynamic>> chaptersMap = {};
      if (chapterIds.isNotEmpty) {
         String chapterIdsString = chapterIds.join(',');
         final List<Map<String, dynamic>> chapters = await db.query(
           'chapter',
           where: 'id IN ($chapterIdsString)',
         );
         chapters.forEach((c) => chaptersMap[c['id'] as int] = c);
      }

      Map<int, Map<String, dynamic>> subchaptersMap = {};
       if (subchapterIds.isNotEmpty) {
          String subchapterIdsString = subchapterIds.join(',');
          final List<Map<String, dynamic>> subchapters = await db.query(
            'subchapter',
            where: 'id IN ($subchapterIdsString)',
          );
          subchapters.forEach((sc) => subchaptersMap[sc['id'] as int] = sc);
       }

      // Get subject IDs from the fetched chapters and fetch subject details
      Set<int> subjectIds = chaptersMap.values.map<int>((c) => c['subject'] as int).toSet();
      Map<int, Map<String, dynamic>> subjectsMap = {};
      if (subjectIds.isNotEmpty) {
         String subjectIdsString = subjectIds.join(',');
         final List<Map<String, dynamic>> subjects = await db.query(
           'subject',
           where: 'id IN ($subjectIdsString)',
         );
         subjects.forEach((s) => subjectsMap[s['id'] as int] = s);
      }


      // 5. Organize the fetched questions into the nested structure
      for (var question in questions) {
        final int chapterId = question['chapter'] as int;
        final int subchapterId = question['subchapter'] as int;
        final int subjectId = chaptersMap[chapterId]?['subject'] as int; // Get subject ID from chapter

        // Get names from lookup maps, using default values if not found (shouldn't happen if database is consistent)
        final String subjectName = subjectsMap[subjectId]?['name'] ?? 'Unknown Subject';
        final String chapterUnit = chaptersMap[chapterId]?['unit'] ?? 'Unknown Unit'; // Assuming 'unit' is the chapter name/unit
        final String subchapterName = subchaptersMap[subchapterId]?['name'] ?? 'Unknown Subchapter';

        // Ensure the nested maps and list exist for the current hierarchy
        organizedQuestions.putIfAbsent(subjectName, () => {});
        organizedQuestions[subjectName]!.putIfAbsent(chapterUnit, () => {});
        organizedQuestions[subjectName]![chapterUnit]!.putIfAbsent(subchapterName, () => []);

        // Add the current question map to the list at the correct level
        organizedQuestions[subjectName]![chapterUnit]![subchapterName]!.add(question);
      }

       print("Organized Questions: $organizedQuestions");


    } catch (e) {
      print("Error loading favorite questions: $e");
      // You might want to show an error message to the user here
    } finally {
      // Set loading to false regardless of success or failure
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to build choice text with highlighting
  Widget _buildChoiceText(String choice, String? text, String? correctAnswer) {
    Color textColor = AppTheme.color21205A; // Default text color
    FontWeight fontWeight = FontWeight.normal;

    // Highlight correct answer in green
    if (correctAnswer != null && choice.toLowerCase() == correctAnswer.toLowerCase()) {
      textColor = AppTheme.color28A164; // Green color from AppTheme
      fontWeight = FontWeight.bold;
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
               color: Colors.transparent,
               border: Border.all(color: textColor, width: 1.0),
               borderRadius: BorderRadius.circular(4.0),
             ),
             child: Center(
               child: Text(
                 choice,
                 style: TextStyle(
                   color: textColor,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 ),
               ),
             ),
           ),
          Expanded( // Use Expanded to prevent overflow
            child: Html(
              data: "<p>${text ?? ''}</p>",
              style: {
                "p": Style(
                  color: textColor,
                  fontSize: FontSize(14),
                  fontWeight: fontWeight,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // final deviceHeight = MediaQuery.of(context).size.height; // Not used
    // final devWidth = MediaQuery.of(context).size.width; // Not directly used in this build method

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.white), // Use AppTheme.white
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_sharp,
                size: 20,
                color: AppTheme.color0081B9, // Use AppTheme color
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.colorF2F5F8, // Use AppTheme color
        title: Center( // Center the title
            child: Text(
          "Favorite Questions", // Updated title
          style: TextStyle(
            color: AppTheme.color21205A, // Use AppTheme color
            fontWeight: FontWeight.bold,
          ),
        )),
      ),
      backgroundColor: AppTheme.colorF2F5F8, // Use AppTheme color
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : organizedQuestions.isEmpty
              ? Center(child: Text('No favorite questions found.')) // Message for empty state
              : ListView.builder(
                  // Build list of Subjects (outermost level)
                  itemCount: organizedQuestions.keys.length,
                  itemBuilder: (context, subjectIndex) {
                    final subjectName = organizedQuestions.keys.elementAt(subjectIndex);
                    final chaptersInSubject = organizedQuestions[subjectName]!;

                    return Card( // Card for Subject level
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0, // Increased elevation for subjects
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
                      child: ExpansionTile(
                        iconColor: AppTheme.color0081B9, // Color for expansion icon
                        collapsedIconColor: AppTheme.color0081B9, // Color for collapsed icon
                        title: Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.color0081B9, // Subject title color
                          ),
                        ),
                        children: chaptersInSubject.keys.map((chapterUnit) {
                          final subchaptersInChapter = chaptersInSubject[chapterUnit]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card( // Card for Chapter Unit level
                              margin: EdgeInsets.symmetric(vertical: 4.0),
                              elevation: 2.0, // Increased elevation for chapters
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners
                              child: ExpansionTile(
                                iconColor: AppTheme.color21205A, // Color for expansion icon
                                collapsedIconColor: AppTheme.color21205A, // Color for collapsed icon
                                title: Text(
                                  'Unit: $chapterUnit', // Display Chapter Unit
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.color21205A, // Chapter title color
                                  ),
                                ),
                                children: subchaptersInChapter.keys.map((subchapterName) {
                                  final questionsInSubchapter = subchaptersInChapter[subchapterName]!;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Card( // Card for Subchapter level
                                       margin: EdgeInsets.symmetric(vertical: 2.0),
                                       elevation: 1.0, // Increased elevation for subchapters
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Rounded corners
                                       child: ExpansionTile(
                                          iconColor: AppTheme.color0081B9, // Color for expansion icon
                                          collapsedIconColor: AppTheme.color0081B9, // Color for collapsed icon
                                          title: Text(
                                             'Subchapter: $subchapterName', // Display Subchapter Name
                                             style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color:AppTheme.color0081B9, // Subchapter title color
                                             ),
                                          ),
                                          children: questionsInSubchapter.map((question) {
                                             // Display individual questions within the subchapter
                                             return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                child: Card( // Card for each Question
                                                   elevation: 0.5, // Slight elevation for questions
                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)), // Rounded corners
                                                   child: Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                            // Display Question Text
                                                            Html(
                                                              data: "<p>Q: ${question['ques']}</p>",
                                                              style: {
                                                                "p": Style(
                                                                    color: AppTheme.color0081B9, // Question text color
                                                                    fontSize: FontSize(16), // Slightly smaller font for questions within subchapter
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                              },
                                                            ),
                                                            SizedBox(height: 8.0),
                                                            // Display Choices with highlighting
                                                            _buildChoiceText('A', question['a'], question['ans']),
                                                            _buildChoiceText('B', question['b'], question['ans']),
                                                            _buildChoiceText('C', question['c'], question['ans']),
                                                            _buildChoiceText('D', question['d'], question['ans']),
                                                            // Display explanation if available
                                                            if (question['explanation'] != null && question['explanation'].isNotEmpty)
                                                              Padding(
                                                                padding: const EdgeInsets.only(top: 8.0),
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      'Explanation:',
                                                                      style: TextStyle(
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: AppTheme.color0081B9, // Explanation title color
                                                                      ),
                                                                    ),
                                                                    Html(
                                                                      data: question['explanation'],
                                                                      style: {
                                                                        "body": Style(
                                                                          fontSize: FontSize(13),
                                                                          fontStyle: FontStyle.italic,
                                                                          color: Colors.grey[700], // Explanation text color
                                                                        ),
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                         ],
                                                      ),
                                                   ),
                                                ),
                                             );
                                          }).toList(), // Convert questions map to a list of Widgets
                                       ),
                                    ),
                                  );
                                }).toList(), // Convert subchapters map to a list of Widgets
                              ),
                            ),
                          );
                        }).toList(), // Convert chapters map to a list of Widgets
                      ),
                    );
                  },
                ),
    );
  }
}

// Helper class for radio button model (kept from previous code)
class RadioModel {
  bool isSelected;
  final String buttonText;
  final String text;

  RadioModel(this.isSelected, this.buttonText, this.text);
}
