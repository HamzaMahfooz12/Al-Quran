// lib/services/word_timing_service.dart
// Word-level audio timestamp alignment and caching service
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WordSegment {
  final int wordPos; // 1-based word position in the Ayah
  final int startMs;
  final int endMs;

  const WordSegment({
    required this.wordPos,
    required this.startMs,
    required this.endMs,
  });

  Map<String, dynamic> toJson() => {
        'w': wordPos,
        's': startMs,
        'e': endMs,
      };

  factory WordSegment.fromJson(Map<String, dynamic> json) => WordSegment(
        wordPos: json['w'] as int? ?? 1,
        startMs: json['s'] as int? ?? 0,
        endMs: json['e'] as int? ?? 0,
      );
}

class VerseTiming {
  final int surah;
  final int ayah;
  final int durationMs;
  final List<WordSegment> segments;

  const VerseTiming({
    required this.surah,
    required this.ayah,
    required this.durationMs,
    required this.segments,
  });

  /// Finds the 1-based word position active at [positionMs]
  int? getActiveWordPos(int positionMs) {
    if (segments.isEmpty) return null;

    for (final seg in segments) {
      if (positionMs >= seg.startMs && positionMs < seg.endMs) {
        return seg.wordPos;
      }
    }

    // Edge check: if slightly before first segment or after last
    if (positionMs < segments.first.startMs && positionMs >= 0) {
      return segments.first.wordPos;
    }
    if (positionMs >= segments.last.endMs && positionMs <= durationMs + 500) {
      return segments.last.wordPos;
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'duration': durationMs,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  factory VerseTiming.fromJson(Map<String, dynamic> json) => VerseTiming(
        surah: json['surah'] as int? ?? 1,
        ayah: json['ayah'] as int? ?? 1,
        durationMs: json['duration'] as int? ?? 0,
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => WordSegment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class WordTimingService {
  static final WordTimingService _instance = WordTimingService._internal();
  factory WordTimingService() => _instance;
  WordTimingService._internal();

  final Dio _dio = Dio();
  final Map<String, Map<String, VerseTiming>> _memoryCache = {};
  Directory? _timingCacheDir;

  /// Reciters with 100% verified official QuranCDN millisecond word segments
  static const Map<String, int> quranCdnReciterMap = {
    'ar.alafasy': 7,
    'ar.abdulbasitmurattal': 2,
    'ar.abdulsamad': 1,
    'ar.husary': 6,
    'ar.husarymujawwad': 12,
    'ar.minshawi': 9,
    'ar.minshawimujawwad': 8,
    'ar.abdurrahmaansudais': 3,
    'ar.shaatree': 4,
    'ar.saoodshuraym': 10,
    'ar.hanirifai': 5,
  };

  /// Non-Arabic translations (whole verse highlight only)
  static const Set<String> translationReciters = {
    'en.walk',
    'fr.leclerc',
    'ru.kuliev-audio',
    'tr.vakfi-audio',
    'zh.chinese',
    'kk.khalifahaltai-audio',
  };

  Future<Directory> _getTimingCacheDir() async {
    if (_timingCacheDir != null && await _timingCacheDir!.exists()) {
      return _timingCacheDir!;
    }
    final temp = await getTemporaryDirectory();
    final dir = Directory(p.join(temp.path, 'word_timings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _timingCacheDir = dir;
    return dir;
  }

  /// Fetches timing data for a full Surah with offline disk persistence
  Future<Map<String, VerseTiming>?> getSurahTimings({
    required String reciterId,
    required int surah,
  }) async {
    final cacheKey = '${reciterId}_$surah';

    // 1. In-memory lookup
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Local disk cache lookup
    final diskData = await _loadFromDisk(reciterId, surah);
    if (diskData != null && diskData.isNotEmpty) {
      _memoryCache[cacheKey] = diskData;
      return diskData;
    }

    // 3. Category A: Fetch from QuranCDN API
    final qdcId = quranCdnReciterMap[reciterId];
    if (qdcId != null) {
      final fetched = await _fetchFromQuranCdn(reciterId: reciterId, qdcId: qdcId, surah: surah);
      if (fetched != null && fetched.isNotEmpty) {
        _memoryCache[cacheKey] = fetched;
        await _saveToDisk(reciterId, surah, fetched);
        return fetched;
      }
    }

    return null;
  }

  Future<Map<String, VerseTiming>?> _fetchFromQuranCdn({
    required String reciterId,
    required int qdcId,
    required int surah,
  }) async {
    final url = 'https://api.qurancdn.com/api/qdc/audio/reciters/$qdcId/audio_files?chapter=$surah&segments=true';
    try {
      final resp = await _dio.get(
        url,
        options: Options(
          headers: {'User-Agent': 'Mozilla/5.0'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        final audioFiles = data['audio_files'] as List<dynamic>? ?? [];
        if (audioFiles.isEmpty) return null;

        final firstFile = audioFiles.first as Map<String, dynamic>;
        final verseTimings = firstFile['verse_timings'] as List<dynamic>? ?? [];

        final result = <String, VerseTiming>{};
        for (final vt in verseTimings) {
          final vtMap = vt as Map<String, dynamic>;
          final verseKey = vtMap['verse_key'] as String? ?? '';
          final parts = verseKey.split(':');
          if (parts.length != 2) continue;
          final sNum = int.tryParse(parts[0]) ?? surah;
          final aNum = int.tryParse(parts[1]) ?? 1;

          final verseFrom = vtMap['timestamp_from'] as int? ?? 0;
          final verseTo = vtMap['timestamp_to'] as int? ?? 0;
          final duration = (verseTo - verseFrom).abs();

          final rawSegments = vtMap['segments'] as List<dynamic>? ?? [];
          final segments = <WordSegment>[];

          for (final seg in rawSegments) {
            if (seg is List && seg.length >= 3) {
              final wPos = seg[0] as int? ?? 1;
              final rawStart = seg[1] as int? ?? 0;
              final rawEnd = seg[2] as int? ?? 0;

              // Timestamps in QuranCDN chapter files are relative to chapter start;
              // convert to verse-relative milliseconds (0-based for individual verse audio).
              final segStart = (rawStart >= verseFrom) ? (rawStart - verseFrom) : rawStart;
              final segEnd = (rawEnd >= verseFrom) ? (rawEnd - verseFrom) : rawEnd;

              segments.add(WordSegment(
                wordPos: wPos,
                startMs: segStart,
                endMs: segEnd,
              ));
            }
          }

          result['$sNum:$aNum'] = VerseTiming(
            surah: sNum,
            ayah: aNum,
            durationMs: duration > 0 ? duration : 5000,
            segments: segments,
          );
        }

        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WordTimingService: fetch error for $reciterId surah $surah: $e');
      }
    }
    return null;
  }

  /// Tajweed-Phonetic Fallback for Category B reciters
  /// Proportionally generates segments using Arabic character weights and Madd prolongation rules.
  VerseTiming generatePhoneticTiming({
    required int surah,
    required int ayah,
    required List<String> words,
    required int totalDurationMs,
  }) {
    if (words.isEmpty || totalDurationMs <= 0) {
      return VerseTiming(surah: surah, ayah: ayah, durationMs: totalDurationMs, segments: []);
    }

    // Calculate phonetic weight per word
    final weights = <double>[];
    for (final word in words) {
      var weight = 0.0;
      for (var i = 0; i < word.length; i++) {
        final char = word[i];
        // Madd & Prolongation letters -> 2.0x
        if (char == 'ا' || char == 'و' || char == 'ي' || char == 'آ' || char == 'ٓ' || char == 'ۥ' || char == 'ۧ') {
          weight += 2.0;
        }
        // Shaddah / Tanween / Ghunnah -> 1.5x
        else if (char == 'ّ' || char == 'ً' || char == 'ٌ' || char == 'ٍ') {
          weight += 1.5;
        }
        // Harakat -> 0.3x
        else if (char == 'َ' || char == 'ُ' || char == 'ِ' || char == 'ْ') {
          weight += 0.3;
        }
        // Standard Arabic consonant -> 1.0x
        else {
          weight += 1.0;
        }
      }
      weights.add(weight > 0 ? weight : 1.0);
    }

    final totalWeight = weights.fold<double>(0.0, (sum, w) => sum + w);
    final segments = <WordSegment>[];
    var currentMs = 0;

    for (var i = 0; i < words.length; i++) {
      final fraction = weights[i] / totalWeight;
      final wordDuration = (fraction * totalDurationMs).round();
      final endMs = (i == words.length - 1) ? totalDurationMs : (currentMs + wordDuration);

      segments.add(WordSegment(
        wordPos: i + 1,
        startMs: currentMs,
        endMs: endMs,
      ));
      currentMs = endMs;
    }

    return VerseTiming(
      surah: surah,
      ayah: ayah,
      durationMs: totalDurationMs,
      segments: segments,
    );
  }

  Future<void> _saveToDisk(String reciterId, int surah, Map<String, VerseTiming> data) async {
    try {
      final dir = await _getTimingCacheDir();
      final file = File(p.join(dir.path, '${reciterId}_$surah.json'));
      final map = data.map((k, v) => MapEntry(k, v.toJson()));
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  Future<Map<String, VerseTiming>?> _loadFromDisk(String reciterId, int surah) async {
    try {
      final dir = await _getTimingCacheDir();
      final file = File(p.join(dir.path, '${reciterId}_$surah.json'));
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, VerseTiming.fromJson(v as Map<String, dynamic>)));
      }
    } catch (_) {}
    return null;
  }
}
