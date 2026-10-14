// lib/features/shell/main_shell.dart
// Root shell widget with docked NavigationBar & More screen matching Reference Image 3
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';
import '../quran/quran_screen.dart';
import '../prayer_times/screens/prayer_times_screen.dart';
import '../qibla/screens/qibla_screen.dart';

// Tab indices:  0=Quran  1=Prayer  2=Home  3=Qibla  4=More
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 2; // Default to Home

  List<Widget> get _tabs => [
    const QuranScreen(),
    const PrayerTimesScreen(),
    const HomeScreen(),
    QiblaScreen(isActive: _selectedIndex == 3),
    const _MoreScreen(),
  ];

  void _onNavTap(int i) {
    HapticFeedback.lightImpact();
    if (i == 2) {
      ref.read(dailyAyahIndexProvider.notifier).update((state) => (state + 1) % kDailyVerses.length);
    }
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2038).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: 'Quran',
                  urduLabel: 'القرآن',
                  index: 0,
                  selectedIndex: _selectedIndex,
                  onTap: _onNavTap,
                ),
                _NavItem(
                  icon: Icons.access_time_outlined,
                  activeIcon: Icons.access_time_filled_rounded,
                  label: 'Prayer',
                  urduLabel: 'نماز',
                  index: 1,
                  selectedIndex: _selectedIndex,
                  onTap: _onNavTap,
                ),
                _CenterHomeItem(
                  selectedIndex: _selectedIndex,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Qibla',
                  urduLabel: 'قبلہ',
                  index: 3,
                  selectedIndex: _selectedIndex,
                  onTap: _onNavTap,
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'More',
                  urduLabel: 'مزید',
                  index: 4,
                  selectedIndex: _selectedIndex,
                  onTap: _onNavTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterHomeItem extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onTap;

  const _CenterHomeItem({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == 2;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? const [Color(0xFFD4AF37), Color(0xFFB8860B)]
                        : const [Color(0xFF1E3A60), Color(0xFF0F2038)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.white : const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? const Color(0xFFD4AF37) : const Color(0xFF0F2038))
                          .withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isActive ? Icons.home_rounded : Icons.home_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                'Home',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF0F2038) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final String urduLabel;
  final int index, selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.urduLabel,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0F2038).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  color: isActive ? const Color(0xFF0F2038) : const Color(0xFF64748B),
                  size: 23,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF0F2038) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 5 : 0,
                height: isActive ? 5 : 0,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── "More" screen — Hero Carousel matching Reference Image 3 ────────────────
class _MoreScreen extends ConsumerWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'More Features',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F2038),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + bottomPad),
        children: [
          // ── 1. Digital Tasbeeh Hero Banner (Matching Reference Image 3) ──
          InkWell(
            onTap: () => context.goNamed('tasbeeh'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 135,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2038).withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Background Tasbeeh / Mosque Art
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/tasbeeh_banner_bg.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                    ),

                    // Atmospheric Gradient Overlay on Left
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0F2038).withValues(alpha: 0.92),
                              const Color(0xFF1E3A60).withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // Banner Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Center(
                              child: Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Digital Tasbeeh',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Keep your Zikr close to your heart',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A60),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Start Tasbeeh',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dots Indicator
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A60),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. More Navigation Tiles ──
          _MoreTile(
            icon: Icons.spa_rounded,
            color: const Color(0xFFC2185B),
            title: 'Daily Duas & Azkar',
            subtitle: 'Hisn al-Muslim morning, evening & daily supplications',
            onTap: () => context.goNamed('azkar'),
          ),
          _MoreTile(
            icon: Icons.bookmarks_rounded,
            color: const Color(0xFF7B1FA2),
            title: 'Bookmarks & Sajda',
            subtitle: 'Quick access to your saved Ayahs, Juz & Sajda locations',
            onTap: () => context.goNamed('bookmarks'),
          ),
          _MoreTile(
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF1976D2),
            title: '15-Line Mushaf',
            subtitle: 'Saudi standard format for Huffaz & Tilawat',
            onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
          ),
          _MoreTile(
            icon: Icons.import_contacts_rounded,
            color: const Color(0xFF6A1B9A),
            title: '16-Line Mushaf',
            subtitle: 'Indo-Pak standard format for Huffaz with tajweed markings',
            onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'}),
          ),
          _MoreTile(
            icon: Icons.compare_arrows_rounded,
            color: const Color(0xFF2563EB),
            title: 'Mutashabihat (Similar Ayat)',
            subtitle: 'Comparative verse explorer for 2,700+ similar Quranic verses',
            onTap: () => context.goNamed('mutashabihat'),
          ),
          _MoreTile(
            icon: Icons.fact_check_rounded,
            color: const Color(0xFFE65100),
            title: 'Mistakes Report',
            subtitle: 'Track your recitation accuracy and memorization errors',
            onTap: () => context.goNamed('mistakes-report'),
          ),
          const Divider(height: 20),
          _MoreTile(
            icon: Icons.settings_outlined,
            color: const Color(0xFF4B5563),
            title: 'Settings & Preferences',
            subtitle: 'Translation languages, reciters, font size & audio cache',
            onTap: () => context.goNamed('settings'),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}