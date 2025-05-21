import 'package:eltest_exit/comps/study/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

import '../service/database_manipulation.dart';

class NationalStudyScreen extends StatefulWidget {
  const NationalStudyScreen({super.key});

  @override
  State<NationalStudyScreen> createState() => _NationalStudyScreenState();
}

class _NationalStudyScreenState extends State<NationalStudyScreen> {
  List<TypeName> allTypeNames = [];
  late Database db;
  bool isLoading = true;
  String detailType = 'exam';
  List<Exam> exams = [];
  List<Map<String, dynamic>> subs = [];
  Map questions = {};
  // ignore: non_constant_identifier_names
  Map subs_map = {};
  int? typeNameGradeSub;
  // ignore: non_constant_identifier_names
  List st_cls = [
    [Color(0xffE1E9F9), Color(0xff0081B9), Color.fromARGB(255, 0, 82, 117)],
    [Color(0xffFDF1D9), Color(0xffF0A714), Color.fromARGB(255, 178, 124, 14)],
    [Color(0xffFDE4E4), Color(0xffF35555), Color.fromARGB(255, 155, 27, 27)],
    [Color(0xffDDF0E6), Color(0xff28A164), Color.fromARGB(255, 24, 111, 68)],
  ];

  @override
  void initState() {
    super.initState();

    gettingFirstList();
  }

  gettingFirstList() async {
    int myCreatorTypeId = 3;
    allTypeNames = await getTypeNamesByCreatorType(myCreatorTypeId);

    if (allTypeNames.isNotEmpty) {
      setState(() {});
    }
  }

  Future<List<TypeName>> getTypeNamesByCreatorType(int creatorTypeId) async {
    // Create an instance of the TypeName model
    final typeNameModel = TypeName();

    // Use the query method to filter by the creatortype foreign key
    List<TypeName> typeNames = await typeNameModel.query(
      where:
          'creatortype = ?', // Filter where the creatortype column matches the provided ID
      whereArgs: [
        creatorTypeId,
      ], // Provide the creatorType ID as a query argument
    );

    return typeNames;
  }

  Map<String, dynamic>? _selectedFilterData;

