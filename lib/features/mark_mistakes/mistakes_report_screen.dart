import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class MistakesReportScreen extends ConsumerStatefulWidget {
  const MistakesReportScreen({super.key});

  @override
  ConsumerState<MistakesReportScreen> createState() => _MistakesReportScreenState();
}

class _MistakesReportScreenState extends ConsumerState<MistakesReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  List<Map<String, dynamic>> _allMistakes = [];
  Map<int, int> _juzCounts = {};
  Map<int, int> _surahCounts = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);

    final all = await repo.getAllMarkedMistakesWithDetails();
    final juzC = await repo.getMistakeCountsByJuz();
    final surahC = await repo.getMistakeCountsBySurah();

    if (mounted) {
      setState(() {
        _allMistakes = all;
        _juzCounts = juzC;
        _surahCounts = surahC;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMistakes = _allMistakes.length;
    // Calculate memorization accuracy score (100% - penalty proportional to mistakes)
    final accuracyScore = (100.0 - (totalMistakes * 0.15)).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 66,
        centerTitle: true,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F2038), size: 17),
            ),
          ),
        ),
        title: Text(
          'Mistakes Analytics & Report',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F2038),
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E1D2), width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFC59A27),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF0F2038),
              unselectedLabelColor: const Color(0xFF7C7365),
              labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'By Para (Juz)'),
                Tab(text: 'By Surah'),
                Tab(text: 'Timeline Logs'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC59A27)))
          : Column(
              children: [
                // Top Summary Header Cards (Warm Daylight Theme)
                _buildSummaryDashboard(totalMistakes, accuracyScore),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildJuzTab(),
                      _buildSurahTab(),
                      _buildTimelineTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryDashboard(int totalMistakes, double accuracyScore) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9C9A7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF625A45).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Mistakes Badge Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: totalMistakes > 0
                      ? const Color(0xFFF8B4B4)
                      : const Color(0xFFE8E1D2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$totalMistakes',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: totalMistakes > 0
                          ? const Color(0xFFC62828)
                          : const Color(0xFF0F2038),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Marked Mistakes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C7365),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Accuracy Score Gauge Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFC59A27).withValues(alpha: 0.50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC59A27).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${accuracyScore.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC59A27),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hifz Accuracy Rate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C7365),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Para (Juz) Breakdown (1–30) ──────────────────────────────────
  Widget _buildJuzTab() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 100 + MediaQuery.paddingOf(context).bottom),
      itemCount: 30,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final juzNum = idx + 1;
        final count = _juzCounts[juzNum] ?? 0;
        final maxCount = _juzCounts.values.isEmpty ? 1 : (_juzCounts.values.reduce((a, b) => a > b ? a : b));
        final ratio = count == 0 ? 0.0 : (count / maxCount).clamp(0.05, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: count > 0 ? const Color(0xFFF3C0C0) : const Color(0xFFE8E1D2),
            ),
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
              onTap: () => context.push('/home/juz/$juzNum'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Leading Number Pill Widget
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: count > 0 ? const Color(0xFFFDE8E8) : const Color(0xFFF5EFE6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: count > 0 ? const Color(0xFFF8B4B4) : const Color(0xFFE8DFC8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$juzNum',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: count > 0 ? const Color(0xFFC62828) : const Color(0xFF876510),
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
                                children: [
                                  Text(
                                    'Juz $juzNum',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F2038),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Arabic Sub-Pill Widget
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EFE6),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE8DFC8)),
                                    ),
                                    child: Text(
                                      'پارہ $juzNum',
                                      style: GoogleFonts.amiri(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF78540E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                count == 0 ? 'No mistakes logged' : '$count mistake${count > 1 ? 's' : ''} recorded',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: count > 0 ? const Color(0xFFC62828) : const Color(0xFF7C7365),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF7F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C7365), size: 18),
                        ),
                      ],
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFFDE8E8),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: Surah Breakdown ──────────────────────────────────────────────
  Widget _buildSurahTab() {
    if (_surahCounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 54, color: Color(0xFFC59A27)),
            const SizedBox(height: 12),
            Text(
              'No Mistakes Recorded!',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F2038)),
            ),
            const SizedBox(height: 4),
            Text(
              'Turn ON "Mark Mistakes" in Mushaf mode to log mistakes.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7C7365)),
            ),
          ],
        ),
      );
    }

    final sortedSurahs = _surahCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 100 + MediaQuery.paddingOf(context).bottom),
      itemCount: sortedSurahs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final entry = sortedSurahs[idx];
        final surahNum = entry.key;
        final count = entry.value;
        final surahInfo = kSurahList[surahNum - 1];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E1D2)),
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
              onTap: () => context.push('/home/surah/$surahNum'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Leading Pill Widget
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF8B4B4)),
                      ),
                      child: Center(
                        child: Text(
                          '$surahNum',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC62828),
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
                            children: [
                              Text(
                                surahInfo.nameTransliteration,
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F2038),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5EFE6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE8DFC8)),
                                ),
                                child: Text(
                                  surahInfo.nameArabic,
                                  style: GoogleFonts.amiri(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF78540E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count mistake${count > 1 ? 's' : ''} in Surah ${surahInfo.nameArabic}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Review Pill Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC59A27),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC59A27).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Review',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Timeline Logs ────────────────────────────────────────────────
  Widget _buildTimelineTab() {
    if (_allMistakes.isEmpty) {
      return Center(
        child: Text(
          'No mistake history logged yet.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7C7365), fontSize: 13),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy — hh:mm a');

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 100 + MediaQuery.paddingOf(context).bottom),
      itemCount: _allMistakes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final item = _allMistakes[idx];
        final wId = item['word_id'] as String;
        final surah = item['surah'] as int;
        final ayah = item['ayah'] as int;
        final juz = item['juz'] as int;
        final page = item['page'] as int;
        final timestamp = item['marked_at'] as int;
        final dateStr = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
        final surahInfo = kSurahList[surah - 1];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E1D2)),
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
              onTap: () => context.push('/home/surah/$surah?scrollToAyah=$ayah'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Leading Pill Icon Widget
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF8B4B4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.bookmark_remove_rounded, color: Color(0xFFC62828), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${surahInfo.nameTransliteration} — Verse $ayah',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F2038),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Pill Badges for Juz, Page, Word
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5EFE6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE8DFC8)),
                                ),
                                child: Text(
                                  'Juz $juz',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF876510),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF7F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE8E1D2)),
                                ),
                                child: Text(
                                  'Page $page',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7C7365),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF7F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE8E1D2)),
                                ),
                                child: Text(
                                  'Word $wId',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7C7365),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF9E9484),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF7F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF7C7365)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
