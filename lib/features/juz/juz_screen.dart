// lib/features/juz/juz_screen.dart
// Juz reader — shows ONLY the ayahs within the selected Juz, grouped by Surah with headers.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ayah.dart';
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
  bool _loading = true;
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

    // Primary: query ayahs from DB by juz column (already cached surahs)
    List<Ayah> ayahs = await repo.getAyahsByJuz(widget.juzNumber);

    // If DB is empty (surahs not yet cached), fetch the relevant surahs from the API.
    // We determine candidate surahs from the juz boundary table:
    // Juz N starts at _kJuzData[N-1] and ends just before _kJuzData[N] (or surah 114).
    if (ayahs.isEmpty) {
      final startSurah = _kJuzData[widget.juzNumber - 1]['surah'] as int;
      final endSurah = widget.juzNumber < 30
          ? (_kJuzData[widget.juzNumber]['surah'] as int)
          : 114;

      for (int sNum = startSurah; sNum <= endSurah; sNum++) {
        final fetched = await repo.getAyahsBySurah(sNum);
        // Only include ayahs where the DB juz field matches this juz
        ayahs.addAll(fetched.where((a) => a.juz == widget.juzNumber));
      }
      ayahs.sort((a, b) => a.id.compareTo(b.id));
    }

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
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
    // Estimate visible index from scroll position (avg card ~120px)
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
    // For juz mode: onAdvance plays next ayah in the juz list (not just within surah)
    audio.onAdvance = (surah, nextAyahInSurah) {
      final nextIdx = _ayahs.indexWhere(
          (a) => a.surah == surah && a.ayahNumber == nextAyahInSurah);
      if (nextIdx >= 0 && mounted) {
        _playAyah(_ayahs[nextIdx]);
      } else {
        // Try globally next ayah in juz list
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
            // Juz name — main title
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
            // Current surah name — subtitle
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
          // Arabic juz name on the right
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
          : _ayahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download_outlined,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Loading Juz ${widget.juzNumber}…',
                        style: GoogleFonts.inter(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please open each surah in this Juz once to cache it.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
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
                        if (item is String) {
                          // Surah divider header
                          return _SurahHeader(surahName: item);
                        }
                        final ayah = item as Ayah;
                        final isCurrentAyahPlaying =
                            audio.currentPlayingAyahId == ayah.id;
                        final isPlayingNow =
                            isCurrentAyahPlaying && audio.isPlaying;
                        final isBufferingNow =
                            isCurrentAyahPlaying && isBuffering;

                        return _JuzAyahCard(
                          ayah: ayah,
                          arabicFontSize: arabicFontSize,
                          isPlaying: isPlayingNow,
                          isBuffering: isBufferingNow,
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

  /// Builds a flat list of items: String = surah header, Ayah = ayah card
  List<Object> _buildItems() {
    final List<Object> items = [];
    int lastSurah = -1;
    for (final ayah in _ayahs) {
      if (ayah.surah != lastSurah) {
        final info = kSurahList[ayah.surah - 1];
        items.add('${info.nameTransliteration} — ${info.nameArabic}');
        lastSurah = ayah.surah;
      }
      items.add(ayah);
    }
    return items;
  }
}

// ── Surah Header Divider ──────────────────────────────────────────────────────
class _SurahHeader extends StatelessWidget {
  final String surahName;
  const _SurahHeader({required this.surahName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            surahName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Juz Ayah Card ─────────────────────────────────────────────────────────────
class _JuzAyahCard extends StatelessWidget {
  final Ayah ayah;
  final double arabicFontSize;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayTap;

  const _JuzAyahCard({
    required this.ayah,
    required this.arabicFontSize,
    required this.isPlaying,
    required this.isBuffering,
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
          // Header row: ayah number badge + play button
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

          // Arabic text
          Text(
            ayah.arabicText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: arabicFontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 2.1,
            ),
          ),
        ],
      ),
    );
  }
}
