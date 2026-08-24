// lib/features/ai_teacher/widgets/live_recitation_toolbar.dart
// Sticky floating toolbar for Live AI Recitation with mic visualizer & sensitivity presets
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/mushaf_page_model.dart';
import '../../../services/recitation_engine.dart';
import '../providers/recitation_provider.dart';
import 'recitation_summary_dialog.dart';

class LiveRecitationToolbar extends ConsumerWidget {
  final List<WordLayoutData> pageWords;
  final VoidCallback onClose;

  const LiveRecitationToolbar({
    super.key,
    required this.pageWords,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);
    final notifier = ref.read(recitationProvider.notifier);
    final recorder = ref.watch(recitationAudioRecorderProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Row: Status Badge + Stats + Hifz Toggle + Close ──
          Row(
            children: [
              // Live / Paused / Idle Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isListening
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.isListening ? const Color(0xFF4CAF50) : Colors.white30,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isListening
                            ? const Color(0xFF4CAF50)
                            : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isListening ? 'LISTENING' : 'PAUSED',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: state.isListening
                            ? const Color(0xFF81C784)
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Accuracy counter (only show when words have been recited)
              if (state.totalRecited > 0)
                Flexible(
                  child: Text(
                    'Accuracy: ${state.accuracyPercent.toStringAsFixed(0)}%'
                    ' (${state.correctCount}/${state.totalRecited})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD54F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const Spacer(),

              // Hifz Reveal Mode Toggle
              IconButton(
                icon: Icon(
                  state.isHifzRevealMode
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: state.isHifzRevealMode
                      ? const Color(0xFFFFD54F)
                      : Colors.white70,
                  size: 20,
                ),
                tooltip: state.isHifzRevealMode
                    ? 'Hifz Mode ON (Text Hidden)'
                    : 'Hifz Mode OFF',
                onPressed: notifier.toggleHifzRevealMode,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(width: 4),

              // Session Summary icon (only when recited > 0)
              if (state.totalRecited > 0)
                IconButton(
                  icon: const Icon(Icons.bar_chart_rounded,
                      color: Color(0xFFFFD54F), size: 20),
                  tooltip: 'Session Summary',
                  onPressed: () =>
                      RecitationSummaryDialog.show(context, state: state),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),

              const SizedBox(width: 4),

              // End / Reset Session button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                tooltip: 'End Recitation',
                onPressed: onClose,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Bottom Row: Sensitivity Presets + Big Mic Button ──
          Row(
            children: [
              // Sensitivity Preset Chips
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: RecitationSensitivity.values.map((preset) {
                    final isSelected = state.sensitivity == preset;
                    return ChoiceChip(
                      label: Text(
                        preset.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1B4332)
                              : Colors.white,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFD54F),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      onSelected: (selected) {
                        if (selected && !state.isListening) {
                          notifier.setSensitivity(preset);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 10),

              // ── Microphone Button with Live Amplitude Visualizer ──
              StreamBuilder<double>(
                stream: recorder.amplitudeStream,
                builder: (context, snapshot) {
                  final amp = (snapshot.data ?? 0.0);
                  // Only pulse when actively listening
                  final scale = state.isListening ? 1.0 + (amp * 0.18) : 1.0;

                  return GestureDetector(
                    onTap: () async {
                      if (state.isListening) {
                        // STOP
                        await notifier.stopListening();
                      } else {
                        // START — only if we have words to listen to
                        if (pageWords.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No words loaded for this page yet.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        await notifier.startListening(pageWords);
                      }
                    },
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 80),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isListening
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFD54F),
                          boxShadow: [
                            BoxShadow(
                              color: (state.isListening
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFFD54F))
                                  .withValues(alpha: state.isListening ? 0.55 : 0.3),
                              blurRadius: state.isListening ? 14 : 8,
                              spreadRadius: state.isListening ? 3 : 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isListening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: state.isListening
                              ? Colors.white
                              : const Color(0xFF1B4332),
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Speech detection hint ──
          if (state.isListening)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white38, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Speak a word aloud — it will highlight green when detected.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
