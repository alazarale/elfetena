// To parse this JSON data, do
//
//     final national = nationalFromJson(jsonString);

import 'dart:convert';

List<National> nationalFromJson(String str) => List<National>.from(json.decode(str).map((x) => National.fromJson(x)));

String nationalToJson(List<National> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class National {
    int id;
    String creatorName;
    String name;

    National({
        required this.id,
        required this.creatorName,
        required this.name,
    });

    factory National.fromJson(Map<String, dynamic> json) => National(
        id: json["id"],
        creatorName: json["creator_name"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "creator_name": creatorName,
        "name": name,
    };
}
