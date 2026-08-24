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
        color: const Color(0xFF1B4332).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Status, Stats, Hifz Mode Toggle, and Close
          Row(
            children: [
              // Live Pulse Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isListening
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.12),
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
                        color: state.isListening ? const Color(0xFF4CAF50) : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isListening ? 'LISTENING' : 'PAUSED',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: state.isListening ? const Color(0xFF81C784) : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Accuracy Counter
              if (state.totalRecited > 0)
                Text(
                  'Accuracy: ${state.accuracyPercent.toStringAsFixed(0)}% (${state.correctCount}/${state.totalRecited})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFD54F),
                  ),
                ),

              const Spacer(),

              // Hifz Reveal Mode Toggle
              IconButton(
                icon: Icon(
                  state.isHifzRevealMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: state.isHifzRevealMode ? const Color(0xFFFFD54F) : Colors.white70,
                  size: 20,
                ),
                tooltip: state.isHifzRevealMode ? 'Hifz Mode ON (Text Hidden)' : 'Hifz Mode OFF',
                onPressed: notifier.toggleHifzRevealMode,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(width: 6),

              // Close / Finish Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                tooltip: 'End Recitation',
                onPressed: () {
                  if (state.totalRecited > 0) {
                    RecitationSummaryDialog.show(context, state: state);
                  }
                  notifier.resetSession();
                  onClose();
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom Row: Sensitivity Preset Chips + Mic Toggle Button
          Row(
            children: [
              // Sensitivity Preset Chips
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: RecitationSensitivity.values.map((preset) {
                    final isSelected = state.sensitivity == preset;
                    return ChoiceChip(
                      label: Text(
                        preset.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1B4332) : Colors.white,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFD54F),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      onSelected: (selected) {
                        if (selected) notifier.setSensitivity(preset);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 8),

              // Big Mic Button with Live Amplitude
              StreamBuilder<double>(
                stream: recorder.amplitudeStream,
                builder: (context, snapshot) {
                  final amp = snapshot.data ?? 0.0;
                  final scale = 1.0 + (state.isListening ? amp * 0.25 : 0.0);

                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: () {
                        if (state.isListening) {
                          notifier.stopListening();
                        } else {
                          notifier.startListening(pageWords);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isListening ? const Color(0xFF4CAF50) : const Color(0xFFFFD54F),
                          boxShadow: [
                            BoxShadow(
                              color: (state.isListening ? const Color(0xFF4CAF50) : const Color(0xFFFFD54F))
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: state.isListening ? Colors.white : const Color(0xFF1B4332),
                          size: 26,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
