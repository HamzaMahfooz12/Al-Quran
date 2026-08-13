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
import '../../core/theme/app_theme.dart';
import '../../data/models/ayah.dart';
import '../../data/models/edition.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/settings_service.dart';
import '../../services/audio_service.dart';
import '../audio/audio_control_bar.dart';

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
  String? _bismillahTafseerText;
  bool _loading = true;

  // Active editions
  Edition? _activeTranslationEdition;
  Edition? _activeTafseerEdition;

  // Toggle states
  bool _showTranslation = true;
  bool _showTafseer = false;
  bool _showHeaderTafseer = false;

  // Auto-scroll
  Timer? _scrollTimer;
  bool _autoScrollActive = false;

  Timer? _lastReadTimer;
  late SurahInfo _surahInfo;

  @override
  void initState() {
    super.initState();
    _surahInfo = kSurahList[widget.surahNumber - 1];
    _loadData();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _lastReadTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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

    // Fetch Bismillah translation & tafseer for Ayah ID 1 (Ayah 1 of Surah 1 = Bismillah)
    String? bTrans = translations[1] ?? await repo.getContent(1, transEdition.id);
    bTrans ??= (transEdition.language == 'ur'
        ? 'شروع اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے'
        : 'In the name of Allah, the Entirely Merciful, the Especially Merciful.');

    String? bTafseer = tafseers[1] ?? await repo.getContent(1, tafseerEdition.id);

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
      bTafseer = tafseers[1] ?? await repo.getContent(1, tafseerEdition.id);
    }

    final lastRead = await repo.getLastRead('verse_by_verse');

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _activeTranslationEdition = transEdition;
        _activeTafseerEdition = tafseerEdition;
        _translations = translations;
        _tafseers = tafseers;
        _bismillahTranslationText = bTrans;
        _bismillahTafseerText = bTafseer;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetAyah = (lastRead != null && lastRead['surah'] == widget.surahNumber)
            ? (lastRead['ayah'] as int? ?? 1)
            : widget.scrollToAyah;

        if (targetAyah > 1 && _ayahs.length >= targetAyah && _scrollCtrl.hasClients) {
          final estimatedOffset = (targetAyah - 1) * 200.0;
          _scrollCtrl.animateTo(
            estimatedOffset.clamp(0, _scrollCtrl.position.maxScrollExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
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
    final audio = ref.read(audioServiceProvider);

    audio.onAdvance = (surah, nextAyahInSurah) {
      final nextIdx = _ayahs.indexWhere((a) => a.ayahNumber == nextAyahInSurah);
      if (nextIdx >= 0 && mounted) {
        _playAyah(_ayahs[nextIdx]);
      }
    };

    await audio.playAyah(
      globalAyahNumber: ayah.id,
      surah: ayah.surah,
      ayahInSurah: ayah.ayahNumber,
      totalAyahsInSurah: _ayahs.length,
    );
    setState(() {});
  }

  // ── Edition Selector Bottom Sheet ─────────────────────────────────────────
  Future<void> _showEditionSelector(String type) async {
    final repo = ref.read(quranRepositoryProvider);
    // Sync all global editions from API first
    await repo.fetchAndSyncApiEditions(type);
    final allEditions = await repo.getAllEditions(type: type);

    final currentLang = type == 'translation'
        ? (_activeTranslationEdition?.language.toLowerCase() ?? 'ur')
        : (_activeTafseerEdition?.language.toLowerCase() ?? 'ar');
    String selectedLangFilter = currentLang;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final baseFiltered = selectedLangFilter == 'all'
                ? List<Edition>.from(allEditions)
                : allEditions.where((e) => e.language.toLowerCase() == selectedLangFilter).toList();

            final filteredList = baseFiltered
              ..sort((a, b) {
                if (a.isAvailable && !b.isAvailable) return -1;
                if (!a.isAvailable && b.isAvailable) return 1;
                return a.name.compareTo(b.name);
              });

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type == 'translation' ? 'Select Translation' : 'Select Tafseer',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Language Filter Chips — Arabic, Urdu, English, Hindi
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLangChip('Arabic (AR)', 'ar', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('Urdu (UR)', 'ur', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('English (EN)', 'en', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('Hindi (HI)', 'hi', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                        ],
                      ),
                    ),

                    const Divider(height: 20),

                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Text(
                                'No editions found for this language.',
                                style: GoogleFonts.inter(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final ed = filteredList[index];
                                final isSelected = type == 'translation'
                                    ? _activeTranslationEdition?.id == ed.id
                                    : _activeTafseerEdition?.id == ed.id;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  title: Text(ed.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text('${ed.language.toUpperCase()} • ${ed.apiKey}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 24)
                                      : (ed.isAvailable
                                          ? const Icon(Icons.radio_button_unchecked, color: AppTheme.textMuted, size: 22)
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.cloud_download_outlined, color: AppTheme.primary, size: 20),
                                                const SizedBox(width: 4),
                                                Text('Download', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                              ],
                                            )),
                                  onTap: () async {
                                    Navigator.pop(ctx);

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
                                        _showTafseer = true;
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
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangChip(String label, String code, String current, Function(String) onSelect) {
    final isSelected = current == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primarySurface,
        checkmarkColor: AppTheme.primary,
        onSelected: (_) => onSelect(code),
      ),
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
          final rawText = val is Map ? (val['text'] ?? '').toString() : val.toString();
          final text = _cleanHtml(rawText);

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

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F3),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_surahInfo.nameTransliteration, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(_surahInfo.nameTranslation, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
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

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                    itemCount: _ayahs.length + 1,
                    itemBuilder: (ctx, i) {
                      // Index 0 → premium Surah Header Banner
                      if (i == 0) {
                        return _SurahHeaderBanner(
                          surahInfo: _surahInfo,
                          showBismillah: widget.surahNumber != 9,
                          translationName: _activeTranslationEdition?.name ?? 'Translation',
                          tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                          bismillahTranslationText: _bismillahTranslationText,
                          bismillahTafseerText: _bismillahTafseerText,
                          showTranslation: _showTranslation,
                          showTafseer: _showHeaderTafseer,
                          onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                          onToggleTafseer: () async {
                            setState(() => _showHeaderTafseer = !_showHeaderTafseer);
                            if (_showHeaderTafseer) {
                              final repo = ref.read(quranRepositoryProvider);
                              final ayahIds = _ayahs.map((a) => a.id).toList();
                              final edId = _activeTafseerEdition?.id ?? 7;
                              var tMap = await repo.getContentBulk(ayahIds, edId);
                              if (tMap.isEmpty && _activeTafseerEdition != null) {
                                tMap = await _fetchSurahEditionFromApi(_activeTafseerEdition!, ayahIds);
                              }
                              final bTaf = tMap[1] ?? await repo.getContent(1, edId);
                              if (mounted && tMap.isNotEmpty) {
                                setState(() {
                                  _tafseers = tMap;
                                  _bismillahTafseerText = bTaf;
                                });
                              }
                            }
                          },
                          onSelectTranslation: () => _showEditionSelector('translation'),
                          onSelectTafseer: () => _showEditionSelector('tafseer'),
                        );
                      }

                      final ayahIdx = i - 1;
                      if (widget.surahNumber == 1 && _ayahs[ayahIdx].ayahNumber == 1) {
                        return const SizedBox.shrink();
                      }
                      final isCurrentAyahPlaying = audio.currentPlayingAyahId == _ayahs[ayahIdx].id;
                      final isPlayingNow = isCurrentAyahPlaying && audio.isPlaying;
                      final isBufferingNow = isCurrentAyahPlaying && isBuffering;

                      return _AyahCard(
                        ayah: _ayahs[ayahIdx],
                        translationText: _translations[_ayahs[ayahIdx].id],
                        tafseerText: _tafseers[_ayahs[ayahIdx].id],
                        translationName: _activeTranslationEdition?.name ?? 'Translation',
                        tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                        showTranslation: _showTranslation,
                        showTafseer: _showTafseer,
                        arabicFontSize: arabicFontSize,
                        isPlaying: isPlayingNow,
                        isBuffering: isBufferingNow,
                        onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                        onToggleTafseer: () async {
                          setState(() => _showTafseer = !_showTafseer);
                          if (_showTafseer) {
                            final repo = ref.read(quranRepositoryProvider);
                            final ayahIds = _ayahs.map((a) => a.id).toList();
                            final edId = _activeTafseerEdition?.id ?? 7;
                            var tMap = await repo.getContentBulk(ayahIds, edId);
                            if (tMap.isEmpty && _activeTafseerEdition != null) {
                              tMap = await _fetchSurahEditionFromApi(_activeTafseerEdition!, ayahIds);
                            }
                            if (mounted && tMap.isNotEmpty) {
                              setState(() => _tafseers = tMap);
                            }
                          }
                        },
                        onSelectTranslation: () => _showEditionSelector('translation'),
                        onSelectTafseer: () => _showEditionSelector('tafseer'),
                        onPlayTap: () => _playAyah(_ayahs[ayahIdx]),
                        onBookmarkTap: () async {
                          final repo = ref.read(quranRepositoryProvider);
                          final messenger = ScaffoldMessenger.of(context);
                          final isBookmarked = await repo.isBookmarked(_ayahs[ayahIdx].surah, _ayahs[ayahIdx].ayahNumber);
                          if (isBookmarked) {
                            await repo.removeBookmark(_ayahs[ayahIdx].surah, _ayahs[ayahIdx].ayahNumber);
                          } else {
                            await repo.addBookmark(_ayahs[ayahIdx].surah, _ayahs[ayahIdx].ayahNumber);
                          }
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(isBookmarked ? 'Bookmark removed' : 'Bookmarked!'),
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
          ? AudioControlBar(
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
            )
          : null,
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
  final String? bismillahTafseerText;
  final bool showTranslation;
  final bool showTafseer;
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
    required this.bismillahTafseerText,
    required this.showTranslation,
    required this.showTafseer,
    required this.onToggleTranslation,
    required this.onToggleTafseer,
    required this.onSelectTranslation,
    required this.onSelectTafseer,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = surahInfo.revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4731), Color(0xFF2D6A4F), Color(0xFF1B5E3B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4731).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main info row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left — Revelation type badge
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                            style: const TextStyle(
                              fontFamily: 'Scheherazade New',
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isMeccan ? 'Meccan' : 'Medinan',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center — Arabic surah name
                Expanded(
                  child: Column(
                    children: [
                      // Decorative line
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A843),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Arabic surah name
                      Text(
                        'سُورَةُ ${surahInfo.nameArabic}',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 28,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        surahInfo.nameTransliteration,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4A843),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right — Surah stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statRow('Verses', surahInfo.ayahCount.toString()),
                      _statRow('Surah', surahInfo.number.toString()),
                      _statRow('Page', surahInfo.startPage.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Translation & Tafseer Control Pills in Header ─────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tafseer Pill Button
                  InkWell(
                    onTap: onToggleTafseer,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: showTafseer ? const Color(0xFFD4A843) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tafseer (تفسير)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: showTafseer ? Colors.black87 : Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: onSelectTafseer,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(width: 1, height: 16, color: Colors.white24),

                  // Translation Pill Button
                  InkWell(
                    onTap: onToggleTranslation,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: showTranslation ? const Color(0xFFA5D6A7) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate,
                            size: 14,
                            color: showTranslation ? const Color(0xFF1B4332) : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            translationName.contains('Urdu') || translationName.contains('Jalandhry') || translationName.contains('Taqi')
                                ? 'Urdu Ttion'
                                : 'Translation',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: showTranslation ? const Color(0xFF1B4332) : Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: onSelectTranslation,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Bismillah & Bismillah Translation line ─────────────────────────
          if (showBismillah) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      color: Colors.white,
                      height: 1.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Bismillah Translation
                  if (showTranslation && bismillahTranslationText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      bismillahTranslationText!,
                      textAlign: TextAlign.center,
                      textDirection: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? GoogleFonts.notoNastaliqUrdu(
                              fontSize: 15, height: 2.2, color: const Color(0xFFE8F5E9))
                          : GoogleFonts.inter(
                              fontSize: 13, height: 1.5, color: const Color(0xFFE8F5E9)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Surah Tafseer Background Details ────────────────────────────────
          if (showTafseer && bismillahTafseerText != null) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFFD4A843)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'تفسیر و پس منظر — $tafseerName',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD4A843),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cleanHtml(bismillahTafseerText!),
                      textAlign: bismillahTafseerText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? TextAlign.right
                          : TextAlign.left,
                      textDirection: bismillahTafseerText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: bismillahTafseerText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? GoogleFonts.notoNastaliqUrdu(
                              fontSize: 14, height: 2.3, color: Colors.white)
                          : GoogleFonts.inter(fontSize: 13, height: 1.6, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ayah Card Component ───────────────────────────────────────────────────────
class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final String? translationText;
  final String? tafseerText;
  final String translationName;
  final String tafseerName;
  final bool showTranslation;
  final bool showTafseer;
  final double arabicFontSize;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleTafseer;
  final VoidCallback onSelectTranslation;
  final VoidCallback onSelectTafseer;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmarkTap;

  const _AyahCard({
    required this.ayah,
    required this.translationText,
    required this.tafseerText,
    required this.translationName,
    required this.tafseerName,
    required this.showTranslation,
    required this.showTafseer,
    required this.arabicFontSize,
    required this.isPlaying,
    required this.isBuffering,
    required this.onToggleTranslation,
    required this.onToggleTafseer,
    required this.onSelectTranslation,
    required this.onSelectTafseer,
    required this.onPlayTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? AppTheme.primary : const Color(0xFFE2EBE3),
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Pill Buttons
          Row(
            children: [
              // Circle Ayah Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA8C8AD)),
                ),
                child: Center(
                  child: Text(
                    ayah.ayahNumber.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D5A34),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Pill Container matching image layout
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4E3D6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tafseer Pill Button
                    InkWell(
                      onTap: onToggleTafseer,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: showTafseer ? const Color(0xFFBBE2EC) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Tafseer (تفسير)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: showTafseer ? const Color(0xFF1E5260) : AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: onSelectTafseer,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(width: 1, height: 16, color: const Color(0xFFE0E0E0)),

                    // Translation Pill Button
                    InkWell(
                      onTap: onToggleTranslation,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: showTranslation ? const Color(0xFFBCE1F5) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.translate, size: 14, color: Color(0xFF1B4E6B)),
                            const SizedBox(width: 4),
                            Text(
                              translationName.contains('Urdu') || translationName.contains('Jalandhry') || translationName.contains('Taqi') || translationName.contains('Tariq')
                                  ? 'Urdu Ttion'
                                  : 'Translation',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: showTranslation ? const Color(0xFF1B4E6B) : AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: onSelectTranslation,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bookmark Button
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 20, color: AppTheme.textSecondary),
                onPressed: onBookmarkTap,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),

              const SizedBox(width: 4),

              // Live API Verse Audio Button
              GestureDetector(
                onTap: onPlayTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA5D6A7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4332)),
                          )
                        : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 20,
                            color: const Color(0xFF1B4332),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Arabic Verse Text (Bismillah stripped on Ayah 1 for surahs != 1 since header shows Bismillah)
          Text(
            cleanAyahText(ayah),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: arabicFontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 2.1,
            ),
          ),

          // Translation Text
          if (showTranslation && translationText != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isUrduOrArabic = translationText!.contains(RegExp(r'[\u0600-\u06FF]'));
                final isHindi = translationText!.contains(RegExp(r'[\u0900-\u097F]'));

                return Text(
                  translationText!,
                  textAlign: isUrduOrArabic ? TextAlign.right : TextAlign.left,
                  textDirection: isUrduOrArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: isUrduOrArabic
                      ? GoogleFonts.notoNastaliqUrdu(fontSize: 16, height: 2.2, color: const Color(0xFF2C3E50))
                      : (isHindi
                          ? GoogleFonts.notoSansDevanagari(fontSize: 15, height: 1.8, color: const Color(0xFF2C3E50))
                          : GoogleFonts.inter(fontSize: 14, height: 1.7, color: const Color(0xFF2C3E50))),
                );
              },
            ),
          ],

          // Tafseer Section — named header + styled body
          if (showTafseer) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA8C8AD), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Tafseer Author Header ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A34).withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5A34).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: Color(0xFF2D5A34),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفسير',
                                style: GoogleFonts.amiri(
                                  fontSize: 11,
                                  color: const Color(0xFF4A7A52),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                tafseerName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D5A34),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ─────────────────────────────────────────────
                  Container(height: 1, color: const Color(0xFFC8DEC9)),

                  // ── Tafseer Body ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: tafseerText == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D5A34)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Loading tafseer…',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF4A7A52),
                                ),
                              ),
                            ],
                          )
                        : Builder(
                            builder: (context) {
                              final cleanedText = _cleanHtml(tafseerText!);
                              final isUrduOrArabic = cleanedText.contains(RegExp(r'[\u0600-\u06FF]'));
                              final isHindi = cleanedText.contains(RegExp(r'[\u0900-\u097F]'));

                              return Text(
                                cleanedText,
                                textAlign: isUrduOrArabic ? TextAlign.right : TextAlign.left,
                                textDirection: isUrduOrArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: isUrduOrArabic
                                    ? GoogleFonts.notoNastaliqUrdu(
                                        fontSize: 15,
                                        height: 2.4,
                                        color: const Color(0xFF2C3E50),
                                      )
                                    : (isHindi
                                        ? GoogleFonts.notoSansDevanagari(
                                            fontSize: 14,
                                            height: 1.8,
                                            color: const Color(0xFF2C3E50),
                                          )
                                        : GoogleFonts.inter(
                                            fontSize: 14,
                                            height: 1.75,
                                            color: const Color(0xFF2C3E50),
                                          )),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
