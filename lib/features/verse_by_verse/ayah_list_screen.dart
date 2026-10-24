// lib/features/verse_by_verse/ayah_list_screen.dart
// Verse-by-verse reading screen with full edition selector bottom sheets & cloud download icons
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ayah.dart';
import '../../data/models/edition.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/settings_service.dart';
import '../../services/audio_service.dart';
import '../audio/audio_control_bar.dart';
import '../share/widgets/ayah_share_dialog.dart';
import '../tafseer/widgets/ayah_tafseer_modal.dart';
import '../shared/widgets/unified_ayah_card.dart';
import '../shared/widgets/edition_selection_sheet.dart';

class AyahListScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int scrollToAyah;

  const AyahListScreen({
    super.key,
    required this.surahNumber,
    this.scrollToAyah = 1,
  });

  @override
  ConsumerState<AyahListScreen> createState() => _AyahListScreenState();
}

class _AyahListScreenState extends ConsumerState<AyahListScreen> {
  final _scrollCtrl = ScrollController();
  List<Ayah> _ayahs = [];
  Map<int, String> _translations = {};
  Map<int, String> _tafseers = {};
  String? _bismillahTranslationText;
  bool _loading = true;

  // Active editions
  Edition? _activeTranslationEdition;
  Edition? _activeTafseerEdition;

  // Toggle states
  bool _showTranslation = true;

  // Auto-scroll
  Timer? _scrollTimer;
  bool _autoScrollActive = false;

  Timer? _lastReadTimer;
  late SurahInfo _surahInfo;
  Set<int> _bookmarkedAyahs = {};

