import 'package:chapasdk/chapasdk.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import '../../models/store_exam_model.dart';
import '../custom_dialog.dart';
import '../provider/auth.dart';
import '../provider/strored_ref.dart';

import '../service/download.dart';
import '../service/remote_services.dart';

import 'package:path/path.dart' as Path;

import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<StoreExamModel>? store_exam;
  late Database db;
  bool isLoading = true;
  List code = [];
  TextEditingController searchControler = new TextEditingController();
  bool search = false;
  String? searchStr;
  String? _payRefId = '0';
  String? _payRef;
  String? isSubsc;
  String? _token;

  List st_cls = [
    [
      const Color(0xffE1E9F9),
      const Color(0xff0081B9),
      const Color.fromARGB(255, 0, 82, 117),
    ],
    [
      const Color(0xffFDF1D9),
      const Color(0xffF0A714),
      const Color.fromARGB(255, 178, 124, 14),
    ],
    [
      const Color(0xffFDE4E4),
      const Color(0xffF35555),
      const Color.fromARGB(255, 155, 27, 27),
    ],
    [
      const Color(0xffDDF0E6),
      const Color(0xff28A164),
      const Color.fromARGB(255, 24, 111, 68),
    ],
  ];

  @override
  void initState() {
    super.initState();
    try {
      _payRef = Provider.of<RefData>(context, listen: false).paymentRef;
      if (_payRef != 'No') {
        _payRefId = _payRef!.replaceAll('exampay', '').split('sid')[0];
      }

      print(_payRef);
    } catch (e) {
      print(e);
    }
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
    _token = Provider.of<Auth>(context, listen: false).token;
    dbstat();
    getData();

    // This widget is the root of your application.
  }

  dbstat() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    db = await openDatabase(path, version: 1);
    List<Map<String, dynamic>> maps = await db.query('exam');
    maps = List.from(maps.reversed);
    List.generate(maps.length, (i) {
      code.add(maps[i]['code']);
    });
    print('sdf');
    print(code);
    setState(() {});
  }

  getData() async {
    isLoading = false;
    print('eeeee');
    if (search) {
      store_exam = await ExamsSearchFetch().getExams(searchStr, '0');
    } else {
      store_exam = await ExamsFetch().getExams();
    }
    print(store_exam);
    if (store_exam != null) {
      int cc = 0;
      store_exam!.removeWhere((item) => code.contains(item.id));

      print(store_exam);
      setState(() {
        store_exam = store_exam;
        isLoading = true;
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
    print(paym_ref);
    DownloadExam(ex_id, paym_ref, context).getQuestions().then((value) {
      print(
        'bnbnbnbnbnbnbnbnbnnbbnnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnb',
      );
      print(value);
      if (value == null) {
      } else {
      
      Navigator.of(context).pop();
      Navigator.popAndPushNamed(context, "/");
      }
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
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0081B9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    SubscDownloadExam(ex_id, _token!, context).getQuestions().then((value) {
      print(
        'bnbnbnbnbnbnbnbnbnnbbnnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnbnb',
      );
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 8,
                  child: TextField(
                    controller: searchControler,
                    decoration: const InputDecoration(
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      filled: true,
                      hintText: "Search",
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        //Outline border type for TextFeild
                        borderRadius: const BorderRadius.all(
                          Radius.circular(1),
                        ),
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
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
                        setState(() {
                          search = true;
                          searchStr = searchControler.text;
                          getData();
                        });
                      },
                      child: Card(
                        color: Color(0xff0081B9),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Center(
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Card(
                          color: Color(0xff0081B9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.library_books_outlined,
                                          color: Color(0xff0081B9),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'All',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/store-national',
                            arguments: {'where': 'all'},
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xff0081B9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.menu_book_sharp,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'National',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 126, 126, 126),
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xff0081B9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.menu_book_sharp,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Uni/Collage',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 126, 126, 126),
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xff0081B9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.menu_book_sharp,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'School',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 126, 126, 126),
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
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       Navigator.pushNamed(context, '/store-sub',
                    //           arguments: {'where': 'all'});
                    //     },
                    //     child: Card(
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(20.0),
                    //       ),
                    //       elevation: 0,
                    //       child: Padding(
                    //         padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                    //         child: Center(
                    //           child: Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Padding(
                    //                 padding: const EdgeInsets.only(right: 5),
                    //                 child: Container(
                    //                   decoration: BoxDecoration(
                    //                       color: Color(0xff0081B9),
                    //                       shape: BoxShape.circle),
                    //                   child: Padding(
                    //                     padding: const EdgeInsets.all(6.0),
                    //                     child: Icon(
                    //                       Icons.menu_book_sharp,
                    //                       color: Colors.white,
                    //                       size: 18,
                    //                     ),
                    //                   ),
                    //                 ),
                    //               ),
                    //               const Text(
                    //                 'Subject',
                    //                 style: TextStyle(
                    //                   color: Color.fromARGB(255, 126, 126, 126),
                    //                   fontWeight: FontWeight.bold,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       Navigator.pushNamed(context, '/store-stream',
                    //           arguments: {'where': 'all'});
                    //     },
                    //     child: Card(
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(20.0),
                    //       ),
                    //       elevation: 0,
                    //       child: Padding(
                    //         padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                    //         child: Center(
                    //           child: Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Padding(
                    //                 padding: const EdgeInsets.only(right: 5),
                    //                 child: Container(
                    //                   decoration: BoxDecoration(
                    //                       color: Color(0xff0081B9),
                    //                       shape: BoxShape.circle),
                    //                   child: Padding(
                    //                     padding: const EdgeInsets.all(6.0),
                    //                     child: Icon(
                    //                       Icons.type_specimen,
                    //                       color: Colors.white,
                    //                       size: 18,
                    //                     ),
                    //                   ),
                    //                 ),
                    //               ),
                    //               const Text(
                    //                 'Stream',
                    //                 style: TextStyle(
                    //                   color: Color.fromARGB(255, 126, 126, 126),
                    //                   fontWeight: FontWeight.bold,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Visibility(
              visible: isLoading,
              replacement: const Center(
                child: const CircularProgressIndicator(),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: (1 / 1.2),
                ),
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                itemCount: store_exam?.length,
                itemBuilder: (context, index) {
                  return Visibility(
                    visible: !code.contains('${store_exam?[index].id}'),
                    child: Padding(
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
                            child: Container(
                              foregroundDecoration:
                                  store_exam?[index].isNew == 'no'
                                      ? null
                                      : RotatedCornerDecoration.withColor(
                                        color: Color.fromARGB(255, 237, 36, 14),
                                        badgeSize: Size(48, 48),
                                        textSpan: const TextSpan(
                                          text: 'NEW',
                                          style: TextStyle(
                                            fontSize: 13,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              BoxShadow(
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                                        PopupMenuButton(
                                          itemBuilder: (context) {
                                            return [
                                              PopupMenuItem(
                                                value: 'buy',
                                                child: Text(
                                                  "BUY  ${store_exam![index].price} ETB",
                                                ),
                                              ),
                                            ];
                                          },
                                          onSelected: (String value) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Text(
                                                  'Subscribe to Download',
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${store_exam?[index].sub}',
                                      style: TextStyle(
                                        color: st_cls[index % 4][2],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        5,
                                        0,
                                        0,
                                      ),
                                      child: Text(
                                        '${store_exam?[index].name}',
                                        style: TextStyle(
                                          color: st_cls[index % 4][1],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    isSubsc == 'yes'
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                downloadIfSubsc(
                                                  store_exam![index].id,
                                                );
                                              },
                                              child: const Text("Download"),
                                              style: ButtonStyle(
                                                side: MaterialStateProperty.all(
                                                  BorderSide(
                                                    color: st_cls[index % 4][1],
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
                                                    >(st_cls[index % 4][0]),
                                              ),
                                            ),
                                          ],
                                        )
                                        : store_exam![index].id ==
                                            int.parse(_payRefId!)
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                downloadIfPayed(
                                                  store_exam![index].id,
                                                  _payRef,
                                                );
                                              },
                                              child: const Text("Download"),
                                              style: ButtonStyle(
                                                side: MaterialStateProperty.all(
                                                  BorderSide(
                                                    color: st_cls[index % 4][1],
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
                                                    >(st_cls[index % 4][0]),
                                              ),
                                            ),
                                          ],
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${store_exam![index].price} ETB',
                                              style: TextStyle(
                                                color: st_cls[index % 4][2],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return CustomDialogBox(
                                                      exam_id:
                                                          store_exam![index].id,
                                                      price:
                                                          store_exam![index]
                                                              .price,
                                                    );
                                                  },
                                                );
                                                // print('sdf');
                                                // Chapa.paymentParameters(
                                                //   context: context, // context
                                                //   publicKey:
                                                //       'CHASECK_TEST-SrzPfzVaXIzgI8s2PtBu59DbTUBnPLtf',
                                                //   currency: 'ETB',
                                                //   amount: '200',
                                                //   email: 'xyz@gmail.com',
                                                //   firstName: 'fullName',
                                                //   lastName: 'lastName',
                                                //   txRef: '34TXdfsfThkhkbmnbHHgb',
                                                //   title: 'title',
                                                //   desc: 'desc',
                                                //   namedRouteFallBack:
                                                //       '/', // fall back route name
                                                // );
                                              },
                                              child: const Text("Buy"),
                                              style: ButtonStyle(
                                                side: MaterialStateProperty.all(
                                                  BorderSide(
                                                    color: st_cls[index % 4][1],
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
                                                    >(st_cls[index % 4][0]),
                                              ),
                                            ),
                                          ],
                                        ),
                                  ],
                                ),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
