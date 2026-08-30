// lib/core/widgets/app_drawer.dart
// Shared Luxury Sidebar Drawer for Hafiz ul Quran app

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // ── Meadow Jade & Warm Amber Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 48 + MediaQuery.paddingOf(context).top * 0.3, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C7A39), Color(0xFF3FA34D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo_emblem.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hifz ul Quran',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'حِفْظُ الْقُرْآنِ • Read, Listen, Reflect',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFFEF3C7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation List ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _drawerTile(
                  context: context,
                  icon: Icons.format_list_bulleted,
                  title: 'Surah & Juz Index',
                  subtitle: 'Complete 114 Surahs browser',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('simple-quran');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  title: '15-Line Mushaf (Hafizi)',
                  subtitle: 'South Asian standard 15-line layout',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mushaf-15');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.auto_stories_rounded,
                  title: '16-Line Mushaf (IndoPak)',
                  subtitle: 'Taj Company standard 16-line layout',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mushaf-16');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.access_time_filled_rounded,
                  title: 'Prayer Times',
                  subtitle: 'Accurate daily schedule & countdown',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('prayer-times');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.explore_rounded,
                  title: 'Qibla Direction',
                  subtitle: 'Live compass to Kaaba',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('qibla');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.fingerprint_rounded,
                  title: 'Digital Tasbeeh',
                  subtitle: 'Target counter with vibration',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('tasbeeh');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.front_hand_rounded,
                  title: 'Authentic Azkar & Duas',
                  subtitle: 'Hisnul Muslim daily supplications',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('azkar');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.compare_arrows_rounded,
                  title: 'Mutashabihat Explorer',
                  subtitle: 'Similar Quranic verses comparator',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mutashabihat');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.error_outline_rounded,
                  title: 'Mistakes Report',
                  subtitle: 'Hifz tracking and error logs',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mistakes-report');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.bookmark_rounded,
                  title: 'Bookmarks & Sajda Verses',
                  subtitle: 'Saved verses and 14 Sajda Ayahs',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('bookmarks');
                  },
                ),
                _drawerTile(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'Fonts, reciters, translations & cache',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('settings');
                  },
                ),
              ],
            ),
          ),

          // ── Drawer Footer ──
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8E4))),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF2D6A4F), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Hifz ul Quran • v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
    );
  }
}
