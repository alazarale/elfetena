import 'dart:convert';

QuestionDownloadModel questionDownloadModelFromJson(String str) =>
    QuestionDownloadModel.fromJson(json.decode(str));

String questionDownloadModelToJson(QuestionDownloadModel data) =>
    json.encode(data.toJson());

class QuestionDownloadModel {
  QuestionDownloadModel({
    required this.name,
    required this.time,
    required this.subject,
    required this.code,
    required this.grade,
    required this.price,
    required this.questions,
  });

  String name;
  int time;
  int subject;
  int code;
  String grade;
  double price;
  List<Question> questions;

  factory QuestionDownloadModel.fromJson(Map<String, dynamic> json) =>
      QuestionDownloadModel(
        name: json["name"],
        time: json["time"],
        subject: json["subject"],
        code: json["code"],
        grade: json['grade'],
        price: json['price'],
        questions: List<Question>.from(
            json["questions"].map((x) => Question.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "time": time,
        "subject": subject,
        'code': code,
        'grade': grade,
        'price': price,
        "questions": List<dynamic>.from(questions.map((x) => x.toJson())),
      };
}

class Question {
  Question({
    required this.ques,
    required this.choiceA,
    required this.choiceB,
    required this.choiceC,
    required this.choiceD,
    required this.ans,
    this.imageN,
    required this.chapter,
  });

  String ques;
  String choiceA;
  String choiceB;
  String choiceC;
  String choiceD;
  String ans;
  String? imageN;
  Chapter chapter;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        ques: json["ques"],
        choiceA: json["choice_a"],
        choiceB: json["choice_b"],
        choiceC: json["choice_c"],
        choiceD: json["choice_d"],
        ans: json["ans"],
        imageN: json['image'],
        chapter: Chapter.fromJson(json["chapter"]),
      );

  Map<String, dynamic> toJson() => {
        "ques": ques,
        "choice_a": choiceA,
        "choice_b": choiceB,
        "choice_c": choiceC,
        "choice_d": choiceD,
        "ans": ans,
        "image": imageN,
        "chapter": chapter.toJson(),
      };
}

class Chapter {
  Chapter({
    required this.id,
    required this.grade,
    required this.name,
    required this.unit,
  });

  int id;
  int grade;
  String name;
  String unit;

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json["id"],
        grade: json["grade"],
        name: json["name"],
        unit: json["unit"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "grade": grade,
        "name": name,
        "unit": unit,
      };
}
