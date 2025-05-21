import 'package:eltest_exit/comps/provider/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_nav.dart';
import 'provider/strored_ref.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service/common.dart';

class PaymentFinishedScreen extends StatefulWidget {
  const PaymentFinishedScreen({Key? key}) : super(key: key);

  @override
  State<PaymentFinishedScreen> createState() => _PaymentFinishedScreenState();
}

class _PaymentFinishedScreenState extends State<PaymentFinishedScreen> {
  var args;
  String? _paym_ref;
  bool isLoading = true;
  String? _token;
  String? _dis;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration.zero, () {
      setState(() {
        if (ModalRoute.of(context)?.settings.arguments != null) {
          args = ModalRoute.of(context)?.settings.arguments;
          print(args);
          if (args['message'] == 'paymentSuccessful') {
            _paym_ref = Provider.of<RefData>(context, listen: false).subRef;
            _dis = Provider.of<RefData>(context, listen: false).dis;
            _token = Provider.of<Auth>(context, listen: false).token;
            print(_paym_ref);
            _checkAndAdd({'payRef': _paym_ref, 'dis': _dis});
          }
          if (args['message'] == 'paymentCancelled') {
            print('cancelled');
          }
        }
      });
    });
  }

  Future<void> _checkAndAdd(j_data) async {
    setState(() {
      isLoading = false;
    });
    final response = await http.post(
      Uri.parse('$main_url/api/exam/add-subs/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode(j_data),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      Provider.of<Auth>(context, listen: false).set_payed();
      setState(() {
        isLoading = true;
      });
    } else {
      print(response.body);
    }
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
            "Finished Subscription",
            style: TextStyle(
              color: const Color(0xff21205A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xffF2F5F8),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                "Your Subscription is Successfull. Enjoy!",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xff0081B9)),
                  padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
                  textStyle: MaterialStateProperty.all(
                      const TextStyle(fontSize: 14, color: Colors.white))),
              onPressed: () => Navigator.pushAndRemoveUntil<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => HomeNavigator(),
                    ),
                    (route) =>
                        false, //if you want to disable back feature set to false
                  ),
              child: const Text('Back to Home')),
        ],
      ),
    );
  }
}
