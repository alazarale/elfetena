import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart' as Path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

import 'provider/strored_ref.dart';

class RandomQuesSettingScreen extends StatefulWidget {
  const RandomQuesSettingScreen({super.key});

  @override
  State<RandomQuesSettingScreen> createState() =>
      _RandomQuesSettingScreenState();
}

class _RandomQuesSettingScreenState extends State<RandomQuesSettingScreen> {
  late Database db;
  Map? sub_map = {};
  Map<int, List> chap_map = {};
  bool isLoading = true;
  List sel_chap = [];
  bool is_changed = false;
  int q_no = 30;

  @override
  void initState() {
    super.initState();
    Provider.of<RefData>(context, listen: false).tryNotIncluded().then((value) {
      sel_chap = Provider.of<RefData>(context, listen: false).not_include;
    });
    Provider.of<RefData>(context, listen: false).tryNoQues().then((value) {
      q_no = Provider.of<RefData>(context, listen: false).no_ques!;
    });

    dbstat();

    // This widget is the root of your application.
  }

  dbstat() async {
    setState(() {
      isLoading = false;
    });
    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "elexam.db");

    db = await openDatabase(
      path,
      version: 1,
    );
    List<Map<String, dynamic>> subs = await db.query('subject');
    List<Map<String, dynamic>> chaps = await db.query('chapter');

    if (subs.isNotEmpty) {
      subs.forEach(
        (element) {
          sub_map?[element['id']] = element['name'];
        },
      );
      print(sub_map);
      setState(() {});
    }

    if (chaps.isNotEmpty) {
      print(chaps);
      chaps.forEach((element) {
        if (chap_map == null) {
          chap_map[element['subject']] = [element];
        } else {
          chap_map.keys.contains(element['subject'])
              ? chap_map[element['subject']]?.add(element)
              : chap_map[element['subject']] = [element];
        }
      });
      print(chap_map);
      print(chaps);
      setState(() {});
    }

    print(chap_map);

    setState(() {
      isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          is_changed
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255)),
                    child: TextButton(
                      child: Text('Save'),
                      onPressed: () {
                        Provider.of<RefData>(context, listen: false)
                            .setNotIncluded(sel_chap, q_no);

                        Navigator.pop(context);
                      },
                    ),
                  ),
                )
              : Text('')
        ],
        elevation: 1,
        backgroundColor: const Color(0xffF2F5F8),
        title: const Center(
          child: Text(
            "RQE Settings",
            style: TextStyle(
              color: const Color(0xff21205A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Random Exam Question Setting',
                style: TextStyle(
                    color: Color(0xff21205A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '# of Question per exam: ',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Color.fromARGB(255, 49, 48, 143),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${q_no.toInt()} ques.',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 40, 37, 248),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Slider(
                value: q_no.toDouble(),
                max: 100,
                divisions: 20,
                label: '$q_no',
                onChanged: (double value) {
                  setState(() {
                    q_no = value.toInt();
                    is_changed = true;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    'Chapters Included: ',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Color.fromARGB(255, 49, 48, 143),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Choose chapters you want to be included in random question exam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color.fromARGB(255, 79, 79, 79),
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isLoading,
              replacement: const CircularProgressIndicator(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: chap_map.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Container(
                        child: ExpansionTile(
                          title: Text(
                            "${sub_map?[chap_map.keys.elementAt(index)]}",
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.w500),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                itemCount:
                                    chap_map[chap_map.keys.elementAt(index)]!
                                        .length,
                                itemBuilder: (BuildContext context, int ind) {
                                  return Row(
                                    children: [
                                      Checkbox(
                                        value: !sel_chap.contains(chap_map[
                                            chap_map.keys
                                                .elementAt(index)]![ind]['id']),
                                        onChanged: (val) {
                                          setState(() {
                                            sel_chap.contains(chap_map[chap_map
                                                        .keys
                                                        .elementAt(index)]![ind]
                                                    ['id'])
                                                ? sel_chap.remove(
                                                    chap_map[chap_map.keys.elementAt(index)]![ind]
                                                        ['id'])
                                                : sel_chap.add(chap_map[chap_map
                                                        .keys
                                                        .elementAt(index)]![ind]
                                                    ['id']);
                                            is_changed = true;
                                            print(json.encode(sel_chap));
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                              '${chap_map[chap_map.keys.elementAt(index)]![ind]["unit"]} ${chap_map[chap_map.keys.elementAt(index)]![ind]["name"]}'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
