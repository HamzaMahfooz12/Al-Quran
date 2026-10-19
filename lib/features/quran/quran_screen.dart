// lib/features/quran/quran_screen.dart
// The Holy Quran - Main Hub Screen matching Google Stitch design exactly
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Stitch quick filter chips
  static const List<String> _quickChips = [
    'Al-Baqarah',
    'Ayat al-Kursi',
    'Surah Yaseen',
    'Ar-Rahman',
  ];

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
    final lr = await repo.getLastReadMushaf();
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
    final lastReadMushafAsync = ref.watch(lastReadMushafProvider);
    final currentLastRead = lastReadMushafAsync.valueOrNull ?? _lastRead;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      drawer: const AppDrawer(),
      appBar: _buildTopAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + bottomPad),
        children: [
          // ── Search & Filter Section (Stitch Exact) ──
          _buildSearchSection(),

          const SizedBox(height: 14),

          // ── Dynamic Body: Search Results vs Quran Main Hub ──
          if (isQueryActive)
            _buildSearchSuggestionsView()
          else ...[
            // ── Continue Reading Card ──
            _buildContinueReadingCard(currentLastRead),

            const SizedBox(height: 16),

            // ── Quran Modes & Reading Section Header ──
            _buildSectionHeader(),

            const SizedBox(height: 12),

            // ── 8-Utility Grid (Stitch Exact) ──
            _buildQuranModesGrid(),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE7DC), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF334155), size: 20),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'القرآن الكريم',
            style: GoogleFonts.amiri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC59B27),
              height: 1.1,
            ),
          ),
          Text(
            'THE HOLY QURAN',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.goNamed('bookmarks');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE7DC), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF334155), size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search textfield
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _query.isNotEmpty ? const Color(0xFFC59B27) : const Color(0xFFEDE7DC),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Search verses, Surahs, keywords...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 19),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 17),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Quick Search Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _quickChips.map((chip) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _searchCtrl.text = chip;
                    _searchCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: chip.length),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEDE7DC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      chip,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingCard([Map<String, dynamic>? data]) {
    final lr = data ?? _lastRead;
    final surahNum = lr?['surah'] as int? ?? 1;
    final ayahNum = lr?['ayah'] as int? ?? 1;
    final pageNum = lr?['page'] as int? ?? 1;
    final juzNum = lr?['juz'] as int? ?? 1;
    final section = lr?['section'] as String? ?? 'mushaf_16';
    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final progress = (ayahNum / sInfo.ayahCount).clamp(0.05, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE7DC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8860B).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.04,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 110,
                  color: const Color(0xFFC59B27),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top tag row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTINUE READING',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: const Color(0xFF996515),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3E5C8)),
                        ),
                        child: Text(
                          '$percent%',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC59B27),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Middle info row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F0E4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECDDC5)),
                        ),
                        child: const Center(
                          child: Icon(Icons.menu_book_rounded, color: Color(0xFFB8860B), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah ${sInfo.nameTransliteration}',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF354033),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ayah $ayahNum • Page $pageNum • Juz $juzNum',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF59634A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (section == 'mushaf_15') {
                            context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'});
                          } else {
                            context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'});
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6EFE3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE9DEC9)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Resume',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF996515),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF996515)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 5,
                      color: const Color(0xFFF1E9DA),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFC59B27),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
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

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC59B27),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'QURAN MODES & READING',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3E5C8)),
          ),
          child: Text(
            '8 Utilities',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF996515),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuranModesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        // 1. 15-Line Mushaf
        _stitchModeCard(
          title: '15-Line Mushaf',
          subtitle: 'Madinah Standard Page Format for Huffaz',
          badge: 'Madani',
          icon: Icons.menu_book_rounded,
          onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
        ),

        // 2. 16-Line Mushaf
        _stitchModeCard(
          title: '16-Line Mushaf',
          subtitle: 'Standard Taj Company Tajweed Format',
          badge: 'Indo-Pak',
          icon: Icons.auto_stories_rounded,
          onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'}),
        ),

        // 3. Surah Index
        _stitchModeCard(
          title: 'Surah Index',
          subtitle: 'All 114 Surahs with Meaning & Revelation Info',
          badge: '114 Surahs',
          icon: Icons.format_list_bulleted_rounded,
          onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
        ),

        // 4. Juz Explorer
        _stitchModeCard(
          title: 'Juz Explorer',
          subtitle: 'Browse & Memorize Quran by 30 Paras & Rub\'s',
          badge: '30 Paras',
          icon: Icons.layers_rounded,
          onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '1'}),
        ),

        // 5. Mutashabihat
        _stitchModeCard(
          title: 'Mutashabihat',
          subtitle: 'Similar & Confusing Verses Comparison for Huffaz',
          badge: '2,700+ Ayat',
          icon: Icons.compare_arrows_rounded,
          onTap: () => context.goNamed('mutashabihat'),
        ),

        // 6. Mistakes Report
        _stitchModeCard(
          title: 'Mistakes Report',
          subtitle: 'Track Hifz & Tajweed Memorization Progress',
          badge: 'Hifz Tracker',
          icon: Icons.fact_check_rounded,
          onTap: () => context.goNamed('mistakes-report'),
        ),

        // 7. Bookmarks & Sajda
        _stitchModeCard(
          title: 'Bookmarks & Sajda',
          subtitle: 'Saved Pins & 14 Obligatory Sajda Verses',
          badge: '14 Sajdas',
          icon: Icons.bookmark_border_rounded,
          onTap: () => context.goNamed('bookmarks'),
        ),

        // 8. Full Surah Audio
        _stitchModeCard(
          title: 'Full Surah Audio',
          subtitle: 'High quality studio Quran recitations',
          badge: '172+ Reciters',
          icon: Icons.headset_mic_rounded,
          onTap: () => context.push('/home/full-surah-audio'),
        ),
      ],
    );
  }

  Widget _stitchModeCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE7DC), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8860B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F0E4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFECDDC5)),
                          ),
                          child: Icon(icon, color: const Color(0xFFB8860B), size: 19),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF3E5C8)),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.outfit(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF996515),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEFE3D0)),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFB8860B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggestions View (Search) ─────────────────────────────────────────────
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
                color: Color(0xFFFAF5E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFFC59B27)),
            ),
            const SizedBox(height: 14),
            Text(
              'No matches found for "$_query"',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching by Surah name (e.g. Yaseen), Ayah ref (e.g. 2:255), or topics (e.g. mercy, patience).',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
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
        if (matchingSurahs.isNotEmpty) ...[
          _suggestionHeader('Matching Surahs (${matchingSurahs.length})', Icons.menu_book_rounded),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingSurahs.take(4).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => _surahSuggestionCard(matchingSurahs[idx]),
          ),
          const SizedBox(height: 16),
        ],

        if (matchingParas.isNotEmpty) ...[
          _suggestionHeader('Matching Paras / Juz (${matchingParas.length})', Icons.auto_stories_rounded),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingParas.take(3).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => _paraSuggestionCard(matchingParas[idx]),
          ),
          const SizedBox(height: 16),
        ],

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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC59B27)),
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
            itemBuilder: (ctx, idx) => _verseSuggestionCard(_verseResults[idx]),
          )
        else if (!_searchingDb)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child: Text(
              'No verses containing "$_query" in Arabic or translation.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  Widget _suggestionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFC59B27)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _surahSuggestionCard(SurahInfo s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7DC)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.goNamed('verse-by-verse', pathParameters: {'surahNumber': '${s.number}'});
          },
          borderRadius: BorderRadius.circular(16),
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
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${s.nameTranslation} • ${s.ayahCount} Verses • ${s.revelationType}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  s.nameArabic,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC59B27),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF64748B)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7DC)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/home/juz/$juzNum'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5E8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3E5C8), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '$juzNum',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC59B27),
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
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        p['startSurah'] as String? ?? 'Juz $juzNum',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC59B27),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF64748B)),
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
        border: Border.all(color: const Color(0xFFEDE7DC)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed(
              'verse-by-verse',
              pathParameters: {'surahNumber': '${r.surahInfo.number}'},
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Surah ${r.surahInfo.nameTransliteration} [${r.surahInfo.number}:${r.ayah.ayahNumber}]',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      r.surahInfo.nameArabic,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC59B27),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.ayah.arabicText,
                  style: GoogleFonts.amiri(
                    fontSize: 19,
                    height: 1.6,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.translation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.translation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
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
}