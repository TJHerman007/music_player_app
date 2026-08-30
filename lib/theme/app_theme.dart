import 'package:flutter/material.dart';

class AppTheme {
  static const _lightSeed = Color.fromARGB(255, 219, 142, 255);

  static const _darkSeed = Color(0xFFE46F50);

  // ==========================================================================
  // ACCENT COLORS
  // ==========================================================================

  static const accentPurple = Color.fromARGB(255, 219, 142, 255);

  static const accentCoral = Color(0xFFE46F50);

  static const accentBlue = Color(0xFF6EA8FF);

  static const accentCyan = Color(0xFF4DD0E1);

  static const accentGreen = Color(0xFF67D58B);

  static const accentPink = Color(0xFFFF78B7);

  static const accentOrange = Color(0xFFFFA45B);

  static const accentRed = Color(0xFFFF6B6B);

  static const List<Color> accentColors = [
    accentPurple,
    accentCoral,
    accentBlue,
    accentCyan,
    accentGreen,
    accentPink,
    accentOrange,
    accentRed,
  ];

  // ==========================================================================
  // LIGHT COLORS
  // ==========================================================================

  static const lightBackground = Color(0xFFF4F2EE);

  static const lightSurface = Color.fromARGB(255, 241, 231, 231);

  static const lightSurfaceSecondary = Color(0xFFECE9E4);

  static const lightCard = Color(0xFFEEEEEE);

  static const lightCanvas = Color(0xFFF7F0F0);

  static const lightInput = Color.fromARGB(255, 245, 166, 166);

  static const lightDivider = Color(0xFFEBEAEA);

  static const lightText = Color(0xFF171514);

  static const lightSecondaryText = Color(0xFF77746F);

  static const lightMutedText = Color(0xFF96928C);

  // ==========================================================================
  // DARK COLORS
  // ==========================================================================

  static const darkBackground = Color(0xFF1B1E22);

  static const darkSurface = Color(0xFF24282D);

  static const darkSurfaceSecondary = Color(0xFF20242A);

  static const darkCard = Color(0xFF20242A);

  static const darkCanvas = Color(0xFF1B1E22);

  static const darkInput = Color(0xFF24282D);

  static const darkDivider = Color(0xFF30343A);

  static const darkText = Color(0xFFF3EEE8);

  static const darkSecondaryText = Color(0xFFAAA7A2);

  static const darkMutedText = Color(0xFF706E69);

  // ==========================================================================
  // UI RADII
  // ==========================================================================

  static const radiusSmall = 10.0;
  static const radiusMedium = 14.0;
  static const radiusLarge = 18.0;
  static const radiusXLarge = 22.0;

  // ==========================================================================
  // UI SPACING
  // ==========================================================================

  static const spacingXS = 4.0;
  static const spacingSM = 8.0;
  static const spacingMD = 12.0;
  static const spacingLG = 16.0;
  static const spacingXL = 20.0;
  static const spacingXXL = 24.0;
  static const spacingHuge = 32.0;

  // ==========================================================================
  // CURRENT ACCENT
  // ==========================================================================

  static Color? accent;

  // ==========================================================================
  // THEME MODE
  // ==========================================================================

  static ThemeMode themeMode = ThemeMode.system;

  // ==========================================================================
  // ORIGINAL BLEND FUNCTION
  // ==========================================================================

  /// Blends [base] toward [accent] by [t], or returns [base] unchanged when
  /// there is no now-playing accent to blend with.
  static Color _blend(Color base, Color? accent, double t) {
    if (accent == null) return base;

    return Color.lerp(base, accent, t) ?? base;
  }

  // ==========================================================================
  // ACCENT CONTROLS
  // ==========================================================================

  static void setAccent(Color color) {
    accent = color;
  }

  static void clearAccent() {
    accent = null;
  }

  static void resetAccent() {
    accent = null;
  }

  // ==========================================================================
  // THEME MODE CONTROLS
  // ==========================================================================

  static void setThemeMode(ThemeMode mode) {
    themeMode = mode;
  }

  static void setLightMode() {
    themeMode = ThemeMode.light;
  }

  static void setDarkMode() {
    themeMode = ThemeMode.dark;
  }

  static void setSystemMode() {
    themeMode = ThemeMode.system;
  }

  // ==========================================================================
  // LIGHT THEME
  // ==========================================================================

