import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

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

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Page, Surah, Juz, Manzil
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pageInputCtrl.dispose();
    super.dispose();
  }

  void _executeJumpToPage(int pageNum) {
    Navigator.pop(context);
    if (widget.onJumpToPage != null) {
      widget.onJumpToPage!(pageNum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMushafMode = widget.onJumpToPage != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
            isMushafMode ? 'Jump To Location (Mushaf)' : 'Jump To Location',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 10),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFF2D6A4F),
            labelColor: const Color(0xFF1B4332),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Page'),
              Tab(text: 'Surah (1-114)'),
              Tab(text: 'Juz (1-30)'),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Enter Page Number (1 - 610)',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageInputCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Page number...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2D6A4F)),
                    ),
                  ),
                  onSubmitted: (v) {
                    final p = int.tryParse(v);
                    if (p != null && p >= 1 && p <= 610) {
                      _executeJumpToPage(p);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final p = int.tryParse(_pageInputCtrl.text);
                  if (p != null && p >= 1 && p <= 610) {
                    _executeJumpToPage(p);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid page number (1-610)')),
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
              itemCount: 60, // Quick page shortcuts (Page 1, 10, 20... up to 600)
              itemBuilder: (ctx, i) {
                final pageNum = (i + 1) * 10;
                if (pageNum > 610) return const SizedBox.shrink();
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
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
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
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: TextField(
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
                      if (widget.onJumpToPage != null && widget.mushafType != null) {
                        final repo = ref.read(quranRepositoryProvider);
                        final page = await repo.getSurahStartPage(surah.number, widget.mushafType!);
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
                                  '${surah.revelationType} • ${surah.ayahCount} Verses • Page ${surah.startPage}',
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

  // ── 3. Juz Jump Tab ─────────────────────────────────────────────────────────
  Widget _buildJuzJumpTab() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 20 + MediaQuery.paddingOf(context).bottom),
      itemCount: 30,
      itemBuilder: (ctx, idx) {
        final juzNum = idx + 1;
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
                if (widget.onJumpToPage != null && widget.mushafType != null) {
                  final repo = ref.read(quranRepositoryProvider);
                  final page = await repo.getJuzStartPage(juzNum, widget.mushafType!);
                  _executeJumpToPage(page);
                } else {
                  Navigator.pop(context);
                  context.push('/home/juz/$juzNum');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _buildStarBadge(juzNum),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Juz $juzNum',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
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

  // ── 4. Manzil Jump Tab ──────────────────────────────────────────────────────
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
                if (widget.onJumpToPage != null && widget.mushafType != null) {
                  final repo = ref.read(quranRepositoryProvider);
                  final page = await repo.getSurahStartPage(startSurah, widget.mushafType!);
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
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: const Color(0xFFD1DDD4), width: 1.2),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: size * 0.84,
              height: size * 0.84,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF9).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(color: const Color(0xFFD1DDD4), width: 1.2),
              ),
            ),
          ),
          Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}
