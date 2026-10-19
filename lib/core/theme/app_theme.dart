// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette: Warm Daylight Tactile Paper & Royal Gold ─────────────────
  // Based on Figma's daylight design: quiet, tactile surfaces instead of harsh navy panels.
  static const Color primary        = Color(0xFF3F4938);   // Tactile Deep Olive Slate (Figma --navy-dark)
  static const Color primaryLight   = Color(0xFF59634A);   // Tactile Olive Gray (Figma --navy)
  static const Color primaryDark    = Color(0xFF354033);   // Deep Ink (Figma --ink)
  static const Color primarySurface = Color(0xFFEDF2E8);   // Soothing Pale Sage Cream Tint
  static const Color gold           = Color(0xFFC6A15B);   // Tactile Warm Gold (Figma --gold)
  static const Color goldLight      = Color(0xFFD8B873);   // Luminous Gold (Figma --bright-gold)
  static const Color goldDark       = Color(0xFF96743B);   // Antique Gold (Figma --gold-dark)
  static const Color goldSurface    = Color(0xFFF7F1E5);   // Soft Champagne Ivory Tint
  static const Color surface        = Color(0xFFFFFFFF);   // Pure Ivory Surface
  static const Color background     = Color(0xFFFAF7F2);   // Warm Alabaster Parchment (Figma --paper)
  static const Color cardBg         = Color(0xFFFFFFFF);   // Elevated Card Surface
  static const Color cardBgSecondary= Color(0xFFF7F4EE);   // Warm Light Parchment Tint
  static const Color textPrimary    = Color(0xFF354033);   // Tactile Slate Ink (Figma --ink)
  static const Color textSecondary  = Color(0xFF59634A);   // Slate Charcoal (Figma --navy)
  static const Color textMuted      = Color(0xFF7A8075);   // Muted Slate (Figma --muted)
  static const Color divider        = Color(0xFFEDE7DC);   // Soft Warm Border
  static const Color error          = Color(0xFFDC2626);   // Crimson Red
  static const Color parchment      = Color(0xFFFAF7F2);   // Warm Alabaster Parchment
  static const Color parchmentLight = Color(0xFFFCFAF7);   // Luminous Parchment
  static const Color borderWarm     = Color(0xFFDED6C6);   // Soft Warm Border
  static const Color borderSoft     = Color(0xFFE8E0D0);   // Subtle Warm Border
  static const Color accentGold     = Color(0xFFC6A15B);   // Royal Stitch Gold
  static const Color accentGoldLight= Color(0xFFD8B873);   // Luminous Accent Gold
  static const Color accentGoldSoft = Color(0xFFEDE1C5);   // Champagne Ivory Gold
  static const Color brightGold     = Color(0xFFD8B873);   // Vibrant Accent Gold
  static const Color sageBadge      = Color(0xFF748164);   // Ayah Medallion Sage Green
  static const Color sageLight      = Color(0xFFEDF2E8);   // Pale Sage Tint

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
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0.2,
          ),
          iconTheme: const IconThemeData(color: primary, size: 24),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.outfit(
              fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
          displayMedium: GoogleFonts.outfit(
              fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary),
          titleLarge: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
          titleMedium: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          titleSmall: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: GoogleFonts.plusJakartaSans(
              fontSize: 15, color: textPrimary, height: 1.5),
          bodyMedium: GoogleFonts.plusJakartaSans(
              fontSize: 13.5, color: textSecondary, height: 1.45),
          bodySmall: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: textMuted),
          labelSmall: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: textMuted, letterSpacing: 0.5),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: divider, width: 1.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primary.withValues(alpha: 0.25),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}
