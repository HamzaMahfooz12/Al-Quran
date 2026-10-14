// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette: Imperial Midnight Sapphire & Brushed Gold ──────────────
  static const Color primary        = Color(0xFF0F2038);   // Imperial Midnight Sapphire
  static const Color primaryLight   = Color(0xFF1E3A60);   // Royal Sapphire Blue
  static const Color primaryDark    = Color(0xFF071424);   // Deep Night Void
  static const Color primarySurface = Color(0xFFEDF3FB);   // Soft Sapphire Tint
  static const Color gold           = Color(0xFFD4AF37);   // Radiant Brushed Gold
  static const Color goldLight      = Color(0xFFF3C64F);   // Luminous Gold
  static const Color goldDark       = Color(0xFFB8860B);   // Antique Gold
  static const Color goldSurface    = Color(0xFFFFFBEB);   // Soft Amber Ivory Tint
  static const Color surface        = Color(0xFFFFFFFF);   // Pure Ivory Surface
  static const Color background     = Color(0xFFF8FAFC);   // Clean Modern Off-White
  static const Color cardBg         = Color(0xFFFFFFFF);   // Elevated Card Surface
  static const Color cardBgSecondary= Color(0xFFF1F5F9);   // Cool Slate Card
  static const Color textPrimary    = Color(0xFF0F172A);   // Deep Slate Charcoal
  static const Color textSecondary  = Color(0xFF334155);   // Slate Charcoal
  static const Color textMuted      = Color(0xFF64748B);   // Muted Slate
  static const Color divider        = Color(0xFFE2E8F0);   // Light Slate Border
  static const Color error          = Color(0xFFDC2626);   // Crimson Red

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
          scrolledUnderElevation: 1.5,
          shadowColor: divider.withValues(alpha: 0.5),
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
            borderSide: const BorderSide(color: primaryLight, width: 1.6),
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
          backgroundColor: Colors.transparent,
          selectedItemColor: primary,
          unselectedItemColor: textMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
