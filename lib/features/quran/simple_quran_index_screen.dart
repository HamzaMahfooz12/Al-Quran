// lib/features/quran/simple_quran_index_screen.dart
// World-Class Quran Surah (114), Juz (30), and Para Navigator matching modern Islamic luxury design

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/surah_info.dart';

const List<Map<String, dynamic>> _kJuzData = [
  {'name': 'Alif Lam Meem',       'arabic': 'الم',               'startSurah': 'Al-Fatihah 1:1',    'page': 1},
  {'name': 'Sayaqool',            'arabic': 'سَيَقُولُ',          'startSurah': 'Al-Baqarah 2:142',   'page': 22},
  {'name': 'Tilka ar-Rusul',      'arabic': 'تِلْكَ الرُّسُلُ',     'startSurah': 'Al-Baqarah 2:253',   'page': 42},
  {'name': 'Lan Tanaloo',         'arabic': 'لَنْ تَنَالُوا',       'startSurah': 'Ali \'Imran 3:92',   'page': 62},
  {'name': 'Wal-Muhsanat',        'arabic': 'وَالْمُحْصَنَاتُ',     'startSurah': 'An-Nisa 4:24',       'page': 82},
  {'name': 'La Yuhibbullah',      'arabic': 'لَا يُحِبُّ اللَّهُ',   'startSurah': 'An-Nisa 4:148',      'page': 102},
  {'name': 'Wa Iza Sami\'u',      'arabic': 'وَإِذَا سَمِعُوا',     'startSurah': 'Al-Ma\'idah 5:82',   'page': 121},
  {'name': 'Wa Law Annana',       'arabic': 'وَلَوْ أَنَّنَا',      'startSurah': 'Al-An\'am 6:111',    'page': 142},
  {'name': 'Qalal-Mala\'u',       'arabic': 'قَالَ الْمَلَأُ',     'startSurah': 'Al-A\'raf 7:88',     'page': 162},
  {'name': 'Wa A\'lamu',          'arabic': 'وَاعْلَمُوا',        'startSurah': 'Al-Anfal 8:41',      'page': 182},
  {'name': 'Ya\'taziroon',        'arabic': 'يَعْتَذِرُونَ',       'startSurah': 'At-Tawbah 9:93',     'page': 201},
  {'name': 'Wa Ma Min Da\'abbah', 'arabic': 'وَمَا مِنْ دَابَّةٍ',  'startSurah': 'Hud 11:6',           'page': 222},
  {'name': 'Wa Ma Ubri\'u',       'arabic': 'وَمَا أُبَرِّئُ',     'startSurah': 'Yusuf 12:53',        'page': 242},
  {'name': 'Rubama',              'arabic': 'رُبَمَا',            'startSurah': 'Al-Hijr 15:1',       'page': 262},
  {'name': 'Subhanallazi',        'arabic': 'سُبْحَانَ الَّذِي',   'startSurah': 'Al-Isra 17:1',       'page': 282},
  {'name': 'Qal Alam',            'arabic': 'قَالَ أَلَمْ',        'startSurah': 'Al-Kahf 18:75',      'page': 302},
  {'name': 'Iqtaraba lin-Nas',    'arabic': 'اقْتَرَبَ لِلنَّاسِ',  'startSurah': 'Al-Anbya 21:1',      'page': 322},
  {'name': 'Qad Aflaha',          'arabic': 'قَدْ أَفْلَحَ',       'startSurah': 'Al-Mu\'minun 23:1',  'page': 342},
  {'name': 'Wa Qalal-Lazeena',    'arabic': 'وَقَالَ الَّذِينَ',   'startSurah': 'Al-Furqan 25:21',    'page': 362},
  {'name': 'Amman Khalaqa',       'arabic': 'أَمَّنْ خَلَقَ',      'startSurah': 'An-Naml 27:60',      'page': 382},
  {'name': 'Utlu Ma Oohiya',      'arabic': 'اتْلُ مَا أُوحِيَ',   'startSurah': 'Al-Ankabut 29:46',   'page': 402},
  {'name': 'Wa Man Yaqnut',       'arabic': 'وَمَنْ يَقْنُتْ',     'startSurah': 'Al-Ahzab 33:31',     'page': 422},
  {'name': 'Wa Maliya',           'arabic': 'وَمَا لِيَ',         'startSurah': 'Ya-Sin 36:28',       'page': 442},
  {'name': 'Faman Azlamu',        'arabic': 'فَمَنْ أَظْلَمُ',     'startSurah': 'Az-Zumar 39:32',     'page': 462},
  {'name': 'Ilaihi Yuraddu',      'arabic': 'إِلَيْهِ يُرَدُّ',     'startSurah': 'Fussilat 41:47',     'page': 482},
  {'name': 'Ha-Meem',             'arabic': 'حم',               'startSurah': 'Al-Jathiyah 45:33',  'page': 502},
  {'name': 'Qala Fama Khatbukum', 'arabic': 'قَالَ فَمَا خَطْبُكُمْ', 'startSurah': 'Adh-Dhariyat 51:31',  'page': 522},
  {'name': 'Qad Sami\'allah',     'arabic': 'قَدْ سَمِعَ اللَّهُ',   'startSurah': 'Al-Mujadila 58:1',   'page': 542},
  {'name': 'Tabarakallazi',       'arabic': 'تَبَارَكَ الَّذِي',   'startSurah': 'Al-Mulk 67:1',       'page': 562},
  {'name': 'Amma Yatasa\'aloon',  'arabic': 'عَمَّ يَتَسَاءَلُونَ', 'startSurah': 'An-Naba 78:1',      'page': 582},
];

/// 8-pointed Islamic Star Badge (Rub-el-Hizb style) for numbering
class IslamicStarBadge extends StatelessWidget {
  final int number;
  final double size;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;

