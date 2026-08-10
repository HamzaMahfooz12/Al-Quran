// lib/data/db/quran_seeder.dart
// Downloads Arabic text + full default translations & tafseer from AlQuran Cloud API
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class QuranSeeder {
  final DatabaseHelper _db;
  final Dio _dio;

  // Callback to report progress 0.0 → 1.0
  final void Function(double progress, String message)? onProgress;

  QuranSeeder(this._db, this._dio, {this.onProgress});

  static const _base = 'https://api.alquran.cloud/v1/quran';

  // Bundled editions to ensure 100% downloaded on first launch
  static const _bundledEditions = [
    {'api_key': 'quran-uthmani', 'type': 'arabic', 'language': 'ar', 'name': 'Uthmani Arabic'},
    {'api_key': 'ur.jalandhry', 'type': 'translation', 'language': 'ur', 'name': 'Fateh Muhammad Jalandhry'},
    {'api_key': 'ur.ahmedali', 'type': 'translation', 'language': 'ur', 'name': 'Ahmed Ali'},
    {'api_key': 'en.sahih', 'type': 'translation', 'language': 'en', 'name': 'Sahih International'},
    {'api_key': 'ur.jalalayn', 'type': 'tafseer', 'language': 'ur', 'name': 'Tafseer Jalalayn (Urdu)'},
  ];

  Future<bool> isAlreadySeeded() => _db.isSeeded();

  /// Full seeding process
  Future<void> seed() async {
    final alreadySeeded = await isAlreadySeeded();
    if (alreadySeeded) return;

    onProgress?.call(0.0, 'Preparing Quran text...');

    // 1. Download Arabic text (source of truth for all 6236 ayahs)
    await _downloadEdition('quran-uthmani', isArabic: true);
    onProgress?.call(0.3, 'Arabic text ready...');

    // 2. Download bundled translations & tafseer
    final editionsToFetch = _bundledEditions.where((e) => e['type'] != 'arabic').toList();
    for (int i = 0; i < editionsToFetch.length; i++) {
      final ed = editionsToFetch[i];
      onProgress?.call(
        0.3 + (0.7 * ((i + 1) / editionsToFetch.length)),
        'Downloading ${ed['name']}...',
      );
      await _downloadEdition(ed['api_key']!, editionType: ed['type']!, language: ed['language']!, name: ed['name']!);
    }

    onProgress?.call(1.0, 'Ready!');
  }

  Future<void> _downloadEdition(
    String apiKey, {
    bool isArabic = false,
    String editionType = 'translation',
    String language = 'en',
    String name = '',
  }) async {
    try {
      final url = '$_base/$apiKey';
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;

      if (data == null || data['status'] != 'OK') return;

      final surahs = (data['data']['surahs'] as List).cast<Map<String, dynamic>>();

      int editionId = 0;
      if (!isArabic) {
        editionId = await _upsertEdition(
          apiKey: apiKey,
          type: editionType,
          language: language,
          name: name.isNotEmpty ? name : apiKey,
        );
      }

      final db = await _db.database;
      final batch = db.batch();

      for (final surah in surahs) {
        final surahNum = surah['number'] as int;
        final ayahs = (surah['ayahs'] as List).cast<Map<String, dynamic>>();

        for (final ayah in ayahs) {
          final ayahNumber = ayah['numberInSurah'] as int;
          final text = ayah['text'] as String;
          final number = ayah['number'] as int; // global ayah number 1-6236

          if (isArabic) {
            batch.insert(
              'ayahs',
              {
                'id': number,
                'surah': surahNum,
                'ayah_number': ayahNumber,
                'juz': ayah['juz'] as int? ?? 1,
                'hizb': ayah['hizbQuarter'] as int? ?? 1,
                'ruku': ayah['ruku'] as int? ?? 1,
                'manzil': ayah['manzil'] as int? ?? 1,
                'page': ayah['page'] as int? ?? 1,
                'is_sajda': (ayah['sajda'] != null && ayah['sajda'] != false) ? 1 : 0,
                'arabic_text': text,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            batch.insert(
              'ayah_content',
              {
                'ayah_id': number,
                'edition_id': editionId,
                'text': text,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }

      await batch.commit(noResult: true);

      if (!isArabic) {
        await _db.update(
          'editions',
          {'is_downloaded': 1},
          where: 'id = ?',
          whereArgs: [editionId],
        );
      }
    } catch (e) {
      // Log or handle error gracefully
    }
  }

  Future<int> _upsertEdition({
    required String apiKey,
    required String type,
    required String language,
    required String name,
  }) async {
    final rows = await _db.query(
      'editions',
      where: 'api_key = ?',
      whereArgs: [apiKey],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first['id'] as int;
    }

    return await _db.insert('editions', {
      'type': type,
      'language': language,
      'name': name,
      'api_key': apiKey,
      'is_bundled': 1,
      'is_downloaded': 1,
    });
  }
}
