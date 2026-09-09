// lib/features/quran/quran_screen.dart
// Premium Quran Hub Screen with unified top live search & optimistic instant suggestions
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/app_drawer.dart';
import '../../data/models/ayah.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/settings_service.dart';
import 'simple_quran_index_screen.dart' show IslamicStarBadge;

const List<Map<String, dynamic>> _kQuickJuzData = [
  {'juz': 1,  'name': 'Alif Lam Meem',       'arabic': 'الم',               'startSurah': 'Al-Fatihah 1:1'},
  {'juz': 2,  'name': 'Sayaqool',            'arabic': 'سَيَقُولُ',          'startSurah': 'Al-Baqarah 2:142'},
  {'juz': 3,  'name': 'Tilka ar-Rusul',      'arabic': 'تِلْكَ الرُّسُلُ',     'startSurah': 'Al-Baqarah 2:253'},
  {'juz': 4,  'name': 'Lan Tanaloo',         'arabic': 'لَنْ تَنَالُوا',       'startSurah': 'Ali \'Imran 3:92'},
  {'juz': 5,  'name': 'Wal-Muhsanat',        'arabic': 'وَالْمُحْصَنَاتُ',     'startSurah': 'An-Nisa 4:24'},
  {'juz': 6,  'name': 'La Yuhibbullah',      'arabic': 'لَا يُحِبُّ اللَّهُ',   'startSurah': 'An-Nisa 4:148'},
  {'juz': 7,  'name': 'Wa Iza Sami\'u',      'arabic': 'وَإِذَا سَمِعُوا',     'startSurah': 'Al-Ma\'idah 5:82'},
  {'juz': 8,  'name': 'Wa Law Annana',       'arabic': 'وَلَوْ أَنَّنَا',      'startSurah': 'Al-An\'am 6:111'},
  {'juz': 9,  'name': 'Qalal-Mala\'u',       'arabic': 'قَالَ الْمَلَأُ',     'startSurah': 'Al-A\'raf 7:88'},
  {'juz': 10, 'name': 'Wa A\'lamu',          'arabic': 'وَاعْلَمُوا',        'startSurah': 'Al-Anfal 8:41'},
  {'juz': 11, 'name': 'Ya\'taziroon',        'arabic': 'يَعْتَذِرُونَ',       'startSurah': 'At-Tawbah 9:93'},
  {'juz': 12, 'name': 'Wa Ma Min Da\'abbah', 'arabic': 'وَمَا مِنْ دَابَّةٍ',  'startSurah': 'Hud 11:6'},
  {'juz': 13, 'name': 'Wa Ma Ubri\'u',       'arabic': 'وَمَا أُبَرِّئُ',     'startSurah': 'Yusuf 12:53'},
  {'juz': 14, 'name': 'Rubama',              'arabic': 'رُبَمَا',            'startSurah': 'Al-Hijr 15:1'},
  {'juz': 15, 'name': 'Subhanallazi',        'arabic': 'سُبْحَانَ الَّذِي',   'startSurah': 'Al-Isra 17:1'},
  {'juz': 16, 'name': 'Qal Alam',            'arabic': 'قَالَ أَلَمْ',        'startSurah': 'Al-Kahf 18:75'},
  {'juz': 17, 'name': 'Iqtaraba lin-Nas',    'arabic': 'اقْتَرَبَ لِلنَّاسِ',  'startSurah': 'Al-Anbya 21:1'},
  {'juz': 18, 'name': 'Qad Aflaha',          'arabic': 'قَدْ أَفْلَحَ',       'startSurah': 'Al-Mu\'minun 23:1'},
  {'juz': 19, 'name': 'Wa Qalal-Lazeena',    'arabic': 'وَقَالَ الَّذِينَ',   'startSurah': 'Al-Furqan 25:21'},
  {'juz': 20, 'name': 'Amman Khalaqa',       'arabic': 'أَمَّنْ خَلَقَ',      'startSurah': 'An-Naml 27:60'},
  {'juz': 21, 'name': 'Utlu Ma Oohiya',      'arabic': 'اتْلُ مَا أُوحِيَ',   'startSurah': 'Al-Ankabut 29:46'},
  {'juz': 22, 'name': 'Wa Man Yaqnut',       'arabic': 'وَمَنْ يَقْنُتْ',     'startSurah': 'Al-Ahzab 33:31'},
  {'juz': 23, 'name': 'Wa Maliya',           'arabic': 'وَمَا لِيَ',         'startSurah': 'Ya-Sin 36:28'},
  {'juz': 24, 'name': 'Faman Azlamu',        'arabic': 'فَمَنْ أَظْلَمُ',     'startSurah': 'Az-Zumar 39:32'},
  {'juz': 25, 'name': 'Ilaihi Yuraddu',      'arabic': 'إِلَيْهِ يُرَدُّ',     'startSurah': 'Fussilat 41:47'},
  {'juz': 26, 'name': 'Ha-Meem',             'arabic': 'حم',               'startSurah': 'Al-Jathiyah 45:33'},
  {'juz': 27, 'name': 'Qala Fama Khatbukum', 'arabic': 'قَالَ فَمَا خَطْبُكُمْ', 'startSurah': 'Adh-Dhariyat 51:31'},
  {'juz': 28, 'name': 'Qad Sami\'allah',     'arabic': 'قَدْ سَمِعَ اللَّهُ',   'startSurah': 'Al-Mujadila 58:1'},
  {'juz': 29, 'name': 'Tabarakallazi',       'arabic': 'تَبَارَكَ الَّذِي',   'startSurah': 'Al-Mulk 67:1'},
  {'juz': 30, 'name': 'Amma Yatasa\'aloon',  'arabic': 'عَمَّ يَتَسَاءَلُونَ', 'startSurah': 'An-Naba 78:1'},
];

