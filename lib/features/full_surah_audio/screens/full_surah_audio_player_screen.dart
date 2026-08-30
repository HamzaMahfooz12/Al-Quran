// lib/features/full_surah_audio/screens/full_surah_audio_player_screen.dart
// Focused Sanctuary Single-Surah Audio Player with serene atmosphere,
// live counting bar (elapsed & remaining), Sleep Timer, Repeat, Speed, and Offline Download

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/full_surah_reciter.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/full_surah_reciter_repository.dart';
import '../../../services/full_surah_audio_service.dart';
import '../../quran/simple_quran_index_screen.dart' show IslamicStarBadge;

class FullSurahAudioPlayerScreen extends ConsumerStatefulWidget {
  final int initialSurah;
  const FullSurahAudioPlayerScreen({super.key, this.initialSurah = 1});

  @override
  ConsumerState<FullSurahAudioPlayerScreen> createState() =>
      _FullSurahAudioPlayerScreenState();
}

class _FullSurahAudioPlayerScreenState
    extends ConsumerState<FullSurahAudioPlayerScreen> {
  double? _dragPositionSec;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = ref.read(fullSurahAudioServiceProvider);
      if (audioService.currentSurahNumber != widget.initialSurah ||
          (!audioService.isPlaying && !audioService.isLoading)) {
        audioService.playSurah(surahNumber: widget.initialSurah);
      }
    });
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatRemaining(Duration? position, Duration? total) {
    if (total == null || position == null) return '-00:00';
    final remaining = total - position;
    if (remaining.isNegative) return '-00:00';
    return '-${_formatDuration(remaining)}';
  }

  void _openSurahSelectorModal(FullSurahAudioService audioService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SurahPickerModal(
        currentSurah: audioService.currentSurahNumber ?? widget.initialSurah,
        onSelected: (surahNum) {
          audioService.playSurah(surahNumber: surahNum);
        },
      ),
    );
  }

  void _openReciterSelectorModal(FullSurahAudioService audioService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlayerReciterPickerModal(
        selectedReciter: audioService.currentReciter,
        onSelected: (reciter) {
          audioService.setReciter(reciter);
        },
      ),
    );
  }

  void _openSleepTimerModal(FullSurahAudioService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SleepTimerModal(audioService: audioService),
    );
  }

  void _cycleSpeed(FullSurahAudioService audioService) {
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final current = audioService.speed;
    int nextIdx = (speeds.indexOf(current) + 1) % speeds.length;
    if (nextIdx < 0) nextIdx = 0;
    audioService.setSpeed(speeds[nextIdx]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(fullSurahAudioServiceProvider);
    final surahNum = audioService.currentSurahNumber ?? widget.initialSurah;
    final sInfo = kSurahList.firstWhere(
      (s) => s.number == surahNum,
      orElse: () => kSurahList.first,
    );
    final reciter = audioService.currentReciter;
    final reciterName = reciter.name;

    final prevSurahNum = (surahNum > 1) ? surahNum - 1 : 114;
    final nextSurahNum = (surahNum < 114) ? surahNum + 1 : 1;
    final prevInfo = kSurahList[prevSurahNum - 1];
    final nextInfo = kSurahList[nextSurahNum - 1];

    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: Stack(
        children: [
          // ── 1. Spiritual Dawn Backdrop Image ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/madinah_hero_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/kaaba_makkah_spiritual.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── 2. Atmospheric Dark Forest Gradient Overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F1A12).withValues(alpha: 0.65),
                    const Color(0xFF1B2A1E).withValues(alpha: 0.85),
                    const Color(0xFF0A140D).withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── 3. Focused Sanctuary Content ──
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
              child: Column(
                children: [
                  // ── Top Navigation Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Now Reciting',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 18),
                        ),
                        tooltip: 'Choose Surah',
                        onPressed: () => _openSurahSelectorModal(audioService),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Central Glowing Quran Medallion ──
                  Container(
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF3FA34D), Color(0xFF1B4332)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3FA34D).withValues(alpha: 0.45),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          blurRadius: 15,
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Color(0xFFFEF3C7), size: 38),
                          const SizedBox(height: 4),
                          Text(
                            'القرآن الكريم',
                            style: GoogleFonts.amiri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Surah Title in Glowing Gold Arabic ──
                  Text(
                    'سورة ${sInfo.nameArabic}',
                    style: GoogleFonts.amiri(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF59E0B),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Surah ${sInfo.nameTransliteration}',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Surah $surahNum • ${sInfo.ayahCount} Verses • ${sInfo.revelationType}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Active Reciter Badge with 1-Tap Switcher ──
                  InkWell(
                    onTap: () => _openReciterSelectorModal(audioService),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF56BA64).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF56BA64)),
                          const SizedBox(width: 6),
                          Text(
                            'Reciter: $reciterName',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.sync_rounded, size: 14, color: Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                  ),

                  if (audioService.isUsingFallback) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Streaming via MP3Quran Fallback CDN',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFFEF3C7)),
                      ),
                    ),
                  ],

                  const Spacer(flex: 1),

                  // ── Live Audio Counting Bar & Time Display ──
                  StreamBuilder<Duration>(
                    stream: audioService.positionStream,
                    builder: (ctx, posSnap) {
                      final currentPos = posSnap.data ?? Duration.zero;

                      return StreamBuilder<Duration?>(
                        stream: audioService.durationStream,
                        builder: (ctx, durSnap) {
                          final totalDur = durSnap.data ?? Duration.zero;
                          final totalSeconds = totalDur.inSeconds > 0 ? totalDur.inSeconds.toDouble() : 1.0;
                          final currentSeconds = (_dragPositionSec ?? currentPos.inSeconds.toDouble())
                              .clamp(0.0, totalSeconds);

                          return Column(
                            children: [
                              // Time Counter (Elapsed on left, Remaining on right)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(Duration(seconds: currentSeconds.toInt())),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    Text(
                                      _formatRemaining(Duration(seconds: currentSeconds.toInt()), totalDur),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Seeker Slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4.5,
                                  activeTrackColor: const Color(0xFFF59E0B),
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                                  thumbColor: const Color(0xFFFEF3C7),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                ),
                                child: Slider(
                                  value: currentSeconds,
                                  min: 0.0,
                                  max: totalSeconds,
                                  onChanged: (val) {
                                    setState(() => _dragPositionSec = val);
                                  },
                                  onChangeEnd: (val) {
                                    audioService.seek(Duration(seconds: val.toInt()));
                                    setState(() => _dragPositionSec = null);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── 4 Listening Options Pills (Speed, Repeat, Sleep Timer, Download) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Speed Pill
                      _optionPill(
                        label: 'Speed',
                        value: '${audioService.speed}x',
                        icon: Icons.speed_rounded,
                        onTap: () => _cycleSpeed(audioService),
                      ),

                      // 2. Repeat Mode Pill
                      _optionPill(
                        label: 'Repeat',
                        value: audioService.repeatMode == FullSurahRepeatMode.surah
                            ? 'Surah'
                            : audioService.repeatMode == FullSurahRepeatMode.continuous
                                ? 'Continuous'
                                : 'Off',
                        icon: Icons.repeat_rounded,
                        isActive: audioService.repeatMode != FullSurahRepeatMode.off,
                        onTap: () {
                          audioService.cycleRepeatMode();
                          setState(() {});
                        },
                      ),

                      // 3. Sleep Timer Pill
                      StreamBuilder<Duration?>(
                        stream: audioService.sleepTimerRemainingStream,
                        builder: (ctx, snap) {
                          final remaining = snap.data;
                          final hasTimer = remaining != null && !remaining.isNegative;
                          final timerText = hasTimer ? '${remaining.inMinutes + 1}m' : 'Off';

                          return _optionPill(
                            label: 'Timer',
                            value: timerText,
                            icon: Icons.timer_rounded,
                            isActive: hasTimer,
                            onTap: () => _openSleepTimerModal(audioService),
                          );
                        },
                      ),

                      // 4. Offline Download Pill
                      StreamBuilder<Map<int, double>>(
                        stream: audioService.downloadProgressStream,
                        builder: (ctx, snap) {
                          final progress = snap.data?[surahNum];
                          if (progress != null) {
                            return _optionPill(
                              label: 'Download',
                              value: '${(progress * 100).toInt()}%',
                              icon: Icons.downloading_rounded,
                              isActive: true,
                              onTap: () {},
                            );
                          }

                          final isDownloaded = audioService.downloadedSurahs.contains(surahNum);

                          return _optionPill(
                            label: 'Offline',
                            value: isDownloaded ? 'Downloaded' : 'Download',
                            icon: isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                            isActive: isDownloaded,
                            onTap: () {
                              if (isDownloaded) {
                                audioService.deleteDownloadedSurah(surahNum, reciter.id);
                              } else {
                                audioService.downloadSurah(surahNum, reciter);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Master Playback Navigation Controls ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Surah Button
                      IconButton(
                        iconSize: 42,
                        tooltip: 'Previous: Surah ${prevInfo.nameTransliteration}',
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                        onPressed: () => audioService.prevSurah(),
                      ),

                      const SizedBox(width: 18),

                      // Glowing Golden Circular Play/Pause Button
                      StreamBuilder<PlayerState>(
                        stream: audioService.playerStateStream,
                        builder: (ctx, snap) {
                          final isPlaying = snap.data?.playing ?? false;
                          final isBuffering = snap.data?.processingState == ProcessingState.buffering ||
                              snap.data?.processingState == ProcessingState.loading;

                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => audioService.togglePlay(),
                                customBorder: const CircleBorder(),
                                child: Center(
                                  child: isBuffering
                                      ? const SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: const Color(0xFF1B2A1E),
                                          size: 40,
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 18),

                      // Next Surah Button
                      IconButton(
                        iconSize: 42,
                        tooltip: 'Next: Surah ${nextInfo.nameTransliteration}',
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                        onPressed: () => audioService.nextSurah(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionPill({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3FA34D).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFF56BA64) : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isActive ? const Color(0xFFFEF3C7) : Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFFFEF3C7) : Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Surah Picker Modal for focused player ───────────────────────────────────
class _SurahPickerModal extends StatefulWidget {
  final int currentSurah;
  final ValueChanged<int> onSelected;

  const _SurahPickerModal({
    required this.currentSurah,
    required this.onSelected,
  });

  @override
  State<_SurahPickerModal> createState() => _SurahPickerModalState();
}

class _SurahPickerModalState extends State<_SurahPickerModal> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() => _query = _ctrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filtered {
    if (_query.isEmpty) return kSurahList;
    return kSurahList.where((s) {
      return s.nameTransliteration.toLowerCase().contains(_query) ||
          s.nameArabic.contains(_query) ||
          s.number.toString() == _query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E1D2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Surah (114)',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2A1E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E1D2)),
              ),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Search Surah...',
                  hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF8D9E92)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3FA34D), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final s = _filtered[idx];
                final isSelected = widget.currentSurah == s.number;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE8E1D2),
                    ),
                  ),
                  child: ListTile(
                    leading: IslamicStarBadge(number: s.number, size: 36),
                    title: Text(
                      'Surah ${s.nameTransliteration}',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: const Color(0xFF1B2A1E),
                      ),
                    ),
                    subtitle: Text(
                      '${s.ayahCount} Verses • ${s.revelationType}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF4B5E50)),
                    ),
                    trailing: Text(
                      s.nameArabic,
                      style: GoogleFonts.amiri(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    onTap: () {
                      widget.onSelected(s.number);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reciter Picker Modal for focused player ─────────────────────────────────
class _PlayerReciterPickerModal extends ConsumerStatefulWidget {
  final FullSurahReciter? selectedReciter;
  final ValueChanged<FullSurahReciter> onSelected;

  const _PlayerReciterPickerModal({
    required this.selectedReciter,
    required this.onSelected,
  });

  @override
  ConsumerState<_PlayerReciterPickerModal> createState() => _PlayerReciterPickerModalState();
}

class _PlayerReciterPickerModalState extends ConsumerState<_PlayerReciterPickerModal> {
  final TextEditingController _filterCtrl = TextEditingController();
  List<FullSurahReciter> _all = [];
  List<FullSurahReciter> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReciters();
    _filterCtrl.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReciters() async {
    final repo = ref.read(fullSurahReciterRepositoryProvider);
    _all = await repo.getAllReciters();
    _filtered = _all;
    if (mounted) setState(() => _loading = false);
  }

  void _onFilterChanged() {
    final q = _filterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
    } else {
      setState(() {
        _filtered = _all.where((r) {
          return r.name.toLowerCase().contains(q) ||
              r.arabicName.contains(q) ||
              r.folderSlug.toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E1D2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Reciter (${_all.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2A1E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E1D2)),
              ),
              child: TextField(
                controller: _filterCtrl,
                decoration: InputDecoration(
                  hintText: 'Search reciters...',
                  hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF8D9E92)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3FA34D), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3FA34D)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE8E1D2)),
                    itemBuilder: (ctx, idx) {
                      final r = _filtered[idx];
                      final isSelected = widget.selectedReciter?.id == r.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF3FA34D) : const Color(0xFFEAF6EC),
                          child: Icon(
                            Icons.person_rounded,
                            color: isSelected ? Colors.white : const Color(0xFF2C7A39),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          r.name,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF2C7A39) : const Color(0xFF1B2A1E),
                          ),
                        ),
                        subtitle: Text(
                          r.arabicName,
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            color: const Color(0xFF4B5E50),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3FA34D), size: 22)
                            : null,
                        onTap: () {
                          widget.onSelected(r);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Sleep Timer Picker Modal ────────────────────────────────────────────────
class _SleepTimerModal extends StatelessWidget {
  final FullSurahAudioService audioService;
  const _SleepTimerModal({required this.audioService});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final options = [
      {'title': '15 Minutes', 'duration': const Duration(minutes: 15)},
      {'title': '30 Minutes', 'duration': const Duration(minutes: 30)},
      {'title': '45 Minutes', 'duration': const Duration(minutes: 45)},
      {'title': '60 Minutes', 'duration': const Duration(minutes: 60)},
      {'title': 'Turn Off Timer', 'duration': Duration.zero},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Timer',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B2A1E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...options.map((opt) {
            final dur = opt['duration'] as Duration;
            final title = opt['title'] as String;
            final isOff = dur == Duration.zero;

            return ListTile(
              leading: Icon(
                isOff ? Icons.timer_off_rounded : Icons.alarm_rounded,
                color: isOff ? const Color(0xFFE53935) : const Color(0xFF3FA34D),
              ),
              title: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isOff ? const Color(0xFFE53935) : const Color(0xFF1B2A1E),
                ),
              ),
              onTap: () {
                audioService.setSleepTimer(isOff ? null : dur);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
