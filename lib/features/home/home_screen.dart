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
          icon: const Icon(Icons.assessment_outlined),
          tooltip: 'Mistakes Analytics & Report',
          onPressed: () => context.goNamed('mistakes-report'),
        ),
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
      itemCount: surahs.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: const Color(0xFF1B4332),
            child: InkWell(
              onTap: () => context.goNamed('mistakes-report'),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFD4A843),
                      child: Icon(Icons.assessment, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mistakes Analytics & Report',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'View mistakes by Para/Surah, timeline & accuracy score',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          );
        }
        final surah = surahs[i - 1];
        return _SurahTile(
          surah: surah,
          onTap: () => context.goNamed('verse-by-verse',
              pathParameters: {'surahNumber': surah.number.toString()}),
        );
      },
    );
  }

  Widget _buildJuzTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 30,
      itemBuilder: (ctx, i) {
        final juzData = _kJuzData[i];
        return _JuzTile(
          juzNumber: i + 1,
          juzName: juzData['name'] as String,
          arabicName: juzData['arabic'] as String,
          startSurahName: juzData['startSurah'] as String,
          onTap: () {
            context.goNamed(
              'juz',
              pathParameters: {'juzNumber': (i + 1).toString()},
            );
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
  final String juzName;
  final String arabicName;
  final String startSurahName;
  final VoidCallback onTap;

  const _JuzTile({
    required this.juzNumber,
    required this.juzName,
    required this.arabicName,
    required this.startSurahName,
    required this.onTap,
  });

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
            // Juz number badge
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
            // Juz name + starting surah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    juzName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Starts from $startSurahName',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arabic juz name
            Text(
              arabicName,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 20,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Juz Data — names, Arabic titles, starting surah/ayah for all 30 Juz ──────
const _kJuzData = [
  {'name': 'Alif Laam Meem',        'arabic': 'الم',              'startSurah': 'Al-Baqarah',   'surah': 2,  'ayah': 1},
  {'name': 'Sayaqool',              'arabic': 'سَيَقُولُ',          'startSurah': 'Al-Baqarah',   'surah': 2,  'ayah': 142},
  {'name': 'Tilkar Rusul',          'arabic': 'تِلۡكَ ٱلرُّسُلُ',  'startSurah': 'Al-Baqarah',   'surah': 2,  'ayah': 253},
  {'name': 'Lan Tanaloo',           'arabic': 'لَن تَنَالُوا',     'startSurah': 'Aal-E-Imran',  'surah': 3,  'ayah': 92},
  {'name': 'Wal Mohsanat',          'arabic': 'وَٱلۡمُحۡصَنَٰتُ', 'startSurah': 'An-Nisa',      'surah': 4,  'ayah': 24},
  {'name': 'La Yuhibbullah',        'arabic': 'لَّا يُحِبُّ ٱللَّهُ', 'startSurah': 'An-Nisa',  'surah': 4,  'ayah': 148},
  {'name': 'Wa Iza Samiu',          'arabic': 'وَإِذَا سَمِعُوا',  'startSurah': 'Al-Maeda',     'surah': 5,  'ayah': 82},
  {'name': 'Wa Lau Annana',         'arabic': 'وَلَوۡ أَنَّنَا',   'startSurah': 'Al-Anaam',     'surah': 6,  'ayah': 111},
  {'name': 'Qalal Malao',           'arabic': 'قَالَ ٱلۡمَلَأُ',   'startSurah': 'Al-Araf',      'surah': 7,  'ayah': 88},
  {'name': 'Wa Alamu',              'arabic': 'وَٱعۡلَمُوٓا',      'startSurah': 'Al-Anfal',     'surah': 8,  'ayah': 41},
  {'name': 'Yatazeroon',            'arabic': 'يَعۡتَذِرُونَ',     'startSurah': 'At-Tawbah',    'surah': 9,  'ayah': 94},
  {'name': 'Wa Ma Min Daabbah',     'arabic': 'وَمَا مِن دَآبَّةٍ', 'startSurah': 'Hud',         'surah': 11, 'ayah': 6},
  {'name': 'Wa Ma Ubarrio',         'arabic': 'وَمَآ أُبَرِّئُ',   'startSurah': 'Yusuf',        'surah': 12, 'ayah': 53},
  {'name': 'Rubama',                'arabic': 'رُّبَمَا',           'startSurah': 'Al-Hijr',      'surah': 15, 'ayah': 1},
  {'name': 'Subhanallazi',          'arabic': 'سُبۡحَٰنَ ٱلَّذِي', 'startSurah': 'Al-Isra',      'surah': 17, 'ayah': 1},
  {'name': 'Qal Alam',              'arabic': 'قَالَ أَلَمۡ',      'startSurah': 'Al-Kahf',      'surah': 18, 'ayah': 75},
  {'name': 'Iqtaraba',              'arabic': 'ٱقۡتَرَبَ',         'startSurah': 'Al-Anbiya',    'surah': 21, 'ayah': 1},
  {'name': 'Qad Aflaha',            'arabic': 'قَدۡ أَفۡلَحَ',     'startSurah': 'Al-Muminoon',  'surah': 23, 'ayah': 1},
  {'name': 'Wa Qalallazina',        'arabic': 'وَقَالَ ٱلَّذِينَ', 'startSurah': 'Al-Furqan',    'surah': 25, 'ayah': 20},
  {'name': 'Amman Khalaq',          'arabic': 'أَمَّنۡ خَلَقَ',    'startSurah': 'An-Naml',      'surah': 27, 'ayah': 60},
  {'name': 'Utlu Ma Oohiya',        'arabic': 'ٱتۡلُ مَآ أُوحِيَ', 'startSurah': 'Al-Ankabut',  'surah': 29, 'ayah': 45},
  {'name': 'Wa Manyaqnut',          'arabic': 'وَمَن يَقۡنُتۡ',    'startSurah': 'Al-Ahzab',     'surah': 33, 'ayah': 31},
  {'name': 'Wa Mali',               'arabic': 'وَمَالِيَ',          'startSurah': 'Ya-Seen',      'surah': 36, 'ayah': 22},
  {'name': 'Faman Azlamu',          'arabic': 'فَمَنۡ أَظۡلَمُ',   'startSurah': 'Az-Zumar',     'surah': 39, 'ayah': 32},
  {'name': 'Ilayhi Yuraddu',        'arabic': 'إِلَيۡهِ يُرَدُّ',  'startSurah': 'Fussilat',     'surah': 41, 'ayah': 47},
  {'name': 'Ha Meem',               'arabic': 'حم',                 'startSurah': 'Al-Ahqaf',     'surah': 46, 'ayah': 1},
  {'name': 'Qala Fama Khatbukum',   'arabic': 'قَالَ فَمَا خَطۡبُكُمۡ', 'startSurah': 'Az-Zariyat', 'surah': 51, 'ayah': 31},
  {'name': 'Qad Sami Allah',        'arabic': 'قَدۡ سَمِعَ ٱللَّهُ', 'startSurah': 'Al-Mujadala', 'surah': 58, 'ayah': 1},
  {'name': 'Tabarakallazi',         'arabic': 'تَبَٰرَكَ ٱلَّذِي', 'startSurah': 'Al-Mulk',      'surah': 67, 'ayah': 1},
  {'name': 'Amma Yatasaaloona',     'arabic': 'عَمَّ يَتَسَآءَلُونَ', 'startSurah': 'An-Naba',   'surah': 78, 'ayah': 1},
];

