// lib/features/audio/audio_control_bar.dart
// Unified Compact Audio Player Bar matching the official Islamic green & orange design specification

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/reciter.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';

class AudioControlBar extends ConsumerStatefulWidget {
  final int surahNumber;
  final String surahName;
  final int currentAyahNumber;
  final int totalAyahs;
  final VoidCallback? onNextAyah;
  final VoidCallback? onPrevAyah;
  final VoidCallback? onClose;

  const AudioControlBar({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.currentAyahNumber,
    required this.totalAyahs,
    this.onNextAyah,
    this.onPrevAyah,
    this.onClose,
  });

  @override
  ConsumerState<AudioControlBar> createState() => _AudioControlBarState();
}

class _AudioControlBarState extends ConsumerState<AudioControlBar> {
  List<Reciter> _allReciters = [];
  bool _loadingReciters = false;

  @override
  void initState() {
    super.initState();
    _loadReciters();
  }

  Future<void> _loadReciters() async {
    setState(() => _loadingReciters = true);
    final repo = ref.read(reciterRepositoryProvider);
    final reciters = await repo.getReciters();
    if (mounted) {
      setState(() {
        _allReciters = reciters;
        _loadingReciters = false;
      });
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showSpeedMenu(BuildContext context, QuranAudioService audioService) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = audioService.speed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.speed_rounded,
                      color: Color(0xFF2C7A39), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Playback Speed',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2A1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: speeds.map((speed) {
                final isSelected = (currentSpeed == speed);
                return ChoiceChip(
                  label: Text(
                    '${speed}x',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color:
                          isSelected ? Colors.white : const Color(0xFF1B4332),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2C7A39),
                  backgroundColor: const Color(0xFFF2F8F4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2C7A39)
                          : const Color(0xFFD3E7D7),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.lightImpact();
                      audioService.setSpeed(speed);
                      setState(() {});
                      Navigator.pop(ctx);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(BuildContext context, SettingsService settings) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _allReciters.where((r) {
            final nameMatch =
                r.name.toLowerCase().contains(searchQuery.toLowerCase());
            final styleMatch = r.style
                    ?.toLowerCase()
                    .contains(searchQuery.toLowerCase()) ??
                false;
            return nameMatch || styleMatch;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.record_voice_over_rounded,
                          color: Color(0xFF2C7A39), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Reciter (قاری)',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B2A1E),
                          ),
                        ),
                        Text(
                          'Select audio reciter for ayah playback',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  onChanged: (val) => setModalState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search reciters...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13.5, color: const Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF2C7A39), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4FAF5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD6E8DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD6E8DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF2C7A39), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reciters List
                Expanded(
                  child: _loadingReciters
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2C7A39)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (c, i) => const Divider(
                              height: 1, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, idx) {
                            final r = filtered[idx];
                            final isSelected =
                                settings.selectedReciterId == r.id;

                            final langUpper = r.language.toUpperCase();
                            final langLabel = r.language == 'ar'
                                ? 'Arabic'
                                : (r.language == 'en'
                                    ? 'English'
                                    : (r.language == 'ur'
                                        ? 'Urdu'
                                        : langUpper));

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2C7A39)
                                      : const Color(0xFFEAF6EC),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    langUpper,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C7A39),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                r.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: const Color(0xFF1B2A1E),
                                ),
                              ),
                              subtitle: Text(
                                '$langLabel • ${r.style ?? 'Murattal'}',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280)),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF2C7A39), size: 22)
                                  : null,
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(selectedReciterIdProvider.notifier)
                                    .setReciterId(r.id);
                                final audioService =
                                    ref.read(audioServiceProvider);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                await audioService.setReciterAndReplay(r.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final settings = ref.watch(settingsServiceProvider);
    final selectedReciterId = ref.watch(selectedReciterIdProvider);
    final reciterName = _allReciters.firstWhere(
      (r) => r.id == selectedReciterId,
      orElse: () => Reciter(
          id: selectedReciterId, name: 'Mishary Alafasi', style: 'Murattal'),
    ).name;

    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom > 0
        ? mq.viewPadding.bottom
        : (mq.padding.bottom > 0 ? mq.padding.bottom : 0.0);
    final effectiveBottomPad = math.max(bottomInset, 8.0) + 8.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E5B2E), // Rich Islamic Forest Green
            Color(0xFF134221), // Deep Emerald Shadow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF2C7A39).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, effectiveBottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main Compact Control Row (Matching Reference Image 1) ────────
          Row(
            children: [
              // 1. Ornamental 8-Point Scalloped Medallion Badge (Left)
              _IslamicMedallionBadge(number: widget.surahNumber),

              const SizedBox(width: 10),

              // 2. Surah Title & Tappable Reciter Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Surah Name (e.g. Surah An-Nisa or Al-Fatiha • 2/7)
                    Text(
                      widget.surahName.startsWith('Surah')
                          ? widget.surahName
                          : 'Surah ${widget.surahName}',
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Reciter Name with dropdown arrow (Tappable)
                    InkWell(
                      onTap: () => _showReciterPicker(context, settings),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reciterName,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD4ECD8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFD4ECD8),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Playback Speed Button (1.0x)
              InkWell(
                onTap: () => _showSpeedMenu(context, audioService),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${audioService.speed}x',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFEF3C7),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 4. Repeat / Loop Toggle Button
              IconButton(
                icon: Icon(
                  audioService.isLooping
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: audioService.isLooping
                      ? const Color(0xFFFFA000)
                      : Colors.white60,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    audioService.isLooping = !audioService.isLooping;
                  });
                },
                tooltip: audioService.isLooping
                    ? 'Looping current Ayah'
                    : 'Repeat Off',
              ),

              // 5. Skip Previous
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded,
                    color: Colors.white, size: 24),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: widget.onPrevAyah,
                tooltip: 'Previous Ayah',
              ),

              // 6. Circular Vibrant Orange Play / Pause Button (Centerpiece)
              StreamBuilder<PlayerState>(
                stream: audioService.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final isPlaying = playerState?.playing ?? false;
                  final isBuffering =
                      processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isPlaying) {
                        audioService.pause();
                      } else {
                        audioService.resume();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFA000), // Vibrant Amber-Orange
                            Color(0xFFF59E0B), // Glowing Gold Accent
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA000)
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isBuffering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF134221),
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 26,
                                color: const Color(0xFF134221),
                              ),
                      ),
                    ),
                  );
                },
              ),

              // 7. Skip Next
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: Colors.white, size: 24),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                onPressed: widget.onNextAyah,
                tooltip: 'Next Ayah',
              ),

              // 8. Close Button
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white60, size: 18),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  audioService.stop();
                  widget.onClose?.call();
                },
                tooltip: 'Close player',
              ),
            ],
          ),

          // ── Live Progress Slider & Time Labels (Matching Reference Image 2) ──
          StreamBuilder<Duration?>(
            stream: audioService.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;

              return StreamBuilder<Duration?>(
                stream: audioService.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  final currentMs =
                      position.inMilliseconds.toDouble().clamp(0.0, maxMs);
                  final remaining = duration > position
                      ? duration - position
                      : Duration.zero;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thin Vibrant Orange Slider
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2.8,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5.5),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10),
                          activeTrackColor: const Color(0xFFFFA000),
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.22),
                          thumbColor: const Color(0xFFFFA000),
                          overlayColor: const Color(0xFFFFA000)
                              .withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentMs,
                          min: 0.0,
                          max: maxMs,
                          onChanged: (val) {
                            audioService
                                .seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),

                      // Time Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '-${_formatDuration(remaining)}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFFFEF3C7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Ornamental 8-Point Scalloped Medallion Badge ──────────────────────────────
class _IslamicMedallionBadge extends StatelessWidget {
  final int number;

  const _IslamicMedallionBadge({
    required this.number,
  });

  static const double size = 42.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 45-degree rotated rounded square
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: size * 0.74,
              height: size * 0.74,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9EE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          // 0-degree square
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
          ),
          // Center Number
          Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF8D4913),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
