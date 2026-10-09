import 'package:flutter/material.dart';

ThemeData kinTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff173d33),
    primary: const Color(0xff173d33),
    surface: const Color(0xfff3f5ef),
  ),
  scaffoldBackgroundColor: const Color(0xfff3f5ef),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xfff3f5ef),
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xffdfe5dc)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.all(16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.5,
    ),
    titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
  ),
);
