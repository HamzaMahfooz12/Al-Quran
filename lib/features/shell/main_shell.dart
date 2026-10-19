// lib/features/shell/main_shell.dart
// Root shell widget with docked NavigationBar & More screen matching Google Stitch design
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';
import '../quran/quran_screen.dart';
import '../prayer_times/screens/prayer_times_screen.dart';
import '../qibla/screens/qibla_screen.dart';
import '../../services/settings_service.dart';
import '../../core/widgets/app_drawer.dart';

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
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFFD7C7A5), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x12625A45),
              blurRadius: 25,
              offset: Offset(0, -8),
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
                  color: const Color(0xFFBCA061),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D9D814C),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Home',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF806433),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isActive)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBCA061),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
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
                      ? const Color(0x1FBCA061)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  color: isActive ? const Color(0xFF806433) : const Color(0xFF70776C),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF806433) : const Color(0xFF70776C),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 4 : 0,
                height: isActive ? 4 : 0,
                decoration: const BoxDecoration(
                  color: Color(0xFFBCA061),
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

// ── "More" Screen matching Stitch All-in-One Utilities design exactly ────────
class _MoreScreen extends ConsumerStatefulWidget {
  const _MoreScreen();

  @override
  ConsumerState<_MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<_MoreScreen> {
  bool _preferencesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final reciterId = ref.watch(selectedReciterIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      drawer: const AppDrawer(),
      appBar: _buildTopAppBar(context),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + bottomPad),
        children: [
          // ── Section 1: Digital Tasbeeh Hero Banner ──
          _buildTasbeehHeroBanner(context),

          const SizedBox(height: 16),

          // ── Section 2: Dedicated Islamic Utility Tiles (6 Features) ──
          _buildCoreUtilitiesSection(context),

          const SizedBox(height: 16),

          // ── Section 3: App Preferences & Global Settings ──
          _buildPreferencesSection(arabicFontSize, reciterId),

          const SizedBox(height: 16),

          // ── Section 4: Spiritual Dedication / About Card ──
          _buildSpiritualDedicationCard(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFAF7F2),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 66,
      leading: Center(
        child: Builder(
          builder: (ctx) => InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Scaffold.of(ctx).openDrawer();
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF0F2038), size: 20),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'More Features',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2038),
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'الميزات والخدمات الإسلامية',
            style: GoogleFonts.amiri(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC59A27),
              height: 1.05,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: InkWell(
            onTap: () => context.goNamed('search'),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded, color: Color(0xFF0F2038), size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasbeehHeroBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.goNamed('tasbeeh');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 134,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFDFBF7), Color(0xFFF5ECE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC59A27).withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2038).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle Islamic Star Watermark on Right
              Positioned(
                right: -15,
                bottom: -20,
                child: Opacity(
                  opacity: 0.08,
                  child: Text(
                    '✦',
                    style: GoogleFonts.amiri(fontSize: 130, color: const Color(0xFFC59A27)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Warm Ivory Frame with Fingerprint / Tasbeeh Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC59A27).withValues(alpha: 0.30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.fingerprint_rounded, color: Color(0xFFC59A27), size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Titles & Start Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Digital Tasbeeh',
                                style: GoogleFonts.outfit(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F2038),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6EBD0),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFC59A27).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'السبحة',
                                  style: GoogleFonts.amiri(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF876510),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Keep your Zikr close to your heart',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF7C7365),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EBD0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFC59A27).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start Tasbeeh',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F2038),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, color: Color(0xFFC59A27), size: 13),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E1D2)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C7365), size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreUtilitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC59A27),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'CORE QURANIC & WORSHIP UTILITIES',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF0F2038),
                  ),
                ),
              ],
            ),
            Text(
              '6 Features',
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC59A27),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Daily Duas & Azkar
        _stitchUtilityTile(
          icon: Icons.spa_rounded,
          title: 'Daily Duas & Azkar',
          arabicBadge: 'الأذكار اليومية',
          subtitle: 'Hisn al-Muslim morning, evening & daily supplications',
          onTap: () => context.goNamed('azkar'),
        ),

        // 2. Bookmarks & Sajda
        _stitchUtilityTile(
          icon: Icons.bookmark_border_rounded,
          title: 'Bookmarks & Sajda',
          pillBadge: '14 Sajdas',
          subtitle: 'Quick access to saved Ayahs, Juz & 14 Sajda locations',
          onTap: () => context.goNamed('bookmarks'),
        ),

        // 3. 15-Line Madani Mushaf
        _stitchUtilityTile(
          icon: Icons.menu_book_rounded,
          title: '15-Line Madani Mushaf',
          pillBadge: 'Madani',
          subtitle: 'Saudi standard format for Huffaz & Tilawat',
          onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
        ),

        // 4. 16-Line Indo-Pak Mushaf
        _stitchUtilityTile(
          icon: Icons.auto_stories_rounded,
          title: '16-Line Indo-Pak Mushaf',
          pillBadge: 'Tajweed',
          subtitle: 'Indo-Pak standard format for Huffaz with tajweed',
          onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'}),
        ),

        // 5. Mutashabihat (Similar Ayat)
        _stitchUtilityTile(
          icon: Icons.compare_arrows_rounded,
          title: 'Mutashabihat (Similar Ayat)',
          pillBadge: '2,700+ Ayat',
          subtitle: 'Comparative verse explorer for 2,700+ similar verses',
          onTap: () => context.goNamed('mutashabihat'),
        ),

        // 6. Mistakes Report
        _stitchUtilityTile(
          icon: Icons.fact_check_rounded,
          title: 'Mistakes Report',
          pillBadge: 'Memorization',
          subtitle: 'Track your recitation accuracy and memorization errors',
          onTap: () => context.goNamed('mistakes-report'),
        ),
      ],
    );
  }

  Widget _stitchUtilityTile({
    required IconData icon,
    required String title,
    String? arabicBadge,
    String? pillBadge,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E1D2).withValues(alpha: 0.6)),
                  ),
                  child: Icon(icon, color: const Color(0xFFC59A27), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F2038),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (arabicBadge != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              arabicBadge,
                              style: GoogleFonts.amiri(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC59A27),
                              ),
                            ),
                          ],
                          if (pillBadge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6EBD0),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFC59A27).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                pillBadge,
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF876510),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF7C7365),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E1D2).withValues(alpha: 0.6)),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC59A27), size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(double arabicFontSize, String reciterId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC59A27),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'PREFERENCES & CUSTOMIZATION',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: const Color(0xFF0F2038),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E1D2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Card Header
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _preferencesExpanded = !_preferencesExpanded);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8E1D2)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF0F2038), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings & Preferences',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F2038),
                              ),
                            ),
                            Text(
                              'Languages, reciters, font size & calculation rules',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: const Color(0xFF7C7365),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _preferencesExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: const Color(0xFF7C7365),
                      ),
                    ],
                  ),
                ),
              ),

              if (_preferencesExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF0EBE1)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Arabic Font Size Preview Slider (Interactive Riverpod state!)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E1D2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_size_rounded, color: Color(0xFFC59A27), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Arabic Font Size Preview',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F2038),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6EBD0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${arabicFontSize.toInt()} px',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF876510),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFC59A27),
                                inactiveTrackColor: const Color(0xFFE8E1D2),
                                thumbColor: const Color(0xFFC59A27),
                                overlayColor: const Color(0xFFC59A27).withValues(alpha: 0.15),
                                trackHeight: 3.5,
                              ),
                              child: Slider(
                                value: arabicFontSize,
                                min: 18.0,
                                max: 48.0,
                                onChanged: (val) {
                                  ref.read(arabicFontSizeProvider.notifier).updateSize(val);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('18px (Compact)', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF7C7365))),
                                Text(
                                  'بِسْمِ اللَّهِ',
                                  style: GoogleFonts.amiri(
                                    fontSize: (arabicFontSize * 0.6).clamp(13.0, 22.0),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F2038),
                                  ),
                                ),
                                Text('48px (Large)', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF7C7365))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Key-value pills grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.3,
                        children: [
                          _preferencePill(Icons.record_voice_over_rounded, 'Reciter', 'Mishary', () {
                            context.goNamed('settings');
                          }),
                          _preferencePill(Icons.balance_rounded, 'Juristic', 'Hanafi', () {
                            context.goNamed('settings');
                          }),
                          _preferencePill(Icons.bedtime_rounded, 'Sleep Timer', '15 min', () {
                            context.goNamed('settings');
                          }),
                          _preferencePill(Icons.storage_rounded, 'Audio Cache', '142 MB', () {
                            context.goNamed('settings');
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _preferencePill(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E1D2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFC59A27)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF7C7365),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE8E1D2)),
              ),
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2038),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiritualDedicationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC59A27).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Center Emblem with Round App Logo and Gold Ring
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE8B931), Color(0xFFC59A27), Color(0xFFA37B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC59A27).withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon_512x512.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hifz ul Quran',
            style: GoogleFonts.outfit(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2038),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EBD0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'v2.0.0',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF876510),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('•', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7C7365))),
              const SizedBox(width: 6),
              Text(
                'Standard Islamic Edition',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7C7365),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFC59A27).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '“Designed and crafted with devotion for Huffaz, students, and lovers of the Holy Quran worldwide.”',
            style: GoogleFonts.amiri(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF7C7365),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}