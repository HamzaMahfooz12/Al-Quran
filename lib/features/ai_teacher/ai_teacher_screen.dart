// lib/features/ai_teacher/ai_teacher_screen.dart
// Dedicated section for Live AI Quran Teacher & Real-Time Recitation Mistake Detection
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/mushaf_page_model.dart';
import '../../data/repositories/quran_repository.dart';
import '../mushaf_shared/widgets/mushaf_page_widget.dart';
import '../shared/jump_navigation_dialog.dart';
import 'providers/recitation_provider.dart';
import 'widgets/live_recitation_toolbar.dart';
import 'widgets/model_download_dialog.dart';
import 'widgets/recitation_summary_dialog.dart';
import 'widgets/word_correction_sheet.dart';

class AiTeacherScreen extends ConsumerStatefulWidget {
  final int initialPage; // 1-548

  const AiTeacherScreen({super.key, this.initialPage = 1});

  @override
  ConsumerState<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends ConsumerState<AiTeacherScreen> {
  PageController? _pageCtrl;
  int _currentPage = 1;
  bool _loading = true;
  List<WordLayoutData> _currentPageWords = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageCtrl = PageController(initialPage: _currentPage - 1);
    _initSession();
  }

  Future<void> _initSession() async {
    final repo = ref.read(quranRepositoryProvider);
    final lastRead = await repo.getLastRead('ai_teacher');
    if (lastRead != null && lastRead['page'] != null) {
      _currentPage = lastRead['page'] as int;
      _pageCtrl = PageController(initialPage: _currentPage - 1);
    }

    await _loadCurrentPageWords();

    if (mounted) {
      setState(() => _loading = false);
      _checkModelAndPrompt();
    }
  }

  Future<void> _loadCurrentPageWords() async {
    final repo = ref.read(quranRepositoryProvider);
    final raw = await repo.getMushafPageWords(_currentPage, '16_line');
    _currentPageWords = raw.map((w) => WordLayoutData.fromMap(w)).toList();
  }

  Future<void> _checkModelAndPrompt() async {
    final aiManager = ref.read(aiModelManagerProvider);
    final isDownloaded = await aiManager.isModelDownloaded();

    if (!isDownloaded && mounted) {
      await ModelDownloadDialog.show(
        context,
        onDownloadComplete: () {
          if (mounted) {
            _startRecitation();
          }
        },
      );
    }
  }

  Future<void> _startRecitation() async {
    if (_currentPageWords.isEmpty) {
      await _loadCurrentPageWords();
    }
    if (mounted) {
      await ref.read(recitationProvider.notifier).startListening(_currentPageWords);
    }
  }

  Future<void> _onPageChanged(int pageIndex) async {
    final pageNum = pageIndex + 1;
    _currentPage = pageNum;
    final repo = ref.read(quranRepositoryProvider);
    await repo.saveLastRead(section: 'ai_teacher', page: pageNum, surah: 1, ayah: 1);
    await _loadCurrentPageWords();

    final state = ref.read(recitationProvider);
    if (state.isListening && mounted) {
      ref.read(recitationProvider.notifier).startListening(_currentPageWords);
    }
  }

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B4332),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD54F))),
      );
    }

    final recitationState = ref.watch(recitationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (recitationState.totalRecited > 0) {
              RecitationSummaryDialog.show(context, state: recitationState);
            }
            ref.read(recitationProvider.notifier).resetSession();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Quran Teacher',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Live Recitation & Mistake Detection (16-Line)',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFFFD54F)),
            ),
          ],
        ),
        actions: [
          // Jump to Page
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Colors.white),
            tooltip: 'Jump to Page',
            onPressed: () => JumpNavigationDialog.show(
              context,
              mushafType: '16_line',
              onJumpToPage: (targetPage) {
                _pageCtrl?.jumpToPage(targetPage - 1);
                _onPageChanged(targetPage - 1);
              },
            ),
          ),

          // Session Summary Button
          if (recitationState.totalRecited > 0)
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Color(0xFFFFD54F)),
              tooltip: 'Recitation Score & Summary',
              onPressed: () => RecitationSummaryDialog.show(context, state: recitationState),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 16-Line Holy Quran Page View
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: 548,
                onPageChanged: _onPageChanged,
                itemBuilder: (ctx, idx) {
                  final pageNum = idx + 1;
                  return MushafPageWidget(
                    pageNumber: pageNum,
                    mushafType: '16_line',
                    isMarkMistakesMode: false,
                    markedWordIds: const {},
                    onToggleWordMistake: (_) {},
                    liveRecitationWordMap: pageNum == _currentPage ? recitationState.wordResults : null,
                    isHifzRevealMode: recitationState.isHifzRevealMode,
                    onLiveRecitationWordTap: (wordResult) => WordCorrectionSheet.show(context, wordResult),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: LiveRecitationToolbar(
        pageWords: _currentPageWords,
        onClose: () {
          ref.read(recitationProvider.notifier).resetSession();
        },
      ),
    );
  }
}
