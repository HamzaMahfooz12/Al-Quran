import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/ruku_data.dart';

class JumpNavigationDialog extends ConsumerStatefulWidget {
  final String? mushafType;
  final Function(int pageNumber)? onJumpToPage;

  const JumpNavigationDialog({
    super.key,
    this.mushafType,
    this.onJumpToPage,
  });

  static Future<void> show(
    BuildContext context, {
    String? mushafType,
    Function(int pageNumber)? onJumpToPage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JumpNavigationDialog(
        mushafType: mushafType,
        onJumpToPage: onJumpToPage,
      ),
    );
  }

  @override
  ConsumerState<JumpNavigationDialog> createState() => _JumpNavigationDialogState();
}

class _JumpNavigationDialogState extends ConsumerState<JumpNavigationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  final TextEditingController _pageInputCtrl = TextEditingController();
  final TextEditingController _ayahInputCtrl = TextEditingController();
  int _selectedSurahForAyah = 1;

  static const List<String> kJuzNamesArabic = [
    'الٓمّٓ ۱',
    'سَیَقُوْلُ ۲',
    'تِلْكَ الرُّسُلُ ۳',
    'لَنْ تَنَالُوا ٤',
    'وَالْمُحْصَنٰتُ ۵',
    'لَا یُحِبُّ اللّٰهُ ٦',
    'وَاِذَا سَمِعُوْا ۷',
    'وَلَوْ اَنَّنَا ۸',
    'قَالَ الْمَلَاُ ۹',
    'وَاعْلَمُوْۤا ۱۰',
    'یَعْتَذِرُوْنَ ۱۱',
    'وَمَا مِنْ دَآبَّةٍ ۱۲',
    'وَمَاۤ اُبَرِّئُ ۱۳',
    'رُبَمَا ۱٤',
    'سُبْحٰنَ الَّذِیْۤ ۱۵',
    'قَالَ اَلَمْ ۱٦',
    'اقْتَرَبَ ۱۷',
    'قَدْ اَفْلَحَ ۱۸',
    'وَقَالَ الَّذِیْنَ ۱۹',
    'اَمَّنْ خَلَقَ ۲۰',
    'اتْلُ مَاۤ اُوْحِیَ ۲۱',
    'وَمَنْ یَّقْنُتْ ۲۲',
    'وَمَا لِیَ ۲۳',
    'فَمَنْ اَظْلَمُ ۲٤',
    'اِلَیْهِ یُرَدُّ ۲۵',
    'حٰمٓ ۲٦',
    'قَالَ فَمَا خَطْبُكُمْ ۲۷',
    'قَدْ سَمِعَ اللّٰهُ ۲۸',
    'تَبٰرَكَ الَّذِیْ ۲۹',
    'عَمَّ ۳۰',
  ];

  @override
  void initState() {
    super.initState();
    // 5 Tabs: Page, Surah, Para/Juz, Ayat/Ruku, Manzil
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pageInputCtrl.dispose();
    _ayahInputCtrl.dispose();
    super.dispose();
  }

  void _executeJumpToPage(int pageNum) {
    Navigator.pop(context);
    if (widget.onJumpToPage != null) {
      widget.onJumpToPage!(pageNum);
    }
  }

  bool get _is16Line =>
      widget.mushafType == '16_line' || widget.mushafType == 'mushaf_16';

  int get _maxPages => _is16Line ? 548 : 610;

  @override
  Widget build(BuildContext context) {
    final isMushafMode = widget.onJumpToPage != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & title
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            isMushafMode
                ? (_is16Line
                    ? 'Jump To Location (16-Line Mushaf)'
                    : 'Jump To Location (15-Line Mushaf)')
                : 'Jump To Location',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A60),
            ),
          ),
          const SizedBox(height: 10),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF1E3A60),
            labelColor: const Color(0xFF1E3A60),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Page'),
              Tab(text: 'Surah (1-114)'),
              Tab(text: 'Para / Juz (1-30)'),
              Tab(text: 'Ayat / Ruku'),
              Tab(text: 'Manzil (1-7)'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPageJumpTab(),
                _buildSurahJumpTab(),
                _buildJuzJumpTab(),
                _buildAyatRukuJumpTab(),
                _buildManzilJumpTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Direct Page Number Jump Tab ──────────────────────────────────────────
  Widget _buildPageJumpTab() {
    final maxPages = _maxPages;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Enter Page Number (1 - $maxPages)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A60),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageInputCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: false, // Prevents keyboard from auto-opening on dialog open
                  decoration: InputDecoration(
                    hintText: 'Page number (1-$maxPages)...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E3A60)),
                    ),
                  ),
                  onSubmitted: (v) {
                    final p = int.tryParse(v);
                    if (p != null && p >= 1 && p <= maxPages) {
                      _executeJumpToPage(p);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final p = int.tryParse(_pageInputCtrl.text);
                  if (p != null && p >= 1 && p <= maxPages) {
                    _executeJumpToPage(p);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid page number (1-$maxPages)')),
                    );
                  }
                },
                child: Text('Jump', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: (maxPages / 10).floor() + (maxPages % 10 != 0 ? 1 : 0),
              itemBuilder: (ctx, i) {
                final pageNum = (i + 1 == (maxPages / 10).floor() + 1)
                    ? maxPages
                    : (i + 1) * 10;
                if (pageNum > maxPages) return const SizedBox.shrink();
                return InkWell(
                  onTap: () => _executeJumpToPage(pageNum),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'P. $pageNum',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A60),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Surah Jump Tab ───────────────────────────────────────────────────────
  Widget _buildSurahJumpTab() {
    final filtered = kSurahList.where((s) {
      final q = _searchQuery.toLowerCase().trim();
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.number.toString() == q;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search Surah by name or number...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6B7280)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(14, 4, 14, 20 + MediaQuery.paddingOf(context).bottom),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final surah = filtered[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDE8DF)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (widget.onJumpToPage != null) {
                        final repo = ref.read(quranRepositoryProvider);
                        final page = await repo.getSurahStartPage(
                          surah.number,
                          widget.mushafType ?? (_is16Line ? '16_line' : '15_line'),
                        );
                        _executeJumpToPage(page);
                      } else {
                        Navigator.pop(context);
                        context.push('/home/surah/${surah.number}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          _buildStarBadge(surah.number),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surah.nameTransliteration,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${surah.revelationType} • ${surah.ayahCount} Verses • ${surah.rukuCount} Rukus',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            surah.nameArabic,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC59B27),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 3. Para / Juz Jump Tab ──────────────────────────────────────────────────
  Widget _buildJuzJumpTab() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 20 + MediaQuery.paddingOf(context).bottom),
      itemCount: 30,
      itemBuilder: (ctx, idx) {
        final juzNum = idx + 1;
        final arabicName = (idx < kJuzNamesArabic.length) ? kJuzNamesArabic[idx] : 'الجزء $juzNum';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE8DF)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                if (widget.onJumpToPage != null) {
                  final repo = ref.read(quranRepositoryProvider);
                  final page = await repo.getJuzStartPage(
                    juzNum,
                    widget.mushafType ?? (_is16Line ? '16_line' : '15_line'),
                  );
                  _executeJumpToPage(page);
                } else {
                  Navigator.pop(context);
                  context.push('/home/juz/$juzNum');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    _buildStarBadge(juzNum),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Para $juzNum (پارہ $juzNum)',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Juz $juzNum of 30',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      arabicName,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC59B27),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 4. Ayat & Ruku Jump Tab ─────────────────────────────────────────────────
  Widget _buildAyatRukuJumpTab() {
    final selectedSurah = kSurahList[_selectedSurahForAyah - 1];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Surah Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A60), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Surah',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedSurahForAyah,
                          isExpanded: true,
                          items: kSurahList.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.number,
                              child: Text(
                                '${s.number}. ${s.nameTransliteration} (${s.nameArabic})',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _selectedSurahForAyah = newVal;
                                _ayahInputCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── A. Direct Ayah Jump Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, color: Color(0xFFD4AF37), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Jump to Specific Ayah (آية)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Surah ${selectedSurah.nameTransliteration} has ${selectedSurah.ayahCount} Ayat',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ayahInputCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Enter Ayah (1 - ${selectedSurah.ayahCount})...',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1E3A60)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final a = int.tryParse(_ayahInputCtrl.text.trim());
                        if (a != null && a >= 1 && a <= selectedSurah.ayahCount) {
                          final repo = ref.read(quranRepositoryProvider);
                          final page = await repo.getMushafPageForAyah(
                            _selectedSurahForAyah,
                            a,
                            widget.mushafType ?? (_is16Line ? '16_line' : '15_line'),
                          );
                          if (page != null) {
                            _executeJumpToPage(page);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ayah page not found in mushaf layout')),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter a valid ayah number between 1 and ${selectedSurah.ayahCount}',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text('Go', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── B. Direct Ruku Jump Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_added_rounded, color: Color(0xFFD4AF37), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Jump to Ruku (رُكُوْع)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select any of the ${selectedSurah.rukuCount} Rukus in Surah ${selectedSurah.nameTransliteration}:',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(selectedSurah.rukuCount, (i) {
                    final rukuNum = i + 1;
                    final startA = RukuData.getRukuStartAyah(_selectedSurahForAyah, rukuNum);
                    final endA = RukuData.getRukuEndAyah(_selectedSurahForAyah, rukuNum);

                    return InkWell(
                      onTap: () async {
                        final repo = ref.read(quranRepositoryProvider);
                        final page = await repo.getMushafPageForAyah(
                          _selectedSurahForAyah,
                          startA,
                          widget.mushafType ?? (_is16Line ? '16_line' : '15_line'),
                        );
                        if (page != null) {
                          _executeJumpToPage(page);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC5D5E8)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ruku $rukuNum',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A60),
                              ),
                            ),
                            Text(
                              'Ayat $startA-$endA',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Manzil Jump Tab ──────────────────────────────────────────────────────
  Widget _buildManzilJumpTab() {
    const manzilInfo = [
      {'num': 1, 'surah': 1, 'title': 'Manzil 1', 'range': 'Surah 1 (Al-Fatihah) – Surah 4 (An-Nisa)'},
      {'num': 2, 'surah': 5, 'title': 'Manzil 2', 'range': "Surah 5 (Al-Ma'idah) – Surah 9 (At-Tawbah)"},
      {'num': 3, 'surah': 10, 'title': 'Manzil 3', 'range': 'Surah 10 (Yunus) – Surah 16 (An-Nahl)'},
      {'num': 4, 'surah': 17, 'title': 'Manzil 4', 'range': "Surah 17 (Al-Isra') – Surah 25 (Al-Furqan)"},
      {'num': 5, 'surah': 26, 'title': 'Manzil 5', 'range': "Surah 26 (Ash-Shu'ara) – Surah 36 (Ya-Sin)"},
      {'num': 6, 'surah': 37, 'title': 'Manzil 6', 'range': 'Surah 37 (As-Saffat) – Surah 49 (Al-Hujurat)'},
      {'num': 7, 'surah': 50, 'title': 'Manzil 7', 'range': 'Surah 50 (Qaf) – Surah 114 (An-Nas)'},
    ];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 20 + MediaQuery.paddingOf(context).bottom),
      itemCount: 7,
      itemBuilder: (ctx, idx) {
        final info = manzilInfo[idx];
        final manzilNum = info['num'] as int;
        final startSurah = info['surah'] as int;
        final title = info['title'] as String;
        final range = info['range'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE8DF)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                if (widget.onJumpToPage != null) {
                  final repo = ref.read(quranRepositoryProvider);
                  final page = await repo.getSurahStartPage(
                    startSurah,
                    widget.mushafType ?? (_is16Line ? '16_line' : '15_line'),
                  );
                  _executeJumpToPage(page);
                } else {
                  Navigator.pop(context);
                  context.push('/home/surah/$startSurah');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _buildStarBadge(manzilNum),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            range,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarBadge(int number) {
    const size = 36.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: size * 0.84,
              height: size * 0.84,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
            ),
          ),
          Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A60),
            ),
          ),
        ],
      ),
    );
  }
}
