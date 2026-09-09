// lib/features/mutashabihat/screens/mutashabihat_screen.dart
// World-class Quran Mutashabihat (Similar Verses) consolidated comparative explorer

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mutashabiha.dart';
import '../../../data/repositories/quran_repository.dart';

class MutashabihaMatch {
  final int similarSurah;
  final int similarAyah;
  final String? similarSurahName;
  final String? similarArabic;
  final int? ctx;

  const MutashabihaMatch({
    required this.similarSurah,
    required this.similarAyah,
    required this.similarSurahName,
    required this.similarArabic,
    this.ctx,
  });
}

class MutashabihatGroup {
  final int srcSurah;
  final int srcAyah;
  final String? srcSurahName;
  final String? srcArabic;
  final int juz;
  final List<MutashabihaMatch> matches;

  const MutashabihatGroup({
    required this.srcSurah,
    required this.srcAyah,
    required this.srcSurahName,
    required this.srcArabic,
    required this.juz,
    required this.matches,
  });
}

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

  List<MutashabihatGroup> get _groupedPairs {
    final Map<String, MutashabihatGroup> groupMap = {};

    for (final p in _allPairs) {
      final key = '${p.srcSurah}:${p.srcAyah}';
      if (!groupMap.containsKey(key)) {
        groupMap[key] = MutashabihatGroup(
          srcSurah: p.srcSurah,
          srcAyah: p.srcAyah,
          srcSurahName: p.srcSurahName,
          srcArabic: p.srcArabic,
          juz: p.juz ?? _selectedJuz,
          matches: [],
        );
      }

      final group = groupMap[key]!;
      final alreadyHasMatch = group.matches.any(
        (m) => m.similarSurah == p.similarSurah && m.similarAyah == p.similarAyah,
      );
      if (!alreadyHasMatch) {
        group.matches.add(
          MutashabihaMatch(
            similarSurah: p.similarSurah,
            similarAyah: p.similarAyah,
            similarSurahName: p.similarSurahName,
            similarArabic: p.similarArabic,
            ctx: p.ctx,
          ),
        );
      }
    }

    final allGroups = groupMap.values.toList();

    if (_searchQuery.isEmpty) return allGroups;

    return allGroups.where((g) {
      final srcSurah = (g.srcSurahName ?? '').toLowerCase();
      final srcRef = '${g.srcSurah}:${g.srcAyah}';
      final srcText = (g.srcArabic ?? '');

      if (srcSurah.contains(_searchQuery) || srcRef.contains(_searchQuery) || srcText.contains(_searchQuery)) {
        return true;
      }

      return g.matches.any((m) {
        final simSurah = (m.similarSurahName ?? '').toLowerCase();
        final simRef = '${m.similarSurah}:${m.similarAyah}';
        final simText = (m.similarArabic ?? '');
        return simSurah.contains(_searchQuery) || simRef.contains(_searchQuery) || simText.contains(_searchQuery);
      });
    }).toList();
  }

  void _copyGroup(MutashabihatGroup group) {
    final buffer = StringBuffer();
    buffer.writeln('Quran Mutashabihat (Similar Verses):\n');
    buffer.writeln('Base Verse: Surah ${group.srcSurahName} [${group.srcSurah}:${group.srcAyah}]:');
    buffer.writeln('${group.srcArabic ?? ""}\n');
    buffer.writeln('Similar Verses (${group.matches.length}):');
    for (int i = 0; i < group.matches.length; i++) {
      final m = group.matches[i];
      buffer.writeln('${i + 1}. Surah ${m.similarSurahName} [${m.similarSurah}:${m.similarAyah}]:');
      buffer.writeln('${m.similarArabic ?? ""}\n');
    }
    buffer.writeln('— Hifz ul Quran App');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mutashabihat verses copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final groups = _groupedPairs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Mutashabihat (Similar Ayat)',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by surah name, ayah (e.g. 2:3), or text...',
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

          // ── 3. Consolidated Mutashabihat Groups List ────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : groups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 100 + bottomPad),
                        itemCount: groups.length,
                        itemBuilder: (ctx, idx) => _buildConsolidatedCard(groups[idx], idx),
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
                    color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
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
                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.primarySurface,
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

  Widget _buildConsolidatedCard(MutashabihatGroup group, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // ── 1. Card Top Header: Index + Similar Count + Copy ─────────────
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
                        '#${index + 1} • Juz ${group.juz}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 0.8),
                      ),
                      child: Text(
                        '${group.matches.length} Similar ${group.matches.length == 1 ? "Ayah" : "Ayat"}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF57F17),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textMuted),
                  tooltip: 'Copy Group',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _copyGroup(group),
                ),
              ],
            ),
          ),

          // ── 2. Base Ayah (Emerald Green Theme) ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Surah ${group.srcSurahName}',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F2038),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF4FC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                            ),
                            child: Text(
                              'Ayah ${group.srcAyah}',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A60),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _openVerse(group.srcSurah, group.srcAyah),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A60),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 13, color: Color(0xFF1E3A60)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA), // Distinct soft royal sapphire canvas
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC5D5E8), width: 1.2),
                  ),
                  child: Text(
                    group.srcArabic ?? '...',
                    style: const TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontSize: 19.5,
                      height: 1.85,
                      color: Color(0xFF0F2038), // Rich deep sapphire text
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Connector Divider ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(child: Container(height: 1.2, color: const Color(0xFFE2E8F0))),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows_rounded, size: 14, color: Color(0xFFF57F17)),
                      const SizedBox(width: 4),
                      Text(
                        'Similar Verses (${group.matches.length}) • المتشابهات',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(height: 1.2, color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),

          // ── 4. All Similar Verses Underneath (Warm Amber Theme) ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              children: List.generate(group.matches.length, (matchIdx) {
                final match = group.matches[matchIdx];

                return Container(
                  margin: EdgeInsets.only(top: matchIdx > 0 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0), // Distinct warm golden parchment tint
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Surah ${match.similarSurahName}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF422006),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Ayah ${match.similarAyah}',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF57F17),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _openVerse(match.similarSurah, match.similarAyah),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Open',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.chevron_right, size: 13, color: Color(0xFFE65100)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.similarArabic ?? '...',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 18.5,
                          height: 1.85,
                          color: Color(0xFF3E2723), // Warm deep brown text
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                );
              }),
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
