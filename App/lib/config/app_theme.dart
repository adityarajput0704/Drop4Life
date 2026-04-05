import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color primaryRed = Color(0xFFC8102E);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Status Badge Colors
  static const Color fulfilledBg = Color(0xFFF0FDF4);
  static const Color fulfilledText = Color(0xFF15803D);
  static const Color acceptedBg = Color(0xFFFFFBEB);
  static const Color acceptedText = Color(0xFFB45309);
  static const Color cancelledBg = Color(0xFFF9FAFB);
  static const Color cancelledText = Color(0xFF6B7280);

  // Urgency Badge Colors
  static const Color criticalBg = primaryRed;
  static const Color criticalText = Colors.white;
  static const Color highBg = Color(0xFFF97316);
  static const Color highText = Colors.white;
  static const Color mediumBg = Color(0xFFEAB308);
  static const Color mediumText = Colors.white;
  static const Color lowBg = Color(0xFF22C55E);
  static const Color lowText = Colors.white;

  // Availability Badge Colors
  static const Color availableBg = fulfilledBg;
  static const Color availableText = fulfilledText;
  static const Color unavailableBg = Color(0xFFFEF2F2);
  static const Color unavailableText = primaryRed;

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryRed,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
