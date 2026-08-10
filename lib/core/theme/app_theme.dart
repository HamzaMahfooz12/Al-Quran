// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1B4332);   // Deep forest green
  static const Color primaryLight   = Color(0xFF2D6A4F);
  static const Color primarySurface = Color(0xFFD8F3DC);
  static const Color gold           = Color(0xFFD4A853);
  static const Color goldLight      = Color(0xFFF0D080);
  static const Color surface        = Color(0xFFF8F9FA);
  static const Color background     = Color(0xFFFFFFFF);
  static const Color cardBg         = Color(0xFFF0F4F1);
  static const Color textPrimary    = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF4A5568);
  static const Color textMuted      = Color(0xFF9AA5B4);
  static const Color divider        = Color(0xFFE2E8F0);
  static const Color error          = Color(0xFFE53E3E);

  // ── Arabic font size ──────────────────────────────────────────────────────
  static const double kArabicFontSizeDefault = 28.0;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: gold,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: divider,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          bodyLarge: GoogleFonts.inter(
              fontSize: 16, color: textPrimary),
          bodyMedium: GoogleFonts.inter(
              fontSize: 14, color: textSecondary),
          bodySmall: GoogleFonts.inter(
              fontSize: 12, color: textMuted),
          titleLarge: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
          titleMedium: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          labelSmall: GoogleFonts.inter(
              fontSize: 11, color: textMuted, letterSpacing: 0.5),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: background,
          selectedItemColor: primary,
          unselectedItemColor: textMuted,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
