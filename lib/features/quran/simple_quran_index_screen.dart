// lib/features/quran/simple_quran_index_screen.dart
// Full Surah (114) and Juz / Para (30) browser screen opened when clicking "Al-Quran" in Quran Hub

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/surah_info.dart';

const List<Map<String, String>> _kJuzData = [
  {'name': 'Alif Lam Meem',       'arabic': 'الم',               'startSurah': 'Al-Fatihah 1:1'},
  {'name': 'Sayaqool',            'arabic': 'سَيَقُولُ',          'startSurah': 'Al-Baqarah 2:142'},
  {'name': 'Tilka ar-Rusul',      'arabic': 'تِلْكَ الرُّسُلُ',     'startSurah': 'Al-Baqarah 2:253'},
  {'name': 'Lan Tanaloo',         'arabic': 'لَنْ تَنَالُوا',       'startSurah': 'Ali \'Imran 3:92'},
  {'name': 'Wal-Muhsanat',        'arabic': 'وَالْمُحْصَنَاتُ',     'startSurah': 'An-Nisa 4:24'},
  {'name': 'La Yuhibbullah',      'arabic': 'لَا يُحِبُّ اللَّهُ',   'startSurah': 'An-Nisa 4:148'},
  {'name': 'Wa Iza Sami\'u',      'arabic': 'وَإِذَا سَمِعُوا',     'startSurah': 'Al-Ma\'idah 5:82'},
  {'name': 'Wa Law Annana',       'arabic': 'وَلَوْ أَنَّنَا',      'startSurah': 'Al-An\'am 6:111'},
  {'name': 'Qalal-Mala\'u',       'arabic': 'قَالَ الْمَلَأُ',     'startSurah': 'Al-A\'raf 7:88'},
  {'name': 'Wa A\'lamu',          'arabic': 'وَاعْلَمُوا',        'startSurah': 'Al-Anfal 8:41'},
  {'name': 'Ya\'taziroon',        'arabic': 'يَعْتَذِرُونَ',       'startSurah': 'At-Tawbah 9:93'},
  {'name': 'Wa Ma Min Da\'abbah', 'arabic': 'وَمَا مِنْ دَابَّةٍ',  'startSurah': 'Hud 11:6'},
  {'name': 'Wa Ma Ubri\'u',       'arabic': 'وَمَا أُبَرِّئُ',     'startSurah': 'Yusuf 12:53'},
  {'name': 'Rubama',              'arabic': 'رُبَمَا',            'startSurah': 'Al-Hijr 15:1'},
  {'name': 'Subhanallazi',        'arabic': 'سُبْحَانَ الَّذِي',   'startSurah': 'Al-Isra 17:1'},
  {'name': 'Qal Alam',            'arabic': 'قَالَ أَلَمْ',        'startSurah': 'Al-Kahf 18:75'},
  {'name': 'Iqtaraba lin-Nas',    'arabic': 'اقْتَرَبَ لِلنَّاسِ',  'startSurah': 'Al-Anbya 21:1'},
  {'name': 'Qad Aflaha',          'arabic': 'قَدْ أَفْلَحَ',       'startSurah': 'Al-Mu\'minun 23:1'},
  {'name': 'Wa Qalal-Lazeena',    'arabic': 'وَقَالَ الَّذِينَ',   'startSurah': 'Al-Furqan 25:21'},
  {'name': 'Amman Khalaqa',       'arabic': 'أَمَّنْ خَلَقَ',      'startSurah': 'An-Naml 27:60'},
  {'name': 'Utlu Ma Oohiya',      'arabic': 'اتْلُ مَا أُوحِيَ',   'startSurah': 'Al-Ankabut 29:46'},
  {'name': 'Wa Man Yaqnut',       'arabic': 'وَمَنْ يَقْنُتْ',     'startSurah': 'Al-Ahzab 33:31'},
  {'name': 'Wa Maliya',           'arabic': 'وَمَا لِيَ',         'startSurah': 'Ya-Sin 36:28'},
  {'name': 'Faman Azlamu',        'arabic': 'فَمَنْ أَظْلَمُ',     'startSurah': 'Az-Zumar 39:32'},
  {'name': 'Ilaihi Yuraddu',      'arabic': 'إِلَيْهِ يُرَدُّ',     'startSurah': 'Fussilat 41:47'},
  {'name': 'Ha-Meem',             'arabic': 'حم',               'startSurah': 'Al-Jathiyah 45:33'},
  {'name': 'Qala Fama Khatbukum', 'arabic': 'قَالَ فَمَا خَطْبُكُمْ', 'startSurah': 'Adh-Dhariyat 51:31'},
  {'name': 'Qad Sami\'allah',     'arabic': 'قَدْ سَمِعَ اللَّهُ',   'startSurah': 'Al-Mujadila 58:1'},
  {'name': 'Tabarakallazi',       'arabic': 'تَبَارَكَ الَّذِي',   'startSurah': 'Al-Mulk 67:1'},
  {'name': 'Amma Yatasa\'aloon',  'arabic': 'عَمَّ يَتَسَاءَلُونَ', 'startSurah': 'An-Naba 78:1'},
];

