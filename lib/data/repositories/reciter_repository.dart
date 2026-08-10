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

  /// Returns reciters from local cache; fetches from API if cache is empty.
  Future<List<Reciter>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _db.query('reciters', orderBy: 'name ASC');
      if (cached.isNotEmpty) {
        return cached.map(Reciter.fromMap).toList();
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
      final reciters = items.map(Reciter.fromApi).toList();

      // Cache in SQLite
      final db = await _db.database;
      final batch = db.batch();
      for (final r in reciters) {
        batch.insert('reciters', r.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      return reciters;
    } catch (_) {
      // Return whatever is cached (may be empty)
      final cached = await _db.query('reciters', orderBy: 'name ASC');
      return cached.map(Reciter.fromMap).toList();
    }
  }
}
