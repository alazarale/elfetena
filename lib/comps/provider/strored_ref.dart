import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RefData with ChangeNotifier {
  late String? _paymentRef;
  late String? _subRef;
  String _first_name = '';
  String _last_name = '';
  String _email = '';
  String _phone = '';
  List _not_include = [];
  int? _no_ques = 30;
  String _not_shown = 'no';
  String _dis = 'no';
  bool _isDarkMode = false;
  String _geminiApi = 'none';

  List get not_include {
    return _not_include;
  }

  bool get isDarkMode {
    return _isDarkMode;
  }

  String get not_shown {
    return _not_shown;
  }

  String get geminiApi {
    return _geminiApi!;
  }

  setGeminiApi(String gemini) async {
    _geminiApi = gemini;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gemin_key', _geminiApi!);
    notifyListeners();
  }

  int? get no_ques {
    return _no_ques;
  }

  String? get paymentRef {
    return _paymentRef;
  }

  String? get subRef {
    return _subRef;
  }

  String get firstName {
    return _first_name;
  }

  String get lastName {
    return _last_name;
  }

  String get email {
    return _email;
  }

  String get phone {
    return _phone;
  }

  String get dis {
    return _dis;
  }

  setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  setDis(dd) {
    _dis = dd;
    notifyListeners();
  }

  setPaymentRef(ref_d) async {
    _paymentRef = ref_d;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('payRef', ref_d);
    notifyListeners();
  }

  setNotShown(is_not) async {
    _not_shown = is_not;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('not_shown', is_not);
    notifyListeners();
  }

  setNotIncluded(List n_inc, int nq) async {
    _not_include = n_inc;
    _no_ques = nq;
    final inc = await SharedPreferences.getInstance();
    inc.setString('not_included', json.encode(n_inc));
    inc.setString('no_ques', json.encode(nq));
    notifyListeners();
  }

  Future<bool> tryNotIncluded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('not_included')) {
      return false;
    }

    final extractedUserData = json.decode(
      prefs.getString('not_included') as String,
    );

    _not_include = extractedUserData;
    notifyListeners();
    return true;
  }

  Future<bool> tryNoQues() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('no_ques')) {
      return false;
    }

    final int extractedUserData = json.decode(
      prefs.getString('no_ques') as String,
    );

    _no_ques = extractedUserData;
    notifyListeners();
    return true;
  }

  Future<bool> tryNotShown() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('not_shown')) {
      return false;
    }

    final String extractedUserData = json.decode(
      prefs.getString('not_shown') as String,
    );

    _not_shown = extractedUserData;
    notifyListeners();
    return true;
  }

  setSubRef(ref_d) async {
    _subRef = ref_d;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('_subRef', ref_d);
    notifyListeners();
  }

  Future<bool> tryGetPayRef() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('payRef')) {
      print('k');
      return false;
    }
    print('d');
    _paymentRef = prefs.getString('payRef') as String;
    notifyListeners();
    return true;
  }

  saveCredintial(name, lName, email, phone) async {
    _first_name = name;
    _last_name = lName;
    _email = email;
    _phone = phone;
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'firstName': _first_name,
      'lastName': _last_name,
      'email': _email,
      'phone': _phone,
    });
    prefs.setString('userData', userData);
  }

  Future<bool> tryGetCredintial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      print('yes');
      return false;
    }
    print('no');
    final extractedUserData = json.decode(
      prefs.getString('userData') as String,
    );

    _first_name = extractedUserData['firstName'] as String;
    _last_name = extractedUserData['lastName'] as String;
    _email = extractedUserData['email'] as String;
    _phone = extractedUserData['phone'] as String;

    return true;
  }

  Future<bool> tryGetDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('isDarkMode')) {
      return false;
    }

    _isDarkMode = prefs.getBool('isDarkMode') as bool;
    notifyListeners();
    return true;
  }

  Future<bool> tryGetGeminiApi() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('gemin_key')) {
      return false;
    }

    _geminiApi = prefs.getString('gemin_key') as String;
    notifyListeners();
    return true;
  }
}