class SimpleQuranIndexScreen extends StatefulWidget {
  final int initialTabIndex; // 0 = Surahs, 1 = Juz
  const SimpleQuranIndexScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SimpleQuranIndexScreen> createState() => _SimpleQuranIndexScreenState();
}

class _SimpleQuranIndexScreenState extends State<SimpleQuranIndexScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filteredSurahs {
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

  List<Map<String, dynamic>> get _filteredJuz {
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < _kJuzData.length; i++) {
      final d = _kJuzData[i];
      final juzNum = i + 1;
      list.add({
        'number': juzNum,
        'name': d['name']!,
        'arabic': d['arabic']!,
        'startSurah': d['startSurah']!,
      });
    }

    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((j) {
      final name = (j['name'] as String).toLowerCase();
      final arabic = (j['arabic'] as String);
      final start = (j['startSurah'] as String).toLowerCase();
      final numStr = j['number'].toString();
      return name.contains(q) || arabic.contains(q) || start.contains(q) || numStr == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Al-Quran',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'القرآن الكريم',
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 20,
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
            tooltip: 'Global Quran Search',
            onPressed: () => context.goNamed('search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: AppTheme.primary),
            tooltip: 'Bookmarks',
            onPressed: () => context.goNamed('bookmarks'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: _tabCtrl.index == 0
                      ? 'Search 114 Surahs by name or number...'
                      : 'Search 30 Juz / Paras...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // ── Tab Bar (Surahs vs Juz) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                onTap: (i) => setState(() {}),
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Surahs (114)'),
                  Tab(text: 'Juz / Paras (30)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── Tab Views (List of Surahs / List of Juz) ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Surahs Tab
                _filteredSurahs.isEmpty
                    ? _buildEmptyState('No matching Surah found for "$_query"')
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + bottomPad),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (ctx, idx) {
                          final surah = _filteredSurahs[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8ECE9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    surah.number.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      surah.nameTransliteration,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    surah.nameArabic,
                                    style: const TextStyle(
                                      fontFamily: 'Scheherazade New',
                                      fontSize: 18,
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${surah.revelationType} • ${surah.ayahCount} Verses • Page ${surah.startPage}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                              onTap: () {
                                context.goNamed(
                                  'verse-by-verse',
                                  pathParameters: {'surahNumber': surah.number.toString()},
                                );
                              },
                            ),
                          );
                        },
                      ),

                // Juz Tab
                _filteredJuz.isEmpty
                    ? _buildEmptyState('No matching Juz found for "$_query"')
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + bottomPad),
                        itemCount: _filteredJuz.length,
                        itemBuilder: (ctx, idx) {
                          final j = _filteredJuz[idx];
                          final int juzNumber = j['number'] as int;
                          final String juzName = j['name'] as String;
                          final String arabicName = j['arabic'] as String;
                          final String startSurah = j['startSurah'] as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8ECE9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    juzNumber.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Juz $juzNumber — $juzName',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    arabicName,
                                    style: const TextStyle(
                                      fontFamily: 'Scheherazade New',
                                      fontSize: 18,
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Starts at $startSurah',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                              onTap: () {
                                context.goNamed(
                                  'juz',
                                  pathParameters: {'juzNumber': juzNumber.toString()},
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
