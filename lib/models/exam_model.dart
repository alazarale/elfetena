class ExamModel {
  final int id;
  final String name;
  final String subject;
  final String code;
  final int time;

  ExamModel(this.id, this.name, this.subject, this.code, this.time);
}

class SubjectModel {
  final int id;
  final String name;

  SubjectModel(this.id, this.name);
}

class QuestionModel {
  final int id;
  final String ques;
  final String choiceA;
  final String choiceB;
  final String choiceC;
  final String choiceD;
  final String ans;
  String? imageN;
  final int chapter;

  QuestionModel(this.id, this.ques, this.choiceA, this.choiceB, this.choiceC,
      this.choiceD, this.ans, this.imageN, this.chapter);
}

class Result {
  int? id;
  int exam;
  String right;
  String unanswered;

  Result(this.exam, this.right, this.unanswered);

  Map<String, dynamic> toMap() {
    return {
      'exam': exam,
      'right': right,
      'unanswered': unanswered,
    };
  }
}

class ResultWrong {
  int? id;
  int? result;
  int question;
  String choosen;

  ResultWrong(this.question, this.choosen);

  setResult(res) {
    result = res;
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result,
      'question': question,
      'choosen': choosen,
    };
  }
}

class ResultTime {
  int? id;
  int? result;
  int question;
  String time;

  ResultTime(this.question, this.time);

  setResult(res) {
    result = res;
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result,
      'question': question,
      'time': time,
    };
  }
}

class Favourite {
  int? id;
  int question;

  Favourite(this.question);

  Map<String, dynamic> toMap() {
    return {
      'question': question,
    };
  }
}

class ResultChapter {
  int? id;
  int chapter;
  int no_ques;
  int right;
  int wrong;
  int unanswered;
  String avg_time;
  int? result;

  ResultChapter(this.chapter, this.no_ques, this.right, this.wrong,
      this.unanswered, this.avg_time);
  setResult(res) {
    result = res;
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result,
      'no_questions': no_ques,
      'right': right,
      'wrong': wrong,
      'unanswered': unanswered,
      'avg_time': avg_time,
      'chapter': chapter,
    };
  }
}
