// lib/features/mutashabihat/screens/mutashabihat_screen.dart
// World-class Quran Mutashabihat (Similar Verses) comparative explorer

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mutashabiha.dart';
import '../../../data/repositories/quran_repository.dart';

class MutashabihatScreen extends ConsumerStatefulWidget {
  final int initialJuz;
  const MutashabihatScreen({super.key, this.initialJuz = 1});

  @override
  ConsumerState<MutashabihatScreen> createState() => _MutashabihatScreenState();
}

class _MutashabihatScreenState extends ConsumerState<MutashabihatScreen> {
  late int _selectedJuz;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Mutashabiha> _allPairs = [];
  Map<int, int> _juzCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedJuz = widget.initialJuz.clamp(1, 30);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);
    final counts = await repo.getMutashabihatCountsByJuz();
    final pairs = await repo.getMutashabihatByJuz(_selectedJuz);
    if (mounted) {
      setState(() {
        _juzCounts = counts;
        _allPairs = pairs;
        _loading = false;
      });
    }
  }

  Future<void> _onSelectJuz(int juz) async {
    if (_selectedJuz == juz) return;
    setState(() {
      _selectedJuz = juz;
      _loading = true;
    });
    final repo = ref.read(quranRepositoryProvider);
    final pairs = await repo.getMutashabihatByJuz(juz);
    if (mounted) {
      setState(() {
        _allPairs = pairs;
        _loading = false;
      });
    }
  }

  List<Mutashabiha> get _filteredPairs {
    if (_searchQuery.isEmpty) return _allPairs;
    return _allPairs.where((p) {
      final sName1 = (p.srcSurahName ?? '').toLowerCase();
      final sName2 = (p.similarSurahName ?? '').toLowerCase();
      final text1 = (p.srcArabic ?? '');
      final text2 = (p.similarArabic ?? '');
      final ref1 = '${p.srcSurah}:${p.srcAyah}';
      final ref2 = '${p.similarSurah}:${p.similarAyah}';
      return sName1.contains(_searchQuery) ||
          sName2.contains(_searchQuery) ||
          text1.contains(_searchQuery) ||
          text2.contains(_searchQuery) ||
          ref1.contains(_searchQuery) ||
          ref2.contains(_searchQuery);
    }).toList();
  }

  void _copyPair(Mutashabiha pair) {
    final text = 'Quran Mutashabihat (Similar Verses):\n\n'
        '1. Surah ${pair.srcSurahName} [${pair.srcSurah}:${pair.srcAyah}]:\n'
        '${pair.srcArabic ?? ""}\n\n'
        '2. Surah ${pair.similarSurahName} [${pair.similarSurah}:${pair.similarAyah}]:\n'
        '${pair.similarArabic ?? ""}\n\n'
        '— Al Quran App';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mutashabihat verses copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              'Mutashabihat',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'المتشابهات',
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
            icon: const Icon(Icons.info_outline, color: AppTheme.primary),
            tooltip: 'About Mutashabihat',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 1. Search Bar ───────────────────────────────────────────────
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
                  hintText: 'Search by surah name, ayah (e.g. 2:9), or text...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
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

          // ── 2. Juz Selector Carousel ────────────────────────────────────
          _buildJuzSelector(),

          const SizedBox(height: 4),

          // ── 3. Mutashabihat Pairs List ──────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredPairs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + bottomPad),
                        itemCount: _filteredPairs.length,
                        itemBuilder: (ctx, idx) => _buildComparativeCard(_filteredPairs[idx], idx),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuzSelector() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 30,
        itemBuilder: (ctx, idx) {
          final juzNum = idx + 1;
          final isSelected = _selectedJuz == juzNum;
          final count = _juzCounts[juzNum] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: InkWell(
              onTap: () => _onSelectJuz(juzNum),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : const Color(0xFFE2E8E4),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Juz $juzNum',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparativeCard(Mutashabiha pair, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${index + 1} • Juz ${pair.juz ?? _selectedJuz}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (pair.ctx != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Context ${pair.ctx}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textMuted),
                      tooltip: 'Copy Pair',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => _copyPair(pair),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 1. Source Ayah Box ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Surah ${pair.srcSurahName}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ayah ${pair.srcAyah}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        context.goNamed(
                          'verse-by-verse',
                          pathParameters: {'surahNumber': '${pair.srcSurah}'},
                          queryParameters: {'ayah': '${pair.srcAyah}'},
                        );
                      },
                      child: Row(
                        children: [
                          Text('Open', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFDFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECE9)),
                  ),
                  child: Text(
                    pair.srcArabic ?? '...',
                    style: const TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontSize: 19,
                      height: 1.85,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          // ── Similarity Connector Divider ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8E4))),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows_rounded, size: 14, color: Color(0xFFF57F17)),
                      const SizedBox(width: 4),
                      Text(
                        'Similar To • يُشبه',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF57F17),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8E4))),
              ],
            ),
          ),

          // ── 2. Similar Ayah Box ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF57F17),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Surah ${pair.similarSurahName}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ayah ${pair.similarAyah}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF57F17),
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        context.goNamed(
                          'verse-by-verse',
                          pathParameters: {'surahNumber': '${pair.similarSurah}'},
                          queryParameters: {'ayah': '${pair.similarAyah}'},
                        );
                      },
                      child: Row(
                        children: [
                          Text('Open', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFCF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0EBE1)),
                  ),
                  child: Text(
                    pair.similarArabic ?? '...',
                    style: const TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontSize: 19,
                      height: 1.85,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text(
              'No Mutashabihat Found',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching similar verses for "$_searchQuery".'
                  : 'No similar verses registered in Juz $_selectedJuz.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('About Mutashabihat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Mutashabihat (الآيات المتشابهات) are Quranic verses that share very similar phrases, structures, or wordings across different Surahs.\n\n'
          'Studying Mutashabihat is essential for Huffaz (memorizers of the Quran) and students to avoid confusion during recitation and deepen contemplation of subtle linguistic distinctions.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
