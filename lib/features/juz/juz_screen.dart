// lib/features/juz/juz_screen.dart
// Juz reader — shows ONLY the ayahs within the selected Juz, grouped by Surah with headers.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ayah.dart';
import '../../data/models/edition.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../audio/audio_control_bar.dart';

// ── Juz metadata ──────────────────────────────────────────────────────────────
const _kJuzInfo = [
  {'name': 'Alif Laam Meem',        'arabic': 'الم'},
  {'name': 'Sayaqool',              'arabic': 'سَيَقُولُ'},
  {'name': 'Tilkar Rusul',          'arabic': 'تِلۡكَ ٱلرُّسُلُ'},
  {'name': 'Lan Tanaloo',           'arabic': 'لَن تَنَالُوا'},
  {'name': 'Wal Mohsanat',          'arabic': 'وَٱلۡمُحۡصَنَٰتُ'},
  {'name': 'La Yuhibbullah',        'arabic': 'لَّا يُحِبُّ ٱللَّهُ'},
  {'name': 'Wa Iza Samiu',          'arabic': 'وَإِذَا سَمِعُوا'},
  {'name': 'Wa Lau Annana',         'arabic': 'وَلَوۡ أَنَّنَا'},
  {'name': 'Qalal Malao',           'arabic': 'قَالَ ٱلۡمَلَأُ'},
  {'name': 'Wa Alamu',              'arabic': 'وَٱعۡلَمُوٓا'},
  {'name': 'Yatazeroon',            'arabic': 'يَعۡتَذِرُونَ'},
  {'name': 'Wa Ma Min Daabbah',     'arabic': 'وَمَا مِن دَآبَّةٍ'},
  {'name': 'Wa Ma Ubarrio',         'arabic': 'وَمَآ أُبَرِّئُ'},
  {'name': 'Rubama',                'arabic': 'رُّبَمَا'},
  {'name': 'Subhanallazi',          'arabic': 'سُبۡحَٰنَ ٱلَّذِي'},
  {'name': 'Qal Alam',              'arabic': 'قَالَ أَلَمۡ'},
  {'name': 'Iqtaraba',              'arabic': 'ٱقۡتَرَبَ'},
  {'name': 'Qad Aflaha',            'arabic': 'قَدۡ أَفۡلَحَ'},
  {'name': 'Wa Qalallazina',        'arabic': 'وَقَالَ ٱلَّذِينَ'},
  {'name': 'Amman Khalaq',          'arabic': 'أَمَّنۡ خَلَقَ'},
  {'name': 'Utlu Ma Oohiya',        'arabic': 'ٱتۡلُ مَآ أُوحِيَ'},
  {'name': 'Wa Manyaqnut',          'arabic': 'وَمَن يَقۡنُتۡ'},
  {'name': 'Wa Mali',               'arabic': 'وَمَالِيَ'},
  {'name': 'Faman Azlamu',          'arabic': 'فَمَنۡ أَظۡلَمُ'},
  {'name': 'Ilayhi Yuraddu',        'arabic': 'إِلَيۡهِ يُرَدُّ'},
  {'name': 'Ha Meem',               'arabic': 'حم'},
  {'name': 'Qala Fama Khatbukum',   'arabic': 'قَالَ فَمَا خَطۡبُكُمۡ'},
  {'name': 'Qad Sami Allah',        'arabic': 'قَدۡ سَمِعَ ٱللَّهُ'},
  {'name': 'Tabarakallazi',         'arabic': 'تَبَٰرَكَ ٱلَّذِي'},
  {'name': 'Amma Yatasaaloona',     'arabic': 'عَمَّ يَتَسَآءَلُونَ'},
];

// Juz boundary data — starting surah/ayah for each Juz (used for fallback fetching)
const _kJuzData = [
  {'surah': 2,  'ayah': 1},
  {'surah': 2,  'ayah': 142},
  {'surah': 2,  'ayah': 253},
  {'surah': 3,  'ayah': 92},
  {'surah': 4,  'ayah': 24},
  {'surah': 4,  'ayah': 148},
  {'surah': 5,  'ayah': 82},
  {'surah': 6,  'ayah': 111},
  {'surah': 7,  'ayah': 88},
  {'surah': 8,  'ayah': 41},
  {'surah': 9,  'ayah': 94},
  {'surah': 11, 'ayah': 6},
  {'surah': 12, 'ayah': 53},
  {'surah': 15, 'ayah': 1},
  {'surah': 17, 'ayah': 1},
  {'surah': 18, 'ayah': 75},
  {'surah': 21, 'ayah': 1},
  {'surah': 23, 'ayah': 1},
  {'surah': 25, 'ayah': 20},
  {'surah': 27, 'ayah': 60},
  {'surah': 29, 'ayah': 45},
  {'surah': 33, 'ayah': 31},
  {'surah': 36, 'ayah': 22},
  {'surah': 39, 'ayah': 32},
  {'surah': 41, 'ayah': 47},
  {'surah': 46, 'ayah': 1},
  {'surah': 51, 'ayah': 31},
  {'surah': 58, 'ayah': 1},
  {'surah': 67, 'ayah': 1},
  {'surah': 78, 'ayah': 1},
];

