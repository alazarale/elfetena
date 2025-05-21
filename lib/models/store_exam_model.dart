// To parse this JSON data, do
//
//     final storeExamModel = storeExamModelFromJson(jsonString);

import 'dart:convert';

List<StoreExamModel> storeExamModelFromJson(String str) =>
    List<StoreExamModel>.from(
        json.decode(str).map((x) => StoreExamModel.fromJson(x)));

String storeExamModelToJson(List<StoreExamModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class StoreExamModel {
  StoreExamModel({
    required this.id,
    required this.name,
    required this.sub,
    required this.noQues,
    required this.price,
    required this.isNew,
  });

  int id;
  String name;
  String sub;
  int noQues;
  double price;
  String isNew;

  factory StoreExamModel.fromJson(Map<String, dynamic> json) => StoreExamModel(
      id: json["id"],
      name: json["name"],
      sub: json["sub"],
      noQues: json["no_ques"],
      price: json['price'],
      isNew: json['is_new'],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "sub": sub,
        "no_ques": noQues,
        'price': price,
        'is_new': isNew,
      };
}
