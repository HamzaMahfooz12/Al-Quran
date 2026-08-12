import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/repositories/reciter_repository.dart';
import '../services/settings_service.dart';

final audioServiceProvider = Provider<QuranAudioService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return QuranAudioService(settings);
});

// playMode: false = advance to next ayah when done, true = loop same ayah forever

class QuranAudioService {
  final SettingsService _settings;
  final AudioPlayer _player = AudioPlayer();

  bool isLooping = false;
  bool _isHandlingComplete = false; // guard: prevents stop() from re-triggering completion

  int? _currentSurah;
  int? _currentAyahNumberInSurah;
  int? _currentSurahTotalAyahs;
  int? currentPlayingAyahId;

  Function(int surah, int ayah)? onAdvance;

  QuranAudioService(this._settings) {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAyahComplete();
      }
    });
  }

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

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

  /// Returns the exact CDN URL for any reciter in 0ms without network delays
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

  Future<void> playAyah({
    required int globalAyahNumber,
    required int surah,
    required int ayahInSurah,
    int totalAyahsInSurah = 1,
    String? reciterId,
  }) async {
    if (currentPlayingAyahId == globalAyahNumber && _player.playing) {
      await pause();
      return;
    }

    _currentSurah = surah;
    _currentAyahNumberInSurah = ayahInSurah;
    _currentSurahTotalAyahs = totalAyahsInSurah;
    currentPlayingAyahId = globalAyahNumber;

    var rId = reciterId ?? _settings.selectedReciterId;
    if (!ReciterRepository.validReciterIds.contains(rId)) {
      rId = 'ar.alafasy';
    }

    try {
      _isHandlingComplete = true;
      try {
        await _player.stop();
      } catch (_) {}
      _isHandlingComplete = false;

      // Pre-validate: find a URL that actually returns 200 before giving it to MPV
      final validUrl = await _resolveValidUrl(rId, globalAyahNumber);
      if (validUrl == null) {
        // ignore: avoid_print
        print('No working URL found for ayah $globalAyahNumber ($rId)');
        return;
      }

      try {
        await _player.setUrl(validUrl);
        await _player.play();
      } catch (e) {
        if (!e.toString().contains('interrupted')) {
          // ignore: avoid_print
          print('Playback error for ayah $globalAyahNumber ($rId): $e');
        }
      }

      // Preload next ayah audio stream in background for zero-latency instant playback
      if (globalAyahNumber < 6236) {
        _preloadNextAyahAudio(rId, globalAyahNumber + 1);
      }
    } catch (e) {
      final errStr = e.toString();
      if (!errStr.contains('interrupted')) {
        // ignore: avoid_print
        print('Error playing audio for ayah $globalAyahNumber ($rId): $e');
      }
    }
  }

  /// Pre-validates candidate URLs via HTTP HEAD — returns first URL returning 200, or null.
  /// This ensures MPV never receives a dead URL, preventing 'Failed to open' errors.
  static Future<String?> _resolveValidUrl(String rId, int globalAyahNumber) async {
    final dio = Dio();
    // Build candidate list: primary bitrate first, then all fallbacks, then alafasy
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

  /// Background pre-fetcher to warm network connection for next Ayah stream
  void _preloadNextAyahAudio(String rId, int nextGlobalAyahNumber) {
    Future.microtask(() async {
      try {
        final nextUrl = getAudioUrlForReciter(rId, nextGlobalAyahNumber);
        final dio = Dio();
        await dio.head(
          nextUrl,
          options: Options(
            headers: {'User-Agent': 'Mozilla/5.0'},
            receiveTimeout: const Duration(seconds: 2),
            sendTimeout: const Duration(seconds: 2),
          ),
        );
      } catch (_) {}
    });
  }

  void _onAyahComplete() {
    if (_isHandlingComplete) return; // ignore completions caused by stop()/load

    if (isLooping) {
      // Loop: replay the same ayah from the beginning
      _player.seek(Duration.zero).then((_) => _player.play());
      return;
    }

    // Continuous: advance to the next ayah
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
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    try {
      _player.dispose();
    } catch (_) {}
  }
}
