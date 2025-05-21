// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:chapasdk/chapasdk.dart';
import 'package:provider/provider.dart';

import 'provider/strored_ref.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'service/common.dart';

class FeedbackDialogBox extends StatefulWidget {
  FeedbackDialogBox({Key? key, required this.examTitle})
      : super(key: key);
  String? examTitle;

  @override
  _FeedbackDialogBoxState createState() => _FeedbackDialogBoxState();
}

class _FeedbackDialogBoxState extends State<FeedbackDialogBox> {
  TextEditingController first_name = TextEditingController();
  TextEditingController last_name = TextEditingController();
  TextEditingController email = TextEditingController();

  bool isloading = true;
  String? ref_no;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Visibility(
        visible: isloading,
        child: contentBox(context),
        replacement: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: Constants.padding,
              top: Constants.avatarRadius + Constants.padding,
              right: Constants.padding,
              bottom: Constants.padding),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: SingleChildScrollView(
            child: Visibility(
              visible: isloading,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Send Your Feedback.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 103, 103, 103),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      fillColor: Colors.grey,

                      hintText: "Name",

                      //make hint text
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),

                      //create lable
                      labelText: 'Name',
                      //lable style
                      labelStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      fillColor: Colors.grey,

                      hintText: "Question #",

                      //make hint text
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),

                      //create lable
                      labelText: 'Question #',
                      //lable style
                      labelStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      fillColor: Colors.grey,

                      hintText: "Feedback",

                      //make hint text
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),

                      //create lable
                      labelText: 'Feedback',
                      //lable style
                      labelStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: "verdana_regular",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.green),
                            ),
                            onPressed: sendExam,
                            child: Text(
                              'Send',
                              style: TextStyle(fontSize: 18),
                            )),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: 18),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
              replacement: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  sendExam() async {
    setState(() {
      isloading = false;
    });
    String comm = 'Title: ' + widget.examTitle! + ', Question #: ' + email.text;

    final response = await http.post(
      Uri.parse('${main_url}/api/exam/comment/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': first_name.text + ', ' + email.text,
        'comment': comm + " Feedback: " + last_name.text
      }),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      setState(() {
        isloading = true;
      });
      
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.bottomSlide,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                'We have recieved your feedback. We will Act on your feedback as soon as posible. Thank you!',
                style: TextStyle(color: Color(0xff0081B9), fontSize: 14),
              ),
            ],
          ),
        ),
        btnOkText: 'OK',
        btnOkOnPress: () {
          Navigator.pop(context);
          
        },
      )..show();
    } else {
      print(response.reasonPhrase);
    }
  }
}

class Constants {
  Constants._();
  static const double padding = 20;
  static const double avatarRadius = 45;
}
