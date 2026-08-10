// ─────────────────────────────────────────────────────────────────────────────
// lib/data/models/ayah.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int id;
  final int surah;
  final int ayahNumber;
  final int juz;
  final int hizb;
  final int ruku;
  final int manzil;
  final int page;
  final bool isSajda;
  final String arabicText;

  const Ayah({
    required this.id,
    required this.surah,
    required this.ayahNumber,
    required this.juz,
    required this.hizb,
    required this.ruku,
    required this.manzil,
    required this.page,
    required this.isSajda,
    required this.arabicText,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] as int,
      surah: map['surah'] as int,
      ayahNumber: map['ayah_number'] as int,
      juz: map['juz'] as int,
      hizb: map['hizb'] as int,
      ruku: map['ruku'] as int,
      manzil: map['manzil'] as int,
      page: map['page'] as int,
      isSajda: (map['is_sajda'] as int) == 1,
      arabicText: map['arabic_text'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'surah': surah,
        'ayah_number': ayahNumber,
        'juz': juz,
        'hizb': hizb,
        'ruku': ruku,
        'manzil': manzil,
        'page': page,
        'is_sajda': isSajda ? 1 : 0,
        'arabic_text': arabicText,
      };

  @override
  List<Object?> get props => [id];
}