  // Function to show the modal bottom sheet and get the result
  void _showFilterModal() async {
    // showModalBottomSheet returns a Future that completes when the modal is popped
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xffF2F5F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return ModalBottomSheet();
      },
    );
    // Check if a result was returned (not null)
    if (result != null) {
      setState(() {
        _selectedFilterData = result;
        typeNameGradeSub = _selectedFilterData!['typeNameGradeSubject'];
        print(_selectedFilterData);
        detailType = _selectedFilterData!['detailType'];
        if (detailType == 'exam') {
          fetchAndPrintExamsByTypeNameGradeSubject(
            _selectedFilterData!['typeNameGradeSubject'],
          );
        } else if (detailType == 'dept') {
          questions = {};
          _selectedFilterData!['selectedItems'].forEach((element) {
            fetchAndPrintQuestionsByUnitAndTypeNameGradeSubject(
              element,
              _selectedFilterData!['typeNameGradeSubject'],
            );
          });
        } else if (detailType == 'topic') {
          questions = {};
          _selectedFilterData!['selectedItems'].forEach((element) {
            fetchAndPrintQuestionsByChapterNameAndTypeNameGradeSubject(
              element,
              _selectedFilterData!['typeNameGradeSubject'],
            );
          });
        } else if (detailType == 'subtopic') {
          questions = {};
          _selectedFilterData!['selectedItems'].forEach((element) {
            fetchAndPrintQuestionsBySubchapterNameAndTypeNameGradeSubject(
              element,
              _selectedFilterData!['typeNameGradeSubject'],
            );
          });
        }
      });

      // You can now use _selectedFilterData in your MainScreen
      // For example: update UI, fetch data based on filters, etc.
    } else {
      setState(() {
        _selectedFilterData =
            null; // Clear data if modal was dismissed without selection
      });
    }
  }

  Future<void> fetchAndPrintExamsByTypeNameGradeSubject(int tgsId) async {
    exams = await Exam.getExamsByTypeNameGradeSubject(tgsId);

    if (exams.isNotEmpty) {
      getSubject();
      setState(() {});
    }
  }

  Future getSubject() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    // open the database
    db = await openDatabase(path, version: 1);
    var dbase = await db;
    subs = await dbase.query('subject');
    if (subs.isNotEmpty) {
      for (var i = 0; i < subs.length; i++) {
        subs_map[subs[i]['id']] = subs[i]['name'];
      }
      setState(() {});
    }
  }

  Future getResult(id) async {
    var dbase = await db;
    subs = await db.query('subject');
    final List<Map<String, dynamic>> results = await dbase.query(
      'result',
      where: 'exam=$id',
    );
    if (results.isNotEmpty) {
      return results[0]['id'];
    } else {
      return 0;
    }
  }

  Future<void> fetchAndPrintQuestionsByUnitAndTypeNameGradeSubject(
    String unitName,
    int tngsId,
  ) async {
    try {
      // Get the database instance (assuming DatabaseHelper is initialized elsewhere)
      final dbHelper = DatabaseHelper();
      // Ensure the database is initialized and data is loaded if necessary
      await dbHelper
          .database; // This will trigger _initDatabase and _onCreate if the database doesn't exist

      // Call the static function to get questions by chapter unit
      List<Question> ques =
          await Question.getQuestionsByChapterUnitAndTypeNameGradeSubject(
            unitName,
            tngsId,
          );

      if (ques.isNotEmpty) {
        // Iterate through the list of questions and print their details
        questions[unitName] = ques;
        setState(() {});
      } else {}
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  Future<void> fetchAndPrintQuestionsByChapterNameAndTypeNameGradeSubject(
    String chapterName,
    int tngsId,
  ) async {
    try {
      // Get the database instance (assuming DatabaseHelper is initialized elsewhere)
      final dbHelper = DatabaseHelper();
      // Ensure the database is initialized and data is loaded if necessary
      // This call will trigger the _onCreate method if the database doesn't exist
      await dbHelper.database;

      // Call the static function with both arguments
      List<Question> ques =
          await Question.getQuestionsByChapterNameAndTypeNameGradeSubject(
            chapterName,
            tngsId,
          );

      if (ques.isNotEmpty) {
        // Iterate through the list of questions and print their details
        questions[chapterName] = ques;
        print(questions);
        setState(() {});
      } else {
        print(
          'No questions found for chapter name: "$chapterName" and TypeNameGradeSubject ID: $tngsId',
        );
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  Future<void> fetchAndPrintQuestionsBySubchapterNameAndTypeNameGradeSubject(
    String subchapterName,
    int tngsId,
  ) async {
    try {
      // Get the database instance (assuming DatabaseHelper is initialized elsewhere)
      final dbHelper = DatabaseHelper();
      // Ensure the database is initialized and data is loaded if necessary
      // This call will trigger the _onCreate method if the database doesn't exist
      await dbHelper.database;

      print(
        'Fetching questions for subchapter name: "$subchapterName" and TypeNameGradeSubject ID: $tngsId',
      );

      // Call the static function with both arguments
      List<Question> ques =
          await Question.getQuestionsBySubchapterNameAndTypeNameGradeSubject(
            subchapterName,
            tngsId,
          );

      if (ques.isNotEmpty) {
        print('Found ${ques.length} questions:');
        // Iterate through the list of questions and print their details
        questions[subchapterName] = ques;
        print(questions);
        setState(() {});
      } else {
        print(
          'No questions found for subchapter name: "$subchapterName" and TypeNameGradeSubject ID: $tngsId',
        );
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _showFilterModal,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(width: 1, color: Color(0xff28A164)),
                ),
                icon: const Icon(Icons.filter_list, color: Color(0xff28A164)),
                label: const Text(
                  "Filter Exam",
                  style: TextStyle(color: Color(0xff28A164)),
                ),
              ),
            ],
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(20),
        //   child: Container(
        //     height: 50,
        //     child: ListView(
        //       scrollDirection: Axis.horizontal,
        //       children:
        //           allTypeNames.map((typeName) {
        //             return Padding(
        //               padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
        //               child: GestureDetector(
        //                 onTap: () {
        //                   setState(() {
        //                     typeNameId = typeName.id;
        //                     // reCheckExams();
        //                   });
        //                 },
        //                 child: Card(
        //                   color:
        //                       typeNameId == typeName.id
        //                           ? Color(0xff0081B9)
        //                           : Color.fromARGB(255, 255, 255, 255),
        //                   shape: RoundedRectangleBorder(
        //                     borderRadius: BorderRadius.circular(20.0),
        //                   ),
        //                   elevation: 0,
        //                   child: Padding(
        //                     padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
        //                     child: Center(
        //                       child: Row(
        //                         mainAxisAlignment:
        //                             MainAxisAlignment.spaceBetween,
        //                         children: [
        //                           Padding(
        //                             padding: const EdgeInsets.only(right: 5),
        //                             child: Container(
        //                               decoration: BoxDecoration(
        //                                 color:
        //                                     typeNameId == typeName.id
        //                                         ? Color.fromARGB(
        //                                           255,
        //                                           255,
        //                                           255,
        //                                           255,
        //                                         )
        //                                         : Color(0xff0081B9),
        //                                 shape: BoxShape.circle,
        //                               ),
        //                               child: Padding(
        //                                 padding: const EdgeInsets.all(6.0),
        //                                 child: Icon(
        //                                   Icons.menu_book_rounded,
        //                                   color:
        //                                       typeNameId == typeName.id
        //                                           ? Color(0xff0081B9)
        //                                           : Color.fromARGB(
        //                                             255,
        //                                             255,
        //                                             255,
        //                                             255,
        //                                           ),
        //                                   size: 18,
        //                                 ),
        //                               ),
        //                             ),
        //                           ),
        //                           Text(
        //                             '${typeName.name}',
        //                             style: TextStyle(
        //                               color:
        //                                   typeNameId == typeName.id
        //                                       ? Color.fromARGB(
        //                                         255,
        //                                         255,
        //                                         255,
        //                                         255,
        //                                       )
        //                                       : Color(0xff0081B9),
        //                               fontWeight: FontWeight.bold,
        //                             ),
        //                           ),
        //                         ],
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             );
        //           }).toList(),
        //     ),
        //   ),
        // ),
        detailType == 'exam'
            ? Padding(
              padding: const EdgeInsets.all(20),
              child: Visibility(
                visible: isLoading,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: (1 / 1.1),
                  ),
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          child: SizedBox(
                            width: (deviceWidth - 50) / 2,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              color: st_cls[index % 4][0],
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.folder,
                                          color: st_cls[index % 4][1],
                                          size: 30,
                                        ),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Icon(
                                            FontAwesomeIcons.heart,
                                            color: Color.fromARGB(
                                              255,
                                              242,
                                              130,
                                              122,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${subs_map[exams[index].subject]}',
                                      style: TextStyle(
                                        color: st_cls[index % 4][2],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                      child: Text(
                                        '${exams[index].name}',
                                        style: TextStyle(
                                          color: st_cls[index % 4][1],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    FutureBuilder<dynamic>(
                                      future: getResult(
                                        exams[index].id,
                                      ), // a Future<String> or null
                                      builder: (
                                        BuildContext context,
                                        AsyncSnapshot<dynamic> snapshot,
                                      ) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: Text(
                                              'Please wait its loading...',
                                            ),
                                          );
                                        } else {
                                          if (snapshot.hasError) {
                                            return Text('error');
                                          } else {
                                            return snapshot.data == 0
                                                ? ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/take',
                                                      arguments: {
                                                        "exam_id":
                                                            exams[index].id,
                                                        'title':
                                                            exams[index].name,
                                                        'time':
                                                            exams[index].time,
                                                      },
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    side:
                                                        WidgetStateProperty.all(
                                                          BorderSide(
                                                            color:
                                                                st_cls[index %
                                                                    4][1],
                                                            width: 1.0,
                                                            style:
                                                                BorderStyle
                                                                    .solid,
                                                          ),
                                                        ),
                                                    foregroundColor:
                                                        WidgetStateProperty.all<
                                                          Color
                                                        >(
                                                          Color.fromARGB(
                                                            255,
                                                            90,
                                                            90,
                                                            90,
                                                          ),
                                                        ),
                                                    backgroundColor:
                                                        MaterialStateProperty.all<
                                                          Color
                                                        >(st_cls[index % 4][0]),
                                                  ),
                                                  child: Text("Take Exam"),
                                                )
                                                : ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/result',
                                                      arguments: {
                                                        "result_id":
                                                            snapshot.data,
                                                        'title':
                                                            exams[index].name,
                                                      },
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    side:
                                                        MaterialStateProperty.all(
                                                          BorderSide(
                                                            color:
                                                                st_cls[index %
                                                                    4][1],
                                                            width: 1.0,
                                                            style:
                                                                BorderStyle
                                                                    .solid,
                                                          ),
                                                        ),
                                                    foregroundColor:
                                                        MaterialStateProperty.all<
                                                          Color
                                                        >(
                                                          Color.fromARGB(
                                                            255,
                                                            90,
                                                            90,
                                                            90,
                                                          ),
                                                        ),
                                                    backgroundColor:
                                                        MaterialStateProperty.all<
                                                          Color
                                                        >(st_cls[index % 4][0]),
                                                  ),
                                                  child: Text("See Result"),
                                                ); // snapshot.data  :- get your object which is pass from your downloadData() function
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
            : detailType == 'dept' ||
                detailType == 'topic' ||
                detailType == 'subtopic'
            ? Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: questions.length,
                shrinkWrap: true,
                physics: ScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: st_cls[index % 4][0],
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.folder,
                                color: st_cls[index % 4][1],
                                size: 30,
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${questions.keys.elementAt(index)}",
                                    style: TextStyle(
                                      color: st_cls[index % 4][2],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${questions[questions.keys.elementAt(index)].length} Questions",
                                    style: TextStyle(
                                      color: st_cls[index % 4][1],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  IconButton(
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
                                                      '/take-chapt-study',
                                                      arguments: {
                                                        'type': detailType,
                                                        'value': questions.keys
                                                            .elementAt(
                                                              index,
                                                            ), // Pass the Chapter Unit name here
                                                        'typenameGradeSubjectId':
                                                            typeNameGradeSub,
                                                        'title':
                                                            '${questions.keys.elementAt(index)} Questions',
                                                      },
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Study Mode',
                                                  ),
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
                                                      '/take-chapt',
                                                      arguments: {
                                                        'type': detailType,
                                                        'value': questions.keys
                                                            .elementAt(
                                                              index,
                                                            ), // Pass the Chapter Unit name here
                                                        'typenameGradeSubjectId':
                                                            typeNameGradeSub,
                                                        'title':
                                                            '${questions.keys.elementAt(index)} Questions',
                                                      },
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Exam Mode',
                                                  ),
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
                                    icon: Icon(
                                      Icons.arrow_circle_right_outlined,
                                      color: st_cls[index % 4][1],
                                      size: 30,
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
                },
              ),
            )
            : Text(''),
      ],
    );
  }
}
