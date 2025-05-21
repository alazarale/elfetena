import 'package:eltest_exit/comps/entrance_study.dart';
import 'package:eltest_exit/comps/study/college_study_screen.dart';
import 'package:eltest_exit/comps/study/national_study_screen.dart';
import 'package:eltest_exit/comps/study/school_study_screen.dart';
import 'package:flutter/material.dart';

import 'model_study.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Map<String, Widget> loc = {
    'national': NationalStudyScreen(),
    'school': SchoolStudyScreen(),
    'college': CollegeStudyScreen(),
  };

  String choosen = 'national';

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          choosen = 'national';
                        });
                      },
                      child: Card(
                        color: choosen == 'national'
                            ? Color(0xff0081B9)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: choosen == 'national'
                                            ? Colors.white
                                            : Color(0xff0081B9),
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.my_library_books_outlined,
                                        color: choosen == 'national'
                                            ? Color(0xff0081B9)
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'National',
                                  style: TextStyle(
                                      color: choosen == 'national'
                                          ? Colors.white
                                          : Color(0xff0081B9),
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: GestureDetector(
                      onTap: () {
                        
                      },
                      child: Card(
                        color: choosen == 'school'
                            ? Color(0xff0081B9)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: choosen == 'school'
                                            ? Colors.white
                                            : Color(0xff0081B9),
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.my_library_books_outlined,
                                        color: choosen == 'school'
                                            ? Color(0xff0081B9)
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'School',
                                  style: TextStyle(
                                    color: choosen == 'school'
                                        ? Colors.white
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: GestureDetector(
                      onTap: () {
                       
                        
                      },
                      child: Card(
                        color: choosen == 'college'
                            ? Color(0xff0081B9)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: choosen == 'college'
                                            ? Colors.white
                                            : Color(0xff0081B9),
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.my_library_books_outlined,
                                        color: choosen == 'college'
                                            ? Color(0xff0081B9)
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'College',
                                  style: TextStyle(
                                    color: choosen == 'college'
                                        ? Colors.white
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
                  ),
                ],
              ),
            ),
          ),
          loc[choosen]!,
        ],
      ),
    );
  }
}
