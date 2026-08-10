import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TafseerImportService {
  /// Key stored in prefs-like flag file to skip re-import on subsequent launches.
  static const _importFlagFile = 'tafseer_imported_v6.flag';

  /// One-time import: called from main() after DB is ready.
  static Future<void> importOnce(Database mainDb) async {
    // Always sync downloadable editions manifest from assets/downloadable_editions.json into editions table
    await _importDownloadableManifest(mainDb);

    // Check flag for heavy sqlite.gz import
    final appDir = await getApplicationSupportDirectory();
    final flag = File(p.join(appDir.path, _importFlagFile));
    if (await flag.exists()) return;

    try {
      // 1. Load compressed asset bytes
      final gzBytes = await rootBundle.load('assets/bundled_editions.sqlite.gz');
      final gzList = gzBytes.buffer.asUint8List();

      // 2. Decompress gzip → raw SQLite bytes
      final rawBytes = GZipCodec().decode(gzList);

      // 3. Write raw SQLite bytes to a temp file
      final tmpDir = await getTemporaryDirectory();
      final tmpFile = File(p.join(tmpDir.path, 'bundled_tafseer_tmp.sqlite'));
      await tmpFile.writeAsBytes(rawBytes, flush: true);

      // 4. Open the temp SQLite file with sqflite_common_ffi (works on all platforms)
      final srcDb = await databaseFactoryFfi.openDatabase(
        tmpFile.path,
        options: OpenDatabaseOptions(readOnly: true),
      );

      await _mergeEditions(srcDb, mainDb);
      await _mergeTafseerContent(srcDb, mainDb);

      await srcDb.close();
      await tmpFile.delete();

      // 5. Write flag so we never import again
      await flag.create(recursive: true);

      // ignore: avoid_print
      print('[TafseerImport] ✅ Import complete');
    } catch (e, st) {
      // Non-fatal — app works even if tafseer import fails
      // ignore: avoid_print
      print('[TafseerImport] ❌ Failed: $e\n$st');
    }
  }

  static Future<void> _importDownloadableManifest(Database mainDb) async {
    try {
      final curatedTafseers = [
        // ── Arabic (8) ──────────────────────────────────────────────────────
        {'id': 101, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafsir Ibn Kathir (تفسير ابن كثير)', 'api_key': 'ar-tafsir-ibn-kathir', 'is_bundled': 1, 'is_downloaded': 1},
        {'id': 102, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafsir al-Tabari (تفسير الطبري)', 'api_key': 'ar-tafsir-al-tabari', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 201, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafseer Al-Qurtubi (تفسير القرطبي)', 'api_key': 'ar-tafseer-al-qurtubi', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 202, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafseer As-Sa\'di (تفسير السعدي)', 'api_key': 'ar-tafseer-al-saddi', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 203, 'type': 'tafseer', 'language': 'ar', 'name': 'As-Seraj Fi Bayan Gharib Al-Quran', 'api_key': 'asseraj-fi-bayan-gharib-alquran', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 204, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafsir Ibn Abi Hatim', 'api_key': 'tafsir-ibn-abi-hatim', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 205, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafsir Ibn Uthaymeen', 'api_key': 'tafsir-ibn-uthaymeen', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 206, 'type': 'tafseer', 'language': 'ar', 'name': 'Tafsir Al-Jalalayn (تفسير الجلالين)', 'api_key': 'tafsir-jalalayn', 'is_bundled': 0, 'is_downloaded': 0},

        // ── Urdu (5) ────────────────────────────────────────────────────────
        {'id': 103, 'type': 'tafseer', 'language': 'ur', 'name': 'Tafseer Ibn e Kaseer (تفسیر ابن کثیر اردو)', 'api_key': 'tafseer-ibn-e-kaseer-urdu', 'is_bundled': 1, 'is_downloaded': 1},
        {'id': 104, 'type': 'tafseer', 'language': 'ur', 'name': 'Tafseer Bayan ul Quran (تفسیر بیان القرآن)', 'api_key': 'tafsir-bayan-ul-quran', 'is_bundled': 1, 'is_downloaded': 1},
        {'id': 207, 'type': 'tafseer', 'language': 'ur', 'name': 'Tafseer As-Sa\'di Urdu', 'api_key': 'tafsir-as-saadi', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 208, 'type': 'tafseer', 'language': 'ur', 'name': 'Fi Zilal al-Quran (Syed Qutb)', 'api_key': 'tafsir-fe-zalul-quran-syed-qatab', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 209, 'type': 'tafseer', 'language': 'ur', 'name': 'Tazkirul Quran Urdu', 'api_key': 'tazkiru-quran-ur', 'is_bundled': 0, 'is_downloaded': 0},

        // ── English (5) ─────────────────────────────────────────────────────
        {'id': 106, 'type': 'tafseer', 'language': 'en', 'name': 'Tafseer Ibn Kathir English', 'api_key': 'en-tafisr-ibn-kathir', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 210, 'type': 'tafseer', 'language': 'en', 'name': 'Al-Mukhtasar English', 'api_key': 'Al-Mukhtasar', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 211, 'type': 'tafseer', 'language': 'en', 'name': 'Ma\'arif-ul-Quran English', 'api_key': 'en-tafsir-maarif-ul-quran', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 212, 'type': 'tafseer', 'language': 'en', 'name': 'Tafsir Al-Jalalayn English', 'api_key': 'tafsir-al-jalalayn', 'is_bundled': 0, 'is_downloaded': 0},
        {'id': 213, 'type': 'tafseer', 'language': 'en', 'name': 'Tazkirul Quran English', 'api_key': 'tazkirul-quran-en', 'is_bundled': 0, 'is_downloaded': 0},

        // ── Hindi (1) ───────────────────────────────────────────────────────
        {'id': 105, 'type': 'tafseer', 'language': 'hi', 'name': 'Al-Mukhtasar Hindi (تफ़सीर अल-मुख़्तसर)', 'api_key': 'hindi-mokhtasar', 'is_bundled': 1, 'is_downloaded': 1},
      ];

      final batch = mainDb.batch();
      for (final item in curatedTafseers) {
        batch.rawInsert('''
          INSERT OR REPLACE INTO editions (id, type, language, name, api_key, is_bundled, is_downloaded)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', [
          item['id'],
          item['type'],
          item['language'],
          item['name'],
          item['api_key'],
          item['is_bundled'],
          item['is_downloaded'],
        ]);
      }
      await batch.commit(noResult: true);
      // ignore: avoid_print
      print('[TafseerImport] Seeded ${curatedTafseers.length} curated tafseers into SQLite');
    } catch (e) {
      // ignore: avoid_print
      print('[TafseerImport] Error seeding curated tafseers: $e');
    }
  }

  // ── Merge editions table ──────────────────────────────────────────────────
  static Future<void> _mergeEditions(Database src, Database dst) async {
    final rows = await src.query('editions');
    final batch = dst.batch();
    for (final row in rows) {
      batch.rawInsert('''
        INSERT OR IGNORE INTO editions
          (id, type, language, name, api_key, is_bundled, is_downloaded)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        row['id'],
        row['type'],
        row['language'],
        row['name'],
        row['api_key'],
        1, // is_bundled
        1, // is_downloaded (pre-shipped)
      ]);
    }
    await batch.commit(noResult: true);
    // ignore: avoid_print
    print('[TafseerImport] Merged ${rows.length} editions');
  }

  // ── Merge ayah_content table ──────────────────────────────────────────────
  static Future<void> _mergeTafseerContent(Database src, Database dst) async {
    // Process in chunks of 500 to avoid memory spikes
    const chunkSize = 500;
    int offset = 0;
    int total = 0;

    while (true) {
      final rows = await src.query(
        'ayah_content',
        limit: chunkSize,
        offset: offset,
      );
      if (rows.isEmpty) break;

      final batch = dst.batch();
      for (final row in rows) {
        batch.rawInsert('''
          INSERT OR REPLACE INTO ayah_content (ayah_id, edition_id, text)
          VALUES (?, ?, ?)
        ''', [row['ayah_id'], row['edition_id'], row['text']]);
      }
      await batch.commit(noResult: true);

      total += rows.length;
      offset += chunkSize;
    }

    // ignore: avoid_print
    print('[TafseerImport] Merged $total ayah_content rows');
  }
}
