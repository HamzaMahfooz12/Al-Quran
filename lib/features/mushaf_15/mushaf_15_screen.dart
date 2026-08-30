import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../audio/audio_control_bar.dart';
import '../mushaf_shared/widgets/mushaf_bottom_control_bar.dart';
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
  int _currentPage = 1;
  bool _isMarkMistakesMode = false;
  Set<String> _markedWordIds = {};
  bool _loadingLastRead = true;
  bool _showBottomBar = true;

  // Auto-scroll
  Timer? _scrollTimer;
  bool _autoScrollActive = false;

  // Active audio metadata
  String _currentSurahName = '';
  int _currentSurahTotalAyahs = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _setupAudioService();
  }

  void _setupAudioService() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = ref.read(audioServiceProvider);
      audioService.onAdvance = (nextSurah, nextAyah) async {
        if (!mounted) return;
        await _onAudioAdvanceTo(nextSurah, nextAyah);
      };
    });
  }

  Future<void> _onAudioAdvanceTo(int nextSurah, int nextAyah) async {
    final repo = ref.read(quranRepositoryProvider);
    final targetPage = await repo.getMushafPageForAyah(nextSurah, nextAyah, '15_line');

    if (targetPage != null && targetPage != _currentPage && _pageCtrl != null && _pageCtrl!.hasClients) {
      _pageCtrl!.animateToPage(
        targetPage - 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
      _currentPage = targetPage;
    }

    await _playSurahAyah(nextSurah, nextAyah);
  }

  Future<void> _loadInitialPage() async {
    final repo = ref.read(quranRepositoryProvider);
    final lastRead = await repo.getLastRead('mushaf_15');
    int page = widget.initialPage;
    if (lastRead != null) {
      page = lastRead['page'] as int? ?? widget.initialPage;
    }
    _currentPage = page;
    _pageCtrl = PageController(initialPage: page - 1);
    _pageCtrl!.addListener(_onScrollPage);
    if (mounted) {
      setState(() {
        _loadingLastRead = false;
      });
    }
    _loadMarkedMistakes();
  }

  void _onScrollPage() {
    if (_pageCtrl == null || !_pageCtrl!.hasClients) return;
    final page = (_pageCtrl!.page?.round() ?? 0) + 1;
    if (page != _currentPage && page >= 1 && page <= 610) {
      _currentPage = page;
      _saveLastRead(page);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageCtrl?.removeListener(_onScrollPage);
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
    _currentPage = pageNum;
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

  Future<void> _playSurahAyah(int surah, int ayah) async {
    final repo = ref.read(quranRepositoryProvider);
    final ayahData = await repo.getAyah(surah, ayah);
    if (ayahData == null) return;

    final surahInfo = kSurahList.firstWhere(
      (s) => s.number == surah,
      orElse: () => SurahInfo(
        number: surah,
        nameArabic: '',
        nameTransliteration: 'Surah $surah',
        nameTranslation: 'Surah $surah',
        ayahCount: 1,
        revelationType: 'Meccan',
        startPage: 1,
      ),
    );

    if (mounted) {
      setState(() {
        _currentSurahName = surahInfo.nameTransliteration;
        _currentSurahTotalAyahs = surahInfo.ayahCount;
      });
    }

    final words = ayahData.arabicText.trim().split(RegExp(r'\s+'));
    final audioService = ref.read(audioServiceProvider);

    await audioService.playAyah(
      globalAyahNumber: ayahData.id,
      surah: surah,
      ayahInSurah: ayah,
      totalAyahsInSurah: surahInfo.ayahCount,
      ayahWords: words,
    );

    if (mounted) setState(() {});
  }

  Future<void> _playCurrentPage() async {
    final repo = ref.read(quranRepositoryProvider);
    final words = await repo.getMushafPageWords(_currentPage, '15_line');
    if (words.isNotEmpty) {
      final s = words.first['surah'] as int? ?? 1;
      final a = words.first['ayah'] as int? ?? 1;
      await _playSurahAyah(s, a);
    }
  }

  void _togglePlayCurrentPage() async {
    final audio = ref.read(audioServiceProvider);
    if (audio.isPlaying) {
      await audio.pause();
      if (mounted) setState(() {});
    } else if (audio.currentPlayingAyahId != null) {
      await audio.resume();
      if (mounted) setState(() {});
    } else {
      await _playCurrentPage();
    }
  }

  void _toggleMarkMistakes() {
    setState(() {
      _isMarkMistakesMode = !_isMarkMistakesMode;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isMarkMistakesMode
              ? 'Mark Mistakes Mode ON — Tap any word to mark/unmark mistakes.'
              : 'Mark Mistakes Mode OFF — Words locked for reading.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    final audio = ref.watch(audioServiceProvider);
    final activeWordAsync = ref.watch(activeWordIdProvider);
    final activeWordId = activeWordAsync.value ?? audio.currentActiveWordId;
    final activeVerseKey = (audio.currentSurah != null && audio.currentAyahNumberInSurah != null)
        ? '${audio.currentSurah}:${audio.currentAyahNumberInSurah}'
        : null;

    final isAudioActive = audio.currentPlayingAyahId != null;

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
          // Jump Navigation Dialog Button
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Colors.white),
            tooltip: 'Jump to Location',
            onPressed: () => JumpNavigationDialog.show(
              context,
              mushafType: '15_line',
              onJumpToPage: (targetPage) {
                _pageCtrl?.jumpToPage(targetPage - 1);
                _currentPage = targetPage;
              },
            ),
          ),
        ],
      ),
      // Use Stack so the audio bar overlays the page without resizing it
      body: Stack(
        children: [
          // ── Full-height Mushaf Page View (never resizes) ─────────────────
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse) {
                  if (_showBottomBar) setState(() => _showBottomBar = false);
                } else if (notification.direction == ScrollDirection.forward) {
                  if (!_showBottomBar) setState(() => _showBottomBar = true);
                }
                return true;
              },
              child: PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                pageSnapping: false,
                physics: const ClampingScrollPhysics(),
                itemCount: 610,
                itemBuilder: (ctx, idx) {
                  final pageNum = idx + 1;
                  return MushafPageWidget(
                    pageNumber: pageNum,
                    mushafType: '15_line',
                    isMarkMistakesMode: _isMarkMistakesMode,
                    markedWordIds: _markedWordIds,
                    onToggleWordMistake: _toggleMistake,
                    activePlayingWordId: activeWordId,
                    activePlayingVerseKey: activeVerseKey,
                    onWordTap: (surah, ayah) {
                      setState(() => _showBottomBar = !_showBottomBar);
                    },
                    onWordDoubleTap: (surah, ayah) => _playSurahAyah(surah, ayah),
                  );
                },
              ),
            ),
          ),

          // ── Audio Bar Overlay (floats above page, doesn't resize it) ────
          if (isAudioActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AudioControlBar(
                surahNumber: audio.currentSurah ?? 1,
                surahName: _currentSurahName.isNotEmpty
                    ? _currentSurahName
                    : 'Surah ${audio.currentSurah ?? 1}',
                currentAyahNumber: audio.currentAyahNumberInSurah ?? 1,
                totalAyahs: _currentSurahTotalAyahs,
                onNextAyah: () {
                  final curS = audio.currentSurah ?? 1;
                  final curA = audio.currentAyahNumberInSurah ?? 1;
                  if (curA < _currentSurahTotalAyahs) {
                    _playSurahAyah(curS, curA + 1);
                  } else if (curS < 114) {
                    _playSurahAyah(curS + 1, 1);
                  }
                },
                onPrevAyah: () {
                  final curS = audio.currentSurah ?? 1;
                  final curA = audio.currentAyahNumberInSurah ?? 1;
                  if (curA > 1) {
                    _playSurahAyah(curS, curA - 1);
                  } else if (curS > 1) {
                    _playSurahAyah(curS - 1, 1);
                  }
                },
                onClose: () {
                  audio.stop();
                  setState(() {});
                },
              ),
            ),

          // ── Mushaf Bottom Control Bar (shown when no audio, as overlay) ─
          if (!isAudioActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MushafBottomControlBar(
                isVisible: _showBottomBar,
                isAutoScrolling: _autoScrollActive,
                onToggleAutoScroll: _toggleAutoScroll,
                isPlaying: audio.isPlaying,
                isBuffering: audio.isBuffering,
                onTogglePlay: _togglePlayCurrentPage,
                isMarkMistakesMode: _isMarkMistakesMode,
                onToggleMarkMistakes: _toggleMarkMistakes,
              ),
            ),
        ],
      ),
    );
  }
}
