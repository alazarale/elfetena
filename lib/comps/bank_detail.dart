import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'home_nav.dart';
import 'provider/auth.dart';
import 'service/common.dart';
import 'dart:convert';
import 'package:path/path.dart' as Path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:eltest_exit/theme/app_theme.dart';

final kHintTextStyle = TextStyle(
  color: AppTheme.color7E7E7E,
  fontFamily: 'OpenSans',
);

final kLabelStyle = TextStyle(
  color: AppTheme.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

final kBoxDecorationStyle = BoxDecoration(
  color: AppTheme.colorE1E9F9,
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: [
    BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2)),
  ],
);

class BankDetailScreen extends StatefulWidget {
  const BankDetailScreen({Key? key}) : super(key: key);

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen> {
  String? _title;
  String? _bnk;
  bool isLoading = true;
  bool isLoading2 = true;
  bool isLoading_s = true;
  String? _acc_num;
  String? _acc_name;
  String _dis_code = 'no';
  int? _sub_amount;
  TextEditingController discountControler = TextEditingController();
  TextEditingController discountControler2 = TextEditingController();
  final _transIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  FilePickerResult? result;
  PlatformFile? file;

  String? _token;

  final ScrollController cont2 = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _title = arguments['title'];
    _bnk = arguments['bank'];
    _token = Provider.of<Auth>(context, listen: false).token;
    checkAccount();
    checkAmount();
  }

