// lib/services/full_surah_audio_service.dart
// Online Full-Surah Audio Playback Service with QuranicAudio primary CDN,
// MP3Quran fallback redundancy, local offline download/cache, and Sleep Timer

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/full_surah_reciter.dart';
import '../data/repositories/full_surah_reciter_repository.dart';

enum FullSurahRepeatMode {
  off,
  surah,
  continuous,
}

final fullSurahAudioServiceProvider =
    ChangeNotifierProvider<FullSurahAudioService>((ref) {
  final repo = ref.watch(fullSurahReciterRepositoryProvider);
  return FullSurahAudioService(repo);
});

class FullSurahAudioService extends ChangeNotifier {
  static const _kSavedFullSurahReciterKey = 'saved_full_surah_reciter_id';

  final FullSurahReciterRepository _reciterRepo;
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  int? _currentSurahNumber;
  int? _activePlayingReciterId;
  FullSurahReciter _currentReciter = FullSurahReciterRepository.kDefaultReciter;
  FullSurahRepeatMode _repeatMode = FullSurahRepeatMode.continuous;
  bool _isUsingFallback = false;
  bool _isLoading = false;

  final Set<int> _downloadedSurahs = {};

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;
  final StreamController<Duration?> _sleepTimerController =
      StreamController<Duration?>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();
  final StreamController<Map<int, double>> _downloadProgressController =
      StreamController<Map<int, double>>.broadcast();
  final Map<int, double> _activeDownloads = {};

  FullSurahAudioService(this._reciterRepo) {
    _initPlayerListeners();
    _initReciter();
  }

