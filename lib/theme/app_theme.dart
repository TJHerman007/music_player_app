import 'package:flutter/material.dart';

class AppTheme {
  static const _lightSeed = Color.fromARGB(255, 219, 142, 255);
  static const _darkSeed = Color(0xFFE46F50);

  /// Blends [base] toward [accent] by [t], or returns [base] unchanged when
  /// there is no now-playing accent to blend with.
  static Color _blend(Color base, Color? accent, double t) {
    if (accent == null) return base;
    return Color.lerp(base, accent, t) ?? base;
  }

  static ThemeData light([Color? accent]) => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _blend(_lightSeed, accent, 0.55),
      brightness: Brightness.light,
      surface: _blend(const Color.fromARGB(255, 241, 231, 231), accent, 0.1),
    ),
    scaffoldBackgroundColor: _blend(
      const Color.fromARGB(255, 219, 219, 219),
      accent,
      0.12,
    ),
    canvasColor: const Color.fromARGB(255, 247, 240, 240),
    dividerColor: const Color.fromARGB(255, 235, 234, 234),
    cardColor: const Color.fromARGB(255, 238, 238, 238),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1D1B1A)),
      bodyMedium: TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
      titleLarge: TextStyle(color: Color(0xFF171514)),
      titleMedium: TextStyle(color: Color(0xFF171514)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color.fromARGB(255, 245, 166, 166),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xFF171514),
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Color.fromARGB(0, 59, 58, 58),
      surfaceTintColor: Color.fromARGB(0, 49, 49, 49),
      elevation: 0,
    ),
    useMaterial3: true,
  );

  static ThemeData dark([Color? accent]) => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _blend(_darkSeed, accent, 0.55),
      brightness: Brightness.dark,
      surface: _blend(const Color.fromARGB(255, 36, 39, 43), accent, 0.14),
    ),
    scaffoldBackgroundColor: _blend(const Color(0xFF1B1E22), accent, 0.16),
    canvasColor: const Color(0xFF1B1E22),
    dividerColor: const Color(0xFF30343A),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF24282D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xFFF3EEE8),
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
