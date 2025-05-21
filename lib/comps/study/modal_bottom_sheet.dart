import 'package:flutter/material.dart';
import '../service/database_manipulation.dart';

class ModalBottomSheet extends StatefulWidget {
  _ModalBottomSheetState createState() => _ModalBottomSheetState();
}

class _ModalBottomSheetState extends State<ModalBottomSheet>
    with SingleTickerProviderStateMixin {
  List<TypeName> allTypeNames = [];
  bool isLoading = true;
  int? typeNameId;
  int? tgs_id;
  List<Map<String, dynamic>> tgsWithSubjects = []; // This list seems unused
  List<String> distinctUnits = [];
  List<String> distinctUnitsSelected = [];
  List<String> distinctChapterNames = [];
  List<String> distinctChapterNamesSelected = [];
  List<String> distinctSubchapterNames = [];
  List<String> distinctSubchapterNamesSelected = [];
  String _detail = 'exam';

  @override
  void initState() {
    super.initState();
    gettingFirstList();
  }

  gettingFirstList() async {
    int myCreatorTypeId = 3;
    allTypeNames = await getTypeNamesByCreatorType(myCreatorTypeId);

    if (allTypeNames.isNotEmpty) {
      // Select the first typeName by default and load its related data
      if (allTypeNames.isNotEmpty) {
        typeNameId = allTypeNames.first.id;
        tgsWithSubjects = await getTypeNameGradeSubjectsWithSubjectByTypeName(
          typeNameId!,
        );
        if (tgsWithSubjects.isNotEmpty) {
          tgs_id = tgsWithSubjects.first['tgs_id'];
          distinctUnits =
              await Chapter.getDistinctChapterUnitsByTypeNameGradeSubject(
                tgs_id!,
              );
          distinctChapterNames =
              await Chapter.getDistinctChapterNamesByTypeNameGradeSubject(
                tgs_id!,
              );
          distinctSubchapterNames =
              await Subchapter.getDistinctSubchapterNamesByTypeNameGradeSubject(
                tgs_id!,
              );
        }
      }

      setState(() {
        isLoading = false;
      });
    } else {
      print('No TypeName objects found for CreatorType ID $myCreatorTypeId');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<TypeName>> getTypeNamesByCreatorType(int creatorTypeId) async {
    final typeNameModel = TypeName();
    List<TypeName> typeNames = await typeNameModel.query(
      where: 'creatortype = ?',
      whereArgs: [creatorTypeId],
    );
    return typeNames;
  }

  Future<List<Map<String, dynamic>>>
  getTypeNameGradeSubjectsWithSubjectByTypeName(int typeNameId) async {
    final dbHelper = DatabaseHelper();
    final joins = [
      Join(
        table: 'typenamegrade',
        on: 'typenamegradesubject.typenamegrade = typenamegrade.id',
      ),
      Join(table: 'typename', on: 'typenamegrade.typename = typename.id'),
      Join(table: 'subject', on: 'typenamegradesubject.subject = subject.id'),
    ];
    final selectColumns = [
      'typenamegradesubject.id AS tgs_id',
      'typenamegradesubject.typenamegrade AS tgs_typenamegrade',
      'typenamegradesubject.subject AS tgs_subject_id_fk',
      'subject.id AS subject_id',
      'subject.name AS subject_name',
    ];
    final whereClause = 'typename.id = ?';
    final whereArgs = [typeNameId];
    List<Map<String, dynamic>> results = await dbHelper.performJoinedQuery(
      selectColumns: selectColumns,
      fromTable: 'typenamegradesubject',
      joins: joins,
      where: whereClause,
      whereArgs: whereArgs,
      distinct: true,
    );
    print(results);
    return results;
  }

  // Function to build the list of checkboxes based on the current detail view
  Widget _buildDetailCheckboxes() {
    List<String> itemsToShow = [];
    List<String> selectedItems = [];
    Function(String)? onItemSelected;

    if (_detail == 'exam') {
      // Assuming 'exam' detail shows units
      itemsToShow = ['All'];
      selectedItems = ['All'];
    } else if (_detail == 'dept') {
      itemsToShow = distinctUnits;
      selectedItems = distinctUnitsSelected;
      onItemSelected = (item) {
        setState(() {
          if (distinctUnitsSelected.contains(item)) {
            distinctUnitsSelected.remove(item);
          } else {
            distinctUnitsSelected.add(item);
          }
        });
      };
    } else if (_detail == 'topic') {
      // Assuming 'topic' detail shows chapter names
      itemsToShow = distinctChapterNames;
      selectedItems = distinctChapterNamesSelected;
      onItemSelected = (item) {
        setState(() {
          if (distinctChapterNamesSelected.contains(item)) {
            distinctChapterNamesSelected.remove(item);
          } else {
            distinctChapterNamesSelected.add(item);
          }
        });
      };
    } else if (_detail == 'subtopic') {
      itemsToShow = distinctSubchapterNames;
      selectedItems = distinctSubchapterNamesSelected;
      onItemSelected = (item) {
        setState(() {
          if (distinctSubchapterNamesSelected.contains(item)) {
            distinctSubchapterNamesSelected.remove(item);
          } else {
            distinctSubchapterNamesSelected.add(item);
          }
        });
      };
    }

    if (itemsToShow.isEmpty) {
      return Center(child: Text('No items available for this selection.'));
    }

    // Return a scrollable ListView.builder with styled cards
    return ListView.builder(
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final item = itemsToShow[index];
        final isSelected = selectedItems.contains(item);

        return GestureDetector(
          onTap: onItemSelected != null ? () => onItemSelected!(item) : null,
          child: Card(
            color:
                isSelected
                    ? Color(0xff0081B9)
                    : Color.fromARGB(255, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 0,
            margin: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8,
            ), // Adjust margin as needed
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ), // Adjust padding
              child: Row(
                children: [
                  // Optional: Add a styled circle like the exam/department buttons
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Color.fromARGB(255, 255, 255, 255)
                              : Color(0xff0081B9),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.check, // You can change this icon
                        color:
                            isSelected
                                ? Color(0xff0081B9)
                                : Color.fromARGB(255, 255, 255, 255),
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 10), // Space between circle and text
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color:
                            isSelected
                                ? Color.fromARGB(255, 255, 255, 255)
                                : Colors
                                    .black, // Or Color(0xff0081B9) for text when not selected
                        fontWeight: FontWeight.bold, // Keep consistent
                      ),
                      // Removed overflow: TextOverflow.ellipsis to allow wrapping
                    ),
                  ),
                  // Keep the Checkbox visually if desired, or rely solely on the card's appearance
                  Checkbox(
                    value: isSelected,
                    onChanged:
                        onItemSelected != null
                            ? (value) => onItemSelected!(item)
                            : null,
                    activeColor:
                        isSelected
                            ? Colors.white
                            : Color(0xff0081B9), // Adjust colors
                    checkColor: isSelected ? Color(0xff0081B9) : Colors.white,
                    // visual density might help align it
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: deviceHeight * 0.8, // Use a percentage of device height
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Color(0xff0081B9),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    color: Color(0xff0081B9),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Content above the independently scrollable list
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Exam Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color.fromARGB(255, 78, 93, 102),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                  child:
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                allTypeNames.map((typeName) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      0,
                                      5,
                                      0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          isLoading =
                                              true; // Show loading indicator
                                        });
                                        typeNameId = typeName.id;
                                        tgsWithSubjects =
                                            await getTypeNameGradeSubjectsWithSubjectByTypeName(
                                              typeNameId!,
                                            );
                                        // Reset tgs_id and subsequent lists when typeName changes
                                        tgs_id = null;
                                        distinctUnits = [];
                                        distinctUnitsSelected = [];
                                        distinctChapterNames = [];
                                        distinctChapterNamesSelected = [];
                                        distinctSubchapterNames = [];
                                        distinctSubchapterNamesSelected = [];

                                        if (tgsWithSubjects.isNotEmpty) {
                                          // Select the first tgs by default for the new typeName
                                          tgs_id =
                                              tgsWithSubjects.first['tgs_id'];
                                          distinctUnits =
                                              await Chapter.getDistinctChapterUnitsByTypeNameGradeSubject(
                                                tgs_id!,
                                              );
                                          distinctChapterNames =
                                              await Chapter.getDistinctChapterNamesByTypeNameGradeSubject(
                                                tgs_id!,
                                              );
                                          distinctSubchapterNames =
                                              await Subchapter.getDistinctSubchapterNamesByTypeNameGradeSubject(
                                                tgs_id!,
                                              );
                                        }

                                        setState(() {
                                          isLoading =
                                              false; // Hide loading indicator
                                        });
                                      },
                                      child: Card(
                                        color:
                                            typeNameId == typeName.id
                                                ? Color(0xff0081B9)
                                                : Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20.0,
                                          ),
                                        ),
                                        elevation: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            5,
                                            15,
                                            5,
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 5,
                                                      ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          typeNameId ==
                                                                  typeName.id
                                                              ? Color.fromARGB(
                                                                255,
                                                                255,
                                                                255,
                                                                255,
                                                              )
                                                              : Color(
                                                                0xff0081B9,
                                                              ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6.0,
                                                          ),
                                                      child: Icon(
                                                        Icons.menu_book_rounded,
                                                        color:
                                                            typeNameId ==
                                                                    typeName.id
                                                                ? Color(
                                                                  0xff0081B9,
                                                                )
                                                                : Color.fromARGB(
                                                                  255,
                                                                  255,
                                                                  255,
                                                                  255,
                                                                ),
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${typeName.name}',
                                                  style: TextStyle(
                                                    color:
                                                        typeNameId ==
                                                                typeName.id
                                                            ? Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255,
                                                            )
                                                            : Color(0xff0081B9),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Department',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color.fromARGB(255, 78, 93, 102),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                  child:
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                tgsWithSubjects.map((tgs) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      0,
                                      5,
                                      0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          isLoading =
                                              true; // Show loading indicator
                                        });
                                        tgs_id = tgs['tgs_id'];
                                        distinctUnits =
                                            await Chapter.getDistinctChapterUnitsByTypeNameGradeSubject(
                                              tgs_id!,
                                            );
                                        distinctChapterNames =
                                            await Chapter.getDistinctChapterNamesByTypeNameGradeSubject(
                                              tgs_id!,
                                            );

                                        distinctSubchapterNames =
                                            await Subchapter.getDistinctSubchapterNamesByTypeNameGradeSubject(
                                              tgs_id!,
                                            );
                                        // Clear previous selections when department changes
                                        distinctUnitsSelected = [];
                                        distinctChapterNamesSelected = [];
                                        distinctSubchapterNamesSelected = [];
                                        print(distinctSubchapterNames);

                                        setState(() {
                                          isLoading =
                                              false; // Hide loading indicator
                                        });
                                      },
                                      child: Card(
                                        color:
                                            tgs_id == tgs['tgs_id']
                                                ? Color(0xff0081B9)
                                                : Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20.0,
                                          ),
                                        ),
                                        elevation: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            5,
                                            15,
                                            5,
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 5,
                                                      ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          tgs_id ==
                                                                  tgs['tgs_id']
                                                              ? Color.fromARGB(
                                                                255,
                                                                255,
                                                                255,
                                                                255,
                                                              )
                                                              : Color(
                                                                0xff0081B9,
                                                              ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6.0,
                                                          ),
                                                      child: Icon(
                                                        Icons.menu_book_rounded,
                                                        color:
                                                            tgs_id ==
                                                                    tgs['tgs_id']
                                                                ? Color(
                                                                  0xff0081B9,
                                                                )
                                                                : Color.fromARGB(
                                                                  255,
                                                                  255,
                                                                  255,
                                                                  255,
                                                                ),
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${tgs['subject_name']}',
                                                  style: TextStyle(
                                                    color:
                                                        tgs_id == tgs['tgs_id']
                                                            ? Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255,
                                                            )
                                                            : Color(0xff0081B9),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Details of Exam',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color.fromARGB(255, 78, 93, 102),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
            // The independently scrollable checkbox list area
            Expanded(
              // Expanded is crucial for the inner ListView to have a defined height
              child: Row(
                // Keep the Row for buttons and the scrollable list
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    // Buttons column
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detail = 'exam';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _detail == 'exam' ? Color(0xff0081B9) : null,
                          foregroundColor:
                              _detail == 'exam'
                                  ? Colors.white
                                  : Color(0xff0081B9),
                        ),
                        child: Text(
                          'By Exam',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detail = 'dept';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _detail == 'dept' ? Color(0xff0081B9) : null,
                          foregroundColor:
                              _detail == 'dept'
                                  ? Colors.white
                                  : Color(0xff0081B9),
                        ),
                        child: Text(
                          'By Dept',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detail = 'topic';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _detail == 'topic' ? Color(0xff0081B9) : null,
                          foregroundColor:
                              _detail == 'topic'
                                  ? Colors.white
                                  : Color(0xff0081B9),
                        ),
                        child: Text(
                          'By Topic',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detail = 'subtopic';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _detail == 'subtopic' ? Color(0xff0081B9) : null,
                          foregroundColor:
                              _detail == 'subtopic'
                                  ? Colors.white
                                  : Color(0xff0081B9),
                        ),
                        child: Text(
                          'Subtopic',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    // This Expanded gives the ListView a flexible width
                    child:
                        isLoading
                            ? Center(child: CircularProgressIndicator())
                            : _buildDetailCheckboxes(), // The scrollable ListView
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement save logic here
                    print('Selected Units: $distinctUnitsSelected');
                    print('Selected Chapters: $distinctChapterNamesSelected');
                    // Depending on _detail, you might save different selections
                    Navigator.pop(context, {
                      'detailType': _detail,
                      'selectedItems':
                          _detail == 'exam'
                              ? ['All']
                              : _detail == 'dept'
                              ? distinctUnitsSelected
                              : _detail == 'topic'
                              ? distinctChapterNamesSelected
                              : _detail == 'subtopic'
                              ? distinctSubchapterNamesSelected
                              : [],
                      'typeName': typeNameId,
                      'typeNameGradeSubject': tgs_id,

                      // Adjust based on what each detail type selects
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff0081B9),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
