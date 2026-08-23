// lib/data/models/mutashabiha.dart
// Represents a pair of Mutashabihat (similar Quranic verses)

class Mutashabiha {
  final int srcSurah;
  final int srcAyah;
  final int similarSurah;
  final int similarAyah;
  final int? ctx;
  final int? juz;

  // Populated fields for rich comparative UI
  final String? srcArabic;
  final String? similarArabic;
  final String? srcSurahName;
  final String? similarSurahName;

  const Mutashabiha({
    required this.srcSurah,
    required this.srcAyah,
    required this.similarSurah,
    required this.similarAyah,
    this.ctx,
    this.juz,
    this.srcArabic,
    this.similarArabic,
    this.srcSurahName,
    this.similarSurahName,
  });

  factory Mutashabiha.fromMap(Map<String, dynamic> map) {
    return Mutashabiha(
      srcSurah: map['src_surah'] as int,
      srcAyah: map['src_ayah'] as int,
      similarSurah: map['similar_surah'] as int,
      similarAyah: map['similar_ayah'] as int,
      ctx: map['ctx'] as int?,
      juz: map['juz'] as int?,
      srcArabic: map['src_arabic'] as String?,
      similarArabic: map['similar_arabic'] as String?,
      srcSurahName: map['src_surah_name'] as String?,
      similarSurahName: map['similar_surah_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'src_surah': srcSurah,
      'src_ayah': srcAyah,
      'similar_surah': similarSurah,
      'similar_ayah': similarAyah,
      'ctx': ctx,
      'juz': juz,
    };
  }

  Mutashabiha copyWith({
    String? srcArabic,
    String? similarArabic,
    String? srcSurahName,
    String? similarSurahName,
  }) {
    return Mutashabiha(
      srcSurah: srcSurah,
      srcAyah: srcAyah,
      similarSurah: similarSurah,
      similarAyah: similarAyah,
      ctx: ctx,
      juz: juz,
      srcArabic: srcArabic ?? this.srcArabic,
      similarArabic: similarArabic ?? this.similarArabic,
      srcSurahName: srcSurahName ?? this.srcSurahName,
      similarSurahName: similarSurahName ?? this.similarSurahName,
    );
  }
}