  final Map<int, GlobalKey> _ayahKeys = {};
  int? _highlightedAyahNumber;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _surahInfo = kSurahList[widget.surahNumber - 1];
    _loadData();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AyahListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _surahInfo = kSurahList[widget.surahNumber - 1];
      _ayahKeys.clear();
      _loadData();
    } else if (oldWidget.scrollToAyah != widget.scrollToAyah && widget.scrollToAyah > 1) {
      _highlightAyahAndScroll(widget.scrollToAyah);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _lastReadTimer?.cancel();
    _highlightTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _highlightAyahAndScroll(int targetAyah) {
    _highlightTimer?.cancel();
    setState(() {
      _highlightedAyahNumber = targetAyah;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        await _scrollToAyah(targetAyah, animate: true, alignment: 0.5);
        _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() => _highlightedAyahNumber = null);
        });
      }
    });
  }

  double _estimateOffsetForAyah(int targetAyah) {
    if (_ayahs.isEmpty || targetAyah <= 1) return 0.0;

    // Header banner height (Surah 9 has no Bismillah banner)
    double total = (widget.surahNumber == 9) ? 140.0 : 270.0;

    for (int i = 0; i < targetAyah - 1 && i < _ayahs.length; i++) {
      final a = _ayahs[i];
      if (widget.surahNumber == 1 && a.ayahNumber == 1) continue;

      // Base card overhead: padding + verse header + action bar + bottom margin
      double cardHeight = 145.0;

      // Arabic text estimation: ~38 chars per line, ~50px line height
      final arabicLines = (a.arabicText.length / 38).ceil().clamp(1, 40);
      cardHeight += arabicLines * 50.0;

      // Translation text estimation (if visible)
      if (_showTranslation) {
        final trans = _translations[a.id] ?? '';
        if (trans.isNotEmpty) {
          final transLines = (trans.length / 48).ceil().clamp(1, 40);
          cardHeight += (transLines * 24.0) + 16.0;
        }
      }

      total += cardHeight;
    }
    return total;
  }

  Future<void> _scrollToAyah(int targetAyah, {bool animate = true, double alignment = 0.5}) async {
    if (!mounted || _ayahs.isEmpty) return;
    if (targetAyah < 1) targetAyah = 1;
    if (targetAyah > _ayahs.length) targetAyah = _ayahs.length;

    try {
      // 1. If key is already mounted, center it directly with animation
      var targetContext = _ayahKeys[targetAyah]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: alignment,
          duration: animate ? const Duration(milliseconds: 550) : Duration.zero,
          curve: Curves.easeInOutCubic,
        );
        return;
      }

      // 2. If not mounted, compute estimated offset
      final estimatedOffset = _estimateOffsetForAyah(targetAyah);

      // 3. Iteratively jump towards estimated offset to trigger ListView.builder layout
      for (int attempt = 0; attempt < 8; attempt++) {
        if (!mounted || !_scrollCtrl.hasClients) break;

        targetContext = _ayahKeys[targetAyah]?.currentContext;
        if (targetContext != null && targetContext.mounted) {
          await Scrollable.ensureVisible(
            targetContext,
            alignment: alignment,
            duration: animate ? const Duration(milliseconds: 500) : Duration.zero,
            curve: Curves.easeInOutCubic,
          );
          return;
        }

        final currentOffset = _scrollCtrl.offset;
        final maxExtent = _scrollCtrl.position.maxScrollExtent;

        // If target key not in tree, inspect which keys ARE mounted
        final mountedAyahs = _ayahKeys.entries
            .where((e) => e.value.currentContext != null && e.value.currentContext!.mounted)
            .map((e) => e.key)
            .toList();

        double nextOffset;
        if (mountedAyahs.isNotEmpty) {
          final maxMounted = mountedAyahs.reduce((a, b) => a > b ? a : b);
          final minMounted = mountedAyahs.reduce((a, b) => a < b ? a : b);
          if (targetAyah > maxMounted) {
            nextOffset = (currentOffset + (targetAyah - maxMounted) * 220.0).clamp(0.0, maxExtent);
          } else if (targetAyah < minMounted) {
            nextOffset = (currentOffset - (minMounted - targetAyah) * 220.0).clamp(0.0, maxExtent);
          } else {
            nextOffset = estimatedOffset.clamp(0.0, maxExtent);
          }
        } else {
          nextOffset = estimatedOffset.clamp(0.0, maxExtent);
        }

        _scrollCtrl.jumpTo(nextOffset);
        await Future.delayed(const Duration(milliseconds: 25));
      }

      // Final attempt
      if (mounted && _scrollCtrl.hasClients) {
        targetContext = _ayahKeys[targetAyah]?.currentContext;
        if (targetContext != null && targetContext.mounted) {
          await Scrollable.ensureVisible(
            targetContext,
            alignment: alignment,
            duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
            curve: Curves.easeInOutCubic,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    _ayahKeys.clear();
    final repo = ref.read(quranRepositoryProvider);
    final settings = ref.read(settingsServiceProvider);

    final ayahs = await repo.getAyahsBySurah(widget.surahNumber);
    final ayahIds = ayahs.map((a) => a.id).toList();

    final availableTranslations = await repo.getAvailableEditions(type: 'translation');
    final availableTafseers = await repo.getAvailableEditions(type: 'tafseer');

    // Select active translation
    Edition? transEdition;
    final selectedTransId = settings.selectedTranslationId;
    if (selectedTransId != null) {
      final match = availableTranslations.where((e) => e.id == selectedTransId);
      if (match.isNotEmpty) transEdition = match.first;
    }
    transEdition ??= (availableTranslations.isNotEmpty
        ? availableTranslations.first
        : const Edition(id: 1, type: 'translation', language: 'ur', name: 'Fateh Muhammad Jalandhry', apiKey: 'ur.jalandhry', isBundled: true, isDownloaded: true));

    // Select active tafseer
    Edition? tafseerEdition;
    final selectedTafseerId = settings.selectedTafseerEditionId;
    if (selectedTafseerId != null) {
      final match = availableTafseers.where((e) => e.id == selectedTafseerId);
      if (match.isNotEmpty) tafseerEdition = match.first;
    }
    tafseerEdition ??= (availableTafseers.isNotEmpty
        ? availableTafseers.first
        : const Edition(id: 103, type: 'tafseer', language: 'ur', name: 'Tafseer Ibn e Kaseer', apiKey: 'tafseer-ibn-e-kaseer-urdu', isBundled: true, isDownloaded: true));

    Map<int, String> translations = await repo.getContentBulk(ayahIds, transEdition.id);
    Map<int, String> tafseers = await repo.getContentBulk(ayahIds, tafseerEdition.id);

    // Fetch Bismillah translation for Ayah ID 1 (Ayah 1 of Surah 1 = Bismillah)
    String? bTrans = translations[1] ?? await repo.getContent(1, transEdition.id);
    bTrans ??= (transEdition.language == 'ur'
        ? 'شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے'
        : 'In the name of Allah, the Entirely Merciful, the Especially Merciful.');

    // If selected translation rows don't exist yet, download on the fly for this Surah
    if (translations.isEmpty) {
      translations = await _fetchSurahEditionFromApi(transEdition, ayahIds);
    }

    // Check if an Urdu translation text is accidentally duplicated Uthmani Arabic text (like ur.taqi audio identifier)
    if (translations.isNotEmpty && ayahs.isNotEmpty && transEdition.language == 'ur') {
      final sampleArabic = ayahs.first.arabicText.trim();
      final sampleTrans = (translations[ayahs.first.id] ?? '').trim();
      if (sampleTrans.isNotEmpty && sampleTrans == sampleArabic) {
        // Fallback to authentic Urdu translation (ur.jalandhry)
        final fallbackEdition = (availableTranslations.firstWhere((e) => e.apiKey == 'ur.jalandhry', orElse: () => availableTranslations.first));
        transEdition = fallbackEdition;
        translations = await repo.getContentBulk(ayahIds, fallbackEdition.id);
        if (translations.isEmpty) {
          translations = await _fetchSurahEditionFromApi(fallbackEdition, ayahIds);
        }
        bTrans = translations[1] ?? 'شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے';
      }
    }

    // Ensure valid Tafseer content is loaded (and auto-heal if cached text is stale Arabic or wrong)
    final bool isTafseerStaleArabic = tafseers.isNotEmpty &&
        tafseerEdition.language != 'ar' &&
        ayahs.isNotEmpty &&
        tafseers[ayahs.first.id]?.trim() == ayahs.first.arabicText.trim();

    if (tafseers.isEmpty || isTafseerStaleArabic) {
      tafseers = await _loadEditionContent(tafseerEdition, ayahIds);
    }

    final lastRead = await repo.getLastRead('verse_by_verse');
    final allBookmarks = await repo.getBookmarks();
    final bookmarkedSet = allBookmarks
        .where((b) => b.surah == widget.surahNumber)
        .map((b) => b.ayah)
        .toSet();

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _activeTranslationEdition = transEdition;
        _activeTafseerEdition = tafseerEdition;
        _translations = translations;
        _tafseers = tafseers;
        _bismillahTranslationText = bTrans;
        _bookmarkedAyahs = bookmarkedSet;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final targetAyah = widget.scrollToAyah > 1
            ? widget.scrollToAyah
            : ((lastRead != null && lastRead['surah'] == widget.surahNumber)
                ? (lastRead['ayah'] as int? ?? 1)
                : 1);

        if (targetAyah > 1 && _ayahs.length >= targetAyah) {
          setState(() {
            _highlightedAyahNumber = targetAyah;
          });
          await Future.delayed(const Duration(milliseconds: 60));
          if (mounted) {
            await _scrollToAyah(targetAyah, animate: false, alignment: 0.5);
            _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
              if (mounted) setState(() => _highlightedAyahNumber = null);
            });
          }
        }
      });
    }
  }

  Future<Map<int, String>> _loadEditionContent(Edition ed, List<int> ayahIds) async {
    final repo = ref.read(quranRepositoryProvider);

    // 1. Try reading from local custom JSON file
    final localPath = _localTafseerPaths[ed.apiKey];
    if (localPath != null && File(localPath).existsSync()) {
      try {
        final jsonStr = await File(localPath).readAsString();
        final Map<String, dynamic> tafseerDict = json.decode(jsonStr);
        final List<Map<String, dynamic>> contentRows = [];
        final Map<int, String> result = {};

        for (final key in tafseerDict.keys) {
          final rawText = _resolveTafseerValue(tafseerDict, key);
          final text = _cleanHtml(rawText);

          final parts = key.split(':');
          if (parts.length == 2) {
            final surah = int.tryParse(parts[0]);
            final ayah = int.tryParse(parts[1]);
            if (surah != null && ayah != null) {
              final globalAyahId = _getGlobalAyahId(surah, ayah);
              if (surah == widget.surahNumber) {
                result[globalAyahId] = text;
              }
              contentRows.add({
                'ayah_id': globalAyahId,
                'edition_id': ed.id,
                'text': text,
              });
            }
          }
        }

        if (contentRows.isNotEmpty) {
          await repo.deleteEditionContent(ed.id);
          await repo.insertEditionContent(contentRows);
          await repo.markEditionDownloaded(ed.id);
          return result;
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error parsing local JSON for ${ed.name}: $e');
      }
    }

    // 2. Fallback to API ONLY for translations (never for Tafseers, as API returns Arabic text)
    if (ed.type != 'tafseer') {
      return await _fetchSurahEditionFromApi(ed, ayahIds);
    }
    return {};
  }

  Future<Map<int, String>> _fetchSurahEditionFromApi(Edition ed, List<int> ayahIds) async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.alquran.cloud/v1/surah/${widget.surahNumber}/${ed.apiKey}');
      if (response.data != null && response.data['status'] == 'OK') {
        final ayahs = (response.data['data']['ayahs'] as List).cast<Map<String, dynamic>>();
        final List<Map<String, dynamic>> contentRows = [];
        final Map<int, String> result = {};

        for (final ayah in ayahs) {
          final globalNum = ayah['number'] as int;
          final text = ayah['text'] as String;
          result[globalNum] = text;
          contentRows.add({
            'ayah_id': globalNum,
            'edition_id': ed.id,
            'text': text,
          });
        }

        await ref.read(quranRepositoryProvider).insertEditionContent(contentRows);
        return result;
      }
    } catch (_) {}
    return {};
  }

  void _onScroll() {
    _lastReadTimer?.cancel();
    _lastReadTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_scrollCtrl.hasClients || _ayahs.isEmpty) return;
      final firstVisible = (_scrollCtrl.offset / 200).floor().clamp(0, _ayahs.length - 1);
      ref.read(quranRepositoryProvider).saveLastRead(
            section: 'verse_by_verse',
            surah: widget.surahNumber,
            ayah: _ayahs[firstVisible].ayahNumber,
          );
    });
  }

  void _toggleAutoScroll() {
    if (_autoScrollActive) {
      _scrollTimer?.cancel();
      setState(() => _autoScrollActive = false);
    } else {
      final speed = ref.read(settingsServiceProvider).autoScrollSpeed;
      final pxPerStep = speed * 1.2;
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (!_scrollCtrl.hasClients) return;
        final newOffset = _scrollCtrl.offset + pxPerStep;
        if (newOffset >= _scrollCtrl.position.maxScrollExtent) {
          _scrollTimer?.cancel();
          setState(() => _autoScrollActive = false);
          return;
        }
        _scrollCtrl.jumpTo(newOffset);
      });
      setState(() => _autoScrollActive = true);
    }
  }

  Future<void> _playAyah(Ayah ayah) async {
    if (_autoScrollActive) {
      _scrollTimer?.cancel();
      _autoScrollActive = false;
    }
    final audio = ref.read(audioServiceProvider);

    // Smoothly slide the newly recited ayah into the center of the screen
    _scrollToAyah(ayah.ayahNumber, animate: true, alignment: 0.45);

    audio.onAdvance = (surah, nextAyahInSurah) {
      final nextIdx = _ayahs.indexWhere((a) => a.ayahNumber == nextAyahInSurah);
      if (nextIdx >= 0 && mounted) {
        final nextAyahObj = _ayahs[nextIdx];
        _playAyah(nextAyahObj);
      }
    };

    await audio.playAyah(
      globalAyahNumber: ayah.id,
      surah: ayah.surah,
      ayahInSurah: ayah.ayahNumber,
      totalAyahsInSurah: _ayahs.length,
    );
    if (mounted) setState(() {});
  }

  // ── Edition Selector Bottom Sheet ─────────────────────────────────────────
  Future<void> _showEditionSelector(String type) async {
    final currentEd = type == 'translation'
        ? _activeTranslationEdition
        : _activeTafseerEdition;

    await showEditionSelectionSheet(
      context: context,
      ref: ref,
      type: type,
      currentEdition: currentEd,
      onEditionSelected: (ed) async {
        // 1. Immediately activate in settings & state
        if (type == 'translation') {
          setState(() {
            _activeTranslationEdition = ed;
            _showTranslation = true;
          });
          await ref.read(settingsServiceProvider).setSelectedTranslationId(ed.id);
        } else {
          setState(() {
            _activeTafseerEdition = ed;
          });
          await ref.read(settingsServiceProvider).setSelectedTafseerEditionId(ed.id);
        }

        // 2. Refresh UI immediately for current surah
        await _loadData();

        // 3. If not downloaded yet, fetch full edition in background
        if (!ed.isAvailable) {
          _downloadAndSetEdition(ed);
        }
      },
    );
  }

  static const Map<String, String> _localTafseerPaths = {
    // Arabic (8)
    'ar-tafsir-ibn-kathir': r'D:\AL Quran\tafssir\arabic\ar-tafsir-ibn-kathir.json',
    'ar-tafsir-al-tabari': r'D:\AL Quran\tafssir\arabic\ar-tafsir-al-tabari.json',
    'ar-tafseer-al-qurtubi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-qurtubi.json',
    'ar-tafseer-al-saddi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-saddi.json',
    'asseraj-fi-bayan-gharib-alquran': r'D:\AL Quran\tafssir\arabic\asseraj-fi-bayan-gharib-alquran.json',
    'tafsir-ibn-abi-hatim': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-abi-hatim.json',
    'tafsir-ibn-uthaymeen': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-uthaymeen.json',
    'tafsir-jalalayn': r'D:\AL Quran\tafssir\arabic\tafsir-jalalayn.json',

    // Urdu (5)
    'tafseer-ibn-e-kaseer-urdu': r'D:\AL Quran\tafssir\urdu\tafseer-ibn-e-kaseer-urdu.json',
    'tafsir-bayan-ul-quran': r'D:\AL Quran\tafssir\urdu\tafsir-bayan-ul-quran.json',
    'tafsir-as-saadi': r'D:\AL Quran\tafssir\urdu\tafsir-as-saadi.json',
    'tafsir-fe-zalul-quran-syed-qatab': r'D:\AL Quran\tafssir\urdu\tafsir-fe-zalul-quran-syed-qatab.json',
    'tazkiru-quran-ur': r'D:\AL Quran\tafssir\urdu\tazkiru-quran-ur.json',

    // English (5)
    'en-tafisr-ibn-kathir': r'D:\AL Quran\tafssir\english\en-tafisr-ibn-kathir.json',
    'Al-Mukhtasar': r'D:\AL Quran\tafssir\english\Al-Mukhtasar.json',
    'en-tafsir-maarif-ul-quran': r'D:\AL Quran\tafssir\english\en-tafsir-maarif-ul-quran.json',
    'tafsir-al-jalalayn': r'D:\AL Quran\tafssir\english\tafsir-al-jalalayn.json',
    'tazkirul-quran-en': r'D:\AL Quran\tafssir\english\tazkirul-quran-en.json',

    // Hindi (1)
    'hindi-mokhtasar': r'D:\AL Quran\tafssir\hindi\hindi-mokhtasar.json',
  };

  Future<void> _downloadAndSetEdition(Edition ed) async {
    final repo = ref.read(quranRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(
      content: Text('Downloading ${ed.name}...'),
      duration: const Duration(seconds: 3),
    ));

    try {
      final List<Map<String, dynamic>> contentRows = [];

      // Check if this edition is in our local JSON files
      final localPath = _localTafseerPaths[ed.apiKey];
      if (localPath != null && File(localPath).existsSync()) {
        final jsonStr = await File(localPath).readAsString();
        final Map<String, dynamic> tafseerDict = json.decode(jsonStr);

        for (final entry in tafseerDict.entries) {
          final key = entry.key; // e.g. "1:1"
          final val = entry.value;
          // Only insert if entry contains actual commentary (skip pointer aliases like "3:1")
          if (val is! Map) continue;
          final rawText = (val['text'] ?? '').toString();
          if (rawText.trim().isEmpty) continue;
          final text = _cleanHtml(rawText);
          if (text.isEmpty) continue;

          final parts = key.split(':');
          if (parts.length == 2) {
            final surah = int.tryParse(parts[0]);
            final ayah = int.tryParse(parts[1]);
            if (surah != null && ayah != null) {
              final globalAyahId = _getGlobalAyahId(surah, ayah);
              contentRows.add({
                'ayah_id': globalAyahId,
                'edition_id': ed.id,
                'text': text,
              });
            }
          }
        }
      } else if (ed.type != 'tafseer') {
        // Fallback for standard online translations
        final dio = Dio();
        final response = await dio.get('https://api.alquran.cloud/v1/quran/${ed.apiKey}');
        if (response.data != null && response.data['status'] == 'OK') {
          final surahs = (response.data['data']['surahs'] as List).cast<Map<String, dynamic>>();
          for (final surah in surahs) {
            final ayahs = (surah['ayahs'] as List).cast<Map<String, dynamic>>();
            for (final ayah in ayahs) {
              contentRows.add({
                'ayah_id': ayah['number'] as int,
                'edition_id': ed.id,
                'text': ayah['text'] as String,
              });
            }
          }
        }
      }

      if (contentRows.isNotEmpty) {
        await repo.insertEditionContent(contentRows);
        await repo.markEditionDownloaded(ed.id);
        await _loadData();

        messenger.showSnackBar(SnackBar(
          content: Text('${ed.name} ready offline!'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error downloading edition ${ed.name}: $e');
    }
  }

  int _getGlobalAyahId(int surah, int ayah) {
    const counts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
      112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
      54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
      14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
      11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];
    int total = 0;
    for (int i = 0; i < surah - 1; i++) {
      total += counts[i];
    }
    return total + ayah;
  }

  Future<void> _showMutashabihatBottomSheet(Ayah ayah) async {
    final repo = ref.read(quranRepositoryProvider);
    final pairs = await repo.getMutashabihatForAyah(ayah.surah, ayah.ayahNumber);

    if (!mounted) return;

    if (pairs.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Mutashabihat (similar verses) registered for Ayah ${ayah.ayahNumber}.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows_rounded, color: Color(0xFFD84315), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Mutashabihat (Similar Verses)',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Similar verses for Surah ${_surahInfo.nameTransliteration} [${ayah.surah}:${ayah.ayahNumber}]',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  final p = pairs[index];
                  final isCurrentSource = p.srcSurah == ayah.surah && p.srcAyah == ayah.ayahNumber;
                  final otherSurah = isCurrentSource ? p.similarSurah : p.srcSurah;
                  final otherAyah = isCurrentSource ? p.similarAyah : p.srcAyah;
                  final otherName = isCurrentSource ? p.similarSurahName : p.srcSurahName;
                  final otherArabic = isCurrentSource ? p.similarArabic : p.srcArabic;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Similar in Surah $otherName [$otherSurah:$otherAyah]',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD84315)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.goNamed(
                                  'verse-by-verse',
                                  pathParameters: {'surahNumber': '$otherSurah'},
                                  queryParameters: {'ayah': '$otherAyah'},
                                );
                              },
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Open'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8ECE9)),
                          ),
                          child: Text(
                            otherArabic ?? '',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final urduFontSize = ref.watch(urduFontSizeProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_surahInfo.nameTransliteration, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text(_surahInfo.nameTranslation, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoScrollActive ? Icons.pause_circle_filled : Icons.play_circle_outline,
              color: _autoScrollActive ? AppTheme.primary : AppTheme.textMuted,
              size: 26,
            ),
            tooltip: 'Auto-scroll',
            onPressed: _toggleAutoScroll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<PlayerState>(
              stream: audio.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final isBuffering = playerState?.processingState == ProcessingState.buffering ||
                    playerState?.processingState == ProcessingState.loading;

                  final double bottomPadding = (audio.currentPlayingAyahId != null ? 260.0 : 110.0) +
                      MediaQuery.paddingOf(context).bottom;

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding),
                    itemCount: _ayahs.length + 1,
                    itemBuilder: (ctx, i) {
                      // Index 0 → premium Surah Header Banner
                      if (i == 0) {
                        return _SurahHeaderBanner(
                          surahInfo: _surahInfo,
                          showBismillah: widget.surahNumber != 9,
                          bismillahTranslationText: _bismillahTranslationText,
                          showTranslation: _showTranslation,
                          translationName: _activeTranslationEdition?.name ?? 'Translation',
                          tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                          onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                          onToggleTafseer: () {
                            showAyahTafseerModal(
                              context: context,
                              ref: ref,
                              ayah: _ayahs.isNotEmpty
                                  ? _ayahs.first
                                  : Ayah(
                                      id: _getGlobalAyahId(widget.surahNumber, 1),
                                      surah: widget.surahNumber,
                                      ayahNumber: 1,
                                      arabicText: widget.surahNumber == 9
                                          ? _surahInfo.nameArabic
                                          : 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                                      juz: _surahInfo.startPage,
                                      hizb: 1,
                                      ruku: 1,
                                      manzil: 1,
                                      page: _surahInfo.startPage,
                                      isSajda: false,
                                    ),
                              activeTafseerEdition: _activeTafseerEdition ??
                                  const Edition(
                                    id: 103,
                                    type: 'tafseer',
                                    language: 'ur',
                                    name: 'Tafseer Ibn e Kaseer',
                                    apiKey: 'tafseer-ibn-e-kaseer-urdu',
                                    isBundled: true,
                                    isDownloaded: true,
                                  ),
                              onEditionChanged: (newEd) {
                                setState(() => _activeTafseerEdition = newEd);
                                _loadData();
                              },
                            );
                          },
                          onSelectTranslation: () => _showEditionSelector('translation'),
                          onSelectTafseer: () => _showEditionSelector('tafseer'),
                        );
                      }

                      final ayahIdx = i - 1;
                      if (widget.surahNumber == 1 && _ayahs[ayahIdx].ayahNumber == 1) {
                        return const SizedBox.shrink();
                      }
                      final curAyah = _ayahs[ayahIdx];
                      final isCurrentAyahPlaying = audio.currentPlayingAyahId == curAyah.id;
                      final isPlayingNow = isCurrentAyahPlaying && audio.isPlaying;
                      final isBufferingNow = isCurrentAyahPlaying && isBuffering;
                      final activeWordAsync = ref.watch(activeWordIdProvider);
                      final activeWordId = activeWordAsync.value ?? audio.currentActiveWordId;

                      final isBookmarkedNow = _bookmarkedAyahs.contains(curAyah.ayahNumber);
                      final isHighlightedNow = _highlightedAyahNumber == curAyah.ayahNumber;
                      final ayahKey = _ayahKeys.putIfAbsent(curAyah.ayahNumber, () => GlobalKey());

                      return UnifiedAyahCard(
                        key: ayahKey,
                        ayah: curAyah,
                        translationText: _translations[curAyah.id],
                        tafseerText: _tafseers[curAyah.id],
                        translationName: _activeTranslationEdition?.name ?? 'Translation',
                        tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                        arabicFontSize: arabicFontSize,
                        urduFontSize: urduFontSize,
                        isPlaying: isPlayingNow,
                        isBuffering: isBufferingNow,
                        isBookmarked: isBookmarkedNow,
                        isHighlighted: isHighlightedNow,
                        activeWordId: activeWordId,
                        onOpenTafseer: () {
                          showAyahTafseerModal(
                            context: context,
                            ref: ref,
                            ayah: _ayahs[ayahIdx],
                            activeTafseerEdition: _activeTafseerEdition ??
                                const Edition(
                                  id: 103,
                                  type: 'tafseer',
                                  language: 'ur',
                                  name: 'Tafseer Ibn e Kaseer',
                                  apiKey: 'tafseer-ibn-e-kaseer-urdu',
                                  isBundled: true,
                                  isDownloaded: true,
                                ),
                            initialTafseerText: _tafseers[_ayahs[ayahIdx].id],
                            onEditionChanged: (newEd) {
                              setState(() => _activeTafseerEdition = newEd);
                              _loadData();
                            },
                          );
                        },
                        onSelectTranslation: () => _showEditionSelector('translation'),
                        onPlayTap: () => _playAyah(_ayahs[ayahIdx]),
                        onShareTap: () {
                          final trText = _translations[_ayahs[ayahIdx].id] ?? '';
                          AyahShareDialog.show(
                            context,
                            surahName: _surahInfo.nameTransliteration,
                            ayahNumber: _ayahs[ayahIdx].ayahNumber,
                            arabicText: cleanAyahText(_ayahs[ayahIdx]),
                            translationText: trText,
                          );
                        },
                        onMutashabihatTap: () => _showMutashabihatBottomSheet(_ayahs[ayahIdx]),
                        onCopyTap: () {
                          final trText = _translations[_ayahs[ayahIdx].id] ?? '';
                          final full = 'Surah ${_surahInfo.nameTransliteration} [${widget.surahNumber}:${_ayahs[ayahIdx].ayahNumber}]\n\n'
                              '${cleanAyahText(_ayahs[ayahIdx])}\n\n'
                              '$trText\n\n— Al Quran App';
                          Clipboard.setData(ClipboardData(text: full));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verse copied to clipboard!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                          );
                        },
                        onBookmarkTap: () async {
                          final repo = ref.read(quranRepositoryProvider);
                          final messenger = ScaffoldMessenger.of(context);
                          final curAyahNum = _ayahs[ayahIdx].ayahNumber;
                          final isCurrentlyBookmarked = _bookmarkedAyahs.contains(curAyahNum);
                          if (isCurrentlyBookmarked) {
                            await repo.removeBookmark(_ayahs[ayahIdx].surah, curAyahNum);
                            if (mounted) {
                              setState(() => _bookmarkedAyahs.remove(curAyahNum));
                            }
                          } else {
                            await repo.addBookmark(_ayahs[ayahIdx].surah, curAyahNum);
                            if (mounted) {
                              setState(() => _bookmarkedAyahs.add(curAyahNum));
                            }
                          }
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(isCurrentlyBookmarked ? 'Bookmark removed' : 'Bookmarked!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                      );
                    },
                  );
                },
              ),
      bottomSheet: (audio.currentPlayingAyahId != null && _ayahs.isNotEmpty)
          ? Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 10,
              ),
              child: AudioControlBar(
                surahNumber: widget.surahNumber,
                surahName: _surahInfo.nameTransliteration,
                currentAyahNumber: _ayahs
                    .firstWhere((a) => a.id == audio.currentPlayingAyahId, orElse: () => _ayahs.first)
                    .ayahNumber,
                totalAyahs: _ayahs.length,
                onNextAyah: () {
                  final curIdx = _ayahs.indexWhere((a) => a.id == audio.currentPlayingAyahId);
                  if (curIdx >= 0 && curIdx < _ayahs.length - 1) {
                    _playAyah(_ayahs[curIdx + 1]);
                  }
                },
                onPrevAyah: () {
                  final curIdx = _ayahs.indexWhere((a) => a.id == audio.currentPlayingAyahId);
                  if (curIdx > 0) {
                    _playAyah(_ayahs[curIdx - 1]);
                  }
                },
                onClose: () => setState(() {}),
              ),
            )
          : null,
      // Auto-scroll FAB: completely hidden when audio session is active, sits near bottom right
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (audio.currentPlayingAyahId != null)
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: (MediaQuery.paddingOf(context).bottom > 0 ? 4.0 : 10.0),
                right: 4.0,
              ),
              child: InkWell(
                onTap: _toggleAutoScroll,
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8B931), Color(0xFFC59A27)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC59A27).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _autoScrollActive ? Icons.pause_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF876510),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Premium Surah Header Banner ───────────────────────────────────────────────
class _SurahHeaderBanner extends StatelessWidget {
  final SurahInfo surahInfo;
  final bool showBismillah;
  final String translationName;
  final String tafseerName;
  final String? bismillahTranslationText;
  final bool showTranslation;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleTafseer;
  final VoidCallback onSelectTranslation;
  final VoidCallback onSelectTafseer;

