// lib/data/repositories/full_surah_reciter_repository.dart
// Manages loading and filtering of 172+ verified 114-surah reciters

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/full_surah_reciter.dart';

final fullSurahReciterRepositoryProvider = Provider<FullSurahReciterRepository>((ref) {
  return FullSurahReciterRepository();
});

final fullSurahRecitersListProvider = FutureProvider<List<FullSurahReciter>>((ref) async {
  final repo = ref.watch(fullSurahReciterRepositoryProvider);
  return repo.getAllReciters();
});

class FullSurahReciterRepository {
  List<FullSurahReciter>? _cachedReciters;

  /// Loads all reciters from the local JSON asset
  Future<List<FullSurahReciter>> getAllReciters() async {
    if (_cachedReciters != null && _cachedReciters!.isNotEmpty) {
      return _cachedReciters!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/full_surah_reciters.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cachedReciters = jsonList
          .map((item) => FullSurahReciter.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedReciters!;
    } catch (_) {
      // Fallback default list if asset load fails
      _cachedReciters = _kFallbackReciters;
      return _cachedReciters!;
    }
  }

  /// Search reciters by English or Arabic name
  Future<List<FullSurahReciter>> searchReciters(String query) async {
    final all = await getAllReciters();
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.arabicName.contains(q) ||
          r.folderSlug.toLowerCase().contains(q);
    }).toList();
  }

  /// Find specific reciter by ID
  Future<FullSurahReciter> getReciterById(int id) async {
    final all = await getAllReciters();
    return all.firstWhere(
      (r) => r.id == id,
      orElse: () => all.isNotEmpty ? all.first : _kFallbackReciters.first,
    );
  }

  static const FullSurahReciter kDefaultReciter = FullSurahReciter(
    id: 123,
    name: 'Mishary Rashid Alafasy',
    arabicName: 'مشاري راشد العفاسي',
    folderSlug: 'mishaari_raashid_al_3afaasee',
    mp3quranServer: 'https://server8.mp3quran.net/afs/',
    surahTotal: 114,
  );

  static const List<FullSurahReciter> _kFallbackReciters = [
    kDefaultReciter,
    FullSurahReciter(
      id: 102,
      name: 'Maher Al-Muaiqly',
      arabicName: 'ماهر المعيقلي',
      folderSlug: 'maher_almu3aiqly/year1440',
      mp3quranServer: 'https://server12.mp3quran.net/maher/',
      surahTotal: 114,
    ),
    FullSurahReciter(
      id: 92,
      name: 'Yasser Al-Dosari',
      arabicName: 'ياسر الدوسري',
      folderSlug: 'yasser_ad-dussary',
      mp3quranServer: 'https://server11.mp3quran.net/dosry/',
      surahTotal: 114,
    ),
    FullSurahReciter(
      id: 30,
      name: 'Saad Al-Ghamdi',
      arabicName: 'سعد الغامدي',
      folderSlug: 'sa3d_al-ghaamidi/complete',
      mp3quranServer: 'https://server7.mp3quran.net/s_gmd/',
      surahTotal: 114,
    ),
  ];
}
