import 'package:eltest_exit/comps/service/remote_services.dart';
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

class StoreSubjectScreen extends StatefulWidget {
  const StoreSubjectScreen({Key? key}) : super(key: key);

  @override
  State<StoreSubjectScreen> createState() => _StoreSubjectScreenState();
}

class _StoreSubjectScreenState extends State<StoreSubjectScreen> {
  List<Subject>? subjects = [];
  bool isLoading = true;
  Map<String, IconData> _subIcon = {
    'Biology': Icons.energy_savings_leaf,
    'Chemistry': Icons.thermostat,
    'Mathematics': Icons.edit,
    'Physics': Icons.lightbulb_outline,
    "Civics": Icons.people_outline,
    "English": Icons.abc_outlined,
    "SAT": Icons.light_mode,
    "Geography": Icons.landscape,
    "History": Icons.rotate_left_outlined,
    "Economics": Icons.monetization_on_outlined,
    "General Business": Icons.store
  };

  List<StoreExamModel>? store_exam;
  List code = [];
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
      const Color.fromARGB(255, 0, 82, 117)
    ],
    [
      const Color(0xffFDF1D9),
      const Color(0xffF0A714),
      const Color.fromARGB(255, 178, 124, 14)
    ],
    [
      const Color(0xffFDE4E4),
      const Color(0xffF35555),
      const Color.fromARGB(255, 155, 27, 27)
    ],
    [
      const Color(0xffDDF0E6),
      const Color(0xff28A164),
      const Color.fromARGB(255, 24, 111, 68)
    ],
  ];

  @override
  void initState() {
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
    _token = Provider.of<Auth>(context, listen: false).token;
    dbstat();
    getData();

    // This widget is the root of your application.
  }

  getData() async {
    print('sdf');
    isLoading = false;
    subjects = await SubjectsFetch().getsubs();
    if (subjects != null) {
      print(subjects);
      setState(() {
        isLoading = true;
      });
    }
  }

  dbstat() async {
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    db = await openDatabase(
      path,
      version: 1,
    );
    List<Map<String, dynamic>> maps = await db.query('exam');
    maps = List.from(maps.reversed);
    List.generate(maps.length, (i) {
      code.add(maps[i]['code']);
    });
    print(code);
    setState(() {});
  }

  getBySubject(sub_name, sub_id) async {
    isLoading = false;
    store_exam = await ExamsSearchFetch().getExams(sub_name, sub_id.toString());

    if (store_exam != null) {
      print(store_exam);
      store_exam!.removeWhere((item) => code.contains('cd${item.id.toString()}'));
      setState(() {
        store_exam;
        isLoading = true;
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
                SizedBox(
                  height: 15,
                ),
                // Some text
                Text('Loading...')
              ],
            ),
          ),
        );
      },
    );
    SubscDownloadExam(ex_id, _token!, context).getQuestions().then((value) {
      Navigator.of(context).pop();
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
                          Navigator.pushNamed(context, '/paid',
                              arguments: {'where': 'all'});
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
                                          shape: BoxShape.circle),
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
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: GestureDetector(
                        onTap: () {
                          
                        },
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
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          shape: BoxShape.circle),
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
                                    'Subject',
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
                          Navigator.pushNamed(context, '/store-stream',
                              arguments: {'where': 'all'});
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
                                          shape: BoxShape.circle),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.type_specimen,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Stream',
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Choose Subject',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              width: deviceWidth - 40,
              height: 140,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: subjects?.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            getBySubject(
                                subjects?[index].name, subjects?[index].id);
                            chosen_sub = subjects?[index].name;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  color: subjects?[index].name == chosen_sub
                                      ? Colors.white
                                      : Color(0xff0081B9),
                                  shape: BoxShape.circle),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Icon(
                                  _subIcon[subjects?[index].name],
                                  color: subjects?[index].name == chosen_sub
                                      ? Color(0xff0081B9)
                                      : Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '${subjects?[index].name}',
                                style: subjects?[index].name == chosen_sub
                                    ? TextStyle(
                                        color: Color(0xff21205A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                       )
                                    : TextStyle(color: Color(0xff21205A)),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            chosen_sub != null
                ? Text(
                    '${chosen_sub}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : Text(''),
            chosen_sub != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Visibility(
                      visible: isLoading,
                      replacement: const Center(
                        child: const CircularProgressIndicator(),
                      ),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: (1/1.1),
                        ),
                        shrinkWrap: true,
                        physics: const ScrollPhysics(),
                        itemCount: store_exam?.length,
                        itemBuilder: (context, index) {
                          return Visibility(
                            visible:
                                !code.contains('cd${store_exam?[index].id}'),
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
                                      foregroundDecoration: store_exam?[index]
                                                  .isNew ==
                                              'no'
                                          ? null
                                          : RotatedCornerDecoration.withColor(
                                              color: Color.fromARGB(
                                                  255, 237, 36, 14),
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
                                                            255, 255, 255, 255),
                                                        blurRadius: 4)
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
                                                  color: st_cls[index % 4][1],
                                                  size: 30,
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
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 5, 0, 0),
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
                                                          const Color.fromARGB(
                                                              255, 90, 90, 90)),
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          st_cls[index % 4][0]),
                                                ),
                                              ),
                                            ],
                                          )
                                        : store_exam![index].id ==
                                                    int.parse(_payRefId!)
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {},
                                                        child: const Text(
                                                            "Download"),
                                                        style: ButtonStyle(
                                                          side: MaterialStateProperty
                                                              .all(BorderSide(
                                                                  color: st_cls[
                                                                      index %
                                                                          4][1],
                                                                  width: 1.0,
                                                                  style: BorderStyle
                                                                      .solid)),
                                                          foregroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  90,
                                                                  90,
                                                                  90)),
                                                          backgroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(st_cls[
                                                                      index % 4]
                                                                  [0]),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${store_exam![index].price} ETB',
                                                        style: TextStyle(
                                                          color:
                                                              st_cls[index % 4]
                                                                  [2],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return CustomDialogBox(
                                                                  exam_id:
                                                                      store_exam![
                                                                              index]
                                                                          .id,
                                                                  price: store_exam![
                                                                          index]
                                                                      .price,
                                                                );
                                                              });
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
                                                        child:
                                                            const Text("Buy"),
                                                        style: ButtonStyle(
                                                          side: MaterialStateProperty
                                                              .all(BorderSide(
                                                                  color: st_cls[
                                                                      index %
                                                                          4][1],
                                                                  width: 1.0,
                                                                  style: BorderStyle
                                                                      .solid)),
                                                          foregroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(const Color
                                                                      .fromARGB(
                                                                  255,
                                                                  90,
                                                                  90,
                                                                  90)),
                                                          backgroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(st_cls[
                                                                      index % 4]
                                                                  [0]),
                                                        ),
                                                      ),
                                                    ],
                                                  )
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
                  )
                : Text('')
          ],
        ),
      ),
    );
  }
}
