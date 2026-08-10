// lib/features/home/home_screen.dart
// Main hub — Surah list with search, Juz/Surah toggle, last-read banner
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/surah_info.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filtered {
    if (_query.isEmpty) return kSurahList;
    final q = _query.toLowerCase();
    return kSurahList
        .where((s) =>
            s.nameTransliteration.toLowerCase().contains(q) ||
            s.nameTranslation.toLowerCase().contains(q) ||
            s.nameArabic.contains(q) ||
            s.number.toString() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSurahTab(),
                _buildJuzTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Al Quran'),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmarks_outlined),
          tooltip: 'Bookmarks',
          onPressed: () => context.goNamed('bookmarks'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => context.goNamed('settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search surah...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Surah'),
            Tab(text: 'Juz'),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTab() {
    final surahs = _filtered;
    if (surahs.isEmpty) {
      return Center(
        child: Text('No surah found',
            style: GoogleFonts.inter(color: AppTheme.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: surahs.length,
      itemBuilder: (ctx, i) => _SurahTile(
        surah: surahs[i],
        onTap: () => context.goNamed('verse-by-verse',
            pathParameters: {'surahNumber': surahs[i].number.toString()}),
      ),
    );
  }

  Widget _buildJuzTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 30,
      itemBuilder: (ctx, i) {
        final juz = i + 1;
        return _JuzTile(
          juzNumber: juz,
          onTap: () {
            // Navigate to verse-by-verse at the start of this juz
            // For now navigate to home — juz navigation will scroll to correct ayah
            context.goNamed('verse-by-verse',
                pathParameters: {'surahNumber': '1'});
          },
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNav,
      onTap: (i) {
        setState(() => _selectedNav = i);
        switch (i) {
          case 0:
            break; // already on home
          case 1:
            context.goNamed('mushaf-15');
            break;
          case 2:
            context.goNamed('mushaf-16');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Verse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories_outlined),
          activeIcon: Icon(Icons.auto_stories),
          label: '15-Line',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.import_contacts_outlined),
          activeIcon: Icon(Icons.import_contacts),
          label: '16-Line',
        ),
      ],
    );
  }
}

// ── Surah Tile ────────────────────────────────────────────────────────────────
class _SurahTile extends StatelessWidget {
  final SurahInfo surah;
  final VoidCallback onTap;

  const _SurahTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Number Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  surah.number.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTransliteration,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        surah.nameTranslation,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${surah.ayahCount} ayahs',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: surah.revelationType == 'Meccan'
                              ? const Color(0xFFFFF3CD)
                              : const Color(0xFFD1ECF1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          surah.revelationType,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: surah.revelationType == 'Meccan'
                                ? const Color(0xFF856404)
                                : const Color(0xFF0C5460),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arabic name
            Text(
              surah.nameArabic,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Juz Tile ──────────────────────────────────────────────────────────────────
class _JuzTile extends StatelessWidget {
  final int juzNumber;
  final VoidCallback onTap;

  const _JuzTile({required this.juzNumber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  juzNumber.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Juz $juzNumber',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
