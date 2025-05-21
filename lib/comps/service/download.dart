import 'dart:convert';

import 'package:eltest_exit/comps/service/database_manipulation.dart';
import 'package:eltest_exit/comps/service/remote_services.dart';
import 'package:eltest_exit/models/store_question_model.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadExam {
  int id;
  String paymRef;
  BuildContext context;
  DownloadExam(this.id, this.paymRef, this.context);

  getQuestions() async {
    Map<String, dynamic>? questions;
    print(paymRef);
    questions = await ExamQuestionFetch(id, paymRef, context).getExams();

    if (questions != null) {
      await addDataToDatabase(questions); // Calls the internal insertion logic
      // print('Data from asset "$assetPath" inserted successfully.');
    } else {
      print('Failed to fetch questions.');
    }
  }

  Future<void> addDataToDatabase(Map<String, dynamic> jsonData) async {
    try {
      final dbHelper = DatabaseHelper();
      final Database db = await dbHelper.database; // Get the database instance

      // Load the additional JSON data from an asset

      // Insert the data into the database
      await dbHelper.insertDataFromJson(db, jsonData);

      print('Additional data inserted successfully!');
    } catch (e) {
      print('Error loading or inserting additional data: $e');
    }
  }
}

class SubscDownloadExam {
  int id;
  String token;
  BuildContext context;
  SubscDownloadExam(this.id, this.token, this.context);

  getQuestions() async {
    Map<String, dynamic>? questions;
    questions = await SubscExamQuestionFetch(id, token, context).getExams();

    if (questions != null) {
      await addDataToDatabase(questions); // Calls the internal insertion logic
      // print('Data from asset "$assetPath" inserted successfully.');
    }
  }

  Future<void> addDataToDatabase(Map<String, dynamic> jsonData) async {
    try {
      final dbHelper = DatabaseHelper();
      final Database db = await dbHelper.database; // Get the database instance

      // Load the additional JSON data from an asset

      // Insert the data into the database
      await dbHelper.insertDataFromJson(db, jsonData);

      Navigator.of(context).pop();
      Navigator.popAndPushNamed(context, "/");
    } catch (e) {
      print('Error loading or inserting additional data: $e');
    }
  }
}

class LocalDownloadExam {
  BuildContext context;
  LocalDownloadExam(this.context);

  late Database db;
  List code = [];
  addExam(questions) async {
    var exam = await db.insert('exam', {
      'name': questions.name,
      'subject': questions.subject,
      'time': questions.time,
      'code': 'cd${questions.code.toString()}',
      'grade': questions.grade,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return exam;
  }

  getQuestions() async {
    QuestionDownloadModel? questions;
    // questions = await SubscExamQuestionFetch(id, token, context).getExams();
    // print(questions);

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "elexam.db");

    db = await openDatabase(path, version: 1);

    var chaps_list = [];
    final List<Map<String, dynamic>> chaps = await db.query('chapter');

    chaps.forEach((element) {
      chaps_list.add(element['id']);
    });

    List<Map<String, dynamic>> maps = await db.query('exam');
    maps = List.from(maps.reversed);
    List.generate(maps.length, (i) {
      code.add(maps[i]['code']);
    });
    print(code);
    print('dfd');
    if (code != null) {
      if (!code.contains("cd32")) {
        QuestionDownloadModel? mathQuestions;
        String data = await DefaultAssetBundle.of(
          context,
        ).loadString("assets/maths.json");
        if (data != '') {
          mathQuestions = questionDownloadModelFromJson(data);
          if (mathQuestions != null) {
            Batch batch = db.batch();
            addExam(mathQuestions).then((value) {
              mathQuestions?.questions.forEach((element) {
                if (!chaps_list.contains(element.chapter.id)) {
                  batch.insert('chapter', {
                    'id': element.chapter.id,
                    'grade': element.chapter.grade,
                    'subject': mathQuestions?.subject,
                    'name': element.chapter.name,
                    'unit': element.chapter.unit,
                  });
                  chaps_list.add(element.chapter.id);
                }
                batch.insert('question', {
                  'exam': value,
                  'ques': element.ques,
                  'a': element.choiceA,
                  'b': element.choiceB,
                  'c': element.choiceC,
                  'd': element.choiceD,
                  'ans': element.ans,
                  'image': element.imageN,
                  'chapter': element.chapter.id,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              });
            });
            await batch.commit(noResult: true);
          } else {
            return 'failed';
          }
        }
      }
      if (!code.contains("cd11")) {
        QuestionDownloadModel? hisQuestions;
        String data = await DefaultAssetBundle.of(
          context,
        ).loadString("assets/hist.json");
        if (data != '') {
          hisQuestions = questionDownloadModelFromJson(data);
          if (hisQuestions != null) {
            Batch batch = db.batch();
            addExam(hisQuestions).then((value) {
              hisQuestions?.questions.forEach((element) {
                if (!chaps_list.contains(element.chapter.id)) {
                  batch.insert('chapter', {
                    'id': element.chapter.id,
                    'grade': element.chapter.grade,
                    'subject': hisQuestions?.subject,
                    'name': element.chapter.name,
                    'unit': element.chapter.unit,
                  });
                  chaps_list.add(element.chapter.id);
                }
                batch.insert('question', {
                  'exam': value,
                  'ques': element.ques,
                  'a': element.choiceA,
                  'b': element.choiceB,
                  'c': element.choiceC,
                  'd': element.choiceD,
                  'ans': element.ans,
                  'image': element.imageN,
                  'chapter': element.chapter.id,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              });
            });
            await batch.commit(noResult: true);
          } else {
            return 'failed';
          }
        }
      }
    }

    // if (questions != null) {
    //   print(questions);
    //   Batch batch = db.batch();
    //   addExam(questions).then((value) {
    //     questions?.questions.forEach((element) {
    //       if (!chaps_list.contains(element.chapter.id)) {
    //         batch.insert(
    //           'chapter',
    //           {
    //             'id': element.chapter.id,
    //             'grade': element.chapter.grade,
    //             'subject': questions?.subject,
    //             'name': element.chapter.name,
    //             'unit': element.chapter.unit
    //           },
    //         );
    //         chaps_list.add(element.chapter.id);
    //       }
    //       batch.insert(
    //         'question',
    //         {
    //           'exam': value,
    //           'ques': element.ques,
    //           'a': element.choiceA,
    //           'b': element.choiceB,
    //           'c': element.choiceC,
    //           'd': element.choiceD,
    //           'ans': element.ans,
    //           'image': element.imageN,
    //           'chapter': element.chapter.id
    //         },
    //         conflictAlgorithm: ConflictAlgorithm.replace,
    //       );
    //     });
    //   });
    //   await batch.commit(noResult: true);
    // } else {
    //   return 'failed';
    // }
  }
}
