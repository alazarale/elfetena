import 'package:eltest_exit/comps/analysis_screen.dart';
import 'package:eltest_exit/comps/home.dart';
import 'package:eltest_exit/comps/provider/auth.dart';
import 'package:eltest_exit/comps/provider/strored_ref.dart';
import 'package:eltest_exit/comps/service/download.dart';
import 'package:eltest_exit/comps/store/store_screen.dart';
import 'package:eltest_exit/comps/study.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eltest_exit/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:convert';

import 'service/common.dart';
import 'service/notification_service.dart';
import 'side_nav.dart';

class HomeNavigator extends StatefulWidget {
  HomeNavigator({Key? key, this.index = 0}) : super(key: key);

  int index;

  @override
  State<HomeNavigator> createState() => _HomeNavigatorState();
}

class _HomeNavigatorState extends State<HomeNavigator> {
  int index = 0;
  final screens = [
    const HomePage(),
    StudyScreen(),
    StoreScreen(),
    const AnalysisScreen(),
  ];

  var args;
  String? _paym_ref;
  bool isloggedin = false;
  String? isSubsc;
  String? _token;
  bool isLoa = false;
  bool isLoading2 = true;
  int? _sub_amount = 400;
  String _lan = 'am';
  String _is_shown = 'no';

  late final NotificationService notificationService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    index = widget.index;

