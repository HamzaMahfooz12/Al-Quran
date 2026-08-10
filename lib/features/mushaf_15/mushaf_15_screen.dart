// lib/features/mushaf_15/mushaf_15_screen.dart
// 15-line Madani Mushaf — QCF v4 word-by-word rendering
// Word layout loaded from word_layout table (mushaf = '15_line')
// Mark Mistakes mode: toggle activates word tap → red underline
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/db_helper.dart';
import '../../data/repositories/quran_repository.dart';

class Mushaf15Screen extends ConsumerStatefulWidget {
  final int initialPage;
  const Mushaf15Screen({super.key, this.initialPage = 1});

  @override
  ConsumerState<Mushaf15Screen> createState() => _Mushaf15ScreenState();
}

class _Mushaf15ScreenState extends ConsumerState<Mushaf15Screen> {
  late final PageController _pageCtrl;
  static const int _totalPages = 604;
  bool _markMistakesMode = false;
  Set<String> _markedWords = {};
  int _currentPage = 1;
  List<Map<String, dynamic>> _pageWords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageCtrl = PageController(initialPage: widget.initialPage - 1);
    _loadPage(widget.initialPage);
    _loadMarkedMistakes();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final rows = await db.rawQuery(
      'SELECT * FROM word_layout WHERE mushaf = ? AND page = ? ORDER BY line, word_pos',
      ['15_line', page],
    );
    if (mounted) {
      setState(() {
        _pageWords = rows;
        _loading = false;
      });
    }
  }

  Future<void> _loadMarkedMistakes() async {
    final repo = ref.read(quranRepositoryProvider);
    final mistakes = await repo.getMarkedMistakes('mushaf_15');
    if (mounted) setState(() => _markedWords = mistakes);
  }

  Future<void> _onWordTap(String wordId) async {
    if (!_markMistakesMode) return;
    final repo = ref.read(quranRepositoryProvider);
    await repo.toggleMarkedMistake(wordId, 'mushaf_15');
    setState(() {
      if (_markedWords.contains(wordId)) {
        _markedWords.remove(wordId);
      } else {
        _markedWords.add(wordId);
      }
    });
  }

  void _saveLastRead(int page) {
    ref.read(quranRepositoryProvider).saveLastRead(
          section: 'mushaf_15',
          page: page,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F0),
        title: Text(
          'Page $_currentPage / $_totalPages',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          // Mark Mistakes toggle
          GestureDetector(
            onTap: () => setState(() => _markMistakesMode = !_markMistakesMode),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _markMistakesMode
                    ? AppTheme.error.withValues(alpha: 0.12)
                    : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _markMistakesMode
                      ? AppTheme.error
                      : AppTheme.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: _markMistakesMode
                        ? AppTheme.error
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mark Mistakes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _markMistakesMode
                          ? AppTheme.error
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_markMistakesMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.error.withValues(alpha: 0.08),
              child: Text(
                '✏️ Tap a word to mark/unmark a mistake',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.error),
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _totalPages,
              onPageChanged: (index) {
                final page = index + 1;
                setState(() => _currentPage = page);
                _loadPage(page);
                _saveLastRead(page);
              },
              itemBuilder: (ctx, index) {
                final page = index + 1;
                if (_loading && page == _currentPage) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _MushafPage(
                  pageWords: _pageWords,
                  markedWords: _markedWords,
                  markMistakesMode: _markMistakesMode,
                  onWordTap: _onWordTap,
                );
              },
            ),
          ),
          // Page navigation bar
          _buildPageNav(),
        ],
      ),
    );
  }

  Widget _buildPageNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primary,
                thumbColor: AppTheme.primary,
              ),
              child: Slider(
                value: _currentPage.toDouble(),
                min: 1,
                max: _totalPages.toDouble(),
                divisions: _totalPages - 1,
                onChanged: (v) {
                  final page = v.round();
                  _pageCtrl.jumpToPage(page - 1);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Mushaf Page Widget ────────────────────────────────────────────────────────
class _MushafPage extends StatelessWidget {
  final List<Map<String, dynamic>> pageWords;
  final Set<String> markedWords;
  final bool markMistakesMode;
  final Future<void> Function(String wordId) onWordTap;

  const _MushafPage({
    required this.pageWords,
    required this.markedWords,
    required this.markMistakesMode,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pageWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Mushaf layout data not loaded yet.\nWord-by-word data will appear here after\nimporting the QCF layout dataset.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Group words by line
    final Map<int, List<Map<String, dynamic>>> byLine = {};
    for (final word in pageWords) {
      final line = word['line'] as int;
      byLine.putIfAbsent(line, () => []).add(word);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: byLine.entries.map((entry) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: entry.value.map((word) {
                final wordId = word['word_id'] as String;
                final glyph = word['glyph_code'] as String;
                final fontFile = word['font_file'] as String;
                final isMarked = markedWords.contains(wordId);

                return GestureDetector(
                  onTap: markMistakesMode ? () => onWordTap(wordId) : null,
                  child: Container(
                    decoration: isMarked
                        ? const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.error, width: 2),
                            ),
                          )
                        : null,
                    child: Text(
                      glyph,
                      style: TextStyle(
                        fontFamily: fontFile,
                        fontSize: 24,
                        color: isMarked ? AppTheme.error : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
