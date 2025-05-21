import 'dart:convert';

List<ChapterModel> chapterModelFromJson(String str) => List<ChapterModel>.from(json.decode(str).map((x) => ChapterModel.fromJson(x)));

String chapterModelToJson(List<ChapterModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ChapterModel {
    ChapterModel({
        required this.id,
        required this.name,
        required this.unit,
    });

    int id;
    String name;
    String unit;

    factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
        id: json["id"],
        name: json["name"],
        unit: json["unit"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "unit": unit,
    };
}
