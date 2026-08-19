import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/settings_service.dart';
import '../mushaf_shared/widgets/mushaf_page_widget.dart';
import '../shared/jump_navigation_dialog.dart';

class Mushaf15Screen extends ConsumerStatefulWidget {
  final int initialPage; // 1-610

  const Mushaf15Screen({super.key, this.initialPage = 1});

  @override
  ConsumerState<Mushaf15Screen> createState() => _Mushaf15ScreenState();
}

class _Mushaf15ScreenState extends ConsumerState<Mushaf15Screen> {
  PageController? _pageCtrl;
  bool _isMarkMistakesMode = false;
  Set<String> _markedWordIds = {};
  bool _loadingLastRead = true;

  // Auto-scroll
  Timer? _scrollTimer;
  bool _autoScrollActive = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    final repo = ref.read(quranRepositoryProvider);
    final lastRead = await repo.getLastRead('mushaf_15');
    int page = widget.initialPage;
    if (lastRead != null) {
      page = lastRead['page'] as int? ?? widget.initialPage;
    }
    _pageCtrl = PageController(initialPage: page - 1);
    if (mounted) {
      setState(() {
        _loadingLastRead = false;
      });
    }
    _loadMarkedMistakes();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageCtrl?.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    if (_autoScrollActive) {
      _scrollTimer?.cancel();
      setState(() => _autoScrollActive = false);
    } else {
      final speed = ref.read(settingsServiceProvider).autoScrollSpeed;
      final pxPerStep = speed * 0.8;
      setState(() => _autoScrollActive = true);

      _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_pageCtrl == null || !_pageCtrl!.hasClients) return;
        final newOffset = _pageCtrl!.offset + pxPerStep;
        if (newOffset >= _pageCtrl!.position.maxScrollExtent) {
          _scrollTimer?.cancel();
          setState(() => _autoScrollActive = false);
          return;
        }
        _pageCtrl!.jumpTo(newOffset);
      });
    }
  }

  Future<void> _loadMarkedMistakes() async {
    final repo = ref.read(quranRepositoryProvider);
    final set = await repo.getMarkedMistakes('mushaf_15');
    if (mounted) {
      setState(() => _markedWordIds = set);
    }
  }

  Future<void> _toggleMistake(String wordId) async {
    final repo = ref.read(quranRepositoryProvider);
    await repo.toggleMarkedMistake(wordId, 'mushaf_15');
    await _loadMarkedMistakes();
  }

  Future<void> _saveLastRead(int pageNum) async {
    final repo = ref.read(quranRepositoryProvider);
    final words = await repo.getMushafPageWords(pageNum, '15_line');
    int surah = 1;
    int ayah = 1;
    if (words.isNotEmpty) {
      surah = words.first['surah'] as int? ?? 1;
      ayah = words.first['ayah'] as int? ?? 1;
    }
    await repo.saveLastRead(section: 'mushaf_15', surah: surah, ayah: ayah, page: pageNum);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLastRead) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B4332),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        title: Text(
          '15-Line Madani Mushaf',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Auto-scroll Play / Pause button
          IconButton(
            icon: Icon(
              _autoScrollActive ? Icons.pause_circle_filled : Icons.play_circle_outline,
              color: _autoScrollActive ? const Color(0xFFFFD54F) : Colors.white,
              size: 24,
            ),
            tooltip: 'Auto-scroll',
            onPressed: _toggleAutoScroll,
          ),

          // Jump Navigation Dialog Button
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Colors.white),
            tooltip: 'Jump to Location',
            onPressed: () => JumpNavigationDialog.show(
              context,
              mushafType: '15_line',
              onJumpToPage: (targetPage) {
                _pageCtrl?.jumpToPage(targetPage - 1);
              },
            ),
          ),

          // Mark Mistakes Mode Toggle Button
          IconButton(
            icon: Icon(
              _isMarkMistakesMode ? Icons.edit_off_rounded : Icons.edit_note_rounded,
              color: _isMarkMistakesMode ? const Color(0xFFFFD54F) : Colors.white70,
            ),
            tooltip: 'Mark Mistakes Mode',
            onPressed: () {
              setState(() => _isMarkMistakesMode = !_isMarkMistakesMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isMarkMistakesMode
                        ? 'Mark Mistakes Mode ON: Tap any word to mark/unmark mistakes.'
                        : 'Mark Mistakes Mode OFF: Words locked for reading.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Vertical Page View (1 to 610)
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                pageSnapping: !_autoScrollActive,
                physics: _autoScrollActive ? const ClampingScrollPhysics() : const PageScrollPhysics(),
                itemCount: 610,
                onPageChanged: (pageIndex) {
                  final pageNum = pageIndex + 1;
                  _saveLastRead(pageNum);
                },
                itemBuilder: (ctx, idx) {
                  final pageNum = idx + 1;
                  return MushafPageWidget(
                    pageNumber: pageNum,
                    mushafType: '15_line',
                    isMarkMistakesMode: _isMarkMistakesMode,
                    markedWordIds: _markedWordIds,
                    onToggleWordMistake: _toggleMistake,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
