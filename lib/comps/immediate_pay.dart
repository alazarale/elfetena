import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:chapasdk/chapasdk.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:eltest_exit/theme/app_theme.dart';

import 'provider/strored_ref.dart';
import 'dart:math';

import 'service/common.dart';

class ImmediateAuthScreen extends StatefulWidget {
  const ImmediateAuthScreen({Key? key}) : super(key: key);

  @override
  State<ImmediateAuthScreen> createState() => _ImmediateAuthScreenState();
}

class _ImmediateAuthScreenState extends State<ImmediateAuthScreen> {
  String? _title;
  TextEditingController first_name = TextEditingController();
  TextEditingController last_name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController discountControler = new TextEditingController();
  TextEditingController phone = TextEditingController();

  String _dis_code = 'no';

  Random random = new Random();

  bool isloading = true;
  bool isLoading2 = true;
  String? ref_no;
  String? _bnk;
  int? _sub_amount;

  @override
  void initState() {
    super.initState();
    Provider.of<RefData>(context, listen: false).tryGetCredintial();
    first_name.text = Provider.of<RefData>(context, listen: false).firstName;
    last_name.text = Provider.of<RefData>(context, listen: false).lastName;
    email.text = Provider.of<RefData>(context, listen: false).email;
    checkAmount();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _title = arguments['title'];
    _bnk = arguments['bank'];
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
      body: jsonEncode({'code': _dis_code}),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      _sub_amount = jsonDecode(json)['amount'].toInt();
    } else {
      if (response.reasonPhrase == "Forbidden") {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Discount Code Failed",
                style: TextStyle(color: AppTheme.red),
              ),
              content: Text(
                "You have used Invalid discount code.",
                style: TextStyle(color: AppTheme.red),
              ),
            );
          },
        );
      }
      setState(() {
        _dis_code = "no";
      });
    }
    setState(() {
      isLoading2 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

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
        title: Center(
          child: Text(
            "${_title}",
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                      left: Constants.padding,
                      top: Constants.avatarRadius + Constants.padding,
                      right: Constants.padding,
                      bottom: Constants.padding,
                    ),
                    margin: EdgeInsets.only(top: Constants.avatarRadius),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Constants.padding),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pay Using ${_title}.',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 103, 103, 103),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Total Amount:  ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                !isLoading2
                                    ? CircularProgressIndicator(
                                      color: Colors.green,
                                    )
                                    : Text(
                                      '${_sub_amount} birr',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: discountControler,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 56, 159, 196),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    focusColor: Colors.white,

                                    //add prefix icon
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),

                                    fillColor: Colors.grey,

                                    hintText: "Discount Code",

                                    //make hint text
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontFamily: "verdana_regular",
                                      fontWeight: FontWeight.w400,
                                    ),
                                    label: Text(
                                      'Discount Code',
                                      style: TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          56,
                                          159,
                                          196,
                                        ),
                                        fontSize: 16,
                                        fontFamily: "verdana_regular",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontFamily: "verdana_regular",
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: GestureDetector(
                                  onTap: () {
                                    _dis_code = discountControler.text;
                                    checkAmount();
                                  },
                                  child: Card(
                                    color: Color(0xff0081B9),
                                    child: Padding(
                                      padding: const EdgeInsets.all(13),
                                      child: Center(
                                        child: Text(
                                          "Apply",
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            controller: first_name,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 103, 103, 103),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              focusColor: Colors.white,

                              //add prefix icon
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              fillColor: Colors.grey,

                              hintText: "First Name",

                              //make hint text
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),

                              //create lable
                              labelText: 'First Name',
                              //lable style
                              labelStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: last_name,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 103, 103, 103),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              focusColor: Colors.white,

                              //add prefix icon
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              fillColor: Colors.grey,

                              hintText: "Last Name",

                              //make hint text
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),

                              //create lable
                              labelText: 'Last Name',
                              //lable style
                              labelStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: phone,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.color7E7E7E,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              focusColor: Colors.white,

                              //add prefix icon
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              fillColor: Colors.grey,

                              hintText: "Phone #",

                              //make hint text
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),

                              //create lable
                              labelText: 'Phone #',
                              //lable style
                              labelStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 103, 103, 103),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              focusColor: Colors.white,

                              //add prefix icon
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              fillColor: Colors.grey,

                              hintText: "Email",

                              //make hint text
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),

                              //create lable
                              labelText: 'Email',
                              //lable style
                              labelStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "verdana_regular",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          _sub_amount != null
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              Colors.green,
                                            ),
                                      ),
                                      onPressed: paying,
                                      child: Text(
                                        'Continue',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Row(),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: Constants.padding,
                    right: Constants.padding,
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: Constants.avatarRadius,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(Constants.avatarRadius),
                        ),
                        child: Image.asset("assets/images/chapa.png"),
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

  paying() {
    showDialog(
      barrierDismissible: false,

      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              Container(
                margin: EdgeInsets.only(left: 7),
                child: Text("Loading..."),
              ),
            ],
          ),
        );
      },
    );
    String datetime = DateTime.now().toString();
    datetime = datetime.replaceAll('-', '');
    datetime = datetime.replaceAll(':', '');
    datetime = datetime.replaceAll('.', '');
    datetime = datetime.replaceAll(' ', '');

    ref_no =
        'subscpay' +
        random.nextInt(10).toString() +
        'sid' +
        datetime +
        random.nextInt(100).toString();
    Provider.of<RefData>(context, listen: false).setSubRef(ref_no);
    Provider.of<RefData>(context, listen: false).setDis(_dis_code);
    Provider.of<RefData>(
      context,
      listen: false,
    ).saveCredintial(first_name.text, last_name.text, email.text, phone.text);
    print(ref_no);
    Chapa.paymentParameters(
      context: context, // context
      publicKey: 'CHAPUBK-Yi1zAN9XeIiwfAMxWSHWuqMcEJZzVf2z',
      currency: 'ETB',
      phone: '${phone.text}',
      amount: '${_sub_amount}',
      email: email.text,
      firstName: first_name.text,
      lastName: last_name.text,
      txRef: ref_no!,
      title: 'Subscription',
      desc: 'El-Test subscription',
      namedRouteFallBack: '/subsc', // fall back route name
      nativeCheckout: true,
      showPaymentMethodsOnGridView: true,
      onPaymentFinished: (message, reference, amount) {
        Navigator.pop(context);
      }, // fall back route name
    );

    setState(() {
      isloading = false;
    });
  }
}

class Constants {
  Constants._();
  static const double padding = 20;
  static const double avatarRadius = 45;
}
