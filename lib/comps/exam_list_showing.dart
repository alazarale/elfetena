import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';

import '../models/exam_model.dart';
import '../models/store_exam_model.dart';

class ExamListShowScreen extends StatefulWidget {
  const ExamListShowScreen({Key? key}) : super(key: key);

  @override
  State<ExamListShowScreen> createState() => _ExamListShowScreenState();
}

class _ExamListShowScreenState extends State<ExamListShowScreen> {
  String? _examWhere;
  List<SubjectModel> subjects = [];
  List<ExamModel> exams = [];
  List<StoreExamModel>? store_exam;
  late Database db;
  bool isLoading = true;
  List<Map<String, dynamic>> maps = [];
  List<Map<String, dynamic>> subs = [];
  List code = [];
  List examOff = [];
  List st_cls = [
    [Color(0xffE1E9F9), Color(0xff0081B9), Color.fromARGB(255, 0, 82, 117)],
    [Color(0xffFDF1D9), Color(0xffF0A714), Color.fromARGB(255, 178, 124, 14)],
    [Color(0xffFDE4E4), Color(0xffF35555), Color.fromARGB(255, 155, 27, 27)],
    [Color(0xffDDF0E6), Color(0xff28A164), Color.fromARGB(255, 24, 111, 68)],
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _examWhere = arguments['where'];
    dbstat();
  }

  dbstat() async {
    setState(() {
      isLoading = false;
      subjects.clear();
      exams.clear();
      code.clear();
    });

    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    // open the database
    db = await openDatabase(
      path,
      version: 1,
    );

    final List<Map<String, dynamic>> favs = await db.query('favoriteexam');

    if (favs.length > 0) {
      favs.forEach((element) {
        if (element['examoff'] != null) {
          examOff.add(element['examoff']);
        }
      });
    }

    if (_examWhere == '12') {
      maps = await db.query('exam', where: "grade='12'");
    } else if (_examWhere == '10') {
      maps = await db.query('exam', where: "grade='10'");
    }else if (_examWhere == '8') {
      maps = await db.query('exam', where: "grade='8'");
    } else if (_examWhere == 'all') {
      maps = await db.query('exam');
    } else if (_examWhere == 'fav') {
      final List<Map<String, dynamic>> mmps = await db.query('exam');
      maps = [];
      if (favs.length > 0) {
        setState(() {
          mmps.forEach((element) {
            if (examOff.contains(element['id'])) {
              maps.add(element);
            }
          });
        });
      }
    } else {
      maps = [];
    }

    maps = List.from(maps.reversed);
    subs = await db.query('subject');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    List.generate(subs.length, (i) {
      subjects.add(SubjectModel(subs[i]['id'], subs[i]['name']));
    });

    List.generate(maps.length, (i) {
      String sub = '';
      subjects.forEach((element) {
        element.id == maps[i]['subject'] ? sub = element.name : null;
      });
      exams.add(
        ExamModel(
          maps[i]['id'],
          maps[i]['name'],
          sub,
          maps[i]['code'],
          maps[i]['time'],
        ),
      );
      code.add(maps[i]['code']);
    });
    setState(() {
      isLoading = true;
    });
  }

  Future getResult(id) async {
    var dbase = await db;
    final List<Map<String, dynamic>> results =
        await dbase.query('result', where: 'exam=${id}');
    if (results.length > 0) {
      return results[0]['id'];
    } else {
      return 0;
    }
  }