    Future.delayed(Duration.zero, () {
      setState(() {
        if (ModalRoute.of(context)?.settings.arguments != null) {
          args = ModalRoute.of(context)?.settings.arguments;
          debugPrint('message after payment');
          debugPrint(args['message']);
          debugPrint(args['transactionReference']);
          debugPrint(args['paidAmount']);
          print(args);
          if (args['message'] == 'paymentSuccessful') {
            _paym_ref = Provider.of<RefData>(context, listen: false).paymentRef;
            String ex_id = _paym_ref!.replaceAll('exampay', '').split('sid')[0];
            downloadIfPayed(int.parse(ex_id), _paym_ref);
          }
          if (args['message'] == 'paymentCancelled') {
            print('cancelled');
            Provider.of<RefData>(context, listen: false).setPaymentRef('No');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment was cancelled'),
              ),
            );
            Navigator.pushNamed(context, '/paid', arguments: {});
          }
        }
      });
    });
    checkAmount();
    Provider.of<RefData>(context, listen: false).tryGetCredintial();
    Provider.of<RefData>(context, listen: false).tryGetPayRef();
    Provider.of<RefData>(context, listen: false).tryGetGeminiApi();
    Provider.of<Auth>(context, listen: false).tryAutoLogin().then((value) {
      if (value) {
        isloggedin = true;
        _token = Provider.of<Auth>(context, listen: false).token;
      }
    });
    Provider.of<Auth>(context, listen: false).try_payment().then((value) {
      if (value) {
        setState(() {
          isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
        });
      }
      isSubsc = Provider.of<Auth>(context, listen: false).is_payed;
      print(isSubsc);
      isSubsc == "waiting" ? checkWaitingStatus() : null;
    });
    isSubsc = Provider.of<Auth>(context, listen: false).is_payed;

    notificationService = NotificationService();
    listenToNotificationStream();
    notificationService.initializePlatformNotifications();
    Provider.of<RefData>(context, listen: false).tryNotShown().then((val) {
      _is_shown = Provider.of<RefData>(context, listen: false).not_shown;
      _is_shown == 'no' ? showNot() : null;
    });
    showNot();
  }

  showNot() async {
    await notificationService.showPeriodicLocalNotification(
        id: 0,
        title: "Don't Forget Entrance Exam",
        body: "Prepare Every day to get the score you deserve.",
        payload: "You just took water! Huurray!");
    Provider.of<RefData>(context, listen: false).setNotShown('yes');
    _is_shown = 'yes';
  }

  void listenToNotificationStream() =>
      notificationService.behaviorSubject.listen((payload) {});

  checkWaitingStatus() async {
    setState(() {
      isLoa = true;
    });
    final response = await http.post(
      Uri.parse('$main_url/api/sub-check/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_token'
      },
    );

    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      Provider.of<Auth>(context, listen: false).set_payed();
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                'You have been approved. Thank you for using',
                style: TextStyle(color: Color(0xff0081B9), fontSize: 14),
              ),
            ],
          ),
        ),
        btnOkText: 'OK',
        btnOkOnPress: () {
          Navigator.of(context).pop;
        },
      )..show();
      setState(() {
        isSubsc = 'yes';
      });
    } else {
      var d = jsonDecode(response.body);
      if (d['stat'] == 'declined') {
        Provider.of<Auth>(context, listen: false).set_payed_no();
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          body: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                const Text(
                  'Your reciept is declined. It has been used for other account. Submit a valid reciept.',
                  style: TextStyle(
                      color: Color.fromARGB(255, 254, 20, 20), fontSize: 14),
                ),
              ],
            ),
          ),
          btnOkText: 'OK',
          btnOkColor: AppTheme.red,
          btnOkOnPress: () {
            Navigator.of(context).pop;
          },
        )..show();
        setState(() {
          isSubsc = 'no';
        });
      }
    }
    setState(() {
      isLoa = false;
    });
  }

  checkAmount() async {
    setState(() {
      isLoading2 = false;
    });

    final response = await http.post(
      Uri.parse('${main_url}/api/sub-am/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'code': 'no'}),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      _sub_amount = jsonDecode(json)['amount'].toInt();
    } else {}
    setState(() {
      isLoading2 = true;
    });
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

    DownloadExam(ex_id, paym_ref, context).getQuestions().then((value) {
      Navigator.of(context).pop();
      Navigator.popAndPushNamed(context, "/");
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: SideNavBar(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 255, 255, 255)),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  size: 20,
                  color: Color(0xff0081B9),
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ),
        // actions: [
        //   Padding(
        //       padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        //       child: new Stack(
        //         children: <Widget>[
        //           Container(
        //             alignment: Alignment.center,
        //             decoration: const BoxDecoration(
        //                 shape: BoxShape.circle,
        //                 color: Color.fromARGB(255, 255, 255, 255)),
        //             child: IconButton(
        //               icon: const Icon(
        //                 Icons.shopping_cart,
        //                 size: 20,
        //                 color: Color(0xff0081B9),
        //               ),
        //               onPressed: () {},
        //             ),
        //           ),
        //           Positioned(
        //               child: new Stack(
        //             children: <Widget>[
        //               new Icon(Icons.brightness_1,
        //                   size: 20.0, color: Colors.green[800]),
        //               new Positioned(
        //                   top: 3.0,
        //                   right: 4.0,
        //                   child: const Text(
        //                     '3',
        //                     style: const TextStyle(
        //                         color: Colors.white,
        //                         fontSize: 11.0,
        //                         fontWeight: FontWeight.w500),
        //                   )),
        //             ],
        //           )),
        //         ],
        //       )),
        // ],
        elevation: 0,
        backgroundColor: const Color(0xffF2F5F8),
        title: Center(
            child: Text(
          index == 0
              ? "El-Test"
              : index == 1
                  ? "Study"
                  : index == 2
                      ? "Store"
                      : index == 3
                          ? "Analysis"
                          : "",
          style: TextStyle(
            color: const Color(0xff21205A),
            fontWeight: FontWeight.bold,
          ),
        )),
        
      ),
      backgroundColor: const Color(0xffF2F5F8),
      bottomNavigationBar: CurvedNavigationBar(
        index: index,
        onTap: (index) => setState(() => this.index = index),
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: const Color(0xff0081B9),
        color: const Color(0xff0081B9),
        height: 60,
        items: const <Widget>[
          Icon(
            Icons.home,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.menu_book_outlined,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.store,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.trending_up,
            size: 30,
            color: Colors.white,
          ),
        ],
      ),
      body: screens[index],
      floatingActionButton: isSubsc == 'yes'
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                isSubsc != 'waiting'
                    ? showModalBottomSheet(
                        context: context,
                        backgroundColor: Color(0xff0081B9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (BuildContext context, setState) =>
                                Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Expanded(
                                            flex: 4,
                                            child: Text(''),
                                          ),
                                          const Expanded(
                                              flex: 4,
                                              child: Text(
                                                "EL-Test",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )),
                                          Expanded(
                                            flex: 4,
                                            child: SizedBox(
                                              width: 50,
                                              child: ElevatedButton(
                                                child: Text(
                                                  _lan == 'am' ? 'EN' : 'AM',
                                                  style: TextStyle(
                                                      color: Color(0xff0081B9),
                                                      fontSize: 16),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _lan == 'am'
                                                        ? _lan = 'en'
                                                        : _lan = 'am';
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 20, 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          _lan == 'am'
                                              ? const Text(
                                                  'ክፍያ መጠን:  ',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : const Text(
                                                  'Price:  ',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                          _lan == 'am'
                                              ? Visibility(
                                                  visible: isLoading2,
                                                  replacement:
                                                      CircularProgressIndicator(),
                                                  child: Text(
                                                    '$_sub_amount ብር',
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              : Visibility(
                                                  visible: isLoading2,
                                                  replacement:
                                                      CircularProgressIndicator(),
                                                  child: Text(
                                                    '$_sub_amount birr',
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                        ],
                                      ),
                                    ),
                                    _lan == 'am'
                                        ? const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 0, 20, 20),
                                            child: Center(
                                              child: Text(
                                                'በአንድ ግዜ የሰብስክሪብሽን ክፍያ መተግበሪያው ላይ የሚገኙትን ፊተናዎች በሙሉ ያለ ተጨማሪ ክፍያ ይጠቀሙ። በውስጡ የብዙ አመታት የሀገር አቀፍ ፈተና እና በተለያዩ ግዜያት የሚዘጋጁ መልመጃዎች ይይዛል።',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 220, 220, 220),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )
                                        : const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 0, 20, 20),
                                            child: Center(
                                              child: Text(
                                                'By paying a one time subscription fee, get all Exams on the APP without any additional fee.',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 220, 220, 220),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                    isloggedin
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                30, 10, 30, 10),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                minimumSize:
                                                    const Size.fromHeight(
                                                        50), // NEW
                                              ),
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                    context, '/payment-list',
                                                    arguments: {});
                                              },
                                              child: const Text(
                                                'Continue',
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    color: Color(0xff0081B9)),
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20, 0, 20, 0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    _lan == 'am'
                                                        ? Text(
                                                            'ለመቀጠል ማንነቶን እንድናስታውስ አካውንት ይክፈቱ',
                                                            style: TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      255,
                                                                      255,
                                                                      255),
                                                              fontSize: 16,
                                                            ),
                                                          )
                                                        : Text(
                                                            'To Continue, Please Signup.',
                                                            style: TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      255,
                                                                      255,
                                                                      255),
                                                              fontSize: 16,
                                                            ),
                                                          )
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        30, 10, 30, 10),
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    minimumSize:
                                                        const Size.fromHeight(
                                                            50), // NEW
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                        context, '/signup',
                                                        arguments: {});
                                                  },
                                                  child: const Text(
                                                    'Signup',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        color:
                                                            Color(0xff0081B9)),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        30, 10, 30, 10),
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    minimumSize:
                                                        const Size.fromHeight(
                                                            50), // NEW
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                        context, '/login',
                                                        arguments: {});
                                                  },
                                                  child: const Text(
                                                    'Login',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        color:
                                                            Color(0xff0081B9)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    SizedBox(
                                      height: 30,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        })
                    : checkWaitingStatus();
              },
              label: isSubsc == 'waiting'
                  ? isLoa
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text('Waiting for approval')
                  : Text('One Time Subscription To get ALL'.toUpperCase()),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
