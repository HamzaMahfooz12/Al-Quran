// lib/data/repositories/quran_repository.dart
// All local data access — Arabic text, translations, tafseers, bookmarks, last read
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../db/db_helper.dart';
import '../models/ayah.dart';
import '../models/edition.dart';
import '../models/bookmark.dart';

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(DatabaseHelper.instance),
);

class QuranRepository {
  final DatabaseHelper _db;
  QuranRepository(this._db);

  Future<List<Ayah>> getAyahsBySurah(int surah) async {
    final rows = await _db.query(
      'ayahs',
      where: 'surah = ?',
      whereArgs: [surah],
      orderBy: 'ayah_number ASC',
    );
    if (rows.isNotEmpty) {
      return rows.map(Ayah.fromMap).toList();
    }

    try {
      final dio = Dio();
      final res = await dio.get('https://api.alquran.cloud/v1/surah/$surah/quran-uthmani');
      if (res.data != null && res.data['data'] != null && res.data['data']['ayahs'] != null) {
        final list = (res.data['data']['ayahs'] as List).cast<Map<String, dynamic>>();
        final db = await _db.database;
        final batch = db.batch();
        for (final item in list) {
          final gId = item['number'] as int;
          final aNum = item['numberInSurah'] as int;
          final juz = item['juz'] as int;
          final hizb = item['hizbQuarter'] as int;
          final ruku = item['ruku'] as int;
          final manzil = item['manzil'] as int;
          final page = item['page'] as int;
          final isSajda = item['sajda'] == true || item['sajda'] is Map ? 1 : 0;
          final text = item['text'] as String;

          batch.insert('ayahs', {
            'id': gId,
            'surah': surah,
            'ayah_number': aNum,
            'juz': juz,
            'hizb': hizb,
            'ruku': ruku,
            'manzil': manzil,
            'page': page,
            'is_sajda': isSajda,
            'arabic_text': text,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);

        final newRows = await _db.query(
          'ayahs',
          where: 'surah = ?',
          whereArgs: [surah],
          orderBy: 'ayah_number ASC',
        );
        return newRows.map(Ayah.fromMap).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Ayah>> getAyahsByJuz(int juz) async {
    final rows = await _db.query(
      'ayahs',
      where: 'juz = ?',
      whereArgs: [juz],
      orderBy: 'id ASC',
    );
    return rows.map(Ayah.fromMap).toList();
  }

  Future<Ayah?> getAyah(int surah, int ayah) async {
    final rows = await _db.query(
      'ayahs',
      where: 'surah = ? AND ayah_number = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );
    return rows.isEmpty ? null : Ayah.fromMap(rows.first);
  }

  Future<List<int>> getSajdaAyahIds() async {
    final rows = await _db.query(
      'ayahs',
      where: 'is_sajda = 1',
    );
    return rows.map((r) => r['id'] as int).toList();
  }

  // ── Translations / Tafseer ────────────────────────────────────────────────
  Future<String?> getContent(int ayahId, int editionId) async {
    final rows = await _db.query(
      'ayah_content',
      where: 'ayah_id = ? AND edition_id = ?',
      whereArgs: [ayahId, editionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['text'] as String;
  }

  Future<Map<int, String>> getContentBulk(
      List<int> ayahIds, int editionId) async {
    if (ayahIds.isEmpty) return {};
    final placeholders = ayahIds.map((_) => '?').join(',');

    final rows = await _db.rawQuery(
      'SELECT ayah_id, text FROM ayah_content '
      'WHERE edition_id = ? AND ayah_id IN ($placeholders)',
      [editionId, ...ayahIds],
    );

    return {
      for (final row in rows) row['ayah_id'] as int: row['text'] as String
    };
  }

  // ── Editions ──────────────────────────────────────────────────────────────
  Future<List<Edition>> getAvailableEditions({String? type, String? language}) async {
    String where = 'is_bundled = 1 OR is_downloaded = 1';
    final args = <Object?>[];
    if (type != null) {
      where += ' AND type = ?';
      args.add(type);
    }
    if (language != null) {
      where += ' AND language = ?';
      args.add(language);
    }
    final rows = await _db.query('editions', where: where, whereArgs: args);
    return rows.map(Edition.fromMap).toList();
  }

  Future<List<Edition>> getAllEditions({String? type, String? language}) async {
    final db = await _db.database;

    // Delete any invalid audio reciter entries saved under translation type
    await db.rawDelete(
      "DELETE FROM ayah_content WHERE edition_id IN (SELECT id FROM editions WHERE api_key LIKE '%taqi%' OR api_key IN ('ur.tariqmasood', 'quran-uthmani'))",
    );
    await db.rawDelete(
      "DELETE FROM editions WHERE api_key LIKE '%taqi%' OR api_key IN ('ur.tariqmasood', 'quran-uthmani')",
    );

    String? where;
    List<Object?>? whereArgs;

    if (type != null && language != null) {
      where = 'type = ? AND language = ?';
      whereArgs = [type, language];
    } else if (type != null) {
      where = 'type = ?';
      whereArgs = [type];
    } else if (language != null) {
      where = 'language = ?';
      whereArgs = [language];
    }

    final rows = await _db.query(
      'editions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_downloaded DESC, is_bundled DESC, name ASC',
    );
    return rows.map(Edition.fromMap).toList();
  }

  /// Fetches all worldwide editions of a given type ('translation' or 'tafseer')
  Future<List<Edition>> fetchAndSyncApiEditions(String type) async {
    if (type == 'translation') {
      try {
        final dio = Dio();
        final response = await dio.get('https://api.alquran.cloud/v1/edition/type/translation');
        if (response.data != null && response.data['status'] == 'OK') {
          final items = (response.data['data'] as List).cast<Map<String, dynamic>>();

          final db = await _db.database;
          final batch = db.batch();

          for (final item in items) {
            final apiKey = item['identifier'] as String? ?? '';
            final name = item['name'] as String? ?? item['englishName'] as String? ?? '';
            final language = item['language'] as String? ?? 'en';

            // Skip invalid translation keys that return Arabic text
            if (apiKey == 'ur.taqi' || apiKey == 'ur.tariqmasood' || apiKey == 'quran-uthmani') {
              continue;
            }

            batch.insert(
              'editions',
              {
                'type': 'translation',
                'language': language,
                'name': name,
                'api_key': apiKey,
                'is_bundled': 0,
                'is_downloaded': 0,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          await batch.commit(noResult: true);
        }
      } catch (_) {}
    }

    return getAllEditions(type: type);
  }

  Future<void> markEditionDownloaded(int editionId) async {
    await _db.update(
      'editions',
      {'is_downloaded': 1},
      where: 'id = ?',
      whereArgs: [editionId],
    );
  }

  Future<void> deleteEditionContent(int editionId) async {
    final db = await _db.database;
    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      await db.delete(
        'ayah_content',
        where: 'edition_id = ?',
        whereArgs: [editionId],
      );
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }

  Future<void> insertEditionContent(
      List<Map<String, dynamic>> rows) async {
    final db = await _db.database;
    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      final batch = db.batch();
      for (final row in rows) {
        batch.insert('ayah_content', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }

  // ── Last Read ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getLastRead(String section) async {
    final rows = await _db.query(
      'last_read',
      where: 'section = ?',
      whereArgs: [section],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveLastRead({
    required String section,
    int? surah,
    int? ayah,
    int? page,
  }) async {
    await _db.insert('last_read', {
      'section': section,
      'surah': surah,
      'ayah': ayah,
      'page': page,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────
  Future<List<Bookmark>> getAllBookmarks() async {
    final rows =
        await _db.query('bookmarks', orderBy: 'created_at DESC');
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<bool> isBookmarked(int surah, int ayah) async {
    final rows = await _db.query(
      'bookmarks',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> addBookmark(int surah, int ayah, {String? label}) async {
    return _db.insert('bookmarks', {
      'surah': surah,
      'ayah': ayah,
      'label': label,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeBookmark(int surah, int ayah) async {
    await _db.delete(
      'bookmarks',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
    );
  }

  // ── Marked Mistakes ───────────────────────────────────────────────────────
  Future<Set<String>> getMarkedMistakes(String section) async {
    final rows = await _db.query(
      'marked_mistakes',
      where: 'section = ?',
      whereArgs: [section],
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  Future<void> toggleMarkedMistake(String wordId, String section) async {
    final rows = await _db.query(
      'marked_mistakes',
      where: 'word_id = ?',
      whereArgs: [wordId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await _db.insert('marked_mistakes', {
        'word_id': wordId,
        'section': section,
        'marked_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await _db.delete(
          'marked_mistakes', where: 'word_id = ?', whereArgs: [wordId]);
    }
  }

  // ── Section Preferences ───────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSectionPreferences(String section) async {
    final rows = await _db.query(
      'section_preferences',
      where: 'section = ?',
      whereArgs: [section],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveSectionPreferences(
    String section, {
    int? translationEditionId,
    int? tafseerEditionId,
    String? reciterId,
  }) async {
    await _db.insert('section_preferences', {
      'section': section,
      'translation_edition_id': translationEditionId,
      'tafseer_edition_id': tafseerEditionId,
      'reciter_id': reciterId,
    });
  }
}
