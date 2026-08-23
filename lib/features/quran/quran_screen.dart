// lib/features/quran/quran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final repo = ref.read(quranRepositoryProvider);
    final lr = await repo.getLastRead('verse_by_verse') ??
        await repo.getLastRead('mushaf_16') ??
        await repo.getLastRead('mushaf_15');
    if (mounted) setState(() => _lastRead = lr);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          Text('Quran Hub', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(width: 6),
          const Text('القرآن الكريم', style: TextStyle(fontFamily: 'Scheherazade New', fontSize: 20, color: AppTheme.gold, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: AppTheme.primary), tooltip: 'Search', onPressed: () => context.goNamed('search')),
          IconButton(icon: const Icon(Icons.bookmarks_outlined, color: AppTheme.primary), tooltip: 'Bookmarks', onPressed: () => context.goNamed('bookmarks')),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomPad),
        children: [
          // ── 1. Last Read Banner ──
          if (_lastRead != null) ...[
            _buildLastReadBanner(),
            const SizedBox(height: 14),
          ],

          // ── 2. Quran Hub Mode Cards Grid (Al-Quran, 15-Line, 16-Line, etc.) ──
          _buildQuranModesGrid(),
        ],
      ),
    );
  }

  Widget _buildLastReadBanner() {
    final surahNum = _lastRead!['surah'] as int? ?? 1;
    final ayahNum = _lastRead!['ayah'] as int? ?? 1;
    final pageNum = _lastRead!['page'] as int? ?? 1;
    final section = _lastRead!['section'] as String? ?? 'verse_by_verse';
    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF1F8F3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Continue Reading', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          Text('Surah ${sInfo.nameTransliteration} • Ayah $ayahNum', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ])),
        ElevatedButton(
          onPressed: () {
            if (section == 'mushaf_15') { context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'}); }
            else if (section == 'mushaf_16') { context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'}); }
            else { context.goNamed('verse-by-verse', pathParameters: {'surahNumber': '$surahNum'}, queryParameters: {'ayah': '$ayahNum'}); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Resume'),
        ),
      ]),
    );
  }

  /// 2-Column Quran Hub Modes Grid matching user specifications
  Widget _buildQuranModesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quran Modes & Reading',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              'المصاحف والقراءات',
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 16,
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quranModeCard(
                title: 'Al-Quran',
                arabicTitle: 'القرآن الكريم',
                subtitle: '114 Surahs & 30 Juz Browser',
                icon: Icons.menu_book_rounded,
                accentColor: const Color(0xFF1B4332),
                onTap: () {
                  context.goNamed('simple-quran', queryParameters: {'tab': '0'});
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quranModeCard(
                title: '15-Line Mushaf',
                arabicTitle: 'مصحف ١٥ سطر',
                subtitle: 'Saudi / Madinah Format',
                icon: Icons.auto_stories_rounded,
                accentColor: const Color(0xFF00796B),
                onTap: () {
                  context.goNamed('mushaf-15', queryParameters: {'page': '1'});
                },
              ),
            ),
          ],
        ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quranModeCard(
                  title: '16-Line Mushaf',
                  arabicTitle: 'مصحف ١٦ سطر',
                  subtitle: 'Indo-Pak / Taj Format',
                  icon: Icons.import_contacts_rounded,
                  accentColor: const Color(0xFF2E7D32),
                  onTap: () {
                    context.goNamed('mushaf-16', queryParameters: {'page': '1'});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quranModeCard(
                  title: 'Mistakes Report',
                  arabicTitle: 'سجل الأخطاء',
                  subtitle: 'Track Tajweed & Hifz',
                  icon: Icons.fact_check_rounded,
                  accentColor: const Color(0xFFE65100),
                  onTap: () {
                    context.goNamed('mistakes-report');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quranModeCard(
                  title: 'Search Quran',
                  arabicTitle: 'البحث في القرآن',
                  subtitle: 'Search All 6,236 Ayahs',
                  icon: Icons.search_rounded,
                  accentColor: const Color(0xFF1565C0),
                  onTap: () {
                    context.goNamed('search');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quranModeCard(
                  title: 'Bookmarks & Sajda',
                  arabicTitle: 'العلامات والسجدات',
                  subtitle: 'Saved Verses & Sajdas',
                  icon: Icons.bookmarks_rounded,
                  accentColor: const Color(0xFF6A1B9A),
                  onTap: () {
                    context.goNamed('bookmarks');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quranModeCard(
                  title: 'Mutashabihat',
                  arabicTitle: 'الآيات المتشابهات',
                  subtitle: 'Explore 2,700+ Similar Ayat',
                  icon: Icons.compare_arrows_rounded,
                  accentColor: const Color(0xFFD84315),
                  onTap: () {
                    context.goNamed('mutashabihat');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quranModeCard(
                  title: 'Juz Explorer',
                  arabicTitle: 'فهرس الأجزاء',
                  subtitle: 'Browse 30 Paras / Ajza',
                  icon: Icons.library_books_rounded,
                  accentColor: const Color(0xFF455A64),
                  onTap: () {
                    context.goNamed('simple-quran', queryParameters: {'tab': '1'});
                  },
                ),
              ),
            ],
          ),
        ],
      );
  }

  Widget _quranModeCard({
    required String title,
    required String arabicTitle,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2421),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3530), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 0.8),
                      ),
                      child: Icon(icon, color: const Color(0xFFFFD54F), size: 18),
                    ),
                    Text(
                      arabicTitle,
                      style: const TextStyle(
                        fontFamily: 'Scheherazade New',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: Colors.white60,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}