// lib/core/widgets/app_drawer.dart
// Luxury Alabaster & Warm Gold Sidebar Drawer for Hifz ul Quran app
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_version_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAF7F2),
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // ── Luxury Alabaster & Brushed Gold Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 48 + MediaQuery.paddingOf(context).top * 0.3, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDFBF7), Color(0xFFF5ECE0)],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFC59A27).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E1E38).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Subtle Islamic Star Watermark on Top-Right
                Positioned(
                  right: -10,
                  top: -15,
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      '✦',
                      style: GoogleFonts.amiri(fontSize: 110, color: const Color(0xFFC59A27)),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Emblem with Gold Bezel Ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1CB8860B),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo_emblem.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Title
                    Row(
                      children: [
                        Text(
                          'Hifz ul Quran',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0E1E38),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC59A27),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Subtitle / Tagline in Gold
                    Text(
                      'حفظ القرآن • Read, Listen, Reflect',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF8C6D34),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Navigation List ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              children: [
                _drawerTile(
                  context: context,
                  icon: Icons.format_list_bulleted_rounded,
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
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFECE4D8))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8DFD0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFFC5A059), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Hifz ul Quran • ${AppVersionService.displayVersion}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C633E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: Color(0xFFD4AF37), size: 16),
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2).withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B1C1E),
            blurRadius: 6,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Warm Ivory / Champagne Icon Container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8E1D2).withValues(alpha: 0.7),
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xFFC59A27), size: 20),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0E1E38),
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Warm Gold Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFC59A27),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
