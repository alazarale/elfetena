import 'package:flutter/material.dart';

class AppTheme {
  static const Color white = Colors.white;
  static const Color white54 = Colors.white54;
  static const Color white12 = Colors.white12;
  static const Color red = Colors.red;
  static const Color blue = Colors.blue;
  static const Color green = Colors.green;
  static const Color color6CA8F1 = Color(0xFF6CA8F1);
  static const Color colorFDF1D9 = Color(0xffFDF1D9);
  static const Color colorF0A714 = Color(0xffF0A714);
  static const Color colorB27C0E = Color.fromARGB(255, 178, 124, 14);
  static const Color colorFDE4E4 = Color(0xffFDE4E4);
  static const Color colorF35555 = Color(0xffF35555);
  static const Color color9B1B1B = Color.fromARGB(255, 155, 27, 27);
  static const Color colorDDF0E6 = Color(0xffDDF0E6);
  static const Color color28A164 = Color(0xff28A164);
  static const Color color186F44 = Color.fromARGB(255, 24, 111, 68);
  static const Color color21205A = Color(0xff21205A);
  static const Color color31308F = Color.fromARGB(255, 49, 48, 143);
  static const Color color2825F8 = Color.fromARGB(255, 40, 37, 248);
  static const Color color4F4F4F = Color.fromARGB(255, 79, 79, 79);
  static const Color color7E7E7E = Color.fromARGB(255, 126, 126, 126);
  static const Color colorED240E = Color.fromARGB(255, 237, 36, 14);
  static const Color color6E3434 = Color.fromARGB(255, 110, 52, 52);
  static const Color color757575 = Color.fromARGB(255, 117, 117, 117);
  static const Color color005275 = Color.fromARGB(255, 0, 82, 117);
  static const Color color0081B9 = Color(0xff0081B9);
  static const Color color2196F3 = Color(0xff2196f3);
  static const Color colorE1E9F9 = Color(0xffE1E9F9);
  static const Color color3275a8 = Color(0xff3275a8);
  static const Color colorF2F5F8 = Color(0xffF2F5F8);
  static const Color color527DAA = Color(0xFF527DAA);
  static const Color color478DE0 = Color(0xFF478DE0);
  static const Color color398AE5 = Color(0xFF398AE5);
  static const Color colorFD1111 = Color.fromARGB(255, 253, 17, 17);
  static const Color color34B1AA = Color.fromARGB(255, 52, 177, 170);

  static ThemeData lightTheme = ThemeData(
    primaryColor: color0081B9,
    scaffoldBackgroundColor: white,
    appBarTheme: const AppBarTheme(
      backgroundColor: colorF2F5F8,
      titleTextStyle: TextStyle(
        color: color21205A,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: color21205A),
      bodyMedium: TextStyle(color: color21205A),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: color0081B9),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: color21205A,
    scaffoldBackgroundColor: color21205A,
    appBarTheme: const AppBarTheme(
      backgroundColor: color31308F,
      titleTextStyle: TextStyle(
        color: white,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: white),
      bodyMedium: TextStyle(color: white),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: color31308F),
  );
}
