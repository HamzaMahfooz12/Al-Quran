import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  // Keep screen awake
  bool _isKeepScreenAwake = false;
  Timer? _inactivityTimer;

  // Auto-scroll
  Timer? _scrollTimer;
  bool _autoScrollActive = false;

  // Active audio metadata
  String _currentSurahName = '';
  int _currentSurahTotalAyahs = 1;

  // Global Zoom & Pan State (Uniform across all pages)
  double _zoomScale = 1.0;
  double _baseZoomScale = 1.0;
  double _panX = 0.0;
  double _basePanX = 0.0;
  final Map<int, Offset> _pointerPositions = {};
  double _initialPinchDistance = 0.0;
  Offset _initialPinchMidpoint = Offset.zero;
  late final ValueNotifier<Matrix4> _transformNotifier;
  late final ValueNotifier<double> _zoomScaleNotifier;

  void _updateTransform() {
    _transformNotifier.value = Matrix4.diagonal3Values(_zoomScale, _zoomScale, 1.0)
      ..setTranslationRaw(_panX, 0.0, 0.0);
    _zoomScaleNotifier.value = _zoomScale;
  }

  void _onPointerDown(PointerDownEvent event) {
    _resetInactivityTimer();
    _pointerPositions[event.pointer] = event.position;
    if (_pointerPositions.length == 2) {
      final points = _pointerPositions.values.toList();
      _initialPinchDistance = (points[0] - points[1]).distance;
      _initialPinchMidpoint = (points[0] + points[1]) / 2;
      _baseZoomScale = _zoomScale;
      _basePanX = _panX;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointerPositions[event.pointer] = event.position;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (_pointerPositions.length == 2) {
      // ── Two-finger Pinch Zoom & Pan (Focal-point aware) ──
      final points = _pointerPositions.values.toList();
      final currentDistance = (points[0] - points[1]).distance;
      final currentMidpoint = (points[0] + points[1]) / 2;

      if (_initialPinchDistance > 10.0) {
        final scaleRatio = currentDistance / _initialPinchDistance;
        final newScale = (_baseZoomScale * scaleRatio).clamp(1.0, 3.0);

        // Maximum pan allows seeing both edges with comfortable breathing room
        final maxPanX = (screenWidth * (newScale - 1.0)) / 2 + 24.0;

        // Shift pan with two-finger movement
        final deltaMidpointX = currentMidpoint.dx - _initialPinchMidpoint.dx;

        // Anchor zoom around the midpoint between fingers so zoom focuses on touched area
        final focalOffsetFromCenter = _initialPinchMidpoint.dx - (screenWidth / 2);
        final focalShift = -focalOffsetFromCenter * (newScale / _baseZoomScale - 1.0);

        _zoomScale = newScale;
        _panX = (_basePanX + deltaMidpointX + focalShift).clamp(-maxPanX, maxPanX);
        _updateTransform();
      }
    } else if (_pointerPositions.length == 1 && _zoomScale > 1.01) {
      // ── One-finger Pan while Zoomed In ──
      // Instant, smooth horizontal panning to see the start or end of ayahs without delay or lag
      final maxPanX = (screenWidth * (_zoomScale - 1.0)) / 2 + 24.0;
      _panX = (_panX + event.delta.dx).clamp(-maxPanX, maxPanX);
      _updateTransform();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.length == 1) {
      // Smoothly transition from two fingers to one finger panning
      _baseZoomScale = _zoomScale;
      _basePanX = _panX;
    } else if (_pointerPositions.isEmpty) {
      _baseZoomScale = _zoomScale;
      _basePanX = _panX;
      if (_zoomScale <= 1.03) {
        _zoomScale = 1.0;
        _panX = 0.0;
        _baseZoomScale = 1.0;
        _basePanX = 0.0;
        _updateTransform();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) {
      _baseZoomScale = _zoomScale;
      _basePanX = _panX;
      if (_zoomScale <= 1.03) {
        _zoomScale = 1.0;
        _panX = 0.0;
        _baseZoomScale = 1.0;
        _basePanX = 0.0;
        _updateTransform();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _transformNotifier = ValueNotifier<Matrix4>(Matrix4.identity());
    _zoomScaleNotifier = ValueNotifier<double>(1.0);
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
    if (page == 1 && lastRead != null) {
      page = lastRead['page'] as int? ?? widget.initialPage;
    }
    _currentPage = page;
    _pageCtrl = PageController(initialPage: page - 1);
    _pageCtrl!.addListener(_onScrollPage);
    _saveLastRead(page);
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
    _inactivityTimer?.cancel();
    WakelockPlus.disable();
    _pageCtrl?.removeListener(_onScrollPage);
    _pageCtrl?.dispose();
    _transformNotifier.dispose();
    _zoomScaleNotifier.dispose();
    super.dispose();
  }

  void _toggleKeepScreenAwake() {
    final settings = ref.read(settingsServiceProvider);
    final timeoutMin = settings.screenTimeoutMinutes;

    setState(() {
      _isKeepScreenAwake = !_isKeepScreenAwake;
    });

    _inactivityTimer?.cancel();

    if (_isKeepScreenAwake) {
      WakelockPlus.enable();
      _resetInactivityTimer();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.light_mode_rounded, color: Color(0xFFD4AF37), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeoutMin == 0
                      ? 'Screen Keep-Awake ON — Screen will never turn off while reading.'
                      : 'Screen Keep-Awake ON — Sleep timeout: $timeoutMin min.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F2038),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.0),
          ),
        ),
      );
    } else {
      WakelockPlus.disable();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Screen Keep-Awake OFF — Default system screen timeout restored.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F2038),
        ),
      );
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_isKeepScreenAwake) return;
    final timeoutMin = ref.read(settingsServiceProvider).screenTimeoutMinutes;
    if (timeoutMin > 0) {
      _inactivityTimer = Timer(Duration(minutes: timeoutMin), () {
        if (mounted && _isKeepScreenAwake) {
          WakelockPlus.disable();
          setState(() => _isKeepScreenAwake = false);
        }
      });
    }
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
    ref.invalidate(lastReadMushafProvider);
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
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC59A27)),
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
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: true,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 12),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F2038), size: 16),
            ),
          ),
        ),
        title: Text(
          '15-Line Madani Mushaf',
          style: GoogleFonts.outfit(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F2038),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // Keep Screen Awake Toggle
          Center(
            child: InkWell(
              onTap: _toggleKeepScreenAwake,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isKeepScreenAwake
                        ? const Color(0xFFC59A27)
                        : const Color(0xFFE8E1D2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isKeepScreenAwake ? Icons.light_mode : Icons.light_mode_outlined,
                  color: _isKeepScreenAwake ? const Color(0xFFC59A27) : const Color(0xFF0F2038),
                  size: 19,
                ),
              ),
            ),
          ),
          // Jump Navigation Dialog Button
          Center(
            child: InkWell(
              onTap: () => JumpNavigationDialog.show(
                context,
                mushafType: '15_line',
                onJumpToPage: (p) {
                  _pageCtrl?.jumpToPage(p - 1);
                  setState(() => _currentPage = p);
                },
              ),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
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
                child: const Icon(Icons.explore_outlined, color: Color(0xFF0F2038), size: 19),
              ),
            ),
          ),
        ],
      ),
      // Use Stack so the audio bar overlays the page without resizing it
      body: Stack(
        children: [
          // ── Full-height Mushaf Page View (never resizes) ─────────────────
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: ClipRect(
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _transformNotifier,
                  builder: (context, matrix, child) {
                    return Transform(
                      transform: matrix,
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
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