class _AyahSearchResult {
  final Ayah ayah;
  final SurahInfo surahInfo;
  final String translation;

  const _AyahSearchResult({
    required this.ayah,
    required this.surahInfo,
    required this.translation,
  });
}

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  Map<String, dynamic>? _lastRead;

  String _query = '';
  bool _searchingDb = false;
  List<_AyahSearchResult> _verseResults = [];

  @override
  void initState() {
    super.initState();
    _loadLastRead();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;

    setState(() {
      _query = q;
    });

    _debounceTimer?.cancel();
    if (q.isEmpty) {
      setState(() {
        _verseResults = [];
        _searchingDb = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      _executeVerseSearch(q);
    });
  }

  Future<void> _loadLastRead() async {
    final repo = ref.read(quranRepositoryProvider);
    final lr = await repo.getLastRead('verse_by_verse') ??
        await repo.getLastRead('mushaf_15');
    if (mounted) setState(() => _lastRead = lr);
  }

  Future<void> _executeVerseSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() => _searchingDb = true);

    try {
      final repo = ref.read(quranRepositoryProvider);
      final settings = ref.read(settingsServiceProvider);
      final translationId = settings.selectedTranslationId ?? 2;

      // 1. Check if user typed surah:ayah (e.g. 2:255 or 36:1)
      final refMatch = RegExp(r'^(\d{1,3}):(\d{1,3})$').firstMatch(clean);
      if (refMatch != null) {
        final sNum = int.tryParse(refMatch.group(1)!) ?? 0;
        final aNum = int.tryParse(refMatch.group(2)!) ?? 0;
        if (sNum >= 1 && sNum <= 114) {
          final specificAyah = await repo.getAyah(sNum, aNum);
          if (specificAyah != null) {
            final trans = await repo.getContent(specificAyah.id, translationId) ?? '';
            final sInfo = kSurahList[sNum - 1];
            if (mounted) {
              setState(() {
                _verseResults = [
                  _AyahSearchResult(
                    ayah: specificAyah,
                    surahInfo: sInfo,
                    translation: trans,
                  )
                ];
                _searchingDb = false;
              });
              return;
            }
          }
        }
      }

      // 2. Full-text search on Arabic and translation
      final matchingAyahs = await repo.searchAyahs(clean, limit: 30);
      final surahMap = {for (final s in kSurahList) s.number: s};
      final ayahIds = matchingAyahs.map((a) => a.id).toList();
      final transMap = await repo.getContentBulk(ayahIds, translationId);

      final list = <_AyahSearchResult>[];
      for (final a in matchingAyahs) {
        final sInfo = surahMap[a.surah];
        if (sInfo != null) {
          list.add(_AyahSearchResult(
            ayah: a,
            surahInfo: sInfo,
            translation: transMap[a.id] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _verseResults = list;
          _searchingDb = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searchingDb = false);
    }
  }

  // ── Synchronous optimistic matching for Surahs & Paras ────────────────────
  List<SurahInfo> get _matchingSurahs {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return kSurahList.where((s) {
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.number.toString() == q;
    }).toList();
  }

  List<Map<String, dynamic>> get _matchingParas {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _kQuickJuzData.where((j) {
      final name = (j['name'] as String).toLowerCase();
      final arabic = j['arabic'] as String;
      final numStr = j['juz'].toString();
      return name.contains(q) ||
          arabic.contains(q) ||
          numStr == q ||
          'juz $numStr' == q ||
          'para $numStr' == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isQueryActive = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E3A60), size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'The Holy Quran',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF1E3A60), size: 24),
            tooltip: 'Bookmarks & Sajdas',
            onPressed: () => context.goNamed('bookmarks'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + bottomPad),
        children: [
          // ── 1. Unified Top Quran Search Bar ──────────────────────────────
          _buildTopSearchBar(),

          const SizedBox(height: 14),

          // ── 2. Dynamic Body: Optimistic Suggestions vs Standard Hub ──────
          if (isQueryActive)
            _buildSearchSuggestionsView()
          else ...[
            _buildContinueReadingBanner(),
            const SizedBox(height: 16),
            _buildQuranModesGrid(),
          ],
        ],
      ),
    );
  }

  // ── Unified Top Search Box ────────────────────────────────────────────────
  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _query.isNotEmpty ? const Color(0xFF1E3A60) : const Color(0xFFE2E8F0),
          width: _query.isNotEmpty ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _query.isNotEmpty
                ? const Color(0xFF1E3A60).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search verses, Surahs, keywords (e.g. 2:255, Baqarah, mercy)...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A60), size: 22),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                  tooltip: 'Clear Search',
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  // ── Live Suggestions View (Optimistic Instant UI) ─────────────────────────
  Widget _buildSearchSuggestionsView() {
    final matchingSurahs = _matchingSurahs;
    final matchingParas = _matchingParas;
    final hasNoResults = !_searchingDb &&
        matchingSurahs.isEmpty &&
        matchingParas.isEmpty &&
        _verseResults.isEmpty;

    if (hasNoResults) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF4FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF1E3A60)),
            ),
            const SizedBox(height: 14),
            Text(
              'No matches found for "$_query"',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2A1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching by Surah name (e.g. Yasin), Ayah ref (e.g. 2:255), or topics (e.g. mercy, patience).',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF8D9E92),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Matching Surahs Suggestions ──
        if (matchingSurahs.isNotEmpty) ...[
          _suggestionHeader('Matching Surahs (${matchingSurahs.length})', Icons.menu_book_rounded),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingSurahs.take(4).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final s = matchingSurahs[idx];
              return _surahSuggestionCard(s);
            },
          ),
          const SizedBox(height: 16),
        ],

        // ── 2. Matching Paras / Juz Suggestions ──
        if (matchingParas.isNotEmpty) ...[
          _suggestionHeader('Matching Paras / Juz (${matchingParas.length})', Icons.auto_stories_rounded),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingParas.take(3).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final p = matchingParas[idx];
              return _paraSuggestionCard(p);
            },
          ),
          const SizedBox(height: 16),
        ],

        // ── 3. Matching Verses & Translations ──
        _suggestionHeader(
          _searchingDb
              ? 'Searching Verses...'
              : 'Matching Verses (${_verseResults.length})',
          Icons.format_quote_rounded,
        ),
        const SizedBox(height: 8),

        if (_searchingDb && _verseResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A60)),
                ),
              ),
            ),
          )
        else if (_verseResults.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _verseResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final r = _verseResults[idx];
              return _verseSuggestionCard(r);
            },
          )
        else if (!_searchingDb)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No verses containing "$_query" in Arabic or translation.',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  Widget _suggestionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E3A60)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A60),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _surahSuggestionCard(SurahInfo s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1D2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            context.goNamed(
              'verse-by-verse',
              pathParameters: {'surahNumber': '${s.number}'},
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                IslamicStarBadge(number: s.number, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surah ${s.nameTransliteration}',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2A1E),
                        ),
                      ),
                      Text(
                        '${s.nameTranslation} • ${s.ayahCount} Verses • ${s.revelationType}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF4B5E50)),
                      ),
                    ],
                  ),
                ),
                Text(
                  s.nameArabic,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF8D9E92)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paraSuggestionCard(Map<String, dynamic> p) {
    final juzNum = p['juz'] as int;
    final name = p['name'] as String;
    final arabic = p['arabic'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1D2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            context.push('/home/juz/$juzNum');
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '$juzNum',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A60),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Para $juzNum ($name)',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2A1E),
                        ),
                      ),
                      Text(
                        p['startSurah'] as String? ?? 'Juz $juzNum',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF4B5E50)),
                      ),
                    ],
                  ),
                ),
                Text(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF8D9E92)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _verseSuggestionCard(_AyahSearchResult r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.goNamed(
              'verse-by-verse',
              pathParameters: {'surahNumber': '${r.ayah.surah}'},
              queryParameters: {
                'ayah': '${r.ayah.ayahNumber}',
                'scrollToAyah': '${r.ayah.ayahNumber}',
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tag Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF1E3A60)),
                          const SizedBox(width: 4),
                          Text(
                            'Surah ${r.surahInfo.nameTransliteration} (${r.ayah.surah}:${r.ayah.ayahNumber})',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A60),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      r.surahInfo.nameArabic,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Arabic Verse Text
                Text(
                  r.ayah.arabicText,
                  style: GoogleFonts.amiri(
                    fontSize: 19,
                    height: 1.6,
                    color: const Color(0xFF1B2A1E),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (r.translation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    r.translation,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF4B5E50),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Continue Reading Card ─────────────────────────────────────────────────
  Widget _buildContinueReadingBanner() {
    final surahNum = _lastRead?['surah'] as int? ?? 1;
    final ayahNum = _lastRead?['ayah'] as int? ?? 1;
    final pageNum = _lastRead?['page'] as int? ?? 1;
    final section = _lastRead?['section'] as String? ?? 'verse_by_verse';
    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final progress = (ayahNum / sInfo.ayahCount).clamp(0.05, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Faded Mosque Watermark on Right
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 150,
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/mosque_silhouette_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content Layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A60),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A60).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Reading',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A60),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Surah ${sInfo.nameTransliteration}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Ayah $ayahNum',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFEEF4FC),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A60)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percent% Completed',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A60),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (section == 'mushaf_15') {
                        context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'});
                      } else if (section == 'mushaf_16') {
                        context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'});
                      } else {
                        context.goNamed('verse-by-verse', pathParameters: {'surahNumber': '$surahNum'}, queryParameters: {'ayah': '$ayahNum'});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A60),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Resume', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2-Column Quran Modes Grid (6 Clean Cards) ─────────────────────────────
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
                color: const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A60),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF1E3A60)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: Surah Index & 15-Line Mushaf
        Row(
          children: [
            Expanded(
              child: _modeCard(
                title: 'Surah Index',
                subtitle: '114 Surahs with Audio & Translations',
                icon: Icons.menu_book_rounded,
                accentColor: const Color(0xFF1E3A60),
                onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeCard(
                title: '15-Line Mushaf',
                subtitle: 'Saudi Madinah Standard Page Format',
                icon: Icons.auto_stories_rounded,
                accentColor: const Color(0xFF1976D2),
                onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: 16-Line Mushaf & Juz Explorer
        Row(
          children: [
            Expanded(
              child: _modeCard(
                title: '16-Line Mushaf',
                subtitle: 'Indo-Pak Standard Taj Page Format',
                icon: Icons.import_contacts_rounded,
                accentColor: const Color(0xFF6A1B9A),
                onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeCard(
                title: 'Juz Explorer',
                subtitle: 'Browse & Read Quran by 30 Paras',
                icon: Icons.library_books_rounded,
                accentColor: const Color(0xFFF57C00),
                onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '1'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 3: Mutashabihat & Mistakes Report
        Row(
          children: [
            Expanded(
              child: _modeCard(
                title: 'Mutashabihat',
                subtitle: 'Similar Verses Grouped by Ayah',
                icon: Icons.compare_arrows_rounded,
                accentColor: const Color(0xFF00897B),
                onTap: () => context.goNamed('mutashabihat'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeCard(
                title: 'Mistakes Report',
                subtitle: 'Track Hifz & Tajweed Memorization Errors',
                icon: Icons.fact_check_rounded,
                accentColor: const Color(0xFFE65100),
                onTap: () => context.goNamed('mistakes-report'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 4: Full Surah Audio & Bookmarks
        Row(
          children: [
            Expanded(
              child: _modeCard(
                title: 'Full Surah Audio',
                subtitle: 'Stream & Download 114 Surahs from 172+ Reciters',
                icon: Icons.headset_mic_rounded,
                accentColor: const Color(0xFF2563EB),
                onTap: () => context.push('/home/full-surah-audio'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeCard(
                title: 'Bookmarks & Sajdas',
                subtitle: 'Saved Verses & 14 Sajda Locations',
                icon: Icons.bookmarks_rounded,
                accentColor: const Color(0xFF7B1FA2),
                onTap: () => context.goNamed('bookmarks'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(icon, color: accentColor, size: 22),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF8F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF8D9E92)),
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
                    color: const Color(0xFF1B2A1E),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF4B5E50),
                    height: 1.3,
                  ),
                  maxLines: 2,
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