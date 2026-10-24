// lib/services/tafseer_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../data/models/edition.dart';
import '../data/repositories/quran_repository.dart';

class TafseerService {
  static const Map<String, String> _localTafseerPaths = {
    // Arabic (8)
    'ar-tafsir-ibn-kathir': r'D:\AL Quran\tafssir\arabic\ar-tafsir-ibn-kathir.json',
    'ar-tafsir-al-tabari': r'D:\AL Quran\tafssir\arabic\ar-tafsir-al-tabari.json',
    'ar-tafseer-al-qurtubi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-qurtubi.json',
    'ar-tafseer-al-saddi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-saddi.json',
    'asseraj-fi-bayan-gharib-alquran': r'D:\AL Quran\tafssir\arabic\asseraj-fi-bayan-gharib-alquran.json',
    'tafsir-ibn-abi-hatim': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-abi-hatim.json',
    'tafsir-ibn-uthaymeen': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-uthaymeen.json',
    'tafsir-jalalayn': r'D:\AL Quran\tafssir\arabic\tafsir-jalalayn.json',

    // Urdu (5)
    'tafseer-ibn-e-kaseer-urdu': r'D:\AL Quran\tafssir\urdu\tafseer-ibn-e-kaseer-urdu.json',
    'tafsir-bayan-ul-quran': r'D:\AL Quran\tafssir\urdu\tafsir-bayan-ul-quran.json',
    'tafsir-as-saadi': r'D:\AL Quran\tafssir\urdu\tafsir-as-saadi.json',
    'tafsir-fe-zalul-quran-syed-qatab': r'D:\AL Quran\tafssir\urdu\tafsir-fe-zalul-quran-syed-qatab.json',
    'tazkiru-quran-ur': r'D:\AL Quran\tafssir\urdu\tazkiru-quran-ur.json',

    // English (5)
    'en-tafisr-ibn-kathir': r'D:\AL Quran\tafssir\english\en-tafisr-ibn-kathir.json',
    'Al-Mukhtasar': r'D:\AL Quran\tafssir\english\Al-Mukhtasar.json',
    'en-tafsir-maarif-ul-quran': r'D:\AL Quran\tafssir\english\en-tafsir-maarif-ul-quran.json',
    'tafsir-al-jalalayn': r'D:\AL Quran\tafssir\english\tafsir-al-jalalayn.json',
    'tazkirul-quran-en': r'D:\AL Quran\tafssir\english\tazkirul-quran-en.json',

    // Hindi (1)
    'hindi-mokhtasar': r'D:\AL Quran\tafssir\hindi\hindi-mokhtasar.json',
  };

  /// In-memory cache for open JSON dictionaries to avoid re-reading multi-MB files
  static final Map<String, Map<String, dynamic>> _loadedJsonDicts = {};

  /// Resolves pointer aliases like "3:2" -> "3:1"
  static String _resolveTafseerValue(Map<String, dynamic> dict, String key, [int depth = 0]) {
    if (depth > 10) return '';
    final val = dict[key];
    if (val == null) return '';
    if (val is Map) return (val['text'] ?? '').toString();
    if (val is String) {
      final str = val.trim();
      if (str.contains(':') && dict.containsKey(str)) {
        return _resolveTafseerValue(dict, str, depth + 1);
      }
      return str;
    }
    return val.toString();
  }

  /// Strips HTML tags, cleans HTML entities, and formats linebreaks
  static String cleanHtml(String text) {
    var s = text;
    s = s.replaceAll(RegExp(r'</p>|<br\s*/?>|</div>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'");
    s = s.replaceAll(RegExp(r'p\s+class="[^"]*"|div\s+lang="[^"]*"'), '');
    s = s.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    return s.trim();
  }

  /// Fetches the Tafseer commentary for a specific Ayah with multi-tier fallback:
  /// 1. SQLite database
  /// 2. Local JSON files (D:\AL Quran\tafssir\...)
  /// 3. Quran.com REST API
  static Future<String?> fetchTafseerForAyah({
    required int surah,
    required int ayah,
    required int ayahId,
    required Edition edition,
    required QuranRepository repo,
  }) async {
    // 1. Check local SQLite database
    final cached = await repo.getContent(ayahId, edition.id);
    if (cached != null && cached.trim().isNotEmpty) {
      final cleaned = cleanHtml(cached);
      if (cleaned.isNotEmpty) return cleaned;
    }

    // 2. Check local JSON file if present
    final localPath = _localTafseerPaths[edition.apiKey];
    if (localPath != null && File(localPath).existsSync()) {
      try {
        if (!_loadedJsonDicts.containsKey(localPath)) {
          final jsonStr = await File(localPath).readAsString();
          _loadedJsonDicts[localPath] = json.decode(jsonStr) as Map<String, dynamic>;
        }
        final dict = _loadedJsonDicts[localPath]!;
        final key = '$surah:$ayah';
        final raw = _resolveTafseerValue(dict, key);
        if (raw.isNotEmpty) {
          final cleaned = cleanHtml(raw);
          if (cleaned.isNotEmpty) {
            // Cache in SQLite for instant future loads
            repo.insertEditionContent([
              {
                'ayah_id': ayahId,
                'edition_id': edition.id,
                'text': cleaned,
              }
            ]);
            return cleaned;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback to Quran.com REST API (works across Android and Desktop)
    try {
      final dio = Dio();
      final url = 'https://api.quran.com/api/v4/tafsirs/${edition.apiKey}/by_ayah/$surah:$ayah';
      final res = await dio.get(
        url,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0 Al-Quran-App'}),
      );
      if (res.data != null && res.data['tafsir'] != null) {
        final raw = (res.data['tafsir']['text'] ?? '').toString();
        if (raw.isNotEmpty) {
          final cleaned = cleanHtml(raw);
          if (cleaned.isNotEmpty) {
            repo.insertEditionContent([
              {
                'ayah_id': ayahId,
                'edition_id': edition.id,
                'text': cleaned,
              }
            ]);
            return cleaned;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Fetches translation for a Surah on the fly if not yet cached in SQLite
  static Future<Map<int, String>> fetchSurahTranslation({
    required int surah,
    required Edition edition,
    required List<int> ayahIds,
    required QuranRepository repo,
  }) async {
    // 1. Check SQLite
    final cached = await repo.getContentBulk(ayahIds, edition.id);
    if (cached.isNotEmpty && cached.length >= ayahIds.length) {
      return cached;
    }

    // 2. Fetch from Al-Quran Cloud API
    try {
      final dio = Dio();
      final response = await dio.get('https://api.alquran.cloud/v1/surah/$surah/${edition.apiKey}');
      if (response.data != null && response.data['status'] == 'OK') {
        final ayahs = (response.data['data']['ayahs'] as List).cast<Map<String, dynamic>>();
        final List<Map<String, dynamic>> contentRows = [];
        final Map<int, String> result = {};

        for (final item in ayahs) {
          final globalNum = item['number'] as int;
          final text = item['text'] as String;
          result[globalNum] = text;
          contentRows.add({
            'ayah_id': globalNum,
            'edition_id': edition.id,
            'text': text,
          });
        }

        if (contentRows.isNotEmpty) {
          await repo.insertEditionContent(contentRows);
          await repo.markEditionDownloaded(edition.id);
        }
        return result;
      }
    } catch (_) {}

    return cached;
  }
}
