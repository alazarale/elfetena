import 'package:flutter/material.dart';

import 'package:path/path.dart' as Path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/store_exam_model.dart';
import '../custom_dialog.dart';
import '../provider/auth.dart';
import '../service/download.dart';
import '../service/remote_services.dart';
import 'package:rotated_corner_decoration/rotated_corner_decoration.dart';

class SubjectStoreListShow extends StatefulWidget {
  const SubjectStoreListShow({Key? key}) : super(key: key);

  @override
  State<SubjectStoreListShow> createState() => _SubjectStoreListShowState();
}

class _SubjectStoreListShowState extends State<SubjectStoreListShow> {
  String? _subName;
  int? _subId;
  late Database db;
  List<StoreExamModel>? store_exam;
  List code = [];
  bool isLoading = true;
  String? _payRefId = '0';
  String? _payRef;
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
    super.initState();
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
    _token = Provider.of<Auth>(context, listen: false).token;
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _subName = arguments['sub_name'];
    _subId = arguments['sub_id'];
    dbstat();
    getData();
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

  getData() async {
    isLoading = false;
    store_exam = await ExamsSearchFetch().getExams(_subName, _subId.toString());

    if (store_exam != null) {
      for (var i = 0; i < store_exam!.length; i++) {
        code.contains('cd${store_exam?[i].id.toString()}')
            ? store_exam?.length == 1
                ? store_exam?.clear()
                : store_exam?.removeAt(i)
            : null;
      }
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          elevation: 1,
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
                padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 24,
                      color: Color.fromARGB(255, 48, 45, 179),
                    ),
                    Text(
                      ' > ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 48, 45, 179),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Subject',
                        style: TextStyle(
                          color: Color.fromARGB(255, 48, 45, 179),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      ' > ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 48, 45, 179),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '${_subName}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 48, 45, 179),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_subName}',
                    style: TextStyle(
                      color: Color(0xff21205A),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Visibility(
                  visible: isLoading,
                  replacement: const Center(
                    child: const CircularProgressIndicator(),
                  ),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    itemCount: store_exam?.length,
                    itemBuilder: (context, index) {
                      return Visibility(
                        visible: !code.contains('cd${store_exam?[index].id}'),
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
                                              MainAxisAlignment.spaceBetween,
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
                                          padding: const EdgeInsets.fromLTRB(
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
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {},
                                                    child:
                                                        const Text("Download"),
                                                    style: ButtonStyle(
                                                      side: MaterialStateProperty
                                                          .all(BorderSide(
                                                              color: st_cls[
                                                                  index % 4][1],
                                                              width: 1.0,
                                                              style: BorderStyle
                                                                  .solid)),
                                                      foregroundColor:
                                                          MaterialStateProperty.all<
                                                              Color>(const Color
                                                                  .fromARGB(
                                                              255, 90, 90, 90)),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<
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
                                                      color: st_cls[index % 4]
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
                                                          builder: (BuildContext
                                                              context) {
                                                            return CustomDialogBox(
                                                              exam_id:
                                                                  store_exam![
                                                                          index]
                                                                      .id,
                                                              price:
                                                                  store_exam![
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
                                                    child: const Text("Buy"),
                                                    style: ButtonStyle(
                                                      side: MaterialStateProperty
                                                          .all(BorderSide(
                                                              color: st_cls[
                                                                  index % 4][1],
                                                              width: 1.0,
                                                              style: BorderStyle
                                                                  .solid)),
                                                      foregroundColor:
                                                          MaterialStateProperty.all<
                                                              Color>(const Color
                                                                  .fromARGB(
                                                              255, 90, 90, 90)),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
