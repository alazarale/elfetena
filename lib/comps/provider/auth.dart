import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/http_exception.dart';
import '../service/common.dart';

class Auth with ChangeNotifier {
  String? _token = null;
  String? _is_payed = 'no';
  late String? _phone_num;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_token != null) {
      return _token;
    }
    return null;
  }

  String? get is_payed {
    if (_token != null) {
      return _is_payed;
    }
    return null;
  }

  String? get phone_num {
    if (_token != null) {
      return _phone_num;
    }
    return null;
  }

  Future set_payed() async {
    _is_payed = "yes";
    final prefs = await SharedPreferences.getInstance();
    final payStat = json.encode(
      {
        'is_payed': _is_payed,
      },
    );
    prefs.setString('payStat', payStat);
  }

  Future set_payed_no() async {
    _is_payed = "no";
    final prefs = await SharedPreferences.getInstance();
    final payStat = json.encode(
      {
        'is_payed': _is_payed,
      },
    );
    prefs.setString('payStat', payStat);
  }

  Future set_waiting() async {
    _is_payed = "waiting";
    final prefs = await SharedPreferences.getInstance();
    final payStat = json.encode(
      {
        'is_payed': _is_payed,
      },
    );
    prefs.setString('payStat', payStat);
  }

  Future<bool> try_payment() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('payStat')) {
      return false;
    }

    final extractedUserData = json.decode(prefs.getString('payStat') as String);
    _is_payed = extractedUserData['is_payed'] as String?;

    return true;
  }

  Future<void> signin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$main_url/api/token/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'username': '$username', 'password': '$password'}),
      );

      if (response.statusCode == 200) {
        var extractedData = jsonDecode(response.body);
        _token = extractedData['access'];
        _phone_num = extractedData['name'];

        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode(
          {
            'token': _token,
            'phone_num': _phone_num,
          },
        );
        prefs.setString('loginData', userData);
      } else {
        var extractedDat = jsonDecode(response.body);
        throw HttpException(extractedDat['detail']);
      }
    } catch (error) {
      throw error;
    }
  }

  Future<void> signup(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$main_url/api/token/register/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'phone': '$username', 'passw': '$password'}),
      );

      if (response.statusCode == 200) {
        var extractedData = jsonDecode(response.body);
        _token = extractedData['access'];
        _phone_num = extractedData['name'];

        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode(
          {
            'token': _token,
            'phone_num': _phone_num,
          },
        );
        prefs.setString('loginData', userData);
      } else {
        var extractedDat = jsonDecode(response.body);

        throw HttpException(extractedDat['detail']);
      }
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('loginData')) {
      return false;
    }

    final extractedUserData =
        json.decode(prefs.getString('loginData') as String);

    _token = extractedUserData['token'] as String?;
    _phone_num = extractedUserData['phone_num'] as String;

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _phone_num = null;

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
