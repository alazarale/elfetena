import 'package:eltest_exit/comps/service/database_manipulation.dart';
import 'package:eltest_exit/comps/service/download.dart';
import 'package:eltest_exit/comps/service/remote_services.dart';
import 'package:eltest_exit/models/exam_model.dart';
import 'package:eltest_exit/models/store_exam_model.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:provider/provider.dart';
import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';

import 'custom_dialog.dart';
import 'provider/auth.dart';
import 'provider/strored_ref.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SubjectModel> subjects = [];
  List<ExamModel> exams = [];
  List<StoreExamModel>? store_exam;
  late Database db;
  TextEditingController searchControler = new TextEditingController();
  bool isLoading = true;
  List code = [];
  List examOn = [];
  List examOff = [];
  int am = 0;
  String? _payRefId = '0';
  String? _payRef;
  String? isSubsc;
  String? _token;

  List st_cls = [
    [Color(0xffE1E9F9), Color(0xff0081B9), Color.fromARGB(255, 0, 82, 117)],
    [Color(0xffFDF1D9), Color(0xffF0A714), Color.fromARGB(255, 178, 124, 14)],
    [Color(0xffFDE4E4), Color(0xffF35555), Color.fromARGB(255, 155, 27, 27)],
    [Color(0xffDDF0E6), Color(0xff28A164), Color.fromARGB(255, 24, 111, 68)],
  ];

  @override
  void initState() {
    super.initState();
    try {
      _payRef = Provider.of<RefData>(context, listen: false).paymentRef;
      if (_payRef != 'No') {
        setState(() {
          _payRefId = _payRef!.replaceAll('exampay', '').split('sid')[0];
        });
      }

      print(_payRefId);
    } catch (e) {
      print(e);
    }
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
    _token = Provider.of<Auth>(context, listen: false).token;
    print(_token);
    print('sfd');
    initializeDatabase();
    dbstat();
    getData();

    // This widget is the root of your application.
  }

  Future<void> initializeDatabase() async {
    // Accessing the database getter will trigger initialization if needed
    print('Initializing database...');
    await DatabaseHelper().database;
    print('Database initialized successfully.');
  }

  localGet() {
    LocalDownloadExam(context).getQuestions();
    Navigator.pushNamed(context, '/');
  }

  dbstat() async {
    print('sdfsdfsdfsfsdfsdfsf');
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    // Check if the database exists
    var exists = await databaseExists(path);
    print(exists);
    if (exists) {
      print("Opening existing database");
    }

    // open the database
    db = await openDatabase(path, version: 1);
    List<Map<String, dynamic>> maps = await db.query('exam');
    maps = List.from(maps.reversed);
    final List<Map<String, dynamic>> subs = await db.query('subject');

    final List<Map<String, dynamic>> favs = await db.query('favoriteexam');

    if (favs.length > 0) {
      setState(() {
        favs.forEach((element) {
          if (element['examoff'] != null) {
            examOff.add(element['examoff']);
          } else if (element['examon'] != null) {
            examOn.add(element['examon']);
          }
        });
      });
    }

    print(examOff);
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
          maps[i]['code'].toString(),
          maps[i]['time'],
        ),
      );
      code.add(maps[i]['code']);
    });
    // print(code);
    // if (code.isNotEmpty) {
    //   print('dd');
    //   if (!code.contains('cd32') || !code.contains('cd11')) {
    //     print('sdf');
    //     localGet();
    //   }
    // }
    setState(() {});
  }

  getData() async {
    isLoading = false;
    store_exam = await ExamsFetch().getExams();

    if (store_exam != null) {
      print(code);
      setState(() {
        store_exam!.removeWhere((item) => code.contains(item.id));
      });

      am = store_exam!.length;

      setState(() {
        isLoading = true;
      });
    }
  }

  Future getResult(id) async {
    var dbase = await db;
    final List<Map<String, dynamic>> results = await dbase.query(
      'result',
      where: 'exam=${id}',
    );
    if (results.length > 0) {
      return results.last['id'];
    } else {
      return 0;
    }
  }

  addFavorite(id, stat) async {
    if (stat == 'off') {
      print('off');
      await db.insert('favoriteexam', {
        'examoff': id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      setState(() {
        examOff.add(id);
      });
    } else if (stat == 'on') {
      await db.insert('favoriteexam', {
        'examon': id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      setState(() {
        examOn.add(id);
      });
    }
  }

  removeFavorite(id, stat) async {
    if (stat == 'off') {
      print('off');
      await db.delete('favoriteexam', where: "examoff=${id}");
      setState(() {
        examOff.remove(id);
      });
    } else if (stat == 'on') {
      await db.delete('favoriteexam', where: "examon=${id}");
      setState(() {
        examOn.remove(id);
      });
    }
  }

  downloadIfPayed(ex_id, paym_ref) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // The loading indicator
                CircularProgressIndicator(),
                SizedBox(height: 15),
                // Some text
                Text('Loading...'),
              ],
            ),
          ),
        );
      },
    );

    DownloadExam(ex_id, paym_ref, context).getQuestions().then((value) {
      Navigator.of(context).pop();
      Navigator.popAndPushNamed(context, "/");
    });
  }

  downloadIfSubsc(ex_id) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // The loading indicator
                CircularProgressIndicator(),
                SizedBox(height: 15),
                // Some text
                Text('Loading...'),
              ],
            ),
          ),
        );
      },
    );
    SubscDownloadExam(ex_id, _token!, context).getQuestions().then((value) {
      print(value);
      if (value == null) {
      } else {
        Navigator.of(context).pop();
        Navigator.popAndPushNamed(context, "/");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: TextField(
                    onTap: () {
                      Navigator.pushNamed(context, '/paid', arguments: {});
                    },
                    controller: searchControler,
                    decoration: const InputDecoration(
                      fillColor: Color.fromARGB(255, 255, 255, 255),
                      filled: true,
                      hintText: "Search",
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        //Outline border type for TextFeild
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/paid', arguments: {});
                      },
                      child: const Card(
                        color: Color(0xff0081B9),
                        child: Padding(
                          padding: EdgeInsets.all(13),
                          child: Center(
                            child: Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CarouselSlider.builder(
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              aspectRatio: 2.0,
              initialPage: 2,
            ),
            itemCount: exams.length < 8 ? exams.length : 8,
            itemBuilder:
                (
                  BuildContext context,
                  int itemIndex,
                  int pageViewIndex,
                ) => Container(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: st_cls[itemIndex % 4][1],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  "Recently Added",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                              child: Icon(
                                Icons.folder,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Text(
                                '${exams[itemIndex].name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Text(
                                '${exams[itemIndex].subject}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FutureBuilder<dynamic>(
                              future: getResult(
                                exams[itemIndex].id,
                              ), // a Future<String> or null
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<dynamic> snapshot,
                              ) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Text('Please wait its loading...'),
                                  );
                                } else {
                                  if (snapshot.hasError) {
                                    return const Text('error');
                                  } else {
                                    return snapshot.data == 0
                                        ? ElevatedButton(
                                          onPressed: () {
                                            showDialog<String>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Select Mode',
                                                  ),
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
                                                            '/take-study',
                                                            arguments: {
                                                              "exam_id":
                                                                  exams[itemIndex]
                                                                      .id,
                                                              'title':
                                                                  exams[itemIndex]
                                                                      .name,
                                                              'time':
                                                                  exams[itemIndex]
                                                                      .time,
                                                            },
                                                          ).then((_) {
                                                            setState(() {
                                                              dbstat();
                                                              getData();
                                                            });
                                                          });
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
                                                            '/take',
                                                            arguments: {
                                                              "exam_id":
                                                                  exams[itemIndex]
                                                                      .id,
                                                              'title':
                                                                  exams[itemIndex]
                                                                      .name,
                                                              'time':
                                                                  exams[itemIndex]
                                                                      .time,
                                                            },
                                                          ).then((_) {
                                                            setState(() {
                                                              dbstat();
                                                              getData();
                                                            });
                                                          });
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
                                          style: ButtonStyle(
                                            side: MaterialStateProperty.all(
                                              BorderSide(
                                                color: st_cls[itemIndex % 4][1],
                                                width: 1.0,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                            foregroundColor:
                                                MaterialStateProperty.all<
                                                  Color
                                                >(
                                                  const Color.fromARGB(
                                                    255,
                                                    90,
                                                    90,
                                                    90,
                                                  ),
                                                ),
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                  Color
                                                >(st_cls[itemIndex % 4][0]),
                                          ),
                                          child: const Text("Take Exam"),
                                        )
                                        : ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/result',
                                              arguments: {
                                                "result_id": snapshot.data,
                                                'title': exams[itemIndex].name,
                                              },
                                            ).then((_) {
                                              setState(() {
                                                print('sdf');
                                                dbstat();
                                                getData();
                                              });
                                            });
                                          },
                                          style: ButtonStyle(
                                            side: MaterialStateProperty.all(
                                              BorderSide(
                                                color: st_cls[itemIndex % 4][1],
                                                width: 1.0,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                            foregroundColor:
                                                MaterialStateProperty.all<
                                                  Color
                                                >(
                                                  const Color.fromARGB(
                                                    255,
                                                    90,
                                                    90,
                                                    90,
                                                  ),
                                                ),
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                  Color
                                                >(st_cls[itemIndex % 4][0]),
                                          ),
                                          child: const Text("See Result"),
                                        );
                                  } // snapshot.data  :- get your object which is pass from your downloadData() function
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
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/fav', arguments: {});
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    color: const Color(0xff0081B9),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 15, 10),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.library_books_outlined,
                                    color: Color(0xff0081B9),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              'Favourite Questions',
                              style: TextStyle(
                                color: Colors.white,
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
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recently Added",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xff21205A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/list',
                            arguments: {'where': 'all'},
                          );
                        },
                        child: const Text(
                          "View all",
                          style: TextStyle(
                            color: Color.fromARGB(255, 120, 120, 120),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                                            examOff.contains(exams[index].id)
                                                ? removeFavorite(
                                                  exams[index].id,
                                                  'off',
                                                )
                                                : addFavorite(
                                                  exams[index].id,
                                                  'off',
                                                );
                                          },
                                          child: Icon(
                                            examOff.contains(exams[index].id)
                                                ? FontAwesomeIcons.solidHeart
                                                : FontAwesomeIcons.heart,
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
                                            child: const Text(
                                              'Please wait its loading...',
                                            ),
                                          );
                                        } else {
                                          if (snapshot.hasError)
                                            return const Text('error');
                                          else
                                            return snapshot.data == 0
                                                ? ElevatedButton(
                                                  onPressed: () {
                                                    showDialog<String>(
                                                      context: context,
                                                      builder: (
                                                        BuildContext context,
                                                      ) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            'Select Mode',
                                                          ),
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
                                                                    '/take-study',
                                                                    arguments: {
                                                                      "exam_id":
                                                                          exams[index]
                                                                              .id,
                                                                      'title':
                                                                          exams[index]
                                                                              .name,
                                                                      'time':
                                                                          exams[index]
                                                                              .time,
                                                                    },
                                                                  ).then((_) {
                                                                    setState(() {
                                                                      dbstat();
                                                                      getData();
                                                                    });
                                                                  });
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
                                                                    '/take',
                                                                    arguments: {
                                                                      "exam_id":
                                                                          exams[index]
                                                                              .id,
                                                                      'title':
                                                                          exams[index]
                                                                              .name,
                                                                      'time':
                                                                          exams[index]
                                                                              .time,
                                                                    },
                                                                  ).then((_) {
                                                                    setState(() {
                                                                      dbstat();
                                                                      getData();
                                                                    });
                                                                  });
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
                                                  child: const Text(
                                                    "Take Exam",
                                                  ),
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
                                                        "exam_id":
                                                            exams[index].id,
                                                        'time':
                                                            exams[index].time,
                                                      },
                                                    );
                                                  },
                                                  child: Text("See Result"),
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
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text(
                  //       "Store",
                  //       style: const TextStyle(
                  //         fontWeight: FontWeight.bold,
                  //         fontSize: 18,
                  //         color: Color(0xff21205A),
                  //       ),
                  //     ),
                  //     TextButton(
                  //       onPressed: () {
                  //         Navigator.pushNamed(context, '/paid', arguments: {});
                  //       },
                  //       child: Text(
                  //         "View all",
                  //         style: TextStyle(
                  //           color: Color.fromARGB(255, 120, 120, 120),
                  //           fontSize: 16,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 20),
                  // Visibility(
                  //   visible: isLoading,
                  //   replacement: const Center(
                  //     child: const CircularProgressIndicator(),
                  //   ),
                  //   child: GridView.builder(
                  //     gridDelegate:
                  //         const SliverGridDelegateWithFixedCrossAxisCount(
                  //           crossAxisCount: 2,
                  //           childAspectRatio: (1 / 1.1),
                  //         ),
                  //     shrinkWrap: true,
                  //     physics: const ScrollPhysics(),
                  //     itemCount: am > 4 ? 4 : store_exam?.length,
                  //     itemBuilder: (context, index) {
                  //       return Visibility(
                  //         visible: !code.contains('${store_exam?[index].id}'),
                  //         child: Padding(
                  //           padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                  //           child: GestureDetector(
                  //             onTap: () {},
                  //             child: Container(
                  //               child: SizedBox(
                  //                 width: (deviceWidth - 50) / 2,
                  //                 child: Card(
                  //                   color: st_cls[index % 4][0],
                  //                   shape: RoundedRectangleBorder(
                  //                     borderRadius: BorderRadius.circular(20.0),
                  //                   ),
                  //                   child: Container(
                  //                     foregroundDecoration:
                  //                         store_exam?[index].isNew == 'no'
                  //                             ? null
                  //                             : RotatedCornerDecoration.withColor(
                  //                               color: Color.fromARGB(
                  //                                 255,
                  //                                 237,
                  //                                 36,
                  //                                 14,
                  //                               ),
                  //                               badgeSize: Size(48, 48),
                  //                               textSpan: const TextSpan(
                  //                                 text: 'NEW',
                  //                                 style: TextStyle(
                  //                                   fontSize: 13,
                  //                                   letterSpacing: 1,
                  //                                   fontWeight: FontWeight.bold,
                  //                                   shadows: [
                  //                                     BoxShadow(
                  //                                       color: Color.fromARGB(
                  //                                         255,
                  //                                         255,
                  //                                         255,
                  //                                         255,
                  //                                       ),
                  //                                       blurRadius: 4,
                  //                                     ),
                  //                                   ],
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                     child: Padding(
                  //                       padding: const EdgeInsets.all(10),
                  //                       child: Column(
                  //                         mainAxisAlignment:
                  //                             MainAxisAlignment.spaceEvenly,
                  //                         crossAxisAlignment:
                  //                             CrossAxisAlignment.start,
                  //                         children: [
                  //                           Row(
                  //                             mainAxisAlignment:
                  //                                 MainAxisAlignment.start,
                  //                             children: [
                  //                               Icon(
                  //                                 Icons.folder,
                  //                                 color: st_cls[index % 4][1],
                  //                                 size: 30,
                  //                               ),
                  //                             ],
                  //                           ),
                  //                           Text(
                  //                             '${store_exam?[index].sub}',
                  //                             style: TextStyle(
                  //                               color: st_cls[index % 4][2],
                  //                               fontSize: 14,
                  //                               fontWeight: FontWeight.bold,
                  //                             ),
                  //                           ),
                  //                           Padding(
                  //                             padding: EdgeInsets.fromLTRB(
                  //                               0,
                  //                               5,
                  //                               0,
                  //                               0,
                  //                             ),
                  //                             child: Text(
                  //                               '${store_exam?[index].name}',
                  //                               style: TextStyle(
                  //                                 color: st_cls[index % 4][1],
                  //                                 fontSize: 16,
                  //                                 fontWeight: FontWeight.bold,
                  //                               ),
                  //                             ),
                  //                           ),
                  //                           isSubsc == 'yes'
                  //                               ? Row(
                  //                                 mainAxisAlignment:
                  //                                     MainAxisAlignment.center,
                  //                                 children: [
                  //                                   ElevatedButton(
                  //                                     onPressed: () {
                  //                                       downloadIfSubsc(
                  //                                         store_exam![index].id,
                  //                                       );
                  //                                     },
                  //                                     child: const Text(
                  //                                       "Download",
                  //                                     ),
                  //                                     style: ButtonStyle(
                  //                                       side: MaterialStateProperty.all(
                  //                                         BorderSide(
                  //                                           color:
                  //                                               st_cls[index %
                  //                                                   4][1],
                  //                                           width: 1.0,
                  //                                           style:
                  //                                               BorderStyle
                  //                                                   .solid,
                  //                                         ),
                  //                                       ),
                  //                                       foregroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             const Color.fromARGB(
                  //                                               255,
                  //                                               90,
                  //                                               90,
                  //                                               90,
                  //                                             ),
                  //                                           ),
                  //                                       backgroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             st_cls[index %
                  //                                                 4][0],
                  //                                           ),
                  //                                     ),
                  //                                   ),
                  //                                 ],
                  //                               )
                  //                               : store_exam![index].id ==
                  //                                   int.parse(_payRefId!)
                  //                               ? Row(
                  //                                 mainAxisAlignment:
                  //                                     MainAxisAlignment.center,
                  //                                 children: [
                  //                                   ElevatedButton(
                  //                                     onPressed: () {
                  //                                       downloadIfPayed(
                  //                                         store_exam![index].id,
                  //                                         _payRef,
                  //                                       );
                  //                                     },
                  //                                     child: const Text(
                  //                                       "Download",
                  //                                     ),
                  //                                     style: ButtonStyle(
                  //                                       side: MaterialStateProperty.all(
                  //                                         BorderSide(
                  //                                           color:
                  //                                               st_cls[index %
                  //                                                   4][1],
                  //                                           width: 1.0,
                  //                                           style:
                  //                                               BorderStyle
                  //                                                   .solid,
                  //                                         ),
                  //                                       ),
                  //                                       foregroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             const Color.fromARGB(
                  //                                               255,
                  //                                               90,
                  //                                               90,
                  //                                               90,
                  //                                             ),
                  //                                           ),
                  //                                       backgroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             st_cls[index %
                  //                                                 4][0],
                  //                                           ),
                  //                                     ),
                  //                                   ),
                  //                                 ],
                  //                               )
                  //                               : Row(
                  //                                 mainAxisAlignment:
                  //                                     MainAxisAlignment
                  //                                         .spaceBetween,
                  //                                 children: [
                  //                                   Text(
                  //                                     '${store_exam![index].price} ETB',
                  //                                     style: TextStyle(
                  //                                       color:
                  //                                           st_cls[index %
                  //                                               4][2],
                  //                                       fontWeight:
                  //                                           FontWeight.bold,
                  //                                       fontSize: 13,
                  //                                     ),
                  //                                   ),
                  //                                   ElevatedButton(
                  //                                     onPressed: () {
                  //                                       showDialog(
                  //                                         context: context,
                  //                                         builder: (
                  //                                           BuildContext
                  //                                           context,
                  //                                         ) {
                  //                                           return CustomDialogBox(
                  //                                             exam_id:
                  //                                                 store_exam![index]
                  //                                                     .id,
                  //                                             price:
                  //                                                 store_exam![index]
                  //                                                     .price,
                  //                                           );
                  //                                         },
                  //                                       );
                  //                                     },
                  //                                     child: const Text("Buy"),
                  //                                     style: ButtonStyle(
                  //                                       side: MaterialStateProperty.all(
                  //                                         BorderSide(
                  //                                           color:
                  //                                               st_cls[index %
                  //                                                   4][1],
                  //                                           width: 1.0,
                  //                                           style:
                  //                                               BorderStyle
                  //                                                   .solid,
                  //                                         ),
                  //                                       ),
                  //                                       foregroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             const Color.fromARGB(
                  //                                               255,
                  //                                               90,
                  //                                               90,
                  //                                               90,
                  //                                             ),
                  //                                           ),
                  //                                       backgroundColor:
                  //                                           MaterialStateProperty.all<
                  //                                             Color
                  //                                           >(
                  //                                             st_cls[index %
                  //                                                 4][0],
                  //                                           ),
                  //                                     ),
                  //                                   ),
                  //                                 ],
                  //                               ),
                  //                         ],
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