  const IslamicStarBadge({
    super.key,
    required this.number,
    this.size = 40,
    this.borderColor = const Color(0xFF56BA64),
    this.fillColor = const Color(0xFFEAF6EC),
    this.textColor = const Color(0xFF2C7A39),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotated square 1
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: borderColor, width: 1.2),
            ),
          ),
          // Rotated square 2 (45 degrees)
          Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: size * 0.84,
              height: size * 0.84,
              decoration: BoxDecoration(
                color: fillColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(color: borderColor, width: 1.2),
              ),
            ),
          ),
          // Center number
          Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleQuranIndexScreen extends StatefulWidget {
  final int initialTab;
  const SimpleQuranIndexScreen({super.key, int? initialTab, int? initialTabIndex})
      : initialTab = initialTab ?? initialTabIndex ?? 0;

  @override
  State<SimpleQuranIndexScreen> createState() => _SimpleQuranIndexScreenState();
}

class _SimpleQuranIndexScreenState extends State<SimpleQuranIndexScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: _activeTab);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging && mounted) {
        setState(() => _activeTab = _tabCtrl.index);
      }
    });
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSelectTab(int index) {
    setState(() => _activeTab = index);
    _tabCtrl.animateTo(index, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  List<SurahInfo> get _filteredSurahs {
    if (_query.isEmpty) return kSurahList;
    final q = _query;
    return kSurahList.where((s) {
      final nameEn = s.nameTransliteration.toLowerCase();
      final nameAr = s.nameArabic;
      final numStr = s.number.toString();
      return nameEn.contains(q) || nameAr.contains(q) || numStr == q;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredJuz {
    final list = List.generate(30, (i) => {
      'number': i + 1,
      'name': _kJuzData[i]['name'],
      'arabic': _kJuzData[i]['arabic'],
      'startSurah': _kJuzData[i]['startSurah'],
      'page': _kJuzData[i]['page'],
    });

    if (_query.isEmpty) return list;
    final q = _query;
    return list.where((j) {
      final name = (j['name'] as String).toLowerCase();
      final arabic = j['arabic'] as String;
      final numStr = j['number'].toString();
      return name.contains(q) || arabic.contains(q) || numStr == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        title: Text(
          'Quran Index',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B2A1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF3FA34D), size: 24),
            tooltip: 'Global Quran Search',
            onPressed: () => context.goNamed('search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: Color(0xFF3FA34D), size: 24),
            tooltip: 'Bookmarks & Sajdas',
            onPressed: () => context.goNamed('bookmarks'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── 1. Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: _activeTab == 0
                      ? 'Search 114 Surahs by name or number'
                      : 'Search 30 Paras / Chapters',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF8D9E92),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF3FA34D), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF8D9E92)),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // ── 2. Pill Tabs Switcher (Surahs & Paras) ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildPillTab(
                    index: 0,
                    label: 'Surahs (114)',
                    icon: Icons.menu_book_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPillTab(
                    index: 1,
                    label: 'Paras (30)',
                    icon: Icons.auto_stories_rounded,
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Tab Views ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── TAB 1: Surahs (114) ──
                _filteredSurahs.isEmpty
                    ? _buildEmptyState('No matching Surah found for "$_query"')
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + bottomPad),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (ctx, idx) {
                          final surah = _filteredSurahs[idx];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 200 + (idx.clamp(0, 12) * 25)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildSurahCard(surah),
                          );
                        },
                      ),

                // ── TAB 2: Paras (30) ──
                _filteredJuz.isEmpty
                    ? _buildEmptyState('No matching Para found for "$_query"')
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + bottomPad),
                        itemCount: _filteredJuz.length,
                        itemBuilder: (ctx, idx) {
                          final j = _filteredJuz[idx];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 200 + (idx.clamp(0, 12) * 25)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildJuzCard(j),
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

  Widget _buildPillTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeTab == index;

    return InkWell(
      onTap: () => _onSelectTab(index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3FA34D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF3FA34D) : const Color(0xFFE8E1D2),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3FA34D).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF3FA34D),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1B2A1E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahCard(SurahInfo surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2), width: 1.0),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.goNamed(
              'verse-by-verse',
              pathParameters: {'surahNumber': surah.number.toString()},
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── 1. 8-Point Islamic Star Number Emblem ──
                IslamicStarBadge(number: surah.number),
                const SizedBox(width: 14),

                // ── 2. Surah Name & Clean Metadata Line ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameTransliteration,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: surah.isMeccan ? const Color(0xFF3FA34D) : const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            surah.revelationType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5E50),
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: Color(0xFFD0C8B8), fontSize: 11)),
                          const Icon(Icons.menu_book_outlined, size: 12, color: Color(0xFF4B5E50)),
                          const SizedBox(width: 2),
                          Text(
                            '${surah.ayahCount} Verses',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5E50),
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: Color(0xFFD0C8B8), fontSize: 11)),
                          const Icon(Icons.description_outlined, size: 12, color: Color(0xFF4B5E50)),
                          const SizedBox(width: 2),
                          Text(
                            'Page ${surah.startPage}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5E50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 3. Warm Amber Arabic Calligraphy ──
                Text(
                  surah.nameArabic,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),

                // ── 4. Subtle Chevron ──
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF8D9E92),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJuzCard(Map<String, dynamic> j) {
    final int juzNumber = j['number'] as int;
    final String arabicName = j['arabic'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2), width: 1.0),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.goNamed(
              'juz',
              pathParameters: {'juzNumber': juzNumber.toString()},
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IslamicStarBadge(number: juzNumber),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Para $juzNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B2A1E),
                    ),
                  ),
                ),
                Text(
                  arabicName,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC59B27),
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
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