  checkAccount() async {
    setState(() {
      isLoading = false;
    });
    final response = await http.post(
      Uri.parse('${main_url}/api/bank/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'bank': _bnk}),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      _acc_name = jsonDecode(json)['name'];
      _acc_num = jsonDecode(json)['number'];
    } else {
      if (response.reasonPhrase == "Unauthorized") {
        print('una');
      }
    }
    setState(() {
      isLoading = true;
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
        setState(() {
          _dis_code = "no";
        });
      }
    }
    setState(() {
      isLoading2 = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      isLoading_s = false;
    });
    print('start');
    var headers = {'Authorization': 'Bearer $_token'};
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$main_url/api/sub-req/'),
    );
    request.fields.addAll({
      'code': discountControler2.text,
      'trans_id': _transIdController.text,
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      setState(() {
        isLoading = true;
      });
      Provider.of<Auth>(context, listen: false).set_waiting();
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
                'Successfully Submitted. We will approve you as soon as possible. Thank you for using!',
                style: TextStyle(color: Color(0xff0081B9), fontSize: 14),
              ),
            ],
          ),
        ),
        btnOkText: 'OK',
        btnOkOnPress: () {
          Navigator.pushAndRemoveUntil<dynamic>(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => HomeNavigator(),
            ),
            (route) => false,
          );
        },
      )..show();
    } else {
      print(response.statusCode);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                'Failed to send. Please Try again later.',
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
    }
    setState(() {
      isLoading_s = true;
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
              color: AppTheme.white,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_sharp,
                size: 20,
                color: AppTheme.color0081B9,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.colorF2F5F8,
        title: Center(
          child: Text(
            "${_title}",
            style: TextStyle(
              color: AppTheme.color21205A,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: AppTheme.colorF2F5F8,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: AppTheme.colorDDF0E6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          text:
                              'Pay using the bellow credential in your nearest ',
                          style: TextStyle(
                            color: AppTheme.color28A164,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${_title} ',
                              style: TextStyle(
                                color: AppTheme.color186F44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: 'branch or using '),
                            TextSpan(
                              text: 'mobile banking.\n\n ',
                              style: TextStyle(
                                color: AppTheme.color186F44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'After making the payment click the ',
                            ),
                            TextSpan(
                              text: 'PAID ',
                              style: TextStyle(
                                color: AppTheme.color186F44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'button below and send the TRANSACTION ID/REF found on the receipt. We will authenticate the receipt and give you access within 30 minutes to an hour. For more information, join our social media channels. \n\nFor immediate authentication you can use ',
                            ),
                            TextSpan(
                              text: 'Telebirr ',
                              style: TextStyle(
                                color: AppTheme.color186F44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: 'from payment choices.'),
                          ],
                        ),
                      ),
                      Text(''),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              'Account #: ',
                              style: TextStyle(
                                color: AppTheme.color005275,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Visibility(
                              visible: isLoading,
                              child: Text(
                                '${_acc_num}',
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              replacement: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              'Name: ',
                              style: TextStyle(
                                color: AppTheme.color005275,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Visibility(
                              visible: isLoading,
                              child: Text(
                                '${_acc_name}',
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              replacement: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              'Amount to be paid: ',
                              style: TextStyle(
                                color: AppTheme.color005275,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Visibility(
                              visible: isLoading2,
                              child: Text(
                                '${_sub_amount} birr',
                                style: TextStyle(
                                  color: AppTheme.color0081B9,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              replacement: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              'Discount code: ',
                              style: TextStyle(
                                color: AppTheme.color005275,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            _dis_code != "no"
                                ? Text(
                                  '${_dis_code}',
                                  style: TextStyle(
                                    color: AppTheme.color0081B9,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19,
                                    decoration: TextDecoration.underline,
                                  ),
                                )
                                : Text(''),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: discountControler,
                              decoration: const InputDecoration(
                                fillColor: AppTheme.white,
                                filled: true,
                                hintText: "Discount code",
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 17,
                                  horizontal: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  //Outline border type for TextFeild
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(1),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.white,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.white,
                                    width: 2,
                                  ),
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
                                color: AppTheme.color0081B9,
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Center(
                                    child: Text(
                                      "Apply",
                                      style: TextStyle(
                                        color: AppTheme.white,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.color0081B9,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder:
                    (BuildContext context, setState) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: cont2,
                        radius: Radius.circular(20),
                        thickness: 5,
                        trackVisibility: true,
                        interactive: true,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center, //content alignment to center
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Finished Payment',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  20,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Look for TRANSACTION ID/REF in the Receipt and send it here. If you used mobile banking, You will find the Transaction ID in payment complete page.\n If you used discount code, don\'t forget to apply it above.',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Transaction ID/REF',
                                        style: kLabelStyle,
                                      ),
                                      SizedBox(height: 10.0),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        decoration: kBoxDecorationStyle,
                                        height: 60.0,
                                        child: TextFormField(
                                          controller: _transIdController,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Required';
                                            }
                                          },
                                          style: TextStyle(
                                            color: AppTheme.color7E7E7E,
                                            fontFamily: 'OpenSans',
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(
                                              left: 14.0,
                                            ),

                                            hintText: 'Transaction ID/REF',
                                            hintStyle: kHintTextStyle,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.0),
                                      Text(
                                        'Discount Code(If used):',
                                        style: kLabelStyle,
                                      ),
                                      SizedBox(height: 10.0),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        decoration: kBoxDecorationStyle,
                                        height: 60.0,
                                        child: TextFormField(
                                          controller: discountControler2,
                                          style: TextStyle(
                                            color: AppTheme.color7E7E7E,
                                            fontFamily: 'OpenSans',
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(
                                              left: 14.0,
                                            ),

                                            hintText: 'Discount Code',
                                            hintStyle: kHintTextStyle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: isLoading_s,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isLoading_s = false;
                                          });
                                          _submit().then((value) {
                                            setState(() {
                                              isLoading_s = true;
                                            });
                                          });
                                        },
                                        child: Text(
                                          'SUBMIT',
                                          style: TextStyle(
                                            color: AppTheme.color0081B9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ), // <-- Text
                                      ),
                                      replacement: CircularProgressIndicator(
                                        color: AppTheme.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              );
            },
          );
        },
        label: Text("PAID"),
        backgroundColor: AppTheme.color0081B9,
        foregroundColor: AppTheme.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget fileDetails(PlatformFile file, double devWid) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: devWid - 150,
        child: Text(
          '${file.name}',
          style: TextStyle(color: AppTheme.white),
          maxLines: 3,
          textAlign: TextAlign.justify,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void pickFiles() async {
    result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    setState(() {
      file = result!.files.first;
    });

    setState(() {});
  }
}
