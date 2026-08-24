// lib/features/ai_teacher/widgets/word_correction_sheet.dart
// Interactive bottom sheet for false-alarm overrides and listening to Qari pronunciation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/audio_service.dart';
import '../../../services/recitation_engine.dart';
import '../providers/recitation_provider.dart';

class WordCorrectionSheet extends ConsumerStatefulWidget {
  final RecitationWordResult wordResult;

  const WordCorrectionSheet({
    super.key,
    required this.wordResult,
  });

  static Future<void> show(BuildContext context, RecitationWordResult wordResult) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => WordCorrectionSheet(wordResult: wordResult),
    );
  }

  @override
  ConsumerState<WordCorrectionSheet> createState() => _WordCorrectionSheetState();
}

class _WordCorrectionSheetState extends ConsumerState<WordCorrectionSheet> {
  bool _playingQari = false;

  Future<void> _playQariAudio(String reciterId) async {
    setState(() => _playingQari = true);
    final repo = ref.read(quranRepositoryProvider);
    final audio = ref.read(audioServiceProvider);

    final ayahData = await repo.getAyah(widget.wordResult.surah, widget.wordResult.ayah);
    if (ayahData != null) {
      await audio.playAyah(
        globalAyahNumber: ayahData.id,
        surah: widget.wordResult.surah,
        ayahInSurah: widget.wordResult.ayah,
        reciterId: reciterId,
      );
    }
    if (mounted) setState(() => _playingQari = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wordResult;
    final surahInfo = kSurahList.firstWhere(
      (s) => s.number == w.surah,
      orElse: () => kSurahList.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF5350)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 4),
                    Text(
                      'Flagged Word',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${surahInfo.nameTransliteration} (${w.surah}:${w.ayah})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Word Display Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE3)),
            ),
            child: Center(
              child: Text(
                w.originalText,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Scheherazade New',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action 1: False Alarm Override ("I recited this correctly")
          ElevatedButton.icon(
            onPressed: () {
              ref.read(recitationProvider.notifier).overrideWordAsCorrect(w.wordId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Word marked as correct! Score updated.'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('I Recited This Correctly (False Alarm)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 10),

          // Action 2: Listen to Sheikh Abdur-Rahman As-Sudais
          OutlinedButton.icon(
            onPressed: _playingQari ? null : () => _playQariAudio('ar.abdurrahmaansudais'),
            icon: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF1B4332)),
            label: const Text('Listen to Sheikh Abdur-Rahman As-Sudais'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B4332),
              side: const BorderSide(color: Color(0xFF2D5A34), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 8),

          // Action 3: Listen to Sheikh Mishary Alafasy
          OutlinedButton.icon(
            onPressed: _playingQari ? null : () => _playQariAudio('ar.alafasy'),
            icon: const Icon(Icons.volume_up_outlined, size: 18, color: AppTheme.textSecondary),
            label: const Text('Listen to Sheikh Mishary Alafasy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: Color(0xFFD0DDD2)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
