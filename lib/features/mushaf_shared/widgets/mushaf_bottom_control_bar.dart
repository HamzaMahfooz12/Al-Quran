// lib/features/mushaf_shared/widgets/mushaf_bottom_control_bar.dart
// Premium animated 3-button bottom bar for 15-Line & 16-Line Mushaf (Auto Scroll, Play Audio, Mark Mistakes)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MushafBottomControlBar extends StatelessWidget {
  final bool isAutoScrolling;
  final VoidCallback onToggleAutoScroll;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTogglePlay;
  final bool isMarkMistakesMode;
  final VoidCallback onToggleMarkMistakes;
  final bool isVisible;

  const MushafBottomControlBar({
    super.key,
    required this.isAutoScrolling,
    required this.onToggleAutoScroll,
    required this.isPlaying,
    required this.isBuffering,
    required this.onTogglePlay,
    required this.isMarkMistakesMode,
    required this.onToggleMarkMistakes,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom > 0
        ? mq.viewPadding.bottom
        : (mq.padding.bottom > 0 ? mq.padding.bottom : 0.0);
    final effectiveBottomPad = bottomInset > 0 ? bottomInset + 4.0 : 12.0;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1.4),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF7EE), // Warm Quranic parchment tone matching reference
              Color(0xFFF3EBDB),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: const Border(
            top: BorderSide(color: Color(0xFFDFD4C0), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 6, 20, effectiveBottomPad),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              // ── 1. Left: Auto Scroll Button ───────────────────────────────
              Expanded(
                child: InkWell(
                  onTap: onToggleAutoScroll,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: isAutoScrolling
                              ? BoxDecoration(
                                  color: const Color(0xFF1E3A60).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Icon(
                            isAutoScrolling
                                ? Icons.pause_circle_filled_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: isAutoScrolling ? const Color(0xFF1E3A60) : const Color(0xFF2C3E50),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAutoScrolling ? 'Scrolling' : 'Auto Scroll',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isAutoScrolling ? FontWeight.w700 : FontWeight.w600,
                            color: isAutoScrolling ? const Color(0xFF1E3A60) : const Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 2. Center: Raised Floating Play / Pause Circle ────────────
              Transform.translate(
                offset: const Offset(0, -12),
                child: GestureDetector(
                  onTap: onTogglePlay,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2038), Color(0xFF1E3A60)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A60).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isBuffering
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),

              // ── 3. Right: Mark Mistake / Last Seen Button ───────────────────
              Expanded(
                child: InkWell(
                  onTap: onToggleMarkMistakes,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: isMarkMistakesMode
                              ? BoxDecoration(
                                  color: const Color(0xFF1E3A60).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Icon(
                            isMarkMistakesMode
                                ? Icons.edit_note_rounded
                                : Icons.visibility_outlined,
                            color: isMarkMistakesMode ? const Color(0xFF1E3A60) : const Color(0xFF2C3E50),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMarkMistakesMode ? 'Mistakes ON' : 'Mark Mistakes',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isMarkMistakesMode ? FontWeight.w700 : FontWeight.w600,
                            color: isMarkMistakesMode ? const Color(0xFF1E3A60) : const Color(0xFF2C3E50),
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
      );
  }
}
