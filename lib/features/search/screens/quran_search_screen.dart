// lib/features/search/screens/quran_search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/settings_service.dart';
import '../../quran/simple_quran_index_screen.dart';

class SearchResultItem {
  final Ayah ayah;
  final SurahInfo surahInfo;
  final String translationText;

  const SearchResultItem({
    required this.ayah,
    required this.surahInfo,
    required this.translationText,
  });
}

const List<Map<String, dynamic>> _kSearchJuzData = [
  {'juz': 1, 'name': 'Alif Lam Meem', 'arabic': 'الم', 'startSurah': 'Al-Fatiha 1:1'},
  {'juz': 2, 'name': 'Sayaqool', 'arabic': 'سَيَقُولُ', 'startSurah': 'Al-Baqarah 2:142'},
  {'juz': 3, 'name': 'Tilkal Rusul', 'arabic': 'تِلْكَ الرُّسُلُ', 'startSurah': 'Al-Baqarah 2:253'},
  {'juz': 4, 'name': 'Lan Tana Loo', 'arabic': 'لَنْ تَنَالُوا', 'startSurah': 'Ali \'Imran 3:93'},
  {'juz': 5, 'name': 'Wal Mohsanat', 'arabic': 'وَالْمُحْصَنَاتُ', 'startSurah': 'An-Nisa 4:24'},
  {'juz': 6, 'name': 'La Yuhibbullah', 'arabic': 'لَا يُحِبُّ اللَّهُ', 'startSurah': 'An-Nisa 4:148'},
  {'juz': 7, 'name': 'Wa Iza Samiu', 'arabic': 'وَإِذَا سَمِعُوا', 'startSurah': 'Al-Ma\'idah 5:82'},
  {'juz': 8, 'name': 'Wa Lau Annana', 'arabic': 'وَلَوْ أَنَّنَا', 'startSurah': 'Al-An\'am 6:111'},
  {'juz': 9, 'name': 'Qalal Malao', 'arabic': 'قَالَ الْمَلَأُ', 'startSurah': 'Al-A\'raf 7:88'},
  {'juz': 10, 'name': 'Wa A\'lamu', 'arabic': 'وَاعْلَمُوا', 'startSurah': 'Al-Anfal 8:41'},
  {'juz': 11, 'name': 'Yatazeroon', 'arabic': 'يَعْتَذِرُونَ', 'startSurah': 'At-Tawbah 9:93'},
  {'juz': 12, 'name': 'Wa Mamin Da\'abat', 'arabic': 'وَمَا مِنْ دَابَّةٍ', 'startSurah': 'Hud 11:6'},
  {'juz': 13, 'name': 'Wa Ma Ubrioo', 'arabic': 'وَمَا أُبَرِّئُ', 'startSurah': 'Yusuf 12:53'},
  {'juz': 14, 'name': 'Rubama', 'arabic': 'رُبَمَا', 'startSurah': 'Al-Hijr 15:1'},
  {'juz': 15, 'name': 'Subhanallazi', 'arabic': 'سُبْحَانَ الَّذِي', 'startSurah': 'Al-Isra 17:1'},
  {'juz': 16, 'name': 'Qal Alam', 'arabic': 'قَالَ أَلَمْ', 'startSurah': 'Al-Kahf 18:75'},
  {'juz': 17, 'name': 'Aqtaraba', 'arabic': 'اقْتَرَبَ', 'startSurah': 'Al-Anbiya 21:1'},
  {'juz': 18, 'name': 'Qadd Aflaha', 'arabic': 'قَدْ أَفْلَحَ', 'startSurah': 'Al-Mu\'minun 23:1'},
  {'juz': 19, 'name': 'Wa Qalallazina', 'arabic': 'وَقَالَ الَّذِينَ', 'startSurah': 'Al-Furqan 25:21'},
  {'juz': 20, 'name': 'Amman Khalaqa', 'arabic': 'أَمَّنْ خَلَقَ', 'startSurah': 'An-Naml 27:60'},
  {'juz': 21, 'name': 'Utlu Ma Oohiya', 'arabic': 'اتْلُ مَا أُوحِيَ', 'startSurah': 'Al-\'Ankabut 29:46'},
  {'juz': 22, 'name': 'Wa Manyaqnut', 'arabic': 'وَمَنْ يَقْنُتْ', 'startSurah': 'Al-Ahzab 33:31'},
  {'juz': 23, 'name': 'Wa Maliya', 'arabic': 'وَمَا لِيَ', 'startSurah': 'Ya-Sin 36:28'},
  {'juz': 24, 'name': 'Faman Azlamu', 'arabic': 'فَمَنْ أَظْلَمُ', 'startSurah': 'Az-Zumar 39:32'},
  {'juz': 25, 'name': 'Ilayhi Yuraddu', 'arabic': 'إِلَيْهِ يُرَدُّ', 'startSurah': 'Fussilat 41:47'},
  {'juz': 26, 'name': 'Ha\'a Meem', 'arabic': 'حم', 'startSurah': 'Al-Ahqaf 46:1'},
  {'juz': 27, 'name': 'Qala Fama Khatbukum', 'arabic': 'قَالَ فَمَا خَطْبُكُمْ', 'startSurah': 'Adh-Dhariyat 51:31'},
  {'juz': 28, 'name': 'Qadd Sami Allah', 'arabic': 'قَدْ سَمِعَ اللَّهُ', 'startSurah': 'Al-Mujadila 58:1'},
  {'juz': 29, 'name': 'Tabarakallazi', 'arabic': 'تَبَارَكَ الَّذِي', 'startSurah': 'Al-Mulk 67:1'},
  {'juz': 30, 'name': 'Amma Yatasa\'aloon', 'arabic': 'عَمَّ يَتَسَاءَلُونَ', 'startSurah': 'An-Naba 78:1'},
];

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<SearchResultItem> _verseResults = [];
  bool _searching = false;
  String _query = '';
  Timer? _debounceTimer;

  static const List<String> _quickChips = [
    'Al-Baqarah',
    'Ayat al-Kursi',
    'Surah Yaseen',
    'Ar-Rahman',
  ];

  @override
  void initState() {
    super.initState();
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
        _searching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      _performSearch(q);
    });
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() => _searching = true);

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
                  SearchResultItem(
                    ayah: specificAyah,
                    surahInfo: sInfo,
                    translationText: trans,
                  )
                ];
                _searching = false;
              });
              return;
            }
          }
        }
      }

      // 2. Full-text search
      final matchingAyahs = await repo.searchAyahs(clean, limit: 40);
      final surahMap = {for (final s in kSurahList) s.number: s};
      final ayahIds = matchingAyahs.map((a) => a.id).toList();
      final transMap = await repo.getContentBulk(ayahIds, translationId);

      final list = <SearchResultItem>[];
      for (final a in matchingAyahs) {
        final sInfo = surahMap[a.surah];
        if (sInfo != null) {
          list.add(SearchResultItem(
            ayah: a,
            surahInfo: sInfo,
            translationText: transMap[a.id] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _verseResults = list;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
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
    return _kSearchJuzData.where((j) {
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
    final matchingSurahs = _matchingSurahs;
    final matchingParas = _matchingParas;
    final isQueryEmpty = _query.isEmpty;
    final hasNoResults = !isQueryEmpty && matchingSurahs.isEmpty && matchingParas.isEmpty && _verseResults.isEmpty && !_searching;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search Quran',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottomPad),
        children: [
          // Search input box
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
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search Surahs, verses, keywords (e.g. 2:255, patience)...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC59B27), size: 21),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Filter Chips
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
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

          const SizedBox(height: 16),

          if (isQueryEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF5E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, size: 36, color: Color(0xFFC59B27)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Search 114 Surahs & 6,236 Verses',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Type any Surah name, Ayah ref (e.g. 2:255), or search in Urdu, Arabic, English',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (hasNoResults)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEDE7DC)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF5E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_off_rounded, size: 28, color: Color(0xFFC59B27)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No matches found for "$_query"',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try checking spelling or search with Surah numbers and verse references.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            // ── 1. Matching Surahs (Shown First) ────────────────────────
            if (matchingSurahs.isNotEmpty) ...[
              _buildSectionHeader('Matching Surahs (${matchingSurahs.length})', Icons.menu_book_rounded),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchingSurahs.take(5).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) => _buildSurahCard(matchingSurahs[idx]),
              ),
              const SizedBox(height: 16),
            ],

            // ── 2. Matching Paras / Juz (Shown Second) ─────────────────
            if (matchingParas.isNotEmpty) ...[
              _buildSectionHeader('Matching Paras / Juz (${matchingParas.length})', Icons.auto_stories_rounded),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchingParas.take(4).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) => _buildParaCard(matchingParas[idx]),
              ),
              const SizedBox(height: 16),
            ],

            // ── 3. Matching Verses (Shown Third) ───────────────────────
            _buildSectionHeader(
              _searching ? 'Searching Verses...' : 'Matching Verses (${_verseResults.length})',
              Icons.format_quote_rounded,
            ),
            const SizedBox(height: 8),

            if (_searching && _verseResults.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
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
                itemBuilder: (ctx, idx) => _buildVerseCard(_verseResults[idx]),
              )
            else if (!_searching)
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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

  Widget _buildSurahCard(SurahInfo s) {
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

  Widget _buildParaCard(Map<String, dynamic> p) {
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

  Widget _buildVerseCard(SearchResultItem r) {
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
                if (r.translationText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.translationText,
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
