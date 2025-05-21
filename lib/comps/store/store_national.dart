import 'package:eltest_exit/comps/service/remote_services.dart';
import 'package:eltest_exit/models/store_national.dart';
import 'package:eltest_exit/models/subject_model.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as Path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';

import '../../models/store_exam_model.dart';
import '../custom_dialog.dart';
import '../provider/auth.dart';
import '../service/download.dart';
import '../service/database_manipulation.dart'; // Import DatabaseHelper for Exam.existsInLocalDb

class StoreNational extends StatefulWidget {
  const StoreNational({super.key});

  @override
  State<StoreNational> createState() => _StoreNationalState();
}

class _StoreNationalState extends State<StoreNational> {
  List<National>? nationals = [];
  bool isLoading = true;

  List<StoreExamModel>? store_exam;
  List code =
      []; // This seems to store exam codes, which might not be the best way to check for downloaded status. We will use Exam.existsInLocalDb instead.
  String? _payRefId = '0';
  String? _payRef;
  late Database db;
  String? chosen_sub;
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
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
    _token = Provider.of<Auth>(context, listen: false).token;
    dbstat(); // This fetches exam codes, which we might not need anymore for checking download status
    getData();

    // This widget is the root of your application.
  }

  getData() async {
    print('Fetching national exams...');
    isLoading = false;
    nationals = await NationalListFetch().get_nationals();
    if (nationals != null) {
      print('Fetched ${nationals!.length} national exams.');
      setState(() {
        isLoading = true; // Data is loaded, hide loading indicator
      });
    } else {
      print('Failed to fetch national exams.');
      setState(() {
        isLoading =
            true; // Still set to true to show content area (possibly empty)
      });
    }
  }

  // This method seems to fetch exam codes from the local database.
  // We will rely on Exam.existsInLocalDb for checking download status instead.
  dbstat() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    db = await openDatabase(path, version: 1);
    // List<Map<String, dynamic>> maps = await db.query('exam');
    // maps = List.from(maps.reversed);
    // List.generate(maps.length, (i) {
    //   code.add(maps[i]['code']);
    // });
    // print(code);
    setState(() {});
  }

  getByNational(nat_id) async {
    print('Fetching exams under national ID: $nat_id');
    isLoading = false; // Show loading indicator while fetching exams
    store_exam = await ListUnderNationalFetch().get_under_nationals(nat_id);

    if (store_exam != null) {
      print('Fetched ${store_exam!.length} exams under national ID: $nat_id');
      // We no longer filter based on the 'code' list here.
      // The download status will be checked dynamically in the GridView.builder.
      setState(() {
        store_exam;
        isLoading = true; // Data is loaded, hide loading indicator
      });
    } else {
      print('Failed to fetch exams under national ID: $nat_id');
      setState(() {
        isLoading =
            true; // Still set to true to show content area (possibly empty)
      });
    }
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
                Text('Downloading...'),
              ],
            ),
          ),
        );
      },
    );
    SubscDownloadExam(ex_id, _token!, context).getQuestions().then((value) {
      Navigator.of(context).pop();
      // After successful download, you might want to refresh the list
      // or update the state to show the "Downloaded" button.
      // For now, let's navigate back to the home screen.
      Navigator.popAndPushNamed(context, "/");
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
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
            "Store",
            style: TextStyle(
              color: const Color(0xff21205A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xffF2F5F8),
      body: SingleChildScrollView(
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/paid',
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
                                          Icons.library_books_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'All',
                                    style: TextStyle(
                                      color: Color(0xff0081B9),
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
                          color: Color(0xff0081B9),
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
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.menu_book_sharp,
                                          color: Color(0xff0081B9),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'National',
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

                    //         Padding(
                    //           padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    //           child: GestureDetector(
                    //             onTap: () {

                    //             },
                    //             child: Card(
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(20.0),
                    //               ),
                    //               color: Color(0xff0081B9),
                    //               elevation: 0,
                    //               child: Padding(
                    //                 padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                    //                 child: Center(
                    //                   child: Row(
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.spaceBetween,
                    //                     children: [
                    //                       Padding(
                    //                         padding: const EdgeInsets.only(right: 5),
                    //                         child: Container(
                    //                           decoration: BoxDecoration(
                    //                               color: Color.fromARGB(
                    //                                   255, 255, 255, 255),
                    //                               shape: BoxShape.circle),
                    //                           child: Padding(
                    //                             padding: const EdgeInsets.all(6.0),
                    //                             child: Icon(
                    //                               Icons.menu_book_sharp,
                    //                               color: Color(0xff0081B9),
                    //                               size: 18,
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       const Text(
                    //                         'Subject',
                    //                         style: TextStyle(
                    //                           color: Color.fromARGB(255, 255, 255, 255),
                    //                           fontWeight: FontWeight.bold,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //         Padding(
                    //           padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    //           child: GestureDetector(
                    //             onTap: () {
                    //               Navigator.pushNamed(context, '/store-stream',
                    //                   arguments: {'where': 'all'});
                    //             },
                    //             child: Card(
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(20.0),
                    //               ),
                    //               elevation: 0,
                    //               child: Padding(
                    //                 padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                    //                 child: Center(
                    //                   child: Row(
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.spaceBetween,
                    //                     children: [
                    //                       Padding(
                    //                         padding: const EdgeInsets.only(right: 5),
                    //                         child: Container(
                    //                           decoration: BoxDecoration(
                    //                               color: Color(0xff0081B9),
                    //                               shape: BoxShape.circle),
                    //                           child: Padding(
                    //                             padding: const EdgeInsets.all(6.0),
                    //                             child: Icon(
                    //                               Icons.type_specimen,
                    //                               color: Colors.white,
                    //                               size: 18,
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       const Text(
                    //                         'Stream',
                    //                         style: TextStyle(
                    //                           color: Color.fromARGB(255, 126, 126, 126),
                    //                           fontWeight: FontWeight.bold,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: Row(
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
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: nationals?.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {
                          getByNational(nationals![index].id);
                          setState(() {
                            chosen_sub = nationals![index].name;
                          });
                        },
                        child: Card(
                          color:
                              nationals?[index].name == chosen_sub
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            nationals?[index].name == chosen_sub
                                                ? Colors.white
                                                : Color(0xff0081B9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.book_online,
                                          color:
                                              nationals?[index].name ==
                                                      chosen_sub
                                                  ? Color(0xff0081B9)
                                                  : Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${nationals?[index].name}',
                                    style: TextStyle(
                                      color:
                                          nationals?[index].name == chosen_sub
                                              ? Colors.white
                                              : Color.fromARGB(
                                                255,
                                                126,
                                                126,
                                                126,
                                              ),
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
                  },
                ),
              ),
            ),

            chosen_sub != null
                ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Visibility(
                    visible:
                        isLoading, // Show GridView when isLoading is true (after fetching exams)
                    replacement: const Center(
                      child:
                          const CircularProgressIndicator(), // Show loading indicator while fetching exams
                    ),
                    child:
                        store_exam != null && store_exam!.isNotEmpty
                            ? GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: (1 / 1.2),
                                  ),
                              shrinkWrap: true,
                              physics: const ScrollPhysics(),
                              itemCount: store_exam!.length,
                              itemBuilder: (context, index) {
                                final exam = store_exam![index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    5,
                                    0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Handle tap if needed, maybe show exam details
                                    },
                                    child: SizedBox(
                                      width: (deviceWidth - 50) / 2,
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20.0,
                                          ),
                                        ),
                                        color: st_cls[index % 4][0],
                                        child: Container(
                                          foregroundDecoration:
                                              exam.isNew == 'no'
                                                  ? null
                                                  : RotatedCornerDecoration.withColor(
                                                    color: Color.fromARGB(
                                                      255,
                                                      237,
                                                      36,
                                                      14,
                                                    ),
                                                    badgeSize: Size(48, 48),
                                                    textSpan: const TextSpan(
                                                      text: 'NEW',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        letterSpacing: 1,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        shadows: [
                                                          BoxShadow(
                                                            color:
                                                                Color.fromARGB(
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Icon(
                                                      Icons.folder,
                                                      color:
                                                          st_cls[index % 4][1],
                                                      size: 30,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${exam.sub}',
                                                  style: TextStyle(
                                                    color: st_cls[index % 4][2],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        0,
                                                        5,
                                                        0,
                                                        0,
                                                      ),
                                                  child: Text(
                                                    '${exam.name}',
                                                    style: TextStyle(
                                                      color:
                                                          st_cls[index % 4][1],
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Use FutureBuilder to check if the exam is downloaded
                                                FutureBuilder<bool>(
                                                  future: Exam.existsInLocalDb(
                                                    exam.id!,
                                                  ), // Check if exam exists locally
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      ); // Small loading indicator
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Text(
                                                        'Error',
                                                      ); // Handle error
                                                    } else {
                                                      final isDownloaded =
                                                          snapshot.data ??
                                                          false;

                                                      if (isDownloaded) {
                                                        // Exam is downloaded, show Downloaded button
                                                        return Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            ElevatedButton(
                                                              onPressed:
                                                                  null, // Disabled
                                                              child: const Text(
                                                                "Downloaded",
                                                              ),
                                                              style: ButtonStyle(
                                                                side: MaterialStateProperty.all(
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .grey, // Grey border for disabled
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
                                                                      Colors
                                                                          .grey, // Grey text for disabled
                                                                    ),
                                                                backgroundColor:
                                                                    MaterialStateProperty.all<
                                                                      Color
                                                                    >(
                                                                      Color.fromARGB(
                                                                        255,
                                                                        224,
                                                                        224,
                                                                        224,
                                                                      ), // Light grey background
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      } else if (isSubsc ==
                                                          'yes') {
                                                        // User is subscribed and exam is not downloaded, show Download button
                                                        return Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                downloadIfSubsc(
                                                                  exam.id,
                                                                );
                                                              },
                                                              child: const Text(
                                                                "Download",
                                                              ),
                                                              style: ButtonStyle(
                                                                side: MaterialStateProperty.all(
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
                                                                    >(
                                                                      st_cls[index %
                                                                          4][0],
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      } else {
                                                        // User is not subscribed and exam is not downloaded, show Buy button
                                                        return Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              '${exam.price} ETB',
                                                              style: TextStyle(
                                                                color:
                                                                    st_cls[index %
                                                                        4][2],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder: (
                                                                    BuildContext
                                                                    context,
                                                                  ) {
                                                                    return CustomDialogBox(
                                                                      exam_id:
                                                                          store_exam![index]
                                                                              .id,
                                                                      price:
                                                                          store_exam![index]
                                                                              .price,
                                                                    );
                                                                    ;
                                                                  },
                                                                );
                                                              },
                                                              child: const Text(
                                                                "Buy",
                                                              ),
                                                              style: ButtonStyle(
                                                                side: MaterialStateProperty.all(
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
                                                                    >(
                                                                      st_cls[index %
                                                                          4][0],
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
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
                            )
                            : Center(
                              child: Text(
                                'No exams available for this selection.',
                              ),
                            ), // Message if no exams found
                  ),
                )
                : Center(
                  child: Text('Select an exam type to view exams.'),
                ), // Message if no exam type is chosen
          ],
        ),
      ),
    );
  }
}
