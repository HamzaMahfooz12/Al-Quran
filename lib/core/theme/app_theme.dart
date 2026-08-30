// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette: Meadow Jade & Warm Amber ────────────────────────────────
  static const Color primary        = Color(0xFF3FA34D);   // Meadow Jade Green
  static const Color primaryLight   = Color(0xFF56BA64);   // Fresh Mint Jade
  static const Color primaryDark    = Color(0xFF2C7A39);   // Deep Meadow
  static const Color primarySurface = Color(0xFFEAF6EC);   // Soft Jade Tint
  static const Color gold           = Color(0xFFF59E0B);   // Warm Radiant Amber
  static const Color goldLight      = Color(0xFFFBBF24);   // Light Amber
  static const Color goldDark       = Color(0xFFD97706);   // Deep Amber
  static const Color goldSurface    = Color(0xFFFEF3C7);   // Soft Amber Tint
  static const Color surface        = Color(0xFFFFFFFF);   // Pure Ivory Surface
  static const Color background     = Color(0xFFFAF7F2);   // Soft Cream Linen Parchment
  static const Color cardBg         = Color(0xFFFFFFFF);   // Clean Elevated Card Surface
  static const Color cardBgSecondary= Color(0xFFF5EFE6);   // Warm Parchment Card
  static const Color textPrimary    = Color(0xFF1B2A1E);   // Deep Forest Charcoal
  static const Color textSecondary  = Color(0xFF4B5E50);   // Warm Olive Slate
  static const Color textMuted      = Color(0xFF8D9E92);   // Warm Khaki Taupe
  static const Color divider        = Color(0xFFE8E1D2);   // Warm Linen Border
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
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          iconTheme: const IconThemeData(color: primary),
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
            side: const BorderSide(color: divider, width: 1.0),
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
          fillColor: cardBgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
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
