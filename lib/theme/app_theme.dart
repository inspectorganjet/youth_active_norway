import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color darkBlue = Color(0xFF1E6091);
  static const Color lightBlue = Color(0xFFE0F2FE);
  static const Color accentCyan = Color(0xFF0077B6);

  static const Color purpleXP = Color(0xFF8B5CF6);
  static const Color goldCoins = Color(0xFFF59E0B);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final baseText = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: cardWhite,
        background: backgroundLight,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textDark,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryBlue),
        titleTextStyle: GoogleFonts.outfit(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue.shade50, width: 1),
        ),
      ),
    );
  }
}