class JuzScreen extends ConsumerStatefulWidget {
  final int juzNumber; // 1–30

  const JuzScreen({super.key, required this.juzNumber});

  @override
  ConsumerState<JuzScreen> createState() => _JuzScreenState();
}

class _JuzScreenState extends ConsumerState<JuzScreen> {
  final _scrollCtrl = ScrollController();
  List<Ayah> _ayahs = [];
  Map<int, String> _translations = {};
  Map<int, String> _tafseers = {};
  bool _loading = true;

  Edition? _activeTranslationEdition;
  Edition? _activeTafseerEdition;

  bool _showTranslation = true;
  bool _showTafseer = false;

  String _currentSurahName = '';
  int _currentSurahNumber = 0;

  String get _juzName => _kJuzInfo[widget.juzNumber - 1]['name']!;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadJuzAyahs();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJuzAyahs() async {
    final repo = ref.read(quranRepositoryProvider);
    final settings = ref.read(settingsServiceProvider);

    // Primary: query ayahs from DB by juz column
    List<Ayah> ayahs = await repo.getAyahsByJuz(widget.juzNumber);

    if (ayahs.isEmpty) {
      final startSurah = _kJuzData[widget.juzNumber - 1]['surah'] as int;
      final endSurah = widget.juzNumber < 30
          ? (_kJuzData[widget.juzNumber]['surah'] as int)
          : 114;

      for (int sNum = startSurah; sNum <= endSurah; sNum++) {
        final fetched = await repo.getAyahsBySurah(sNum);
        ayahs.addAll(fetched.where((a) => a.juz == widget.juzNumber));
      }
      ayahs.sort((a, b) => a.id.compareTo(b.id));
    }

    final ayahIds = ayahs.map((a) => a.id).toList();
    final availableTranslations = await repo.getAvailableEditions(type: 'translation');
    final availableTafseers = await repo.getAvailableEditions(type: 'tafseer');

    Edition? transEdition;
    final selectedTransId = settings.selectedTranslationId;
    if (selectedTransId != null) {
      final match = availableTranslations.where((e) => e.id == selectedTransId);
      if (match.isNotEmpty) transEdition = match.first;
    }
    transEdition ??= (availableTranslations.isNotEmpty
        ? availableTranslations.first
        : const Edition(id: 1, type: 'translation', language: 'ur', name: 'Fateh Muhammad Jalandhry', apiKey: 'ur.jalandhry', isBundled: true, isDownloaded: true));

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

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _activeTranslationEdition = transEdition;
        _activeTafseerEdition = tafseerEdition;
        _translations = translations;
        _tafseers = tafseers;
        _loading = false;
        if (ayahs.isNotEmpty) {
          _currentSurahNumber = ayahs.first.surah;
          _currentSurahName =
              kSurahList[_currentSurahNumber - 1].nameTransliteration;
        }
      });
    }
  }

  void _onScroll() {
    if (_ayahs.isEmpty || !_scrollCtrl.hasClients) return;
    final idx = (_scrollCtrl.offset / 120).floor().clamp(0, _ayahs.length - 1);
    final surahNum = _ayahs[idx].surah;
    if (surahNum != _currentSurahNumber) {
      setState(() {
        _currentSurahNumber = surahNum;
        _currentSurahName = kSurahList[surahNum - 1].nameTransliteration;
      });
    }
  }

  Future<void> _playAyah(Ayah ayah) async {
    final audio = ref.read(audioServiceProvider);
    audio.onAdvance = (surah, nextAyahInSurah) {
      final nextIdx = _ayahs.indexWhere(
          (a) => a.surah == surah && a.ayahNumber == nextAyahInSurah);
      if (nextIdx >= 0 && mounted) {
        _playAyah(_ayahs[nextIdx]);
      } else {
        final curIdx = _ayahs.indexWhere((a) => a.id == audio.currentPlayingAyahId);
        if (curIdx >= 0 && curIdx < _ayahs.length - 1 && mounted) {
          _playAyah(_ayahs[curIdx + 1]);
        }
      }
    };

    await audio.playAyah(
      globalAyahNumber: ayah.id,
      surah: ayah.surah,
      ayahInSurah: ayah.ayahNumber,
      totalAyahsInSurah: _ayahs.where((a) => a.surah == ayah.surah).length,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Juz ${widget.juzNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _juzName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (_currentSurahName.isNotEmpty)
              Text(
                _currentSurahName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              _kJuzInfo[widget.juzNumber - 1]['arabic']!,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<PlayerState>(
              stream: audio.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final isBuffering =
                    playerState?.processingState == ProcessingState.buffering ||
                    playerState?.processingState == ProcessingState.loading;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                  itemCount: _buildItems().length,
                  itemBuilder: (ctx, i) {
                    final item = _buildItems()[i];
                    if (item is int) {
                      return _SurahHeader(
                        surahNumber: item,
                        translationName: _activeTranslationEdition?.name ?? 'Translation',
                        tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                        bismillahTranslationText: _translations[1],
                        bismillahTafseerText: _tafseers[1],
                        showTranslation: _showTranslation,
                        showTafseer: _showTafseer,
                        onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                        onToggleTafseer: () => setState(() => _showTafseer = !_showTafseer),
                      );
                    }
                    final ayah = item as Ayah;
                    final isCurrentAyahPlaying = audio.currentPlayingAyahId == ayah.id;
                    final isPlayingNow = isCurrentAyahPlaying && audio.isPlaying;
                    final isBufferingNow = isCurrentAyahPlaying && isBuffering;

                    return _JuzAyahCard(
                      ayah: ayah,
                      translationText: _translations[ayah.id],
                      tafseerText: _tafseers[ayah.id],
                      translationName: _activeTranslationEdition?.name ?? 'Translation',
                      tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                      showTranslation: _showTranslation,
                      showTafseer: _showTafseer,
                      arabicFontSize: arabicFontSize,
                      isPlaying: isPlayingNow,
                      isBuffering: isBufferingNow,
                      onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                      onToggleTafseer: () => setState(() => _showTafseer = !_showTafseer),
                      onPlayTap: () => _playAyah(ayah),
                    );
                  },
                );
              },
            ),
      bottomSheet: (audio.currentPlayingAyahId != null && _ayahs.isNotEmpty)
          ? AudioControlBar(
              surahNumber: _currentSurahNumber,
              surahName: _juzName,
              currentAyahNumber: _ayahs
                  .firstWhere((a) => a.id == audio.currentPlayingAyahId,
                      orElse: () => _ayahs.first)
                  .ayahNumber,
              totalAyahs: _ayahs.length,
              onNextAyah: () {
                final curIdx = _ayahs
                    .indexWhere((a) => a.id == audio.currentPlayingAyahId);
                if (curIdx >= 0 && curIdx < _ayahs.length - 1) {
                  _playAyah(_ayahs[curIdx + 1]);
                }
              },
              onPrevAyah: () {
                final curIdx = _ayahs
                    .indexWhere((a) => a.id == audio.currentPlayingAyahId);
                if (curIdx > 0) {
                  _playAyah(_ayahs[curIdx - 1]);
                }
              },
              onClose: () => setState(() {}),
            )
          : null,
    );
  }

  List<Object> _buildItems() {
    final List<Object> items = [];
    int lastSurah = -1;
    for (final ayah in _ayahs) {
      if (ayah.surah != lastSurah) {
        items.add(ayah.surah);
        lastSurah = ayah.surah;
      }
      items.add(ayah);
    }
    return items;
  }
}

