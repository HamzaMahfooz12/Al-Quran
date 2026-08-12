// lib/features/audio/audio_control_bar.dart
// Premium sticky Audio Control Bar for Quran verse-by-verse playback
import 'package:flutter/material.dart';
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
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = audioService.speed;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback Speed',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: speeds.map((speed) {
                final isSelected = (currentSpeed == speed);
                return ChoiceChip(
                  label: Text('${speed}x', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF1B4332))),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2D5A34),
                  backgroundColor: const Color(0xFFE8F5E9),
                  onSelected: (selected) {
                    if (selected) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _allReciters.where((r) {
            final nameMatch = r.name.toLowerCase().contains(searchQuery.toLowerCase());
            final styleMatch = r.style?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
            return nameMatch || styleMatch;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Indicator
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Select Audio Reciter',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332)),
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  onChanged: (val) => setModalState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search 188+ Reciters...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2D5A34)),
                    filled: true,
                    fillColor: const Color(0xFFF0F8F1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reciters List
                Expanded(
                  child: _loadingReciters
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A34)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          itemBuilder: (context, idx) {
                            final r = filtered[idx];
                            final isSelected = settings.selectedReciterId == r.id;

                            final langUpper = r.language.toUpperCase();
                            final langLabel = r.language == 'ar'
                                ? 'Arabic'
                                : (r.language == 'en' ? 'English' : (r.language == 'ur' ? 'Urdu' : langUpper));

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2D5A34)
                                      : (r.language == 'ar' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  langUpper,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : (r.language == 'ar' ? const Color(0xFF2D5A34) : const Color(0xFF1565C0)),
                                  ),
                                ),
                              ),
                              title: Text(
                                r.name,
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: const Color(0xFF1B4332),
                                ),
                              ),
                              subtitle: Text(
                                '$langLabel • ${r.style ?? 'Murattal'}',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF2D5A34))
                                  : null,
                              onTap: () async {
                                ref.read(selectedReciterIdProvider.notifier).setReciterId(r.id);
                                final audioService = ref.read(audioServiceProvider);
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
      orElse: () => Reciter(id: selectedReciterId, name: selectedReciterId, style: 'Murattal'),
    ).name;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Top Header Row: Ayah Info & Controls ─────────────────────
          Row(
            children: [
              // Surah & Ayah badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: Color(0xFFA5D6A7), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.surahName} • ${widget.currentAyahNumber}/${widget.totalAyahs}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Reciter Selector Button
              Expanded(
                child: InkWell(
                  onTap: () => _showReciterPicker(context, settings),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.record_voice_over, color: Color(0xFFA5D6A7), size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reciterName,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              // Close Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () {
                  audioService.stop();
                  widget.onClose?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── 2. Live Audio Progress Slider & Timestamps ────────────────────
          StreamBuilder<Duration?>(
            stream: audioService.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;

              return StreamBuilder<Duration?>(
                stream: audioService.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                  final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

                  final remaining = duration > position ? duration - position : Duration.zero;

                  return Column(
                    children: [
                      // Timeline Slider
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFFA5D6A7),
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                          thumbColor: const Color(0xFFA5D6A7),
                          overlayColor: const Color(0xFFA5D6A7).withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentMs,
                          min: 0.0,
                          max: maxMs,
                          onChanged: (val) {
                            audioService.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),

                      // Time Labels (Elapsed vs Remaining)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '-${_formatDuration(remaining)}',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA5D6A7), fontWeight: FontWeight.w500),
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

          const SizedBox(height: 4),

          // ── 3. Playback Controls Toolbar ────────────────────────────────
          StreamBuilder<PlayerState>(
            stream: audioService.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final isPlaying = playerState?.playing ?? false;
              final isBuffering = processingState == ProcessingState.loading || processingState == ProcessingState.buffering;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Playback Speed Button
                  IconButton(
                    icon: Text(
                      '${audioService.speed}x',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFA5D6A7)),
                    ),
                    onPressed: () => _showSpeedMenu(context, audioService),
                    tooltip: 'Playback Speed',
                  ),

                  // Previous Ayah Button
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                    onPressed: widget.onPrevAyah,
                    tooltip: 'Previous Ayah',
                  ),

                  // Main Play / Pause Circle Button
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        audioService.pause();
                      } else {
                        audioService.resume();
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA5D6A7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: isBuffering
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1B4332)),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 30,
                                color: const Color(0xFF1B4332),
                              ),
                      ),
                    ),
                  ),

                  // Next Ayah Button
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                    onPressed: widget.onNextAyah,
                    tooltip: 'Next Ayah',
                  ),

                  // Loop Toggle Button — ON: loop same ayah | OFF: play next ayah
                  IconButton(
                    icon: Icon(
                      audioService.isLooping
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: audioService.isLooping
                          ? const Color(0xFFA5D6A7)
                          : Colors.white60,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        audioService.isLooping = !audioService.isLooping;
                      });
                    },
                    tooltip: audioService.isLooping ? 'Looping this Ayah' : 'Advance to next Ayah',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
