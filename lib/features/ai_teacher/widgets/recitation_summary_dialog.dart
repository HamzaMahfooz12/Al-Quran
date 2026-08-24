// lib/features/ai_teacher/widgets/recitation_summary_dialog.dart
// Session completion summary score card with mistakes list and audio playback
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/audio_service.dart';
import '../providers/recitation_provider.dart';

class RecitationSummaryDialog extends ConsumerWidget {
  final RecitationSessionState state;

  const RecitationSummaryDialog({
    super.key,
    required this.state,
  });

  static Future<void> show(BuildContext context, {required RecitationSessionState state}) {
    return showDialog(
      context: context,
      builder: (ctx) => RecitationSummaryDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = state.mistakesList;
    final accuracy = state.accuracyPercent.toStringAsFixed(0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Center(
              child: Text(
                'Recitation Summary',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Big Circular Accuracy Badge
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(
                    color: (state.accuracyPercent >= 85)
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$accuracy%',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        'Accuracy',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Quick Stat Tiles
            Row(
              children: [
                _statTile('Total Recited', '${state.totalRecited} words', const Color(0xFF1B4332)),
                const SizedBox(width: 8),
                _statTile('Correct', '${state.correctCount}', const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                _statTile('Mistakes', '${state.mistakeCount}', const Color(0xFFD32F2F)),
              ],
            ),

            const SizedBox(height: 16),

            // Mistakes Review section (if any)
            if (mistakes.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Words to Revise (${mistakes.length}):',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECE9)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: mistakes.length,
                  separatorBuilder: (context, index) => const Divider(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = mistakes[i];
                    final surahInfo = kSurahList.firstWhere(
                      (s) => s.number == item.surah,
                      orElse: () => kSurahList.first,
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.originalText,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Scheherazade New',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              Text(
                                '${surahInfo.nameTransliteration} (${item.surah}:${item.ayah})',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF1B4332)),
                          tooltip: 'Listen to Sheikh As-Sudais',
                          onPressed: () async {
                            final repo = ref.read(quranRepositoryProvider);
                            final audio = ref.read(audioServiceProvider);
                            final ayahData = await repo.getAyah(item.surah, item.ayah);
                            if (ayahData != null) {
                              await audio.playAyah(
                                globalAyahNumber: ayahData.id,
                                surah: item.surah,
                                ayahInSurah: item.ayah,
                                reciterId: 'ar.abdurrahmaansudais',
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
