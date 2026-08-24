// lib/services/recitation_engine.dart
// Real-time Quranic Recitation Alignment & Phonetic Verification Engine
import 'dart:math';

enum RecitationSensitivity {
  beginner(
    name: 'Beginner & Kids',
    threshold: 0.45,
    maxPauseSeconds: 2.5,
    description: 'Generous timing and gentle matching for children & learners',
  ),
  standard(
    name: 'Standard',
    threshold: 0.60,
    maxPauseSeconds: 1.6,
    description: 'Balanced matching for regular everyday recitation',
  ),
  hafiz(
    name: 'Hafiz / Strict',
    threshold: 0.75,
    maxPauseSeconds: 1.0,
    description: 'Precise matching for fluent memorization revision',
  );

  final String name;
  final double threshold;
  final double maxPauseSeconds;
  final String description;

  const RecitationSensitivity({
    required this.name,
    required this.threshold,
    required this.maxPauseSeconds,
    required this.description,
  });
}

enum RecitationWordStatus {
  pending,
  active,
  correct,
  mistake,
}

class RecitationWordResult {
  final String wordId; // e.g. '1:1:1'
  final int surah;
  final int ayah;
  final int wordPos;
  final String originalText;
  final RecitationWordStatus status;
  final double confidence;
  final bool isOverridden;

  const RecitationWordResult({
    required this.wordId,
    required this.surah,
    required this.ayah,
    required this.wordPos,
    required this.originalText,
    required this.status,
    this.confidence = 1.0,
    this.isOverridden = false,
  });

  RecitationWordResult copyWith({
    RecitationWordStatus? status,
    double? confidence,
    bool? isOverridden,
  }) {
    return RecitationWordResult(
      wordId: wordId,
      surah: surah,
      ayah: ayah,
      wordPos: wordPos,
      originalText: originalText,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      isOverridden: isOverridden ?? this.isOverridden,
    );
  }
}

class RecitationEngine {
  RecitationSensitivity sensitivity = RecitationSensitivity.standard;

  /// Normalizes Arabic text into a clean phonetic skeleton for robust speech matching
  static String normalizeArabicText(String text) {
    var s = text.trim();
    // 1. Remove all Arabic diacritics / harakat / tashkeel
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0610-\u061A]'), '');
    // 2. Remove punctuation and Quranic pause marks
    s = s.replaceAll(RegExp(r'[\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\uFD3E\uFD3F]'), '');
    s = s.replaceAll(RegExp(r'[.,;!?"()\[\]{}–—]'), '');
    // 3. Normalize Alif variations (أ, إ, آ, ٱ -> ا)
    s = s.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // 4. Normalize Ya and Alif Maqsura (ى -> ي)
    s = s.replaceAll('ى', 'ي');
    // 5. Normalize Ta Marbuta (ة -> ه)
    s = s.replaceAll('ة', 'ه');
    // 6. Normalize Hamza forms (ؤ, ئ -> ء)
    s = s.replaceAll(RegExp(r'[ؤئ]'), 'ء');
    // 7. Remove Tatweel / Kashida
    s = s.replaceAll('ـ', '');
    return s.trim();
  }

  /// Calculates phonetic similarity score [0.0 to 1.0] using Levenshtein distance
  static double calculateSimilarity(String spoken, String expected) {
    final sNorm = normalizeArabicText(spoken);
    final eNorm = normalizeArabicText(expected);

    if (sNorm.isEmpty && eNorm.isEmpty) return 1.0;
    if (sNorm.isEmpty || eNorm.isEmpty) return 0.0;
    if (sNorm == eNorm) return 1.0;

    final distance = _levenshteinDistance(sNorm, eNorm);
    final maxLen = max(sNorm.length, eNorm.length);
    if (maxLen == 0) return 1.0;

    return ((maxLen - distance) / maxLen).clamp(0.0, 1.0);
  }

  static int _levenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    final d = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        d[i][j] = min(
          min(d[i - 1][j] + 1, d[i][j - 1] + 1),
          d[i - 1][j - 1] + cost,
        );
      }
    }
    return d[m][n];
  }
}
