import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFFF8DA1); // Ballet Pink
  static const Color secondaryColor = Color(0xFFFFC2D1); // Light Pink
  static const Color accentColor = Color(0xFFE5C1CD); // Dusty Rose

  static const Color backgroundLight = Color(0xFFFFF5F6); // Soft Pink White
  static const Color backgroundDark = Color(0xFF2D2426); // Dark Mauve

  static const Color textPrimaryLight = Color(0xFF4A3034); // Deep Mauve
  static const Color textSecondaryLight = Color(0xFF836267); // Muted Mauve
  static const Color textPrimaryDark = Color(0xFFFFF5F6); // Soft Pink White
  static const Color textSecondaryDark = Color(0xFFE5C1CD); // Dusty Rose

  static const Color errorColor = Color(0xFFE57373); // Soft Red
  static const Color successColor = Color(0xFF81C784); // Soft Green
  static const Color warningColor = Color(0xFFFFB74D); // Soft Orange

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundLight,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: textPrimaryLight,
      onSurface: textPrimaryLight,
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryLight,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: textSecondaryLight,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );

  // Dark Theme
}