  const _SurahHeaderBanner({
    required this.surahInfo,
    required this.showBismillah,
    required this.translationName,
    required this.tafseerName,
    required this.bismillahTranslationText,
    required this.showTranslation,
    required this.onToggleTranslation,
    required this.onToggleTafseer,
    required this.onSelectTranslation,
    required this.onSelectTafseer,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = surahInfo.revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFF9F4EA),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC59A27).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Top Gilded Surah Title & Metadata ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              children: [
                // Arabic Surah Title with subtle gold glow
                Text(
                  'سُورَةُ ${surahInfo.nameArabic}',
                  style: const TextStyle(
                    fontFamily: 'Scheherazade New',
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2038),
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Transliteration & Translation
                Text(
                  'Surah ${surahInfo.nameTransliteration} • ${surahInfo.nameTranslation}',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF876510),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Symmetrical Metadata Info Chips Row (No colliding boxes, no overflow)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC59A27), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isMeccan ? Icons.mosque_rounded : Icons.location_city_rounded, size: 12, color: const Color(0xFF876510)),
                          const SizedBox(width: 4),
                          Text(
                            isMeccan ? 'Meccan • مَكِّيَّة' : 'Medinan • مَدَنِيَّة',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF876510)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC59A27), width: 1.2),
                      ),
                      child: Text(
                        '${surahInfo.ayahCount} Ayahs',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF876510)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC59A27), width: 1.2),
                      ),
                      child: Text(
                        '${surahInfo.rukuCount} Rukus',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF876510)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Separate [Translation] and [Tafsir] Buttons ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                // Translation Button
                Expanded(
                  child: InkWell(
                    onTap: onSelectTranslation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: showTranslation ? const Color(0xFFFEF9EE) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: showTranslation ? const Color(0xFFC59A27) : const Color(0xFFE8DFC8),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 15,
                            color: showTranslation ? const Color(0xFF876510) : const Color(0xFF7C7365),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              translationName.isNotEmpty ? translationName : 'Translation',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: showTranslation ? const Color(0xFF876510) : const Color(0xFF7C7365),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Tafsir Button
                Expanded(
                  child: InkWell(
                    onTap: onToggleTafseer,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE8DFC8),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 15,
                            color: Color(0xFF876510),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              tafseerName.isNotEmpty ? tafseerName : 'Tafsir',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF876510),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── 3. Bismillah & Urdu Translation Section ───────────────────────
          if (showBismillah) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFC59A27).withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: const Color(0xFFC59A27),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFC59A27).withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontSize: 25,
                      color: Color(0xFF0F2038),
                      height: 1.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Bismillah Urdu Translation
                  if (showTranslation && bismillahTranslationText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      bismillahTranslationText!,
                      textAlign: TextAlign.center,
                      textDirection: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? const TextStyle(
                              fontFamily: 'Noto Nastaliq Urdu',
                              fontSize: 15,
                              height: 2.2,
                              color: Color(0xFF554B3E),
                            )
                          : GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: const Color(0xFF554B3E),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _resolveTafseerValue(Map<String, dynamic> dict, String key, [int depth = 0]) {
  if (depth > 10) return '';
  final val = dict[key];
  if (val == null) return '';
  if (val is Map) return (val['text'] ?? '').toString();
  if (val is String) {
    final str = val.trim();
    if (str.contains(':') && dict.containsKey(str)) {
      return _resolveTafseerValue(dict, str, depth + 1);
    }
    return str;
  }
  return val.toString();
}

/// Strips all Arabic diacritical marks (tashkeel) from a string for bare comparison.
String _stripTashkeel(String s) {
  return s.replaceAll(
    RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06EF\u0670\u06E1\uFC60-\uFC62]'),
    '',
  );
}

