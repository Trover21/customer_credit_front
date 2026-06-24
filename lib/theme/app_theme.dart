import 'package:flutter/material.dart';

/// ኣኩ ሚኒ-ማርኬት Design System
/// ኩሎም ሕብርታትን theme configuration ን ኣብዚ ፋይል ይርከቡ።

// --- Color Constants ---
const Color kSlate900 = Color(0xFF0F172A);
const Color kSlate800 = Color(0xFF1E293B);
const Color kSlate700 = Color(0xFF334155);
const Color kSlate500 = Color(0xFF64748B);
const Color kSlate400 = Color(0xFF94A3B8);

// Emerald/Mint Green brand color from the reference image
const Color kPrimaryGreen = Color(0xFF00B589);
const Color kIndigo500 = kPrimaryGreen; // Aliased to avoid breaking existing imports referencing kIndigo500

const Color kEmerald500 = Color(0xFF10B981);
const Color kCoral500 = Color(0xFFF43F5E);
const Color kAmber500 = Color(0xFFF59E0B);

// Global theme notifier to switch dynamically
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class AppTheme {
  AppTheme._();

  // --- Light Theme Definition ---
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0), // Slate 200
      primaryColor: kPrimaryGreen,
      colorScheme: const ColorScheme.light(
        primary: kPrimaryGreen,
        secondary: kEmerald500,
        surface: Colors.white,
        error: kCoral500,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: kSlate900),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: kSlate900,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kSlate900),
        bodyMedium: TextStyle(color: kSlate500),
      ),
    );
  }

  // --- Dark Theme Definition ---
  static ThemeData get darkTheme {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: kSlate900,
    cardColor: kSlate800,
    dividerColor: kSlate700,
    primaryColor: kPrimaryGreen,
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryGreen,
      secondary: kEmerald500,
      surface: kSlate800,
      error: kCoral500,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSlate800,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSlate800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: kSlate400),
    ),
  );
  }
}
