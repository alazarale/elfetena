// This is the main entry point of the Flutter application.
import 'package:eltest_exit/comps/chapter_study_take.dart';
import 'package:eltest_exit/comps/exam_take_notimer.dart';
import 'package:eltest_exit/comps/how_to_api.dart';
import 'package:eltest_exit/comps/store/store_national.dart';

import 'comps/bank_detail.dart';
import 'comps/chapter_take_exam.dart';
import 'comps/code.dart';
import 'comps/contact.dart';
import 'comps/exam_list_showing.dart';
import 'comps/exam_result_screen.dart';
import 'comps/fav_question.dart';
import 'comps/home_nav.dart';
import 'comps/how_to_pay.dart';
import 'comps/immediate_pay.dart';
import 'comps/login.dart';
import 'comps/payment_finished.dart';
import 'comps/payment_list.dart';
import 'comps/provider/auth.dart';
import 'comps/provider/strored_ref.dart';
import 'comps/random/random_question.dart';
import 'comps/random/random_res_main.dart';
import 'comps/random_ques_setting.dart';
import 'comps/take_exam.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'comps/chapter/chapter_result.dart';
import 'comps/signup.dart';
import 'comps/store/store_stream.dart';
import 'comps/store/store_sub.dart';

main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RefData()),
        ChangeNotifierProvider(create: (context) => Auth()),
      ],
      child: ELExam(),
    ),
  );
}

class ELExam extends StatefulWidget {
  ELExam({Key? key}) : super(key: key);

  @override
  State<ELExam> createState() => _ELExamState();
}

class _ELExamState extends State<ELExam> {
  @override
  void initState() {
    super.initState();
    Provider.of<RefData>(context, listen: false).tryGetDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => HomeNavigator(),
        '/paid': (context) => HomeNavigator(index: 2),
        '/take': (context) => const TakeExam(),
        '/take-study': (context) => const TakeStudyExam(),
        '/result': (context) => const ExamResultScreen(),
        '/list': (context) => const ExamListShowScreen(),
        '/fav': (context) => const FavoriteQuestionScreen(),
        '/contact': (context) => const ContactScreen(),
        '/code': (context) => const CodePage(),
        '/how-to': (context) => const HowToPay(),
        '/how-to-api': (context) => const HowToApi(),
        '/store-sub': (context) => const StoreSubjectScreen(),
        '/store-national': (context) => const StoreNational(),
        '/store-stream': (context) => const StoreStreamScreen(),
        '/signup': (context) => const AccountSignup(),
        '/login': (context) => const AccountLogin(),
        '/payment-list': (context) => const PaymentListScreen(),
        '/subsc': (context) => const PaymentFinishedScreen(),
        '/take-chapt-study': (context) => const ChapStudyMode(),
        '/take-chapt': (context) => const ChapTakeExam(),
        '/result-chapt': (context) => const ChapterExamResultScreen(),
        '/bank': (context) => const BankDetailScreen(),
        '/immed': (context) => const ImmediateAuthScreen(),
        '/random': (context) => const RandomQuestionScreen(),
        '/random-res': (context) => const RandomExamResultScreen(),
        '/random-set': (context) => const RandomQuesSettingScreen(),
        
      },
      title: 'Flutter Demo',
      theme: Provider.of<RefData>(context).isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}
