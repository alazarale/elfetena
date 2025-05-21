import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';

import '../../models/exam_model.dart';
import '../feedback_dialog.dart';
import '../service/common.dart';

class RandomQuestionAllScreen extends StatefulWidget {
  RandomQuestionAllScreen({
    Key? key,
    required this.right,
    required this.wrong,
    required this.questions,
  }) : super(key: key);
  List right;
  Map wrong;
  List<QuestionModel> questions = [];

  @override
  State<RandomQuestionAllScreen> createState() =>
      _RandomQuestionAllScreenState();
}

class _RandomQuestionAllScreenState extends State<RandomQuestionAllScreen> {
  bool isLoading = true;
  double perc = 0;
  List<Map<String, dynamic>> maps = [];
  List<TeXViewWidget> ques_tex = [];
  int q_count = 0;

  @override
  void initState() {
    super.initState();
    widget.questions.forEach((value) {
      q_count++;
      ques_tex.add(
        _teXViewWidget(
          value.ques,
          value.choiceA,
          value.choiceB,
          value.choiceC,
          value.choiceD,
          value.ans,
          q_count,
          value.imageN,
          value.id,
          widget.right,
          widget.wrong,
        ),
      );
    });
  }

  static TeXViewWidget _teXViewWidget(
    String title,
    String a,
    String b,
    String c,
    String d,
    String ans,
    int q_c,
    String? imgs,
    int q_id,
    List right,
    Map wrong,
  ) {
    return TeXViewColumn(
      style: const TeXViewStyle(
        margin: TeXViewMargin.all(10),
        padding: TeXViewPadding.all(10),
        backgroundColor: Colors.white,
        elevation: 3,
      ),
      children: [
        TeXViewDocument(
          'Question ' + q_c.toString(),
          style: TeXViewStyle(
            padding: TeXViewPadding.all(10),
            textAlign: TeXViewTextAlign.center,
            fontStyle: TeXViewFontStyle(
              fontWeight: TeXViewFontWeight.bold,
              fontSize: 20,
            ),
            contentColor: Colors.blue,
          ),
        ),
        TeXViewDocument(
          imgs == null
              ? title
              : title + '<br><img src="${main_url}$imgs" style="width: 300px">',
          style: TeXViewStyle.fromCSS(
            'overflow: scroll; padding: 15px; color: white; background: #0081B9; border-radius: 10px;',
          ),
        ),
        TeXViewDocument(
          ans == 'a'
              ? right.contains(q_id) || wrong.keys.contains(q_id)
                  ? "<div style='display: flex; color: green;'><span style='border: 1px solid green; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: green; color: white'>A</span>" +
                      a +
                      "</div>"
                  : "<div style='display: flex; color: #3275a8;'><span style='border: 1px solid #3275a8; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #3275a8; color: white'>A</span>" +
                      a +
                      "</div>"
              : wrong.keys.contains(q_id) && wrong[q_id] == 'A'
              ? "<div style='display: flex; color: red;'><span style='border: 1px solid red; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: red; color: white'>A</span>" +
                  a +
                  "</div>"
              : "<div style='display: flex; color: #757575;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>A</span>" +
                  a +
                  "</div>",
          style: const TeXViewStyle(padding: TeXViewPadding.all(15)),
        ),
        TeXViewDocument(
          ans == 'b'
              ? right.contains(q_id) || wrong.keys.contains(q_id)
                  ? "<div style='display: flex; color: green;'><span style='border: 1px solid green; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: green; color: white'>B</span>" +
                      b +
                      "</div>"
                  : "<div style='display: flex; color: #3275a8;'><span style='border: 1px solid #3275a8; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #3275a8; color: white'>B</span>" +
                      b +
                      "</div>"
              : wrong.keys.contains(q_id) && wrong[q_id] == 'B'
              ? "<div style='display: flex; color: red;'><span style='border: 1px solid red; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: red; color: white'>B</span>" +
                  b +
                  "</div>"
              : "<div style='display: flex; color: #757575;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>B</span>" +
                  b +
                  "</div>",
          style: const TeXViewStyle(padding: TeXViewPadding.all(15)),
        ),
        TeXViewDocument(
          ans == 'c'
              ? right.contains(q_id) || wrong.keys.contains(q_id)
                  ? "<div style='display: flex; color: green;'><span style='border: 1px solid green; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: green; color: white'>C</span>" +
                      c +
                      "</div>"
                  : "<div style='display: flex; color: #3275a8;'><span style='border: 1px solid #3275a8; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #3275a8; color: white'>C</span>" +
                      c +
                      "</div>"
              : wrong.keys.contains(q_id) && wrong[q_id] == 'C'
              ? "<div style='display: flex; color: red;'><span style='border: 1px solid red; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: red; color: white'>C</span>" +
                  c +
                  "</div>"
              : "<div style='display: flex; color: #757575;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>C</span>" +
                  c +
                  "</div>",
          style: const TeXViewStyle(padding: TeXViewPadding.all(15)),
        ),
        TeXViewDocument(
          ans == 'd'
              ? right.contains(q_id) || wrong.keys.contains(q_id)
                  ? "<div style='display: flex; color: green;'><span style='border: 1px solid green; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: green; color: white'>D</span>" +
                      d +
                      "</div>"
                  : "<div style='display: flex; color: #3275a8;'><span style='border: 1px solid #3275a8; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: #3275a8; color: white'>D</span>" +
                      d +
                      "</div>"
              : wrong.keys.contains(q_id) && wrong[q_id] == 'D'
              ? "<div style='display: flex; color: red;'><span style='border: 1px solid red; padding: 2px 10px; padding-top: 6px; margin-right:15px; background: red; color: white'>D</span>" +
                  d +
                  "</div>"
              : "<div style='display: flex; color: #757575;'><span style='border: 1px solid #757575; padding: 2px 10px; padding-top: 6px; margin-right:15px;'>D</span>" +
                  d +
                  "</div>",
          style: const TeXViewStyle(padding: TeXViewPadding.all(15)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF2F5F8),
      body: SingleChildScrollView(
        child: Visibility(
          visible: isLoading,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                const Center(
                  child: const Text(
                    'All Questions',
                    style: const TextStyle(
                      color: Color(0xff21205A),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TeXView(child: TeXViewColumn(children: ques_tex)),
                // ListView.builder(
                //   shrinkWrap: true,
                //   physics: const ScrollPhysics(),
                //   itemCount: widget.questions.length,
                //   itemBuilder: (context, index) {
                //     return Card(
                //       child: Column(
                //         children: [
                //           Padding(
                //             padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                //             child: Center(
                //               child: Text(
                //                 'Question ${index + 1}',
                //                 style: const TextStyle(
                //                     color: Colors.blue,
                //                     fontSize: 18,
                //                     fontWeight: FontWeight.bold),
                //               ),
                //             ),
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                //             child: Html(
                //               data: "<p>${widget.questions[index].ques}</p>",
                //               style: {
                //                 "p": Style(
                //                     color:
                //                         const Color.fromARGB(255, 95, 95, 95),
                //                     fontSize: const FontSize(18),
                //                     fontWeight: FontWeight.bold),
                //               },
                //             ),
                //           ),
                //           widget.questions[index].imageN != null
                //               ? SizedBox(
                //                   height: 150,
                //                   child: widget.questions[index].imageN !=
                //                           null
                //                       ? Image.network(
                //                           '${main_url}${widget.questions[index].imageN}')
                //                       : const Text(''),
                //                 )
                //               : const SizedBox(
                //                   height: 0,
                //                 ),
                //           const Divider(),
                //           Row(
                //             children: [
                //               Padding(
                //                 padding: const EdgeInsets.only(left: 20),
                //                 child: Column(
                //                   children: [
                //                     Container(
                //                       height: 35.0,
                //                       width: 35.0,
                //                       decoration: BoxDecoration(
                //                         color: Colors.transparent,
                //                         border: Border.all(
                //                           width: 1.0,
                //                           color: widget.questions[index].ans ==
                //                                   'a'
                //                               ? widget.right.contains(widget
                //                                           .questions[index]
                //                                           .id) ||
                //                                       widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id)
                //                                   ? Colors.green
                //                                   : Color(0xff0081B9)
                //                               : widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id) &&
                //                                       widget.wrong[widget
                //                                               .questions[
                //                                                   index]
                //                                               .id] ==
                //                                           'A'
                //                                   ? Colors.red
                //                                   : const Color.fromARGB(
                //                                       255, 95, 95, 95),
                //                         ),
                //                         borderRadius: const BorderRadius.all(
                //                             Radius.circular(2.0)),
                //                       ),
                //                       child: Center(
                //                         child: Text('A',
                //                             style: TextStyle(
                //                                 color: widget.questions[index]
                //                                             .ans ==
                //                                         'a'
                //                                     ? widget.right.contains(widget.questions[index].id) ||
                //                                             widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id)
                //                                         ? Colors.green
                //                                         : Color(0xff0081B9)
                //                                     : widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id) &&
                //                                             widget.wrong[widget.questions[index].id] ==
                //                                                 'A'
                //                                         ? Colors.red
                //                                         : const Color.fromARGB(
                //                                             255, 95, 95, 95),

                //                                 //fontWeight: FontWeight.bold,
                //                                 fontSize: 18.0)),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Expanded(
                //                 child: Padding(
                //                   padding:
                //                       const EdgeInsets.fromLTRB(10, 0, 0, 0),
                //                   child: SizedBox(
                //                     width: devWidth - 80,
                //                     child: Html(
                //                       data:
                //                           "<p>${widget.questions[index].choiceA}</p>",
                //                       style: {
                //                         "p": Style(
                //                             color: widget.questions[index]
                //                                         .ans ==
                //                                     'a'
                //                                 ? widget.right.contains(widget
                //                                             .questions[index]
                //                                             .id) ||
                //                                         widget.wrong.keys
                //                                             .contains(widget
                //                                                 .questions[
                //                                                     index]
                //                                                 .id)
                //                                     ? Colors.green
                //                                     : Color(0xff0081B9)
                //                                 : widget.wrong.keys.contains(widget
                //                                             .questions[index]
                //                                             .id) &&
                //                                         widget.wrong[widget
                //                                                 .questions[index]
                //                                                 .id] ==
                //                                             'A'
                //                                     ? Colors.red
                //                                     : const Color.fromARGB(255, 95, 95, 95),
                //                             fontSize: const FontSize(18)),
                //                       },
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           const Divider(),
                //           Row(
                //             children: [
                //               Padding(
                //                 padding: const EdgeInsets.only(left: 20),
                //                 child: Column(
                //                   children: [
                //                     Container(
                //                       height: 35.0,
                //                       width: 35.0,
                //                       decoration: BoxDecoration(
                //                         color: Colors.transparent,
                //                         border: Border.all(
                //                           width: 1.0,
                //                           color: widget.questions[index].ans ==
                //                                   'b'
                //                               ? widget.right.contains(widget
                //                                           .questions[index]
                //                                           .id) ||
                //                                       widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id)
                //                                   ? Colors.green
                //                                   : Color(0xff0081B9)
                //                               : widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id) &&
                //                                       widget.wrong[widget
                //                                               .questions[
                //                                                   index]
                //                                               .id] ==
                //                                           'B'
                //                                   ? Colors.red
                //                                   : const Color.fromARGB(
                //                                       255, 95, 95, 95),
                //                         ),
                //                         borderRadius: const BorderRadius.all(
                //                             Radius.circular(2.0)),
                //                       ),
                //                       child: Center(
                //                         child: Text('B',
                //                             style: TextStyle(
                //                                 color: widget.questions[index]
                //                                             .ans ==
                //                                         'b'
                //                                     ? widget.right.contains(widget.questions[index].id) ||
                //                                             widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id)
                //                                         ? Colors.green
                //                                         : Color(0xff0081B9)
                //                                     : widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id) &&
                //                                             widget.wrong[widget.questions[index].id] ==
                //                                                 'B'
                //                                         ? Colors.red
                //                                         : const Color.fromARGB(
                //                                             255, 95, 95, 95),
                //                                 //fontWeight: FontWeight.bold,
                //                                 fontSize: 18.0)),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Expanded(
                //                 child: Padding(
                //                   padding:
                //                       const EdgeInsets.fromLTRB(10, 0, 0, 0),
                //                   child: SizedBox(
                //                     width: devWidth - 80,
                //                     child: Html(
                //                       data:
                //                           "<p>${widget.questions[index].choiceB}</p>",
                //                       style: {
                //                         "p": Style(
                //                             color: widget.questions[index]
                //                                         .ans ==
                //                                     'b'
                //                                 ? widget.right.contains(widget
                //                                             .questions[index]
                //                                             .id) ||
                //                                         widget.wrong.keys
                //                                             .contains(widget
                //                                                 .questions[
                //                                                     index]
                //                                                 .id)
                //                                     ? Colors.green
                //                                     : Color(0xff0081B9)
                //                                 : widget.wrong.keys.contains(widget
                //                                             .questions[index]
                //                                             .id) &&
                //                                         widget.wrong[widget
                //                                                 .questions[index]
                //                                                 .id] ==
                //                                             'B'
                //                                     ? Colors.red
                //                                     : const Color.fromARGB(255, 95, 95, 95),
                //                             fontSize: const FontSize(18)),
                //                       },
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           const Divider(),
                //           Row(
                //             children: [
                //               Padding(
                //                 padding: const EdgeInsets.only(left: 20),
                //                 child: Column(
                //                   children: [
                //                     Container(
                //                       height: 35.0,
                //                       width: 35.0,
                //                       decoration: BoxDecoration(
                //                         color: Colors.transparent,
                //                         border: Border.all(
                //                           width: 1.0,
                //                           color: widget.questions[index].ans ==
                //                                   'c'
                //                               ? widget.right.contains(widget
                //                                           .questions[index]
                //                                           .id) ||
                //                                       widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id)
                //                                   ? Colors.green
                //                                   : Color(0xff0081B9)
                //                               : widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id) &&
                //                                       widget.wrong[widget
                //                                               .questions[
                //                                                   index]
                //                                               .id] ==
                //                                           'C'
                //                                   ? Colors.red
                //                                   : const Color.fromARGB(
                //                                       255, 95, 95, 95),
                //                         ),
                //                         borderRadius: const BorderRadius.all(
                //                             Radius.circular(2.0)),
                //                       ),
                //                       child: Center(
                //                         child: Text('C',
                //                             style: TextStyle(
                //                                 color: widget.questions[index]
                //                                             .ans ==
                //                                         'c'
                //                                     ? widget.right.contains(widget.questions[index].id) ||
                //                                             widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id)
                //                                         ? Colors.green
                //                                         : Color(0xff0081B9)
                //                                     : widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id) &&
                //                                             widget.wrong[widget.questions[index].id] ==
                //                                                 'C'
                //                                         ? Colors.red
                //                                         : const Color.fromARGB(
                //                                             255, 95, 95, 95),
                //                                 //fontWeight: FontWeight.bold,
                //                                 fontSize: 18.0)),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Expanded(
                //                 child: Padding(
                //                   padding:
                //                       const EdgeInsets.fromLTRB(10, 0, 0, 0),
                //                   child: SizedBox(
                //                     width: devWidth - 80,
                //                     child: Html(
                //                       data:
                //                           "<p>${widget.questions[index].choiceC}</p>",
                //                       style: {
                //                         "p": Style(
                //                             color: widget.questions[index]
                //                                         .ans ==
                //                                     'c'
                //                                 ? widget.right.contains(widget
                //                                             .questions[index]
                //                                             .id) ||
                //                                         widget.wrong.keys
                //                                             .contains(widget
                //                                                 .questions[
                //                                                     index]
                //                                                 .id)
                //                                     ? Colors.green
                //                                     : Color(0xff0081B9)
                //                                 : widget.wrong.keys.contains(widget
                //                                             .questions[index]
                //                                             .id) &&
                //                                         widget.wrong[widget
                //                                                 .questions[index]
                //                                                 .id] ==
                //                                             'C'
                //                                     ? Colors.red
                //                                     : const Color.fromARGB(255, 95, 95, 95),
                //                             fontSize: const FontSize(18)),
                //                       },
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           const Divider(),
                //           Row(
                //             children: [
                //               Padding(
                //                 padding: const EdgeInsets.only(left: 20),
                //                 child: Column(
                //                   children: [
                //                     Container(
                //                       height: 35.0,
                //                       width: 35.0,
                //                       decoration: BoxDecoration(
                //                         color: Colors.transparent,
                //                         border: Border.all(
                //                           width: 1.0,
                //                           color: widget.questions[index].ans ==
                //                                   'd'
                //                               ? widget.right.contains(widget
                //                                           .questions[index]
                //                                           .id) ||
                //                                       widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id)
                //                                   ? Colors.green
                //                                   : Color(0xff0081B9)
                //                               : widget.wrong.keys.contains(widget
                //                                           .questions[index]
                //                                           .id) &&
                //                                       widget.wrong[widget
                //                                               .questions[
                //                                                   index]
                //                                               .id] ==
                //                                           'D'
                //                                   ? Colors.red
                //                                   : const Color.fromARGB(
                //                                       255, 95, 95, 95),
                //                         ),
                //                         borderRadius: const BorderRadius.all(
                //                             Radius.circular(2.0)),
                //                       ),
                //                       child: Center(
                //                         child: Text('D',
                //                             style: TextStyle(
                //                                 color: widget.questions[index]
                //                                             .ans ==
                //                                         'd'
                //                                     ? widget.right.contains(widget.questions[index].id) ||
                //                                             widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id)
                //                                         ? Colors.green
                //                                         : Color(0xff0081B9)
                //                                     : widget.wrong.keys
                //                                                 .contains(widget
                //                                                     .questions[
                //                                                         index]
                //                                                     .id) &&
                //                                             widget.wrong[widget.questions[index].id] ==
                //                                                 'D'
                //                                         ? Colors.red
                //                                         : const Color.fromARGB(
                //                                             255, 95, 95, 95),
                //                                 //fontWeight: FontWeight.bold,
                //                                 fontSize: 18.0)),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Expanded(
                //                 child: Padding(
                //                   padding:
                //                       const EdgeInsets.fromLTRB(10, 0, 0, 0),
                //                   child: SizedBox(
                //                     width: devWidth - 80,
                //                     child: Html(
                //                       data:
                //                           "<p>${widget.questions[index].choiceD}</p>",
                //                       style: {
                //                         "p": Style(
                //                             color: widget.questions[index]
                //                                         .ans ==
                //                                     'd'
                //                                 ? widget.right.contains(widget
                //                                             .questions[index]
                //                                             .id) ||
                //                                         widget.wrong.keys
                //                                             .contains(widget
                //                                                 .questions[
                //                                                     index]
                //                                                 .id)
                //                                     ? Colors.green
                //                                     : Color(0xff0081B9)
                //                                 : widget.wrong.keys.contains(widget
                //                                             .questions[index]
                //                                             .id) &&
                //                                         widget.wrong[widget
                //                                                 .questions[index]
                //                                                 .id] ==
                //                                             'D'
                //                                     ? Colors.red
                //                                     : const Color.fromARGB(255, 95, 95, 95),
                //                             fontSize: const FontSize(18)),
                //                       },
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           Row(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               ElevatedButton(
                //                 onPressed: () {
                //                   showDialog(
                //                       context: context,
                //                       builder: (BuildContext context) {
                //                         return FeedbackDialogBox(
                //                           examTitle: "Random Question",
                //                         );
                //                       });
                //                 },
                //                 child: const Text("Send Feedback"),
                //                 style: ButtonStyle(
                //                   foregroundColor:
                //                       MaterialStateProperty.all<Color>(
                //                           const Color.fromARGB(
                //                               255, 255, 255, 255)),
                //                   backgroundColor:
                //                       MaterialStateProperty.all<Color>(
                //                           const Color(0xff0081B9)),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           const SizedBox(
                //             height: 40,
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
