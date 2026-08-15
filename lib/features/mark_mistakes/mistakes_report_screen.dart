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
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        title: Text(
          'Mistakes Analytics & Report',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFD4A843),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'By Para (Juz)'),
            Tab(text: 'By Surah'),
            Tab(text: 'Timeline Logs'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
          : Column(
              children: [
                // Top Summary Header Cards
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1B4332),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Total Mistakes Badge
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  Text(
                    '$totalMistakes',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
                  ),
                  const SizedBox(height: 2),
                  Text('Marked Mistakes', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Accuracy Score Gauge
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  Text(
                    '${accuracyScore.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFA5D6A7)),
                  ),
                  const SizedBox(height: 2),
                  Text('Hifz Accuracy Rate', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
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
      padding: const EdgeInsets.all(14),
      itemCount: 30,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final juzNum = idx + 1;
        final count = _juzCounts[juzNum] ?? 0;
        final maxCount = _juzCounts.values.isEmpty ? 1 : (_juzCounts.values.reduce((a, b) => a > b ? a : b));
        final ratio = count == 0 ? 0.0 : (count / maxCount).clamp(0.05, 1.0);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => context.push('/home/juz/$juzNum'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: count > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                        child: Text(
                          '$juzNum',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Juz $juzNum (پارہ $juzNum)',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
                            ),
                            Text(
                              count == 0 ? 'No mistakes logged' : '$count mistake${count > 1 ? 's' : ''} recorded',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: count > 0 ? Colors.red[700] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: Colors.red[50],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                      ),
                    ),
                  ],
                ],
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
            const Icon(Icons.check_circle_outline, size: 54, color: Color(0xFF2D6A4F)),
            const SizedBox(height: 12),
            Text('No Mistakes Recorded!', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Turn ON "Mark Mistakes" in Mushaf mode to log mistakes.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    final sortedSurahs = _surahCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: sortedSurahs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final entry = sortedSurahs[idx];
        final surahNum = entry.key;
        final count = entry.value;
        final surahInfo = kSurahList[surahNum - 1];

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFEBEE),
              child: Text(
                '$surahNum',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFC62828)),
              ),
            ),
            title: Text(
              surahInfo.nameTransliteration,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '$count mistake${count > 1 ? 's' : ''} in Surah ${surahInfo.nameArabic}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.red[700]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Review',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            onTap: () => context.push('/home/surah/$surahNum'),
          ),
        );
      },
    );
  }

  // ── Tab 3: Timeline Logs ────────────────────────────────────────────────
  Widget _buildTimelineTab() {
    if (_allMistakes.isEmpty) {
      return Center(
        child: Text('No mistake history logged yet.', style: GoogleFonts.inter(color: Colors.grey)),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy — hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.all(14),
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

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.bookmark_remove_rounded, color: Color(0xFFE53935)),
            title: Text(
              '${surahInfo.nameTransliteration} — Verse $ayah (Juz $juz)',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Word $wId • Page $page\n$dateStr',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () => context.push('/home/surah/$surah?scrollToAyah=$ayah'),
          ),
        );
      },
    );
  }
}