  Future<void> _initReciter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(_kSavedFullSurahReciterKey);
      if (savedId != null) {
        final savedReciter = await _reciterRepo.getReciterById(savedId);
        _currentReciter = savedReciter;
      } else {
        final defaultReciter = await _reciterRepo.getReciterById(123);
        _currentReciter = defaultReciter;
      }
    } catch (_) {
      _currentReciter = FullSurahReciterRepository.kDefaultReciter;
    }
    await refreshDownloadedSurahs();
    notifyListeners();
  }

  void _initPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackComplete();
      }
      notifyListeners();
    });
  }

  // ── Getters & Streams ─────────────────────────────────────────────────────
  AudioPlayer get player => _player;
  int? get currentSurahNumber => _currentSurahNumber;
  int? get activePlayingReciterId => _activePlayingReciterId;
  FullSurahReciter get currentReciter => _currentReciter;
  FullSurahRepeatMode get repeatMode => _repeatMode;
  bool get isUsingFallback => _isUsingFallback;
  bool get isLoading => _isLoading;
  Set<int> get downloadedSurahs => _downloadedSurahs;

  bool get isPlaying => _player.playing;
  bool get isBuffering =>
      _player.processingState == ProcessingState.buffering ||
      _player.processingState == ProcessingState.loading ||
      _isLoading;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration?> get sleepTimerRemainingStream =>
      _sleepTimerController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<Map<int, double>> get downloadProgressStream =>
      _downloadProgressController.stream;
  double get speed => _player.speed;

  // ── Reciter Selection ─────────────────────────────────────────────────────
  Future<void> setReciter(FullSurahReciter reciter) async {
    _currentReciter = reciter;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSavedFullSurahReciterKey, reciter.id);
    } catch (_) {}
    await refreshDownloadedSurahs();
    notifyListeners();

    // If audio is currently playing or loaded on a surah, immediately shift
    // to the new reciter and start playing the new selected reciter on that surah
    if (_currentSurahNumber != null) {
      await playSurah(surahNumber: _currentSurahNumber!, reciter: reciter);
    }
  }

  // ── Playback Controls ─────────────────────────────────────────────────────
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  void setRepeatMode(FullSurahRepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case FullSurahRepeatMode.off:
        _repeatMode = FullSurahRepeatMode.surah;
        break;
      case FullSurahRepeatMode.surah:
        _repeatMode = FullSurahRepeatMode.continuous;
        break;
      case FullSurahRepeatMode.continuous:
        _repeatMode = FullSurahRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_currentSurahNumber != null) {
        if (_player.processingState == ProcessingState.idle ||
            _activePlayingReciterId != _currentReciter.id) {
          await playSurah(surahNumber: _currentSurahNumber!);
        } else {
          await _player.play();
        }
      } else {
        await playSurah(surahNumber: 1);
      }
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _activePlayingReciterId = null;
    notifyListeners();
  }

  // ── Play Surah (Local File -> QuranicAudio CDN -> MP3Quran Fallback) ───────
  Future<void> playSurah({
    required int surahNumber,
    FullSurahReciter? reciter,
    bool forceOnline = false,
  }) async {
    final targetReciter = reciter ?? _currentReciter;
    _currentReciter = targetReciter;

    final bool isSameReciter = (_activePlayingReciterId == targetReciter.id);
    final bool isSameSurah = (_currentSurahNumber == surahNumber);

    // Only skip reloading if the exact same surah with the exact same reciter is already active & playing
    if (isSameSurah &&
        isSameReciter &&
        _player.playing &&
        _player.processingState != ProcessingState.completed &&
        !forceOnline) {
      return;
    }

    _currentSurahNumber = surahNumber;
    _activePlayingReciterId = targetReciter.id;
    _isUsingFallback = false;
    _isLoading = true;
    notifyListeners();

    // Instantly stop previous reciter audio to prevent overlap while buffering
    try {
      if (_player.playing) {
        await _player.stop();
      }
    } catch (_) {}

    // 1. Check local file first
    if (!forceOnline) {
      try {
        final localFile = await getLocalSurahFile(surahNumber, targetReciter.id);
        if (await localFile.exists()) {
          final length = await localFile.length();
          if (length > 30720) { // > 30KB
            try {
              await _player.setFilePath(localFile.path);
              _isLoading = false;
              notifyListeners();
              await _player.play();
              return;
            } catch (e) {
              debugPrint('Local file playback error: $e, falling back to online stream');
            }
          }
        }
      } catch (_) {}
    }

    // 2. Primary Online Stream: QuranicAudio.com
    final primaryUrl = targetReciter.getPrimaryUrl(surahNumber);
    try {
      _isUsingFallback = false;
      await _player.setUrl(primaryUrl);
      _isLoading = false;
      notifyListeners();
      await _player.play();
      return;
    } catch (primaryError) {
      debugPrint('Primary QuranicAudio stream error: $primaryError. Trying fallback...');
    }

    // 3. Redundancy Fallback: MP3Quran.net
    final fallbackUrl = targetReciter.getFallbackUrl(surahNumber);
    try {
      _isUsingFallback = true;
      await _player.setUrl(fallbackUrl);
      _isLoading = false;
      notifyListeners();
      await _player.play();
      return;
    } catch (fallbackError) {
      _isLoading = false;
      _activePlayingReciterId = null;
      notifyListeners();
      debugPrint('Fallback MP3Quran stream error: $fallbackError');
      _errorController.add(
        'Audio unavailable for Surah $surahNumber with ${targetReciter.name}. Please check internet connection.',
      );
    }
  }

  void _handleTrackComplete() {
    if (_sleepTimerEndTime != null &&
        DateTime.now().isAfter(_sleepTimerEndTime!)) {
      _cancelSleepTimer();
      _player.pause();
      return;
    }

    switch (_repeatMode) {
      case FullSurahRepeatMode.surah:
        if (_currentSurahNumber != null) {
          playSurah(surahNumber: _currentSurahNumber!, reciter: _currentReciter);
        }
        break;
      case FullSurahRepeatMode.continuous:
        nextSurah();
        break;
      case FullSurahRepeatMode.off:
        // Track finished
        break;
    }
  }

  Future<void> nextSurah() async {
    if (_currentSurahNumber == null) return;
    final next = (_currentSurahNumber! < 114) ? _currentSurahNumber! + 1 : 1;
    await playSurah(surahNumber: next, reciter: _currentReciter);
  }

  Future<void> prevSurah() async {
    if (_currentSurahNumber == null) return;
    final prev = (_currentSurahNumber! > 1) ? _currentSurahNumber! - 1 : 114;
    await playSurah(surahNumber: prev, reciter: _currentReciter);
  }

  // ── Sleep Timer Management ────────────────────────────────────────────────
  void setSleepTimer(Duration? duration) {
    _cancelSleepTimer();
    if (duration == null || duration == Duration.zero) {
      _sleepTimerController.add(null);
      return;
    }

    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = _sleepTimerEndTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        _cancelSleepTimer();
        _player.pause();
        _sleepTimerController.add(null);
      } else {
        _sleepTimerController.add(remaining);
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    _sleepTimerController.add(null);
  }

  // ── Local Storage & Offline Audio Download ────────────────────────────────
  Future<Directory> _getAudioDirectory(int reciterId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir =
        Directory(p.join(appDir.path, 'full_surah_audio', 'reciter_$reciterId'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> getLocalSurahFile(int surahNumber, int reciterId) async {
    final dir = await _getAudioDirectory(reciterId);
    final padded = surahNumber.toString().padLeft(3, '0');
    return File(p.join(dir.path, 'surah_$padded.mp3'));
  }

  Future<bool> isSurahDownloaded(int surahNumber, int reciterId) async {
    try {
      final file = await getLocalSurahFile(surahNumber, reciterId);
      if (await file.exists()) {
        final length = await file.length();
        return length > 30720; // > 30KB
      }
    } catch (_) {}
    return false;
  }

  Future<void> refreshDownloadedSurahs() async {
    _downloadedSurahs.clear();
    for (int i = 1; i <= 114; i++) {
      final downloaded = await isSurahDownloaded(i, _currentReciter.id);
      if (downloaded) _downloadedSurahs.add(i);
    }
    notifyListeners();
  }

  Future<bool> downloadSurah(
      int surahNumber, FullSurahReciter reciter) async {
    if (_activeDownloads.containsKey(surahNumber)) return false;

    final targetFile = await getLocalSurahFile(surahNumber, reciter.id);
    final tempFile = File('${targetFile.path}.tmp');

    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    _activeDownloads[surahNumber] = 0.01;
    _downloadProgressController.add(Map.from(_activeDownloads));

    final downloadOptions = Options(
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    );

    bool downloadedSuccess = false;

    // Try primary first: QuranicAudio.com
    String downloadUrl = reciter.getPrimaryUrl(surahNumber);
    try {
      await _dio.download(
        downloadUrl,
        tempFile.path,
        options: downloadOptions,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.01, 0.99);
            _activeDownloads[surahNumber] = progress;
            _downloadProgressController.add(Map.from(_activeDownloads));
          }
        },
      );
      downloadedSuccess = true;
    } catch (_) {
      // Primary failed, retry with fallback: MP3Quran.net
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      downloadUrl = reciter.getFallbackUrl(surahNumber);
      try {
        await _dio.download(
          downloadUrl,
          tempFile.path,
          options: downloadOptions,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final progress = (received / total).clamp(0.01, 0.99);
              _activeDownloads[surahNumber] = progress;
              _downloadProgressController.add(Map.from(_activeDownloads));
            }
          },
        );
        downloadedSuccess = true;
      } catch (e) {
        debugPrint('Both download sources failed for Surah $surahNumber: $e');
        downloadedSuccess = false;
      }
    }

    _activeDownloads.remove(surahNumber);
    _downloadProgressController.add(Map.from(_activeDownloads));

    if (downloadedSuccess && await tempFile.exists()) {
      final length = await tempFile.length();
      if (length > 30720) { // > 30KB
        try {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.copy(targetFile.path);
          try {
            await tempFile.delete();
          } catch (_) {}
          _downloadedSurahs.add(surahNumber);
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('Error writing downloaded file: $e');
        }
      }
    }

    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }
    return false;
  }

  Future<void> deleteDownloadedSurah(int surahNumber, int reciterId) async {
    try {
      final file = await getLocalSurahFile(surahNumber, reciterId);
      if (await file.exists()) {
        await file.delete();
        _downloadedSurahs.remove(surahNumber);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Scans and retrieves all downloaded full Surahs across all reciters
  Future<List<DownloadedSurahInfo>> getAllDownloadedSurahs() async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory(p.join(appDir.path, 'full_surah_audio'));
    if (!await baseDir.exists()) return [];

    final List<DownloadedSurahInfo> result = [];
    final allReciters = await _reciterRepo.getAllReciters();
    final recitersMap = {for (var r in allReciters) r.id: r};

    try {
      final entities = baseDir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final folderName = p.basename(entity.path); // e.g. "reciter_123"
          final reciterId = int.tryParse(folderName.replaceAll('reciter_', ''));
          if (reciterId == null) continue;

          final reciter = recitersMap[reciterId] ?? await _reciterRepo.getReciterById(reciterId);

          final files = entity.listSync();
          for (final f in files) {
            if (f is File && f.path.endsWith('.mp3') && !f.path.endsWith('.tmp')) {
              final fileName = p.basename(f.path); // e.g. "surah_001.mp3"
              final numStr = fileName.replaceAll('surah_', '').replaceAll('.mp3', '');
              final surahNum = int.tryParse(numStr);
              if (surahNum == null || surahNum < 1 || surahNum > 114) continue;

              final length = await f.length();
              if (length > 30720) { // > 30KB
                final stat = await f.stat();
                result.add(
                  DownloadedSurahInfo(
                    surahNumber: surahNum,
                    reciter: reciter,
                    file: f,
                    fileSizeBytes: length,
                    downloadedAt: stat.modified,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning downloaded surahs: $e');
    }

    // Sort by surah number, then reciter name
    result.sort((a, b) {
      final cmp = a.surahNumber.compareTo(b.surahNumber);
      if (cmp != 0) return cmp;
      return a.reciter.name.compareTo(b.reciter.name);
    });

    return result;
  }

  /// Deletes all downloaded full Surahs across all reciters
  Future<void> deleteAllDownloads() async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory(p.join(appDir.path, 'full_surah_audio'));
    if (await baseDir.exists()) {
      try {
        await baseDir.delete(recursive: true);
        await baseDir.create(recursive: true);
      } catch (e) {
        debugPrint('Error deleting all downloads: $e');
      }
    }
    _downloadedSurahs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerController.close();
    _errorController.close();
    _downloadProgressController.close();
    _player.dispose();
    super.dispose();
  }
}

class DownloadedSurahInfo {
  final int surahNumber;
  final FullSurahReciter reciter;
  final File file;
  final int fileSizeBytes;
  final DateTime downloadedAt;

  const DownloadedSurahInfo({
    required this.surahNumber,
    required this.reciter,
    required this.file,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