  static ThemeData light([Color? accent]) {
    final activeAccent = accent ?? AppTheme.accent;

    final primaryAccent = activeAccent ?? _lightSeed;

    return ThemeData(
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _blend(_lightSeed, activeAccent, 0.55),
        brightness: Brightness.light,
        surface: _blend(lightSurface, activeAccent, 0.10),
      ),

      scaffoldBackgroundColor: _blend(lightBackground, activeAccent, 0.12),

      canvasColor: lightCanvas,

      dividerColor: lightDivider,

      cardColor: lightCard,

      splashColor: primaryAccent.withValues(alpha: 0.08),

      highlightColor: primaryAccent.withValues(alpha: 0.05),

      hoverColor: primaryAccent.withValues(alpha: 0.06),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
        bodySmall: TextStyle(color: lightSecondaryText),
        titleLarge: TextStyle(color: lightText),
        titleMedium: TextStyle(color: lightText),
        titleSmall: TextStyle(color: lightSecondaryText),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: lightInput,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryAccent, width: 1.2),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFF171514),
        centerTitle: false,
      ),

      cardTheme: const CardThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryAccent.withValues(alpha: 0.15),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryAccent.withValues(alpha: 0.15),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        thumbColor: primaryAccent,
        overlayColor: primaryAccent.withValues(alpha: 0.12),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryAccent),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent;
          }

          return lightMutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent.withValues(alpha: 0.35);
          }

          return lightDivider;
        }),
      ),

      useMaterial3: true,
    );
  }

  // ==========================================================================
  // DARK THEME
  // ==========================================================================

  static ThemeData dark([Color? accent]) {
    final activeAccent = accent ?? AppTheme.accent;

    final primaryAccent = activeAccent ?? _darkSeed;

    return ThemeData(
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _blend(_darkSeed, activeAccent, 0.55),
        brightness: Brightness.dark,
        surface: _blend(darkSurface, activeAccent, 0.14),
      ),

      scaffoldBackgroundColor: _blend(darkBackground, activeAccent, 0.16),

      canvasColor: darkCanvas,

      dividerColor: darkDivider,

      cardColor: darkCard,

      splashColor: primaryAccent.withValues(alpha: 0.08),

      highlightColor: primaryAccent.withValues(alpha: 0.05),

      hoverColor: primaryAccent.withValues(alpha: 0.06),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: darkSecondaryText),
        titleLarge: TextStyle(color: darkText),
        titleMedium: TextStyle(color: darkText),
        titleSmall: TextStyle(color: darkSecondaryText),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: darkInput,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryAccent, width: 1.2),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryAccent.withValues(alpha: 0.18),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryAccent.withValues(alpha: 0.18),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        thumbColor: primaryAccent,
        overlayColor: primaryAccent.withValues(alpha: 0.12),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryAccent),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent;
          }

          return darkMutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent.withValues(alpha: 0.35);
          }

          return darkDivider;
        }),
      ),

      useMaterial3: true,
    );
  }

  // ==========================================================================
  // CENTRALIZED UI COLORS
  // ==========================================================================

  static AppThemeColors colors(BuildContext context) {
    return AppThemeColors(context);
  }
}

// ============================================================================
// CENTRALIZED APP COLORS
// ============================================================================
//
// Usage:
//
// final colors = AppTheme.colors(context);
//
// colors.primary
// colors.background
// colors.surface
// colors.text
// colors.textPrimary
// colors.textSecondary
// colors.textMuted
// colors.glass
// colors.glassBorder
// colors.glassStrong
//
// ============================================================================

class AppThemeColors {
  const AppThemeColors(this.context);

  final BuildContext context;

  ThemeData get theme => Theme.of(context);

  Color get primary => theme.colorScheme.primary;

  Color get secondary => theme.colorScheme.secondary;

  Color get tertiary => theme.colorScheme.tertiary;

  Color get background => theme.scaffoldBackgroundColor;

  Color get surface => theme.colorScheme.surface;

  Color get surfaceSecondary {
    return theme.brightness == Brightness.dark
        ? AppTheme.darkSurfaceSecondary
        : AppTheme.lightSurfaceSecondary;
  }

  Color get card => theme.cardColor;

  Color get canvas => theme.canvasColor;

  Color get divider => theme.dividerColor;

  // --------------------------------------------------------------------------
  // TEXT
  // --------------------------------------------------------------------------

