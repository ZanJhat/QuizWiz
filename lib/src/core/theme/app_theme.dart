import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );

  static ThemeData darkTheme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
