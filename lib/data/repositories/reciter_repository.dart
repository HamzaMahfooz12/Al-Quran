// lib/data/repositories/reciter_repository.dart
// Fetches reciter list from AlQuran Cloud API and caches in SQLite
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../db/db_helper.dart';
import '../models/reciter.dart';

final reciterRepositoryProvider = Provider<ReciterRepository>(
  (ref) => ReciterRepository(DatabaseHelper.instance, Dio()),
);

class ReciterRepository {
  static const _apiUrl =
      'https://api.alquran.cloud/v1/edition/format/audio';

  final DatabaseHelper _db;
  final Dio _dio;

  ReciterRepository(this._db, this._dio);

  static const _orderBy = "CASE WHEN language = 'ar' THEN 0 ELSE 1 END ASC, language ASC, name ASC";



  static const Set<String> validReciterIds = {
    'ar.alafasy',
    'ar.abdurrahmaansudais',
    'ar.abdulbasitmurattal',
    'ar.shaatree',
    'ar.ahmedajamy',
    'ar.husary',
    'ar.husarymujawwad',
    'ar.hudhaify',
    'ar.mahermuaiqly',
    'ar.minshawi',
    'ar.minshawimujawwad',
    'ar.muhammadayyoub',
    'ar.muhammadjibreel',
    'ar.hanirifai',
    'ar.abdullahbasfar',
    'ar.aymanswoaid',
    'ar.ibrahimakhbar',
    'ar.saoodshuraym',
    'ar.abdulsamad',
    'en.walk',
    'fr.leclerc',
    'ru.kuliev-audio',
    'tr.vakfi-audio',
    'zh.chinese',
    'kk.khalifahaltai-audio',
  };

  /// Returns reciters from local cache; fetches from API if cache is empty.
  Future<List<Reciter>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final cached = await _db.query('reciters', orderBy: _orderBy);
        if (cached.isNotEmpty) {
          final list = cached.map(Reciter.fromMap).where((r) => validReciterIds.contains(r.id)).toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {
        // Table column migration fallback
      }
    }
    return _fetchAndCache();
  }

  Future<List<Reciter>> _fetchAndCache() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      final data = response.data;
      if (data == null || data['status'] != 'OK') return [];

      final items = (data['data'] as List).cast<Map<String, dynamic>>();
      final reciters = items
          .map(Reciter.fromApi)
          .where((r) => validReciterIds.contains(r.id))
          .toList();

      // Cache in SQLite
      final db = await _db.database;
      try {
        await db.execute("ALTER TABLE reciters ADD COLUMN language TEXT NOT NULL DEFAULT 'ar'");
      } catch (_) {}

      // Purge stale broken reciters
      final validPlaceholders = List.filled(validReciterIds.length, '?').join(',');
      await db.delete(
        'reciters',
        where: 'id NOT IN ($validPlaceholders)',
        whereArgs: validReciterIds.toList(),
      );

      final batch = db.batch();
      for (final r in reciters) {
        batch.insert('reciters', r.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      reciters.sort((a, b) {
        final aAr = a.language == 'ar' ? 0 : 1;
        final bAr = b.language == 'ar' ? 0 : 1;
        if (aAr != bAr) return aAr.compareTo(bAr);
        return a.name.compareTo(b.name);
      });

      return reciters;
    } catch (_) {
      try {
        final cached = await _db.query('reciters', orderBy: _orderBy);
        return cached.map(Reciter.fromMap).where((r) => validReciterIds.contains(r.id)).toList();
      } catch (_) {
        return [];
      }
    }
  }
}