  Color get textPrimary => theme.colorScheme.onSurface;

  Color get text => textPrimary;

  Color get textSecondary =>
      theme.colorScheme.onSurface.withValues(alpha: 0.66);

  Color get textMuted => theme.colorScheme.onSurface.withValues(alpha: 0.42);

  // --------------------------------------------------------------------------
  // ICONS
  // --------------------------------------------------------------------------

  Color get icon => theme.colorScheme.onSurface;

  Color get iconMuted => theme.colorScheme.onSurface.withValues(alpha: 0.50);

  // --------------------------------------------------------------------------
  // GLASS
  // --------------------------------------------------------------------------

  Color get glass {
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.055);
    }

    return Colors.white.withValues(alpha: 0.48);
  }

  Color get glassStrong {
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.085);
    }

    return Colors.white.withValues(alpha: 0.68);
  }

  Color get glassBorder {
    if (theme.brightness == Brightness.dark) {
      return Colors.white.withValues(alpha: 0.075);
    }

    return Colors.black.withValues(alpha: 0.065);
  }

  // --------------------------------------------------------------------------
  // SPECIAL COLORS
  // --------------------------------------------------------------------------

  Color get favorite => const Color(0xFFE85D75);

  Color get success => const Color(0xFF67D58B);

  Color get warning => const Color(0xFFFFB45E);

  Color get error => theme.colorScheme.error;

  Color get playing => primary;
}

// import 'package:flutter/material.dart';

// class AppTheme {
//   static const _lightSeed = Color.fromARGB(255, 219, 142, 255);
//   static const _darkSeed = Color(0xFFE46F50);

//   /// Blends [base] toward [accent] by [t], or returns [base] unchanged when
//   /// there is no now-playing accent to blend with.
//   static Color _blend(Color base, Color? accent, double t) {
//     if (accent == null) return base;
//     return Color.lerp(base, accent, t) ?? base;
//   }

//   static ThemeData light([Color? accent]) => ThemeData(
//     brightness: Brightness.light,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: _blend(_lightSeed, accent, 0.55),
//       brightness: Brightness.light,
//       surface: _blend(const Color.fromARGB(255, 241, 231, 231), accent, 0.1),
//     ),
//     scaffoldBackgroundColor: _blend(
//       const Color.fromARGB(255, 219, 219, 219),
//       accent,
//       0.12,
//     ),
//     canvasColor: const Color.fromARGB(255, 247, 240, 240),
//     dividerColor: const Color.fromARGB(255, 235, 234, 234),
//     cardColor: const Color.fromARGB(255, 238, 238, 238),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: Color(0xFF1D1B1A)),
//       bodyMedium: TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
//       titleLarge: TextStyle(color: Color(0xFF171514)),
//       titleMedium: TextStyle(color: Color(0xFF171514)),
//     ),
//     inputDecorationTheme: const InputDecorationTheme(
//       filled: true,
//       fillColor: Color.fromARGB(255, 245, 166, 166),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.all(Radius.circular(14)),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,
//       foregroundColor: Color(0xFF171514),
//       centerTitle: false,
//     ),
//     cardTheme: const CardThemeData(
//       color: Color.fromARGB(0, 59, 58, 58),
//       surfaceTintColor: Color.fromARGB(0, 49, 49, 49),
//       elevation: 0,
//     ),
//     useMaterial3: true,
//   );

//   static ThemeData dark([Color? accent]) => ThemeData(
//     brightness: Brightness.dark,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: _blend(_darkSeed, accent, 0.55),
//       brightness: Brightness.dark,
//       surface: _blend(const Color.fromARGB(255, 36, 39, 43), accent, 0.14),
//     ),
//     scaffoldBackgroundColor: _blend(const Color(0xFF1B1E22), accent, 0.16),
//     canvasColor: const Color(0xFF1B1E22),
//     dividerColor: const Color(0xFF30343A),
//     inputDecorationTheme: const InputDecorationTheme(
//       filled: true,
//       fillColor: Color(0xFF24282D),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.all(Radius.circular(14)),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,
//       foregroundColor: Color(0xFFF3EEE8),
//       centerTitle: false,
//     ),
//     cardTheme: const CardThemeData(
//       color: Colors.transparent,
//       surfaceTintColor: Colors.transparent,
//       elevation: 0,
//     ),
//     useMaterial3: true,
//   );
// }