/// Helper function to strip Bismillah prefix from Ayah 1 of any surah
/// because the Bismillah is prominently displayed inside the Surah Header Banner.
String cleanAyahText(Ayah ayah) {
  if (ayah.ayahNumber == 1 && ayah.surah != 1) {
    final text = ayah.arabicText.trim();
    final bare = _stripTashkeel(text);
    // Match Bismillah without any diacritics — covers ALL variant spellings
    final m = RegExp(r'^بسم\s*[اٱ]لله\s*[اٱ]لرحمن\s*[اٱ]لرحيم\s*').firstMatch(bare);
    if (m != null) {
      // Walk original string, skipping diacritics, until we've consumed bareMatchLen bare chars
      final bareLen = m.group(0)!.length;
      int bareCount = 0;
      int idx = 0;
      final diacriticRe = RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06EF\u0670\u06E1\uFC60-\uFC62]');
      while (idx < text.length && bareCount < bareLen) {
        if (!diacriticRe.hasMatch(text[idx])) bareCount++;
        idx++;
      }
      while (idx < text.length && (text[idx] == ' ' || text[idx] == '\u200C')) { idx++; }
      final remaining = text.substring(idx).trim();
      if (remaining.isNotEmpty) return remaining;
    }
  }
  return ayah.arabicText;
}

/// Strip all HTML tags, clean HTML entities, and format linebreaks for pure text
String _cleanHtml(String text) {
  var s = text;
  // Replace paragraph break tags with double linebreaks
  s = s.replaceAll(RegExp(r'</p>|<br\s*/?>|</div>', caseSensitive: false), '\n');

  // Strip all HTML tags (including self-closing like <p/>, <span/>, etc.)
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');

  // Clean HTML entities
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'");

  // Strip dangling unclosed html/class attribute snippets if any
  s = s.replaceAll(RegExp(r'p\s+class="[^"]*"|div\s+lang="[^"]*"'), '');

  // Remove multiple consecutive blank lines
  s = s.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');

  return s.trim();
}
