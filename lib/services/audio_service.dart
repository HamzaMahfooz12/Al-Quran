// lib/services/audio_service.dart
// Audio playback — just_audio with live CDN streaming, local caching, and player state streams
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/settings_service.dart';

final audioServiceProvider = Provider<QuranAudioService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return QuranAudioService(settings);
});

enum AudioPlayMode { single, continuous, loop }

class QuranAudioService {
  final SettingsService _settings;
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  AudioPlayMode playMode = AudioPlayMode.single;
  int loopCount = 1;
  int _loopsDone = 0;

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

  Future<void> playAyah({
    required int globalAyahNumber,
    required int surah,
    required int ayahInSurah,
    int totalAyahsInSurah = 1,
    String? reciterId,
  }) async {
    // If playing the same ayah, toggle pause/play
    if (currentPlayingAyahId == globalAyahNumber && _player.playing) {
      await pause();
      return;
    }

    _currentSurah = surah;
    _currentAyahNumberInSurah = ayahInSurah;
    _currentSurahTotalAyahs = totalAyahsInSurah;
    currentPlayingAyahId = globalAyahNumber;
    _loopsDone = 0;

    final rId = reciterId ?? _settings.selectedReciterId;

    try {
      await _player.stop();

      // Try playing cached local file first, or set direct URL stream
      final localFile = await _getLocalFile(globalAyahNumber, rId);
      if (localFile != null && await localFile.exists()) {
        await _player.setFilePath(localFile.path);
      } else {
        final url192 = 'https://cdn.islamic.network/quran/audio/192/$rId/$globalAyahNumber.mp3';
        final url128 = 'https://cdn.islamic.network/quran/audio/128/$rId/$globalAyahNumber.mp3';

        bool loaded = false;
        try {
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(url192),
              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
            ),
          );
          loaded = true;
        } catch (_) {
          try {
            await _player.setAudioSource(
              AudioSource.uri(
                Uri.parse(url128),
                headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
              ),
            );
            loaded = true;
          } catch (_) {}
        }

        if (!loaded) {
          try {
            final apiResponse = await _dio.get('https://api.alquran.cloud/v1/ayah/$globalAyahNumber/$rId');
            if (apiResponse.data != null && apiResponse.data['data'] != null) {
              final liveUrl = apiResponse.data['data']['audio'] as String;
              await _player.setAudioSource(
                AudioSource.uri(
                  Uri.parse(liveUrl),
                  headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                ),
              );
              loaded = true;
            }
          } catch (_) {}
        }

        // Cache in background if loaded
        if (loaded) {
          _cacheInBackground(globalAyahNumber, rId, url192);
        }
      }

      await _player.play();
    } catch (e) {
      // ignore: avoid_print
      print('Error playing audio for ayah $globalAyahNumber ($rId): $e');
    }
  }

  void _onAyahComplete() {
    if (playMode == AudioPlayMode.loop) {
      _loopsDone++;
      final maxLoops = loopCount == 0 ? double.maxFinite.toInt() : loopCount;
      if (_loopsDone < maxLoops) {
        _player.seek(Duration.zero);
        _player.play();
        return;
      }
    }

    if (playMode == AudioPlayMode.continuous) {
      final nextAyah = (_currentAyahNumberInSurah ?? 0) + 1;
      if (nextAyah <= (_currentSurahTotalAyahs ?? 1)) {
        onAdvance?.call(_currentSurah!, nextAyah);
      }
    }
  }

  Future<File?> _getLocalFile(int globalAyah, String reciterId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, 'audio', reciterId, '$globalAyah.mp3');
      return File(filePath);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheInBackground(int globalAyah, String reciterId, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'audio', reciterId));
      if (!await folder.exists()) await folder.create(recursive: true);
      final filePath = p.join(folder.path, '$globalAyah.mp3');
      await _dio.download(url, filePath);
    } catch (_) {}
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
