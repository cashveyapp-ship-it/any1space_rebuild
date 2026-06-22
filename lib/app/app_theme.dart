import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF0B1F3A);
  static const gold = Color(0xFFF5B700);
  static const background = Color(0xFFF6F7FB);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: gold,
      surface: background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

