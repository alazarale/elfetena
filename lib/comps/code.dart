import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'provider/auth.dart';
import 'service/common.dart';

class SubsData {
  SubsData(this._name, this._total);
  String _name;
  int _total;
  String _bank_stat = 'no';

  String get name {
    return _name;
  }

  int get total {
    return _total;
  }
}

class TransData {
  TransData(this._created, this._amount);
  String _created;
  String _amount;

  String get created {
    return _created;
  }

  String get amount {
    return _amount;
  }
}

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  bool isLoading = true;
  bool isLoading2 = true;
  bool isLoading3 = true;
  String? _token;
  List<SubsData> _all_data = [];
  List<TransData> _all_trans = [];
  String? _bank_name;
  String? _acc_no;
  int? _tot_sub;
  int _left = 0;
  int? _tot_made;
  String? _trans_stat;
  String? is_bank;
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController _noController = new TextEditingController();
  TextEditingController _bankController = new TextEditingController();
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
    _token = Provider.of<Auth>(context, listen: false).token;
    checkSubs();
    checkBank();
    transHis();
    // This widget is the root of your application.
  }

  checkSubs() async {
    setState(() {
      isLoading = false;
    });
    var headers = {'Authorization': 'Bearer $_token'};
    var request = http.Request('GET', Uri.parse('$main_url/api/user-disc/'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await response.stream.bytesToString().then((value) {
        Map json = jsonDecode(value);
        print(json);
        _tot_sub = json['tot'];
        _tot_made = json['tot_money'];
        _left = json['left'];
        json['codes'].keys.forEach((element) {
          _all_data.add(SubsData(element, json['codes'][element]['total']));
        });
        setState(() {});
        print(_all_data);
      });
    } else {
      print(response.reasonPhrase);
    }

    setState(() {
      isLoading = true;
    });
  }

  checkBank() async {
    setState(() {
      isLoading2 = false;
    });
    var headers = {'Authorization': 'Bearer $_token'};
    var request =
        http.MultipartRequest('GET', Uri.parse('$main_url/api/user-bank-get/'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await response.stream.bytesToString().then((value) {
        Map json = jsonDecode(value);
        print(json);
        _bank_name = json['bank'];
        _acc_no = json['acc_no'];
        _trans_stat = json['stat'];
        is_bank = 'yes';
        setState(() {});
        print(_all_data);
      });
    } else {
      if (response.reasonPhrase == "Not Found") {
        is_bank = 'no';
      }
    }
    setState(() {
      isLoading2 = true;
    });
  }

  transReq() async {
    var headers = {'Authorization': 'Bearer $_token'};
    var request =
        http.MultipartRequest('GET', Uri.parse('$main_url/api/trans-req/'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        _trans_stat = 'pend';
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  bankSubmit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      isLoading3 = false;
    });
    var headers = {'Authorization': 'Bearer $_token'};
    var request =
        http.MultipartRequest('POST', Uri.parse('$main_url/api/user-bank/'));
    request.fields.addAll(
      {
        'acc': _noController.text,
        'name': _bankController.text,
      },
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      checkBank();
    } else {
      print(response.reasonPhrase);
    }
    Navigator.pop(context);
  }

  transHis() async {
    var headers = {'Authorization': 'Bearer $_token'};
    var request =
        http.MultipartRequest('GET', Uri.parse('$main_url/api/trans-his/'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await response.stream.bytesToString().then(
        (value) {
          List json = jsonDecode(value);
          json.forEach((element) {
            _all_trans.add(
              TransData(element['created'], element['amount']),
            );
          });
          print(_all_trans);
        },
      );
    } else {
      print(response.reasonPhrase);
    }
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
              "El-Test",
              style: TextStyle(
                color: const Color(0xff21205A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 246, 246, 246),
        body: SingleChildScrollView(
          child: _all_data.length == 0
              ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Visibility(
                        visible: isLoading,
                        replacement: CircularProgressIndicator(),
                        child: Text('You are not registered for this service.'),
                      ),
                    ),
                  ),
                ],
              )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: is_bank == 'no'
                          ? ElevatedButton(
                              child: Text("Add Bank Account"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 0, 114, 163),
                                elevation: 0,
                              ),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        scrollable: true,
                                        title: Text('Add Bank Account'),
                                        content: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Visibility(
                                            visible: isLoading3,
                                            replacement:
                                                CircularProgressIndicator(),
                                            child: Form(
                                              key: _formKey,
                                              child: Column(
                                                children: <Widget>[
                                                  Text('Bank: CBE'),
                                                  TextFormField(
                                                    controller: _noController,
                                                    validator: (value) {
                                                      if (value!.isEmpty) {
                                                        return 'Required';
                                                      }
                                                    },
                                                    decoration: InputDecoration(
                                                      labelText: 'Account #',
                                                      icon: Icon(Icons.numbers),
                                                    ),
                                                  ),
                                                  TextFormField(
                                                    controller: _bankController,
                                                    validator: (value) {
                                                      if (value!.isEmpty) {
                                                        return 'Required';
                                                      }
                                                    },
                                                    decoration: InputDecoration(
                                                      labelText: 'Holder Name',
                                                      icon: Icon(
                                                          Icons.account_box),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            child: Text("Submit"),
                                            onPressed: () {
                                              bankSubmit();
                                            },
                                          ),
                                        ],
                                      );
                                    });
                              },
                            )
                          : Container(
                              width: devWidth - 30,
                              height: 180,
                              child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  color: Color.fromARGB(255, 0, 82, 117),
                                  elevation: 10,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Account #: ",
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 22,
                                              ),
                                            ),
                                            Visibility(
                                              visible: isLoading2,
                                              replacement:
                                                  CircularProgressIndicator(),
                                              child: Text(
                                                '$_acc_no',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 214, 214, 214),
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            15, 0, 15, 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Bank: ",
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 22,
                                              ),
                                            ),
                                            Visibility(
                                              visible: isLoading2,
                                              replacement:
                                                  CircularProgressIndicator(),
                                              child: Text(
                                                '$_bank_name',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 214, 214, 214),
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _left > 0
                                          ? _trans_stat == 'pend'
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          15, 0, 15, 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Color.fromARGB(
                                                              255, 0, 114, 163),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .fromLTRB(
                                                                  30,
                                                                  15,
                                                                  30,
                                                                  15),
                                                          child: Text(
                                                            'Transfer Pending...',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          15, 0, 15, 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                        child: Text(
                                                            "Request Transfer"),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Color.fromARGB(
                                                                  255,
                                                                  0,
                                                                  114,
                                                                  163),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () {
                                                          transReq();
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                )
                                          : Text(''),
                                    ],
                                  )),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        width: devWidth - 30,
                        child: SingleChildScrollView(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: Color.fromARGB(255, 0, 82, 117),
                            elevation: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Balance',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 214, 214, 214),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Visibility(
                                      visible: isLoading,
                                      child: Text(
                                        '$_left birr',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 25,
                                        ),
                                      ),
                                      replacement: CircularProgressIndicator(),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Divider(
                                    color: Color.fromARGB(
                                        255, 0, 73, 104), //color of divider
                                    height: 5, //height spacing of divider
                                    thickness: 3, //thickness of divier line
                                    //spacing at the start of divider
                                    endIndent:
                                        10, //spacing at the end of divider
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Total Subscribers',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 214, 214, 214),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Visibility(
                                              visible: isLoading,
                                              child: Text(
                                                '$_tot_sub',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255),
                                                  fontSize: 20,
                                                ),
                                              ),
                                              replacement:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'Total Earning',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 214, 214, 214),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Visibility(
                                              visible: isLoading,
                                              child: Text(
                                                '$_tot_made birr',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255),
                                                  fontSize: 20,
                                                ),
                                              ),
                                              replacement:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Divider(
                                    color: Color.fromARGB(
                                        255, 0, 73, 104), //color of divider
                                    height: 5, //height spacing of divider
                                    thickness: 3, //thickness of divier line
                                    //spacing at the start of divider
                                    endIndent:
                                        10, //spacing at the end of divider
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sub. Code',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 181, 181, 181),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '# of Subscribers',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 181, 181, 181),
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                  Visibility(
                                    visible: isLoading,
                                    replacement: CircularProgressIndicator(),
                                    child: SizedBox(
                                      child: ListView.builder(
                                        itemCount: _all_data.length,
                                        shrinkWrap: true,
                                        physics: const ScrollPhysics(),
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${_all_data[index].name}',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  '${_all_data[index].total}',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ],
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
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        width: devWidth - 30,
                        child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: Color.fromARGB(255, 0, 82, 117),
                            elevation: 10,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    "Transfer history",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 22),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Date',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 181, 181, 181),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'amount',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 181, 181, 181),
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Visibility(
                                    visible: isLoading,
                                    replacement: CircularProgressIndicator(),
                                    child: SizedBox(
                                      child: ListView.builder(
                                        itemCount: _all_trans.length,
                                        shrinkWrap: true,
                                        physics: const ScrollPhysics(),
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${_all_trans[index].created}',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  '${_all_trans[index].amount} birr',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ),
                  ],
                ),
        ));
  }
}
