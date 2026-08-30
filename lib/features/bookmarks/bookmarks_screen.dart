// lib/features/bookmarks/bookmarks_screen.dart
// Dual-Tab Bookmarks & 14 Authentic Sajda Verses with direct verse navigation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';
import '../../data/models/bookmark.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class SajdaVerseInfo {
  final int index;
  final int surah;
  final int ayah;
  final String surahName;
  final String surahNameArabic;
  final int juz;
  final String arabicText;
  final String translation;
  final String type; // 'Wajib' or 'Sunnah'

  const SajdaVerseInfo({
    required this.index,
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.surahNameArabic,
    required this.juz,
    required this.arabicText,
    required this.translation,
    required this.type,
  });
}

const List<SajdaVerseInfo> kSajdaVerses = [
  SajdaVerseInfo(
    index: 1,
    surah: 7,
    ayah: 206,
    surahName: "Al-A'raf",
    surahNameArabic: "الأعراف",
    juz: 9,
    arabicText: "إِنَّ الَّذِينَ عِندَ رَبِّكَ لَا يَسْتَكْبِرُونَ عَنْ عِبَادَتِهِ وَيُسَبِّحُونَهُ وَلَهُ يَسْجُدُونَ ۩",
    translation: "Indeed, those who are near your Lord are not too proud to serve Him; they glorify Him, and to Him they prostrate.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 2,
    surah: 13,
    ayah: 15,
    surahName: "Ar-Ra'd",
    surahNameArabic: "الرعد",
    juz: 13,
    arabicText: "وَلِلَّـهِ يَسْجُدُ مَن فِي السَّمَاوَاتِ وَالْأَرْضِ طَوْعًا وَكَرْهًا وَظِلَالُهُم بِالْغُدُوِّ وَالْآصَالِ ۩",
    translation: "And to Allah prostrates whoever is in the heavens and the earth, willingly or by compulsion, and their shadows in the mornings and afternoons.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 3,
    surah: 16,
    ayah: 50,
    surahName: "An-Nahl",
    surahNameArabic: "النحل",
    juz: 14,
    arabicText: "يَخَافُونَ رَبَّهُم مِّن فَوْقِهِمْ وَيَفْعَلُونَ مَا يُؤْمَرُونَ ۩",
    translation: "They fear their Lord above them, and they do what they are commanded.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 4,
    surah: 17,
    ayah: 109,
    surahName: "Al-Isra",
    surahNameArabic: "الإسراء",
    juz: 15,
    arabicText: "وَيَخِرُّونَ لِلْأَذْقَانِ يَبْكُونَ وَيَزِيدُهُمْ خُشُوعًا ۩",
    translation: "And they fall upon their faces weeping, and the Qur'an increases them in humble submission.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 5,
    surah: 19,
    ayah: 58,
    surahName: "Maryam",
    surahNameArabic: "مريم",
    juz: 16,
    arabicText: "إِذَا تُتْلَىٰ عَلَيْهِمْ آيَاتُ الرَّحْمَـٰنِ خَرُّوا سُجَّدًا وَبُكِيًّا ۩",
    translation: "When the verses of the Most Merciful were recited to them, they fell in prostration and weeping.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 6,
    surah: 22,
    ayah: 18,
    surahName: "Al-Hajj",
    surahNameArabic: "الحج",
    juz: 17,
    arabicText: "أَلَمْ تَرَ أَنَّ اللَّـهَ يَسْجُدُ لَهُ مَن فِي السَّمَاوَاتِ وَمَن فِي الْأَرْضِ وَالشَّمْسُ وَالْقَمَرُ وَالنُّجُومُ وَالْجِبَالُ وَالشَّجَرُ وَالدَّوَابُّ وَكَثِيرٌ مِّنَ النَّاسِ ۩",
    translation: "Do you not see that to Allah prostrates whoever is in the heavens and whoever is on the earth and the sun, the moon, the stars, the mountains, the trees, the moving creatures and many of the people?",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 7,
    surah: 22,
    ayah: 77,
    surahName: "Al-Hajj",
    surahNameArabic: "الحج",
    juz: 17,
    arabicText: "يَا أَيُّهَا الَّذِينَ آمَنُوا ارْكَعُوا وَاسْجُدُوا وَاعْبُدُوا رَبَّكُمْ وَافْعَلُوا الْخَيْرَ لَعَلَّكُمْ تُفْلِحُونَ ۩",
    translation: "O you who have believed, bow down and prostrate yourselves and serve your Lord, and do good that you may succeed.",
    type: "Sunnah",
  ),
  SajdaVerseInfo(
    index: 8,
    surah: 25,
    ayah: 60,
    surahName: "Al-Furqan",
    surahNameArabic: "الفرقان",
    juz: 19,
    arabicText: "وَإِذَا قِيلَ لَهُمُ اسْجُدُوا لِلرَّحْمَـٰنِ قَالُوا وَمَا الرَّحْمَـٰنُ أَنَسْجُدُ لِمَا تَأْمُرُنَا وَزَادَهُمْ نُفُورًا ۩",
    translation: "And when it is said to them, 'Prostrate to the Most Merciful,' they say, 'And what is the Most Merciful? Shall we prostrate to whatever you command us?' And it increases them in aversion.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 9,
    surah: 27,
    ayah: 26,
    surahName: "An-Naml",
    surahNameArabic: "النمل",
    juz: 19,
    arabicText: "اللَّـهُ لَا إِلَـٰهَ إِلَّا هُوَ رَبُّ الْعَرْشِ الْعَظِيمِ ۩",
    translation: "Allah - there is no deity except Him, Lord of the Great Throne.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 10,
    surah: 32,
    ayah: 15,
    surahName: "As-Sajdah",
    surahNameArabic: "السجدة",
    juz: 21,
    arabicText: "إِنَّمَا يُؤْمِنُ بِآيَاتِنَا الَّذِينَ إِذَا ذُكِّرُوا بِهَا خَرُّوا سُجَّدًا وَسَبَّحُوا بِحَمْدِ رَبِّهِمْ وَهُمْ لَا يَسْتَكْبِرُونَ ۩",
    translation: "Only those believe in Our verses who, when they are reminded of them, fall down in prostration and hymn the praise of their Lord, and they are not arrogant.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 11,
    surah: 38,
    ayah: 24,
    surahName: "Sad",
    surahNameArabic: "ص",
    juz: 23,
    arabicText: "وَظَنَّ دَاوُودُ أَنَّمَا فَتَنَّاهُ فَاسْتَغْفَرَ رَبَّهُ وَخَرَّ رَاكِعًا وَأَنَابَ ۩",
    translation: "And David became certain that We had tried him, and he asked forgiveness of his Lord and fell down bowing [in prostration] and turned in repentance.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 12,
    surah: 41,
    ayah: 38,
    surahName: "Fussilat",
    surahNameArabic: "فصلت",
    juz: 24,
    arabicText: "فَإِنِ اسْتَكْبَرُوا فَالَّذِينَ عِندَ رَبِّكَ يُسَبِّحُونَ لَهُ بِاللَّيْلِ وَالنَّهَارِ وَهُمْ لَا يَسْأَمُونَ ۩",
    translation: "But if they are arrogant - then those who are near your Lord glorify Him by night and by day, and they do not become weary.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 13,
    surah: 53,
    ayah: 62,
    surahName: "An-Najm",
    surahNameArabic: "النجم",
    juz: 27,
    arabicText: "فَاسْجُدُوا لِلَّـهِ وَاعْبُدُوا ۩",
    translation: "So prostrate to Allah and worship Him.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 14,
    surah: 84,
    ayah: 21,
    surahName: "Al-Inshiqaq",
    surahNameArabic: "الانشقاق",
    juz: 30,
    arabicText: "وَإِذَا قُرِئَ عَلَيْهِمُ الْقُرْآنُ لَا يَسْجُدُونَ ۩",
    translation: "And when the Qur'an is recited to them, they do not prostrate.",
    type: "Wajib",
  ),
  SajdaVerseInfo(
    index: 15,
    surah: 96,
    ayah: 19,
    surahName: "Al-'Alaq",
    surahNameArabic: "العلق",
    juz: 30,
    arabicText: "كَلَّا لَا تُطِعْهُ وَاسْجُدْ وَاقْتَرِب ۩",
    translation: "No! Do not obey him. But prostrate and draw near [to Allah].",
    type: "Wajib",
  ),
];

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  List<Bookmark> _bookmarks = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);
    final list = await repo.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _loading = false;
      });
    }
  }

  Future<void> _deleteBookmark(Bookmark b) async {
    final repo = ref.read(quranRepositoryProvider);
    await repo.removeBookmark(b.surah, b.ayah);
    await _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookmark removed'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openVerse(int surah, int ayah) {
    context.goNamed(
      'verse-by-verse',
      pathParameters: {'surahNumber': '$surah'},
      queryParameters: {
        'ayah': '$ayah',
        'scrollToAyah': '$ayah',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final filteredBookmarks = _bookmarks.where((b) {
      if (b.surah < 1 || b.surah > 114) return false;
      final info = kSurahList[b.surah - 1];
      final matchesSurah = info.nameTransliteration.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          info.nameArabic.contains(_searchQuery);
      final matchesLabel = b.label?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return matchesSurah || matchesLabel;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Bookmarks & Sajda Verses',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              icon: const Icon(Icons.bookmark_rounded, size: 20),
              text: 'Bookmarks (${_bookmarks.length})',
            ),
            Tab(
              icon: const Icon(Icons.airline_seat_recline_extra_rounded, size: 20),
              text: 'Sajda Verses (${kSajdaVerses.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── TAB 1: User Bookmarks ─────────────────────────────────────────
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search saved bookmarks...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2D6A4F)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0EAE3)),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
                    : filteredBookmarks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.bookmark_border_rounded, size: 48, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Bookmarks Found',
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap the bookmark ribbon on any Ayah while reading to save it for quick access.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(14, 6, 14, 100 + bottomPad),
                            itemCount: filteredBookmarks.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final b = filteredBookmarks[idx];
                              final info = kSurahList[b.surah - 1];
                              final dateStr = DateFormat('MMM dd, yyyy').format(b.createdAt);

                              return Card(
                                elevation: 0.8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: Color(0xFFE8ECE9)),
                                ),
                                child: InkWell(
                                  onTap: () => _openVerse(b.surah, b.ayah),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primarySurface,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${b.ayah}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${info.nameTransliteration} (${info.number})',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    info.nameArabic,
                                                    style: GoogleFonts.amiri(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.gold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                b.label != null && b.label!.isNotEmpty
                                                    ? 'Note: ${b.label}\nSaved on $dateStr'
                                                    : 'Verse ${b.ayah} • Saved on $dateStr',
                                                style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                          tooltip: 'Remove',
                                          onPressed: () => _deleteBookmark(b),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // ── TAB 2: Sajda Verses ───────────────────────────────────────────
          ListView.separated(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 100 + bottomPad),
            itemCount: kSajdaVerses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final s = kSajdaVerses[idx];

              return Card(
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2EBE5)),
                ),
                child: InkWell(
                  onTap: () => _openVerse(s.surah, s.ayah),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: Sajdah Number & Surah Info & Type Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4332),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Sajdah ${s.index}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFD54F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Surah ${s.surahName} [${s.surah}:${s.ayah}]',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.type == 'Wajib'
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: s.type == 'Wajib'
                                      ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                                      : const Color(0xFFFFA000).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '${s.type} • Juz ${s.juz}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: s.type == 'Wajib' ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Arabic Verse Text with Sajdah Mark
                        Text(
                          s.arabicText,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Scheherazade New',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Translation snippet
                        Text(
                          s.translation,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Bottom Action Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Open in Quran',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
