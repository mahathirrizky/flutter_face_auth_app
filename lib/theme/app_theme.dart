import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1F2937);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color textBase = Color(0xFFF9FAFB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color bgBase = Color(0xFF111827);
  static const Color bgMuted = Color(0xFF1F2937);
}

ThemeData appTheme() {
  return ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bgBase, // Default background color
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgMuted, // AppBar background
      foregroundColor: AppColors.textBase, // AppBar text/icon color
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textBase),
      bodyMedium: TextStyle(color: AppColors.textBase),
      // Add more text styles as needed
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary, // Button background
        foregroundColor: AppColors.textBase, // Button text color
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: AppColors.textMuted),
      hintStyle: TextStyle(color: AppColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.textMuted),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondary),
      ),
    ),
    // Add more theme properties as needed
  );
}
