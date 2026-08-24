// lib/services/audio_cache_service.dart
// Sliding-Window Audio Pre-Caching Engine (N-1, N, N+1) with instant skip cleanup
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'audio_service.dart';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  final Dio _dio = Dio();
  Directory? _cacheDir;
  final Set<String> _inFlightDownloads = {};

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      return _cacheDir!;
    }
    final temp = await getTemporaryDirectory();
    final audioDir = Directory(p.join(temp.path, 'audio_cache'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    _cacheDir = audioDir;
    return audioDir;
  }

  String _getFileName(String reciterId, int globalAyahNumber) {
    return '${reciterId}_$globalAyahNumber.mp3';
  }

  Future<File> getCachedFile(String reciterId, int globalAyahNumber) async {
    final dir = await _getCacheDirectory();
    return File(p.join(dir.path, _getFileName(reciterId, globalAyahNumber)));
  }

  Future<bool> isAyahCached(String reciterId, int globalAyahNumber) async {
    try {
      final file = await getCachedFile(reciterId, globalAyahNumber);
      if (await file.exists()) {
        final len = await file.length();
        return len > 2048; // Valid audio file (>2KB)
      }
    } catch (_) {}
    return false;
  }

  /// Downloads and caches an Ayah's MP3 file safely using atomic temp-file rename
  Future<File?> downloadAyahAudio(String reciterId, int globalAyahNumber) async {
    final cacheKey = '${reciterId}_$globalAyahNumber';
    if (_inFlightDownloads.contains(cacheKey)) return null;

    final targetFile = await getCachedFile(reciterId, globalAyahNumber);
    if (await isAyahCached(reciterId, globalAyahNumber)) {
      return targetFile;
    }

    _inFlightDownloads.add(cacheKey);
    final tempFile = File('${targetFile.path}.tmp');

    try {
      final audioUrl = QuranAudioService.getAudioUrlForReciter(reciterId, globalAyahNumber);
      final response = await _dio.download(
        audioUrl,
        tempFile.path,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && await tempFile.exists()) {
        final length = await tempFile.length();
        if (length > 2048) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);
          return targetFile;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: failed to download $reciterId:$globalAyahNumber: $e');
      }
    } finally {
      _inFlightDownloads.remove(cacheKey);
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
    return null;
  }

  /// Sliding-window management for Ayahs [N-1, N, N+1]:
  /// 1. Immediately purges all old cached audio files outside [N-1, N, N+1] (handling skips cleanly).
  /// 2. Asynchronously downloads N+1 and N-1 in background so transition is 0ms delay.
  Future<void> prepareWindow(String reciterId, int currentGlobalAyahNumber) async {
    try {
      final dir = await _getCacheDirectory();
      final allowedFiles = <String>{
        _getFileName(reciterId, currentGlobalAyahNumber),
      };

      if (currentGlobalAyahNumber > 1) {
        allowedFiles.add(_getFileName(reciterId, currentGlobalAyahNumber - 1));
      }
      if (currentGlobalAyahNumber < 6236) {
        allowedFiles.add(_getFileName(reciterId, currentGlobalAyahNumber + 1));
      }

      // 1. Purge all files outside [N-1, N, N+1]
      if (await dir.exists()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final base = p.basename(entry.path);
            if (!allowedFiles.contains(base) && !base.endsWith('.tmp')) {
              try {
                entry.deleteSync();
              } catch (_) {}
            }
          }
        }
      }

      // 2. Pre-download N+1 in background
      if (currentGlobalAyahNumber < 6236) {
        downloadAyahAudio(reciterId, currentGlobalAyahNumber + 1);
      }
      // 3. Pre-download N-1 in background if not present
      if (currentGlobalAyahNumber > 1) {
        downloadAyahAudio(reciterId, currentGlobalAyahNumber - 1);
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioCache: prepareWindow error: $e');
      }
    }
  }

  /// Calculates total size of cached audio files in bytes
  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _getCacheDirectory();
      if (!await dir.exists()) return 0;
      var total = 0;
      final files = dir.listSync(recursive: true);
      for (final f in files) {
        if (f is File) {
          total += f.lengthSync();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Formats byte count to readable string (e.g. "4.2 MB")
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Deletes all cached audio files
  Future<void> clearAllCache() async {
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final f in files) {
          try {
            f.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
