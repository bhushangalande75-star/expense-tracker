import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A light, luxurious theme: warm ivory backgrounds, a deep emerald-teal
/// accent (matching the app icon), and gold highlights for a premium,
/// airy feel instead of a dark/nightclub look.
class AppTheme {
  static const Color background = Color(0xFFFBF8F2); // warm ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEAE3D3);

  static const Color gold = Color(0xFFB8860B); // deeper gold, reads well on light bg
  static const Color goldMuted = Color(0xFFD4AF37);
  static const Color emerald = Color(0xFF0F6D5C); // matches the icon's teal-green
  static const Color emeraldLight = Color(0xFF17A589);

  static const Color textPrimary = Color(0xFF22262B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color danger = Color(0xFFC0392B);
  static const Color success = Color(0xFF1F8A55);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: emerald,
        secondary: gold,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
        bodyLarge: GoogleFonts.inter(color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: emerald),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F1E6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emerald, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: emerald,
        unselectedItemColor: textSecondary,
        elevation: 8,
      ),
      dividerColor: cardBorder,
    );
  }
}
