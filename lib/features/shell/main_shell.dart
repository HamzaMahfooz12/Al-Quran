// lib/features/shell/main_shell.dart
// Root shell widget — persistent bottom NavigationBar across all 5 main tabs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
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

  static const _tabs = [
    QuranScreen(),
    PrayerTimesScreen(),
    HomeScreen(),
    QiblaScreen(),
    _MoreScreen(),
  ];

  void _onNavTap(int i) {
    if (i == 2) {
      // Whenever Home is clicked, pick/refresh a new Ayah of the Day
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
          color: AppTheme.cardBg,
          border: const Border(top: BorderSide(color: Color(0xFFE8ECE9), width: 0.8)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Quran', index: 0, selectedIndex: _selectedIndex, onTap: _onNavTap),
                _NavItem(icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled_rounded, label: 'Prayer', index: 1, selectedIndex: _selectedIndex, onTap: _onNavTap),
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 2, selectedIndex: _selectedIndex, onTap: _onNavTap),
                _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Qibla', index: 3, selectedIndex: _selectedIndex, onTap: _onNavTap),
                _NavItem(icon: Icons.apps_outlined, activeIcon: Icons.apps, label: 'More', index: 4, selectedIndex: _selectedIndex, onTap: _onNavTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "More" screen — Tasbeeh, Azkar, Search, Bookmarks, Settings ──────────────
class _MoreScreen extends ConsumerWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('More', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomPad),
        children: [
          _MoreTile(icon: Icons.fingerprint_rounded, color: const Color(0xFF5D4037), title: 'Digital Tasbeeh', subtitle: 'Counter with haptic feedback', onTap: () => context.goNamed('tasbeeh')),
          _MoreTile(icon: Icons.auto_awesome, color: const Color(0xFFC2185B), title: 'Daily Duas & Azkar', subtitle: 'Hisn al-Muslim supplications', onTap: () => context.goNamed('azkar')),
          _MoreTile(icon: Icons.search_rounded, color: const Color(0xFF1565C0), title: 'Search Quran', subtitle: 'Search across 6,236 verses', onTap: () => context.goNamed('search')),
          _MoreTile(icon: Icons.bookmarks_rounded, color: const Color(0xFF2E7D32), title: 'Bookmarks', subtitle: 'Saved verses & pages', onTap: () => context.goNamed('bookmarks')),
          _MoreTile(icon: Icons.auto_stories, color: const Color(0xFF00796B), title: '15-Line Mushaf', subtitle: 'Saudi standard format', onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'})),
          _MoreTile(icon: Icons.import_contacts, color: const Color(0xFF6A1B9A), title: '16-Line Mushaf', subtitle: 'Indo-Pak standard format', onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'})),
          _MoreTile(icon: Icons.analytics_outlined, color: const Color(0xFFE65100), title: 'Mistakes Report', subtitle: 'Track recitation errors', onTap: () => context.goNamed('mistakes-report')),
          const Divider(height: 24),
          _MoreTile(icon: Icons.settings_outlined, color: AppTheme.textMuted, title: 'Settings', subtitle: 'App preferences & audio', onTap: () => context.goNamed('settings')),
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

  const _MoreTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8ECE9))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}