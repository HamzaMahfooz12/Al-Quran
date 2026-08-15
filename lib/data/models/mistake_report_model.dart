class MarkedMistake {
  final String wordId; // 'surah:ayah:word_pos'
  final String section; // 'mushaf_15' | 'mushaf_16'
  final DateTime markedAt;
  final int surah;
  final int ayah;
  final int juz;
  final int page;
  final String? surahName;

  const MarkedMistake({
    required this.wordId,
    required this.section,
    required this.markedAt,
    required this.surah,
    required this.ayah,
    required this.juz,
    required this.page,
    this.surahName,
  });

  factory MarkedMistake.fromMap(Map<String, dynamic> map) {
    final wId = map['word_id'] as String? ?? '1:1:1';
    final parts = wId.split(':');
    final s = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 1 : 1;
    final a = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;

    return MarkedMistake(
      wordId: wId,
      section: map['section'] as String? ?? 'mushaf_15',
      markedAt: DateTime.fromMillisecondsSinceEpoch(map['marked_at'] as int? ?? 0),
      surah: map['surah'] as int? ?? s,
      ayah: map['ayah'] as int? ?? a,
      juz: map['juz'] as int? ?? 1,
      page: map['page'] as int? ?? 1,
      surahName: map['surah_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word_id': wordId,
      'section': section,
      'marked_at': markedAt.millisecondsSinceEpoch,
    };
  }
}

class JuzMistakeStat {
  final int juzNumber;
  final String juzName;
  final int mistakeCount;
  final double accuracyPercentage;

  const JuzMistakeStat({
    required this.juzNumber,
    required this.juzName,
    required this.mistakeCount,
    required this.accuracyPercentage,
  });
}

class SurahMistakeStat {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int mistakeCount;

  const SurahMistakeStat({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.mistakeCount,
  });
}
