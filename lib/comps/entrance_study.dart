import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/exam_model.dart';

class EntranceStudyScreen extends StatefulWidget {
  const EntranceStudyScreen({Key? key}) : super(key: key);

  @override
  State<EntranceStudyScreen> createState() => _EntranceStudyScreenState();
}

class _EntranceStudyScreenState extends State<EntranceStudyScreen> {
  late Database db;
  bool isLoading = true;
  List<SubjectModel> subjects = [];
  List<Map<String, dynamic>> subs = [];
  List<Map<String, dynamic>> maps = [];
  List<ExamModel> exams = [];
  List examOff = [];
  int? subId;
  List st_cls = [
    [Color(0xffE1E9F9), Color(0xff0081B9), Color.fromARGB(255, 0, 82, 117)],
    [Color(0xffFDF1D9), Color(0xffF0A714), Color.fromARGB(255, 178, 124, 14)],
    [Color(0xffFDE4E4), Color(0xffF35555), Color.fromARGB(255, 155, 27, 27)],
    [Color(0xffDDF0E6), Color(0xff28A164), Color.fromARGB(255, 24, 111, 68)],
  ];

  @override
  void initState() {
    super.initState();

    dbstat();
  }

  dbstat() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    // open the database
    db = await openDatabase(
      path,
      version: 1,
    );

    final List<Map<String, dynamic>> favs = await db.query('favoriteexam');

    subs = await db.query('subject');
    print(subs);
    if (subId == null) {
      maps = await db.query('exam',
          where: "name LIKE 'UEE%' OR name LIKE '%Entrance%' OR name LIKE '%G10%'");
    } else {
      maps = await db.query('exam', where: "subject=${subId}");
    }

    maps = List.from(maps.reversed);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    List.generate(
      subs.length,
      (i) {
        subs[i]['name'] == 'Amharic'
            ? null
            : subs[i]['name'] == 'General Business'
                ? null
                : subjects.add(
                    SubjectModel(
                      subs[i]['id'],
                      subs[i]['name'],
                    ),
                  );
      },
    );

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
    });

    if (favs.length > 0) {
      favs.forEach((element) {
        if (element['examoff'] != null) {
          examOff.add(element['examoff']);
        }
      });
    }

    print(exams);

    setState(() {
      isLoading = true;
    });
  }

  reCheckExams() async {
    setState(() {
      isLoading = false;
      exams.clear();
    });
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    // open the database
    db = await openDatabase(
      path,
      version: 1,
    );
    print(subId);

    if (subId == null) {
      maps = await db.query('exam');
    } else {
      maps = await db.query('exam', where: "subject=${subId} AND (name LIKE 'UEE%' OR name LIKE '%Entrance%' OR name LIKE '%G10%')");
    }
    print('kjhknk');
    print(maps);
    maps = List.from(maps.reversed);

    print(maps);
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
    });
    setState(() {
      isLoading = true;
    });
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

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Subject Filter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: subjects.map((sub) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        subId = sub.id;
                        reCheckExams();
                      });
                    },
                    child: Card(
                      color: subId == sub.id
                          ? Color(0xff0081B9)
                          : Color.fromARGB(255, 255, 255, 255),
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
                                      color: subId == sub.id
                                          ? Color.fromARGB(255, 255, 255, 255)
                                          : Color(0xff0081B9),
                                      shape: BoxShape.circle),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: subId == sub.id
                                          ? Color(0xff0081B9)
                                          : Color.fromARGB(255, 255, 255, 255),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${sub.name}',
                                style: TextStyle(
                                  color: subId == sub.id
                                      ? Color.fromARGB(255, 255, 255, 255)
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
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Visibility(
            visible: isLoading,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: (1/1.1),
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                        examOff.contains(exams[index].id)
                                            ? removeFavorite(
                                                exams[index].id, 'off')
                                            : addFavorite(
                                                exams[index].id, 'off');
                                      },
                                      child: Icon(
                                        examOff.contains(exams[index].id)
                                            ? FontAwesomeIcons.solidHeart
                                            : FontAwesomeIcons.heart,
                                        color:
                                            Color.fromARGB(255, 242, 130, 122),
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
                                                            exams[index].name,
                                                        'time':
                                                            exams[index].time,
                                                      });
                                                },
                                                child: const Text("Take Exam"),
                                                style: ButtonStyle(
                                                  side: MaterialStateProperty
                                                      .all(BorderSide(
                                                          color:
                                                              st_cls[index % 4]
                                                                  [1],
                                                          width: 1.0,
                                                          style: BorderStyle
                                                              .solid)),
                                                  foregroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          Color.fromARGB(
                                                              255, 90, 90, 90)),
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          st_cls[index % 4][0]),
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
                                                            exams[index].name,
                                                      });
                                                },
                                                child: Text("See Result"),
                                                style: ButtonStyle(
                                                  side: MaterialStateProperty
                                                      .all(BorderSide(
                                                          color:
                                                              st_cls[index % 4]
                                                                  [1],
                                                          width: 1.0,
                                                          style: BorderStyle
                                                              .solid)),
                                                  foregroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          Color.fromARGB(
                                                              255, 90, 90, 90)),
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          st_cls[index % 4][0]),
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
        ),
      ],
    );
  }
}
