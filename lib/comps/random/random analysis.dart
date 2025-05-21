import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:eltest_exit/theme/app_theme.dart';


import '../../models/exam_model.dart';
import '../circle_progress.dart';

class RandomResultMainScreen extends StatefulWidget {
  RandomResultMainScreen(
      {Key? key,
      required this.right,
      required this.wrong,
      required this.questions})
      : super(key: key);
  List right;
  Map wrong;
  List<QuestionModel> questions = [];

  @override
  State<RandomResultMainScreen> createState() => _RandomResultMainScreenState();
}

class _RandomResultMainScreenState extends State<RandomResultMainScreen> {
  bool isLoading = true;
  double perc = 0;
  List<Map<String, dynamic>> maps = [];

  @override
  void initState() {
    super.initState();
    getPerc();
  }

  getPerc() {
    setState(() {
      perc = (widget.right.length / widget.questions.length) * 100;
    });

    print(perc);
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        backgroundColor: Color(0xffF2F5F8),
        body: SingleChildScrollView(
          child: Visibility(
            visible: isLoading,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Result Statistics',
                      style: TextStyle(
                        color: Color(0xff21205A),
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                CircularProgressForResult(
                    perc, widget.right.length, widget.questions.length),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "You have got ${widget.right.length} questions Right",
                              style: const TextStyle(
                                color: Color(0xff21205A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${((widget.right.length / widget.questions.length) * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        child: LinearPercentIndicator(
                          width: devWidth - 30,
                          animation: true,
                          lineHeight: 10,
                          animationDuration: 1000,
                          percent: widget.right.length / widget.questions.length,
                          barRadius: const Radius.circular(10),
                          progressColor: Colors.green,
                          backgroundColor: const Color.fromARGB(116, 90, 89, 89),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "You have got ${widget.wrong.length} questions Wrong",
                              style: const TextStyle(
                                color: Color(0xff21205A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${((widget.wrong.length / widget.questions.length) * 100).toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: AppTheme.red,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        child: LinearPercentIndicator(
                          width: devWidth - 30,
                          animation: true,
                          lineHeight: 10.0,
                          animationDuration: 1000,
                          percent: widget.wrong.length / widget.questions.length,
                          barRadius: const Radius.circular(10),
                          progressColor: Colors.red,
                          backgroundColor: const Color.fromARGB(116, 90, 89, 89),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${widget.questions.length - (widget.right.length + widget.wrong.length)} question left unanswered",
                              style: const TextStyle(
                                color: Color(0xff21205A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${(((widget.questions.length - (widget.right.length + widget.wrong.length)) / widget.questions.length) * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                color: Color(0xff0081B9),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        child: LinearPercentIndicator(
                          width: devWidth - 30,
                          animation: true,
                          lineHeight: 10.0,
                          animationDuration: 1000,
                          percent: (widget.questions.length -
                                  (widget.right.length + widget.wrong.length)) /
                              widget.questions.length,
                          barRadius: const Radius.circular(10),
                          progressColor: const Color(0xff0081B9),
                          backgroundColor: const Color.fromARGB(116, 90, 89, 89),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
