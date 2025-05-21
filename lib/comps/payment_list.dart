import 'package:eltest_exit/comps/dialog_subsc.dart';
import 'package:flutter/material.dart';

import 'home_nav.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({Key? key}) : super(key: key);

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
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
                Icons.home,
                size: 20,
                color: Color(0xff0081B9),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => HomeNavigator(),
                ),
                (route) =>
                    false, //if you want to disable back feature set to false
              ),
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xffF2F5F8),
        title: const Center(
          child: Text(
            "Payment Methods",
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
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children: [
            //       Text(
            //         'For immediate approval use these:',
            //         style: TextStyle(
            //           fontSize: 18,
            //           fontStyle: FontStyle.italic,
            //           color: Color(0xff0081B9),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.only(right: 15),
            //         child: Column(
            //           children: [
            //             GestureDetector(
            //               onTap: () {
            //                 Navigator.pushNamed(context, '/immed',
            //                     arguments: {'title': 'Telebirr', 'bank': "Telebirr"});
            //               },
            //               child: SizedBox(
            //                 height: 100,
            //                 width: 100,
            //                 child: CircleAvatar(
            //                   backgroundColor: Colors.white,
            //                   backgroundImage:
            //                       AssetImage('assets/images/TeleBirr.png'),
            //                 ),
            //               ),
            //             ),
            //             SizedBox(
            //               height: 10,
            //             ),
            //             Text(
            //               'Tele Birr',
            //               style: TextStyle(fontSize: 16, color: Color(0xff0081B9),),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                   'Choose Bank:',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Color(0xff0081B9),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap:() {
                      Navigator.pushNamed(context, '/bank',
                                arguments: {'title': 'Commercial Bank Of Ethiopia', 'bank': "CBE"});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  AssetImage('assets/images/cbe.png'),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'CBE',
                            style: TextStyle(fontSize: 16, color: Color(0xff0081B9),),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/bank',
                                arguments: {'title': 'Abyssinia Bank', 'bank': "abyssinia"});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/images/boa.png'),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Abyssinia Bank',
                            style: TextStyle(fontSize: 16, color: Color(0xff0081B9),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/bank',
                                arguments: {'title': 'Cooperative Bank of Oromia', 'bank': "coop"});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  AssetImage('assets/images/coop.png'),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'COOP',
                            style: TextStyle(fontSize: 16, color: Color(0xff0081B9),),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/bank',
                                arguments: {'title': 'Awash Bank', 'bank': "awash"});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  AssetImage('assets/images/aib.png'),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Awash Bank',
                            style: TextStyle(fontSize: 16, color: Color(0xff0081B9),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