  addFavorite(id, stat) async {
    if (stat == 'off') {
      await db.insert(
        'favoriteexam',
        {'examoff': id},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      setState(() {
        examOff.add(id);
      });
    }
  }

  removeFavorite(id, stat) async {
    if (stat == 'off') {
      await db.delete(
        'favoriteexam',
        where: "examoff=${id}",
      );
      setState(() {
        examOff.remove(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                Icons.arrow_back_sharp,
                size: 20,
                color: Color(0xff0081B9),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xffF2F5F8),
        title: const Center(
            child: Text(
          "El-Test",
          style: TextStyle(
            color: const Color(0xff21205A),
            fontWeight: FontWeight.bold,
          ),
        )),
      ),
      backgroundColor: const Color(0xffF2F5F8),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Container(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: GestureDetector(
                          onTap: (() {
                            setState(() {
                              _examWhere = 'all';
                              dbstat();
                            });
                          }),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      Icons.laptop_windows,
                                      color: _examWhere == 'all'
                                          ? Colors.blue
                                          : Color.fromARGB(255, 126, 126, 126),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: Text(
                                        'ALL',
                                        style: TextStyle(
                                            color: _examWhere == 'all'
                                                ? Colors.blue
                                                : Color.fromARGB(
                                                    255, 126, 126, 126),
                                            fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: GestureDetector(
                          onTap: (() {
                            setState(() {
                              _examWhere = 'fav';
                              dbstat();
                            });
                          }),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.solidHeart,
                                      color: _examWhere == 'fav'
                                          ? Colors.blue
                                          : Color.fromARGB(255, 126, 126, 126),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: Text(
                                        'Favorite',
                                        style: TextStyle(
                                            color: _examWhere == 'fav'
                                                ? Colors.blue
                                                : Color.fromARGB(
                                                    255, 126, 126, 126)),
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
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: GestureDetector(
                          onTap: (() {
                            setState(() {
                              _examWhere = '12';
                              dbstat();
                            });
                          }),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.graduationCap,
                                      color: _examWhere == '12'
                                          ? Colors.blue
                                          : Color.fromARGB(255, 126, 126, 126),
                                    ),
                                    Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 0, 0, 0),
                                        child: Text(
                                          'Grade 12',
                                          style: TextStyle(
                                            color: _examWhere == '12'
                                                ? Colors.blue
                                                : Color.fromARGB(
                                                    255, 126, 126, 126),
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: GestureDetector(
                          onTap: (() {
                            setState(() {
                              _examWhere = '10';
                              dbstat();
                            });
                          }),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.graduationCap,
                                      color: _examWhere == '10'
                                          ? Colors.blue
                                          : Color.fromARGB(255, 126, 126, 126),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: Text(
                                        'Grade 10',
                                        style: TextStyle(
                                            color: _examWhere == '10'
                                                ? Colors.blue
                                                : Color.fromARGB(
                                                    255, 126, 126, 126),
                                            fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: GestureDetector(
                          onTap: (() {
                            setState(() {
                              _examWhere = '8';
                              dbstat();
                            });
                          }),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.graduationCap,
                                      color: _examWhere == '8'
                                          ? Colors.blue
                                          : Color.fromARGB(255, 126, 126, 126),
                                    ),
                                    Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 0, 0, 0),
                                        child: Text(
                                          'Grade 8',
                                          style: TextStyle(
                                            color: _examWhere == '8'
                                                ? Colors.blue
                                                : Color.fromARGB(
                                                    255, 126, 126, 126),
                                          ),
                                        )),
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
              const SizedBox(
                height: 20,
              ),
              Visibility(
                visible: isLoading,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
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
                                          onTap: () {
                                            _examWhere == 'fav'
                                                ? null
                                                : examOff.contains(
                                                        exams[index].id)
                                                    ? removeFavorite(
                                                        exams[index].id, 'off')
                                                    : addFavorite(
                                                        exams[index].id, 'off');
                                          },
                                          child: Icon(
                                            examOff.contains(exams[index].id)
                                                ? FontAwesomeIcons.solidHeart
                                                : FontAwesomeIcons.heart,
                                            color: Color.fromARGB(
                                                255, 242, 130, 122),
                                          ),
                                        )
                                      ],
                                    ),
                                    Text(
                                      '${exams[index].subject}',
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
                                      future: getResult(exams[index]
                                          .id), // a Future<String> or null
                                      builder: (BuildContext context,
                                          AsyncSnapshot<dynamic> snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child: const Text(
                                                  'Please wait its loading...'));
                                        } else {
                                          if (snapshot.hasError)
                                            return const Text('error');
                                          else
                                            return snapshot.data == 0
                                                ? ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                          context, '/take',
                                                          arguments: {
                                                            "exam_id":
                                                                exams[index].id,
                                                            'title':
                                                                exams[index]
                                                                    .name,
                                                            'time': exams[index]
                                                                .time,
                                                          });
                                                    },
                                                    child:
                                                        const Text("Take Exam"),
                                                    style: ButtonStyle(
                                                      side: MaterialStateProperty
                                                          .all(BorderSide(
                                                              color: st_cls[
                                                                  index % 4][1],
                                                              width: 1.0,
                                                              style: BorderStyle
                                                                  .solid)),
                                                      foregroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(Color
                                                                  .fromARGB(
                                                                      255,
                                                                      90,
                                                                      90,
                                                                      90)),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<
                                                                  Color>(st_cls[
                                                                      index % 4]
                                                                  [0]),
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                          context, '/result',
                                                          arguments: {
                                                            "result_id":
                                                                snapshot.data,
                                                            'title':
                                                                exams[index]
                                                                    .name,
                                                          });
                                                    },
                                                    child: Text("See Result"),
                                                    style: ButtonStyle(
                                                      side: MaterialStateProperty
                                                          .all(BorderSide(
                                                              color: st_cls[
                                                                  index % 4][1],
                                                              width: 1.0,
                                                              style: BorderStyle
                                                                  .solid)),
                                                      foregroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(Color
                                                                  .fromARGB(
                                                                      255,
                                                                      90,
                                                                      90,
                                                                      90)),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<
                                                                  Color>(st_cls[
                                                                      index % 4]
                                                                  [0]),
                                                    ),
                                                  ); // snapshot.data  :- get your object which is pass from your downloadData() function
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
                replacement: Center(
                    child: CircularProgressIndicator(
                  color: Color(0xff0081B9),
                )),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
