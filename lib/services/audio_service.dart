// lib/services/audio_service.dart
// Unified Audio Service with Word-by-Word Synchronization and Sliding-Window Caching
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/repositories/reciter_repository.dart';
import '../services/settings_service.dart';
import 'audio_cache_service.dart';
import 'word_timing_service.dart';

final audioServiceProvider = Provider<QuranAudioService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return QuranAudioService(settings);
});

final activeWordIdProvider = StreamProvider<String?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.activeWordIdStream;
});

class QuranAudioService {
  final SettingsService _settings;
  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _audioCache = AudioCacheService();
  final WordTimingService _wordTimingService = WordTimingService();

  final StreamController<String?> _activeWordIdController = StreamController<String?>.broadcast();
  Stream<String?> get activeWordIdStream => _activeWordIdController.stream;

  bool isLooping = false;
  bool _isHandlingComplete = false;

  int? _currentSurah;
  int? _currentAyahNumberInSurah;
  int? _currentSurahTotalAyahs;
  int? currentPlayingAyahId;
  String? _currentActiveWordId;

  Map<String, VerseTiming>? _currentSurahTimings;
  List<String>? _currentAyahWords; // For phonetic calculation if needed

  Function(int surah, int ayah)? onAdvance;

  QuranAudioService(this._settings) {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAyahComplete();
      }
    });

    _player.positionStream.listen((position) {
      _updateActiveWord(position);
    });
  }

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  String? get currentActiveWordId => _currentActiveWordId;

  double get speed => _player.speed;
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  int? get currentSurah => _currentSurah;
  int? get currentAyahNumberInSurah => _currentAyahNumberInSurah;

  Future<void> setReciterAndReplay(String newReciterId) async {
    await _settings.setSelectedReciterId(newReciterId);
    if (currentPlayingAyahId != null && _currentSurah != null && _currentAyahNumberInSurah != null) {
      final ayahId = currentPlayingAyahId!;
      final surah = _currentSurah!;
      final ayahNum = _currentAyahNumberInSurah!;
      final total = _currentSurahTotalAyahs ?? 1;

      currentPlayingAyahId = null;
      try {
        await playAyah(
          globalAyahNumber: ayahId,
          surah: surah,
          ayahInSurah: ayahNum,
          totalAyahsInSurah: total,
          reciterId: newReciterId,
        );
      } catch (_) {}
    }
  }

  /// Returns the exact CDN URL for any reciter
  static String getAudioUrlForReciter(String rId, int globalAyahNumber, [String? overrideBitrate]) {
    if (overrideBitrate != null) {
      return 'https://cdn.islamic.network/quran/audio/$overrideBitrate/$rId/$globalAyahNumber.mp3';
    }

    const bitrate32Reciters = {
      'ar.ibrahimakhbar',
    };
    const bitrate64Reciters = {
      'ar.saoodshuraym',
      'ar.abdulsamad',
      'ar.abdurrahmaansudais',
      'ar.abdulbasitmurattal',
      'ar.abdullahbasfar',
      'ar.hanirifai',
      'ar.shaatree',
      'ar.ahmedajamy',
      'ar.husary',
      'ar.hudhaify',
      'ar.minshawimujawwad',
      'ar.aymanswoaid',
      'ur.khan',
      'fa.hedayatfarfooladvand',
    };
    const bitrate192Reciters = {
      'en.walk',
    };

    var bitrate = '128';
    if (bitrate32Reciters.contains(rId)) {
      bitrate = '32';
    } else if (bitrate64Reciters.contains(rId)) {
      bitrate = '64';
    } else if (bitrate192Reciters.contains(rId)) {
      bitrate = '192';
    }

    return 'https://cdn.islamic.network/quran/audio/$bitrate/$rId/$globalAyahNumber.mp3';
  }

  /// Plays an Ayah with sliding-window pre-caching and word timing sync
  Future<void> playAyah({
    required int globalAyahNumber,
    required int surah,
    required int ayahInSurah,
    int totalAyahsInSurah = 1,
    String? reciterId,
    List<String>? ayahWords,
  }) async {
    if (currentPlayingAyahId == globalAyahNumber && _player.playing) {
      await pause();
      return;
    }

    _currentSurah = surah;
    _currentAyahNumberInSurah = ayahInSurah;
    _currentSurahTotalAyahs = totalAyahsInSurah;
    currentPlayingAyahId = globalAyahNumber;
    _currentAyahWords = ayahWords;

    var rId = reciterId ?? _settings.selectedReciterId;
    if (!ReciterRepository.validReciterIds.contains(rId)) {
      rId = 'ar.alafasy';
    }

    // 1. Sliding window management: Instant skip cleanup & download N+1, N-1
    _audioCache.prepareWindow(rId, globalAyahNumber);

    // 2. Fetch Surah timings in background / cache
    _loadTimingsForSurah(rId, surah);

    try {
      _isHandlingComplete = true;
      try {
        await _player.stop();
      } catch (_) {}
      _isHandlingComplete = false;

      // 3. Check if Ayah N is already cached on disk (0ms latency transition)
      final cached = await _audioCache.isAyahCached(rId, globalAyahNumber);
      if (cached) {
        final cachedFile = await _audioCache.getCachedFile(rId, globalAyahNumber);
        await _player.setFilePath(cachedFile.path);
        await _player.play();
      } else {
        // Fallback: Stream directly while caching in background
        final validUrl = await _resolveValidUrl(rId, globalAyahNumber);
        if (validUrl == null) {
          if (kDebugMode) {
            print('No working URL found for ayah $globalAyahNumber ($rId)');
          }
          return;
        }
        await _player.setUrl(validUrl);
        await _player.play();

        // Download N in background for subsequent offline / rewind
        _audioCache.downloadAyahAudio(rId, globalAyahNumber);
      }
    } catch (e) {
      final errStr = e.toString();
      if (!errStr.contains('interrupted')) {
        debugPrint('Error playing audio for ayah $globalAyahNumber ($rId): $e');
      }
    }
  }

  Future<void> _loadTimingsForSurah(String rId, int surah) async {
    try {
      _currentSurahTimings = await _wordTimingService.getSurahTimings(
        reciterId: rId,
        surah: surah,
      );
    } catch (_) {}
  }

  void _updateActiveWord(Duration? position) {
    if (position == null || _currentSurah == null || _currentAyahNumberInSurah == null) {
      _setActiveWordId(null);
      return;
    }

    final rId = _settings.selectedReciterId;
    if (WordTimingService.translationReciters.contains(rId)) {
      _setActiveWordId(null);
      return;
    }

    final verseKey = '$_currentSurah:$_currentAyahNumberInSurah';
    final timing = _currentSurahTimings?[verseKey];

    if (timing != null && timing.segments.isNotEmpty) {
      final posMs = position.inMilliseconds;
      final wordPos = timing.getActiveWordPos(posMs);
      if (wordPos != null) {
        _setActiveWordId('$_currentSurah:$_currentAyahNumberInSurah:$wordPos');
        return;
      }
    } else if (_currentAyahWords != null && _currentAyahWords!.isNotEmpty) {
      // Category B fallback: phonetic calculation with live duration
      final totalDurMs = _player.duration?.inMilliseconds ?? 0;
      if (totalDurMs > 0) {
        final phoneticTiming = _wordTimingService.generatePhoneticTiming(
          surah: _currentSurah!,
          ayah: _currentAyahNumberInSurah!,
          words: _currentAyahWords!,
          totalDurationMs: totalDurMs,
        );
        final wordPos = phoneticTiming.getActiveWordPos(position.inMilliseconds);
        if (wordPos != null) {
          _setActiveWordId('$_currentSurah:$_currentAyahNumberInSurah:$wordPos');
          return;
        }
      }
    }

    _setActiveWordId(null);
  }

  void _setActiveWordId(String? wordId) {
    if (_currentActiveWordId != wordId) {
      _currentActiveWordId = wordId;
      _activeWordIdController.add(wordId);
    }
  }

  static Future<String?> _resolveValidUrl(String rId, int globalAyahNumber) async {
    final dio = Dio();
    final primary = getAudioUrlForReciter(rId, globalAyahNumber);
    final candidates = <String>[primary];
    for (final b in ['64', '128', '32', '192']) {
      final u = getAudioUrlForReciter(rId, globalAyahNumber, b);
      if (!candidates.contains(u)) candidates.add(u);
    }
    if (rId != 'ar.alafasy') {
      candidates.add(getAudioUrlForReciter('ar.alafasy', globalAyahNumber));
    }

    for (final url in candidates) {
      try {
        final resp = await dio.head(
          url,
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
            receiveTimeout: const Duration(seconds: 4),
            sendTimeout: const Duration(seconds: 4),
          ),
        );
        if (resp.statusCode != null && resp.statusCode! < 400) {
          return url;
        }
      } catch (_) {}
    }
    return null;
  }

  void _onAyahComplete() {
    if (_isHandlingComplete) return;

    _setActiveWordId(null);

    if (isLooping) {
      _player.seek(Duration.zero).then((_) => _player.play());
      return;
    }

    final nextAyah = (_currentAyahNumberInSurah ?? 0) + 1;
    if (nextAyah <= (_currentSurahTotalAyahs ?? 1)) {
      onAdvance?.call(_currentSurah!, nextAyah);
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await _player.play();
    } catch (_) {}
  }

  Future<void> stop() async {
    currentPlayingAyahId = null;
    _setActiveWordId(null);
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    try {
      _activeWordIdController.close();
      _player.dispose();
    } catch (_) {}
  }
}
