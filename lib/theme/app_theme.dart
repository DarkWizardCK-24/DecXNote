import 'package:deck_note/models/todo_model.dart';
import 'package:flutter/material.dart';

/// Coral on midnight navy. Everything (ThemeData, glass widgets, cards) pulls
/// its colours, radii and spacing from here.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFFFF6F61);
  static const Color secondaryColor = Color(0xFFFF9F6B);
  static const Color accentColor = Color(0xFFFF4D6D);
  static const Color backgroundColor = Color(0xFF0A0E27);
  static const Color surfaceColor = Color(0xFF131833);
  static const Color cardColor = Color(0xFF1C2244);

  static const Color success = Color(0xFF2ED8A3);
  static const Color warning = Color(0xFFFFB84D);
  static const Color danger = Color(0xFFFF5470);
  static const Color info = Color(0xFF6EA8FF);

  static const String fontFamily = 'Inter';

  // Radii and spacing.
  static const double radiusS = 10;
  static const double radiusM = 15;
  static const double radiusL = 25;
  static const double space = 20;

  static const List<Color> cardColors = [
    Color(0xFFFF7A8A),
    Color(0xFFFF9F6B),
    Color(0xFF8E7CFF),
    Color(0xFF2ED8A3),
    Color(0xFFFF6FB5),
    Color(0xFF6EA8FF),
    Color(0xFFB69CFF),
    Color(0xFFFFB84D),
    Color(0xFF5BE3C2),
    Color(0xFFFF6F61),
  ];

  /// Safe lookup so a bad `colorIndex` in Firestore can never crash a card.
  static Color cardColorAt(int index) =>
      cardColors[index.abs() % cardColors.length];

  static Color priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return danger;
      case Priority.medium:
        return warning;
      case Priority.low:
        return success;
    }
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: danger,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        actionTextColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.22),
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: const IconThemeData(color: Colors.white60),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white60,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: primaryColor.withValues(alpha: 0.28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white70,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}
