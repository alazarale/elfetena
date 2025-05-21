import 'dart:convert';
import 'package:eltest_exit/models/chapter_model.dart';
import 'package:eltest_exit/models/exam_model.dart';
import 'package:eltest_exit/models/store_national.dart';
import 'package:eltest_exit/models/subject_model.dart';
import 'package:flutter/material.dart';
import 'package:eltest_exit/models/store_exam_model.dart';
import 'package:eltest_exit/models/store_question_model.dart';
import 'package:http/http.dart' as http;
import 'package:eltest_exit/theme/app_theme.dart';
import 'common.dart';

class ExamsFetch {
  Future<List<StoreExamModel>?> getExams() async {
    var client = http.Client();
    var url = Uri.parse('${main_url}/api/exam/');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      var json = response.body;
      return storeExamModelFromJson(json);
    } else {
      print(response.reasonPhrase);
    }
  }
}

class ExamsSearchFetch {
  Future<List<StoreExamModel>?> getExams(search, sub_id) async {
    final response = await http.post(
      Uri.parse('$main_url/api/exam/search/new/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'search': search, 'sub_id': sub_id}),
    );

    if (response.statusCode == 200) {
      var json = response.body;
      return storeExamModelFromJson(json);
    } else {
      print(response.reasonPhrase);
    }
  }
}

class ExamQuestionFetch {
  int id;
  String payRef;
  BuildContext context;
  ExamQuestionFetch(this.id, this.payRef, this.context);

  Future getExams() async {
    final response = await http.post(
      Uri.parse('${main_url}/api/exam/${id.toString()}/download/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'payRef': payRef}),
    );

    print('here');
    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      return jsonDecode(json);
    } else {
      print('jgjgiu');
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
      if (response.reasonPhrase == "Unauthorized") {
        print('una');
      }
      ;
    }
  }
}

class SubscExamQuestionFetch {
  int id;
  String token;
  BuildContext context;
  SubscExamQuestionFetch(this.id, this.token, this.context);

  Future getExams() async {
    final response = await http.post(
      Uri.parse('${main_url}/api/exam/${id.toString()}/subsc/download/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print('dsfsfsfsdfsdfsdfsdfsfsddfsfsdffsdfsdfsdfsdfsdfs');
    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      return jsonDecode(json);
    } else {
      print('sdfsdf');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Already Downloaded",
              style: TextStyle(color: AppTheme.red),
            ),
            content: Text(
              "You have already downloaded this exam before. The subscription only allows one time download.",
              style: TextStyle(color: AppTheme.red),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      );
      if (response.reasonPhrase == "Unauthorized") {}
      ;
    }
  }
}

class ChapaCallFetch {
  getExams() async {
    var headers = {
      'Authorization': 'Bearer CHASECK_TEST-SrzPfzVaXIzgI8s2PtBu59DbTUBnPLtf',
    };
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.chapa.co/v1/transaction/initialize'),
    );
    request.fields.addAll({
      'amount': ' 100',
      'currency': ' ETB',
      'email': ' abebe@bikila.com',
      'first_name': ' Abebe',
      'last_name': ' Bikila',
      'tx_ref': ' tx-myecommerceegdsdfssfdgsdfsfdfgddfgdgsdfwtert564sdf446',
      'callback_url': ' https://chapa.co',
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var json1 = await response.stream.bytesToString();
      Map json2 = json.decode(json1);
      return json2['data']['checkout_url'];
    } else {
      print(response.reasonPhrase);
    }
  }
}

class SubjectsFetch {
  Future<List<Subject>?> getsubs() async {
    var client = http.Client();
    var url = Uri.parse('${main_url}/api/exam/subjects/');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      var json = response.body;
      return subjectFromJson(json);
    } else {
      print(response.reasonPhrase);
    }
  }
}

class ChaptersFetch {
  Future<List<ChapterModel>?> getsubs(sub_id) async {
    var client = http.Client();
    var url = Uri.parse('${main_url}/api/exam/${sub_id}/chapters/');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      var json = response.body;
      return chapterModelFromJson(json);
    } else {
      print(response.reasonPhrase);
    }
  }
}

class NationalListFetch {
  Future<List<National>?> get_nationals() async {
    var client = http.Client();
    var url = Uri.parse('${main_url}/api/exam/national/');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      return nationalFromJson(json);
    } else {
      print(response.reasonPhrase);
    }
  }
}

class ListUnderNationalFetch {
  Future<List<StoreExamModel>?> get_under_nationals(nat_id) async {
    var client = http.Client();
    var url = Uri.parse('${main_url}/api/exam/national/${nat_id}');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      var json = response.body;
      print(json);
      return storeExamModelFromJson(jsonEncode(jsonDecode(json)['data']));
    } else {
      print(response.reasonPhrase);
    }
  }
}
