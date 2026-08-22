import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF4D8DFF),
    scaffoldBackgroundColor: const Color(0xFFF6F8FC),
    canvasColor: const Color(0xFFF6F8FC),
    dividerColor: const Color(0xFFDDE4EA),
    cardColor: const Color(0xFFFFFFFF),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1D2935)),
      bodyMedium: TextStyle(color: Color(0xFF40505E)),
      titleLarge: TextStyle(color: Color(0xFF17232E)),
      titleMedium: TextStyle(color: Color(0xFF17232E)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFEAF1F4),
      border: InputBorder.none,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xFF17232E),
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF1DB954),
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    dividerColor: const Color(0xFF2A2A2A),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF242424),
      border: InputBorder.none,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