// ── Premium Surah Header for Juz ─────────────────────────────────────────────
class _SurahHeader extends StatelessWidget {
  final int surahNumber;
  final String translationName;
  final String tafseerName;
  final String? bismillahTranslationText;
  final String? bismillahTafseerText;
  final bool showTranslation;
  final bool showTafseer;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleTafseer;

  const _SurahHeader({
    required this.surahNumber,
    required this.translationName,
    required this.tafseerName,
    required this.bismillahTranslationText,
    required this.bismillahTafseerText,
    required this.showTranslation,
    required this.showTafseer,
    required this.onToggleTranslation,
    required this.onToggleTafseer,
  });

  @override
  Widget build(BuildContext context) {
    final info = kSurahList[surahNumber - 1];
    final isMeccan = info.revelationType == 'Meccan';
    final showBismillah = surahNumber != 9;

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4731), Color(0xFF2D6A4F), Color(0xFF1B5E3B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4731).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left — revelation type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isMeccan ? 'Meccan' : 'Medinan',
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // Center — Arabic name + transliteration
                Expanded(
                  child: Column(
                    children: [
                      _dividerRow(),
                      const SizedBox(height: 6),
                      Text(
                        'سُورَةُ ${info.nameArabic}',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        info.nameTransliteration,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _dividerRow(),
                    ],
                  ),
                ),
                // Right — stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stat('Verses', info.ayahCount.toString()),
                      _stat('Surah', info.number.toString()),
                      _stat('Page', info.startPage.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Translation & Tafseer Pills inside Header ─────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tafseer Pill
                  InkWell(
                    onTap: onToggleTafseer,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: showTafseer ? const Color(0xFFD4A843) : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      ),
                      child: Text(
                        'Tafseer (تفسير)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: showTafseer ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 16, color: Colors.white24),
                  // Translation Pill
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Bismillah & Translation line ─────────────────────────────────
          if (showBismillah) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      color: Colors.white,
                      height: 1.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showTranslation && bismillahTranslationText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      bismillahTranslationText!,
                      textAlign: TextAlign.center,
                      textDirection: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: bismillahTranslationText!.contains(RegExp(r'[\u0600-\u06FF]'))
                          ? GoogleFonts.notoNastaliqUrdu(
                              fontSize: 14, height: 2.1, color: const Color(0xFFE8F5E9))
                          : GoogleFonts.inter(
                              fontSize: 12, height: 1.4, color: const Color(0xFFE8F5E9)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Surah Tafseer Background Details ──────────────────────────────
          if (showTafseer && bismillahTafseerText != null) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFFD4A843)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'تفسیر و پس منظر — $tafseerName',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD4A843),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                              fontSize: 13, height: 2.2, color: Colors.white)
                          : GoogleFonts.inter(fontSize: 12, height: 1.5, color: Colors.white),
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

  Widget _dividerRow() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(color: Color(0xFFD4A843), shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: GoogleFonts.inter(fontSize: 9, color: Colors.white60)),
          Text(value, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Juz Ayah Card ─────────────────────────────────────────────────────────────
class _JuzAyahCard extends StatelessWidget {
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
  final VoidCallback onPlayTap;

  const _JuzAyahCard({
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
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          // Header row: ayah number badge + pill buttons + play button
          Row(
            children: [
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

              const SizedBox(width: 8),

              // Pill container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4E3D6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onToggleTafseer,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: showTafseer ? const Color(0xFFBBE2EC) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        ),
                        child: Text(
                          'Tafseer (تفسير)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: showTafseer ? const Color(0xFF1E5260) : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 16, color: const Color(0xFFE0E0E0)),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.translate, size: 14, color: Color(0xFF1B4E6B)),
                            const SizedBox(width: 4),
                            Text(
                              translationName.contains('Urdu') || translationName.contains('Jalandhry') || translationName.contains('Taqi')
                                  ? 'Urdu Ttion'
                                  : 'Translation',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: showTranslation ? const Color(0xFF1B4E6B) : AppTheme.textSecondary,
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

              // Play button
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
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1B4332)),
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

          const SizedBox(height: 14),

          // Arabic text (Bismillah stripped on Ayah 1 of surahs != 1)
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

          // Tafseer Body
          if (showTafseer && tafseerText != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA8C8AD)),
              ),
              child: Text(
                tafseerText!,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 15,
                  height: 2.2,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Strip all HTML tags, clean HTML entities, and format linebreaks for pure text
String _cleanHtml(String text) {
  var s = text;
  s = s.replaceAll(RegExp(r'</p>|<br\s*/?>|</div>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'");
  s = s.replaceAll(RegExp(r'p\s+class="[^"]*"|div\s+lang="[^"]*"'), '');
  s = s.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
  return s.trim();
}

/// Helper function to strip Bismillah prefix from Ayah 1 of any surah (except Surah 1)
String cleanAyahText(Ayah ayah) {
  if (ayah.ayahNumber == 1 && ayah.surah != 1) {
    String text = ayah.arabicText.trim();
    const bismillahVariants = [
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
      'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ',
    ];
    for (final b in bismillahVariants) {
      if (text.startsWith(b)) {
        final remaining = text.substring(b.length).trim();
        if (remaining.isNotEmpty) return remaining;
      }
    }
    final match = RegExp(r'^بِ?سۡ?مِ?\s*ٱ?لَّ?لَّ?هِ?\s*ٱ?لرَّ?حۡ?مَـٰ?نِ?\s*ٱ?لرَّ?حِ?ی?مِ?\s*').firstMatch(text);
    if (match != null && match.group(0)!.length >= 15) {
      final remaining = text.substring(match.group(0)!.length).trim();
      if (remaining.isNotEmpty) return remaining;
    }
  }
  return ayah.arabicText;
}
