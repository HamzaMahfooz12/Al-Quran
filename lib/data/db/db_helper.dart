// ─────────────────────────────────────────────────────────────────────────────
// lib/data/db/db_helper.dart
// SQLite helper — schema creation for all 9 tables + first-launch seeding
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'al_quran.db';
  static const _dbVersion = 1;

  // Singleton
  DatabaseHelper._private();
  static final DatabaseHelper instance = DatabaseHelper._private();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbsPath = await getDatabasesPath();
    final path = join(dbsPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );

    // Auto-cleanup any invalid audio entries saved under translation
    await db.rawDelete(
      "DELETE FROM ayah_content WHERE edition_id IN (SELECT id FROM editions WHERE api_key IN ('ur.taqi', 'ur.tariqmasood', 'quran-uthmani') AND type = 'translation')",
    );
    await db.rawDelete(
      "DELETE FROM editions WHERE api_key IN ('ur.taqi', 'ur.tariqmasood', 'quran-uthmani') AND type = 'translation'",
    );

    return db;
  }

  // ── Schema creation ──────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. ayahs
    batch.execute('''
      CREATE TABLE ayahs (
        id           INTEGER PRIMARY KEY,
        surah        INTEGER NOT NULL,
        ayah_number  INTEGER NOT NULL,
        juz          INTEGER NOT NULL,
        hizb         INTEGER NOT NULL,
        ruku         INTEGER NOT NULL,
        manzil       INTEGER NOT NULL,
        page         INTEGER NOT NULL,
        is_sajda     INTEGER NOT NULL DEFAULT 0,
        arabic_text  TEXT    NOT NULL
      )
    ''');

    // 2. editions (translations + tafseer registry)
    batch.execute('''
      CREATE TABLE editions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        type          TEXT    NOT NULL,
        language      TEXT    NOT NULL,
        name          TEXT    NOT NULL,
        api_key       TEXT    NOT NULL UNIQUE,
        is_bundled    INTEGER NOT NULL DEFAULT 0,
        is_downloaded INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. ayah_content (normalized text per edition)
    batch.execute('''
      CREATE TABLE ayah_content (
        ayah_id    INTEGER NOT NULL,
        edition_id INTEGER NOT NULL,
        text       TEXT    NOT NULL,
        PRIMARY KEY (ayah_id, edition_id),
        FOREIGN KEY (ayah_id)    REFERENCES ayahs(id),
        FOREIGN KEY (edition_id) REFERENCES editions(id)
      )
    ''');

    // 4. reciters
    batch.execute('''
      CREATE TABLE reciters (
        id    TEXT PRIMARY KEY,
        name  TEXT NOT NULL,
        style TEXT
      )
    ''');

    // 5. last_read (one row per section)
    batch.execute('''
      CREATE TABLE last_read (
        section    TEXT PRIMARY KEY,
        surah      INTEGER,
        ayah       INTEGER,
        page       INTEGER,
        updated_at INTEGER
      )
    ''');

    // 6. marked_mistakes
    batch.execute('''
      CREATE TABLE marked_mistakes (
        word_id    TEXT PRIMARY KEY,
        section    TEXT    NOT NULL,
        marked_at  INTEGER NOT NULL
      )
    ''');

    // 7. bookmarks
    batch.execute('''
      CREATE TABLE bookmarks (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        surah      INTEGER NOT NULL,
        ayah       INTEGER NOT NULL,
        label      TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 8. section_preferences
    batch.execute('''
      CREATE TABLE section_preferences (
        section                TEXT PRIMARY KEY,
        translation_edition_id INTEGER,
        tafseer_edition_id     INTEGER,
        reciter_id             TEXT
      )
    ''');

    // 9. word_layout (for QCF mushaf rendering)
    batch.execute('''
      CREATE TABLE word_layout (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        mushaf     TEXT    NOT NULL,
        page       INTEGER NOT NULL,
        line       INTEGER NOT NULL,
        surah      INTEGER NOT NULL,
        ayah       INTEGER NOT NULL,
        word_pos   INTEGER NOT NULL,
        word_id    TEXT    NOT NULL,
        glyph_code TEXT    NOT NULL,
        font_file  TEXT    NOT NULL
      )
    ''');

    // Indexes for performance
    batch.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah)');
    batch.execute('CREATE INDEX idx_ayahs_juz ON ayahs(juz)');
    batch.execute('CREATE INDEX idx_ayahs_page ON ayahs(page)');
    batch.execute('CREATE INDEX idx_content_ayah ON ayah_content(ayah_id)');
    batch.execute('CREATE INDEX idx_content_edition ON ayah_content(edition_id)');
    batch.execute('CREATE INDEX idx_layout_mushaf_page ON word_layout(mushaf, page)');
    batch.execute('CREATE INDEX idx_bookmarks_surah ON bookmarks(surah, ayah)');

    await batch.commit(noResult: true);

    // Seed bundled editions registry & offline Al-Fatiha data
    await _seedBundledEditions(db);
    await _seedInitialOfflineData(db);
  }

  // ── Seed instant offline data (Surah Al-Fatiha 1:1 - 1:7) ──────────────────
  Future<void> _seedInitialOfflineData(Database db) async {
    final fatihaAyahs = [
      {'id': 1, 'surah': 1, 'ayah_number': 1, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'},
      {'id': 2, 'surah': 1, 'ayah_number': 2, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'},
      {'id': 3, 'surah': 1, 'ayah_number': 3, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'},
      {'id': 4, 'surah': 1, 'ayah_number': 4, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'مَٰلِكِ يَوْمِ ٱلدِّينِ'},
      {'id': 5, 'surah': 1, 'ayah_number': 5, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'},
      {'id': 6, 'surah': 1, 'ayah_number': 6, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ'},
      {'id': 7, 'surah': 1, 'ayah_number': 7, 'juz': 1, 'hizb': 1, 'ruku': 1, 'manzil': 1, 'page': 1, 'is_sajda': 0, 'arabic_text': 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ'},
    ];

    final fatihaUrduJalandhry = [
      {'ayah_id': 1, 'edition_id': 1, 'text': 'شروع اللہ کے نام سے جو بے حد مہربان، نہایت رحم کرنے والا ہے۔'},
      {'ayah_id': 2, 'edition_id': 1, 'text': 'سب تعریفیں اللہ ہی کے لیے ہیں جو تمام جہانوں کا پرورش کرنے والا ہے۔'},
      {'ayah_id': 3, 'edition_id': 1, 'text': 'بہت مہربان، نہایت رحم کرنے والا۔'},
      {'ayah_id': 4, 'edition_id': 1, 'text': 'روزِ جزا کا مالک۔'},
      {'ayah_id': 5, 'edition_id': 1, 'text': 'ہم تیری ہی عبادت کرتے ہیں اور تجھ ہی سے مدد مانگتے ہیں۔'},
      {'ayah_id': 6, 'edition_id': 1, 'text': 'ہمیں سیدھا راستہ دکھا۔'},
      {'ayah_id': 7, 'edition_id': 1, 'text': 'ان لوگوں کا راستہ جن پر تو نے انعام فرمایا، نہ ان کا جن پر غضب ہوا اور نہ گمراہوں کا۔'},
    ];

    final fatihaUrduTafseer = [
      {'ayah_id': 1, 'edition_id': 1, 'text': 'تفسیر: تسمیہ (بسم اللہ) ہر اچھے کام کے شروع میں پڑھنا سنت ہے تا کہ اس کام میں برکت حاصل ہو۔'},
      {'ayah_id': 2, 'edition_id': 1, 'text': 'تفسیر: الحمد لله تمام حمد و ثنا کا مستحق صرف اللہ تعالی ہے۔ رب العالمین یعنی تمام کائنات کی پروردگاری اسی کے ہاتھ میں ہے۔'},
      {'ayah_id': 3, 'edition_id': 1, 'text': 'تفسیر: الرحمن اور الرحیم اللہ کی وہ صفات عالیہ ہیں جو اس کی بے انتہا رحمت و شفقت پر دلالت کرتی ہیں۔'},
      {'ayah_id': 4, 'edition_id': 1, 'text': 'تفسیر: مالک یوم الدین، یعنی قیامت کے دن کا مطلق حاکم و مالک جس دن تمام انسان اپنے اعمال کا حساب دیں گے۔'},
      {'ayah_id': 5, 'edition_id': 1, 'text': 'تفسیر: ایاک نعبد وایاک نستعین، توحید عبادت اور توحید استعانت کا عظیم اعلان ہے۔'},
      {'ayah_id': 6, 'edition_id': 1, 'text': 'تفسیر: اہدنا الصراط المستقیم، ہدایت اور صراط مستقیم (اسلامی تعلیمات) پر قائم رہنے کی دعا۔'},
      {'ayah_id': 7, 'edition_id': 1, 'text': 'تفسیر: انعام یافتہ بندے انبیاء، صدیقین، شہداء اور صالحین ہیں، جن کے نقش قدم پر چلنے کی دعا کی گئی ہے۔'},
    ];

    final batch = db.batch();
    for (final row in fatihaAyahs) {
      batch.insert('ayahs', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final row in fatihaUrduJalandhry) {
      batch.insert('ayah_content', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final row in fatihaUrduTafseer) {
      batch.insert('ayah_content', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ── Seed the 5 pre-bundled editions ─────────────────────────────────────
  Future<void> _seedBundledEditions(Database db) async {
    final editions = [
      {
        'id': 1,
        'type': 'translation',
        'language': 'ur',
        'name': 'Fateh Muhammad Jalandhry (مولانا فتح محمد جالندھری)',
        'api_key': 'ur.jalandhry',
        'is_bundled': 1,
        'is_downloaded': 1,
      },
      {
        'id': 2,
        'type': 'translation',
        'language': 'ur',
        'name': 'Ahmed Ali (احمد علی)',
        'api_key': 'ur.ahmedali',
        'is_bundled': 1,
        'is_downloaded': 1,
      },
      {
        'id': 3,
        'type': 'translation',
        'language': 'ur',
        'name': 'Abul A\'la Maududi (مولانا ابوالاعلی مودودی)',
        'api_key': 'ur.maududi',
        'is_bundled': 1,
        'is_downloaded': 0,
      },
      {
        'id': 4,
        'type': 'translation',
        'language': 'ur',
        'name': 'Kanzul Iman (کنز الایمان)',
        'api_key': 'ur.kanzulumal',
        'is_bundled': 1,
        'is_downloaded': 0,
      },
      {
        'id': 5,
        'type': 'translation',
        'language': 'en',
        'name': 'Sahih International',
        'api_key': 'en.sahih',
        'is_bundled': 1,
        'is_downloaded': 1,
      },
      {
        'id': 6,
        'type': 'translation',
        'language': 'en',
        'name': 'Yusuf Ali',
        'api_key': 'en.yusufali',
        'is_bundled': 1,
        'is_downloaded': 1,
      },
      {
        'id': 7,
        'type': 'tafseer',
        'language': 'ur',
        'name': 'Tafseer Jalalayn (تفسیر جلالین اردو)',
        'api_key': 'ur.jalalayn',
        'is_bundled': 1,
        'is_downloaded': 1,
      },
      {
        'id': 8,
        'type': 'tafseer',
        'language': 'ur',
        'name': 'Mufti Taqi Usmani Tafseer (تفسیر مفتی تقی عثمانی)',
        'api_key': 'ur.taqiusmani',
        'is_bundled': 1,
        'is_downloaded': 0,
      },
    ];

    for (final edition in editions) {
      await db.insert(
        'editions',
        edition,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ── Convenience methods ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<int> insert(String table, Map<String, dynamic> row,
      {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: conflictAlgorithm);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<bool> isSeeded() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ayahs');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
