// lib/services/ai_model_manager.dart
// On-demand downloader and manager for the Quranic ASR AI model (~35 MB)
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ModelDownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final double progress; // 0.0 to 1.0
  final String speedString;

  const ModelDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this.speedString,
  });
}

class AiModelManager {
  static final AiModelManager _instance = AiModelManager._internal();
  factory AiModelManager() => _instance;
  AiModelManager._internal();

  final Dio _dio = Dio();
  final StreamController<ModelDownloadProgress> _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  Stream<ModelDownloadProgress> get progressStream => _progressController.stream;

  static const String kModelFileName = 'quran_asr_int8.onnx';
  static const int kApproxModelSizeBytes = 36700160; // ~35 MB

  // High-speed CDN mirror for the quantized Quranic ASR ONNX model
  static const String kModelDownloadUrl =
      'https://github.com/HamzaMahfooz12/Al-Quran/releases/download/v1.0.3/quran_asr_int8.onnx';

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  Future<Directory> _getModelDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(p.join(appDir.path, 'ai_models'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  Future<File> getModelFile() async {
    final dir = await _getModelDir();
    return File(p.join(dir.path, kModelFileName));
  }

  /// Checks if the AI model is already downloaded and valid
  Future<bool> isModelDownloaded() async {
    try {
      final file = await getModelFile();
      if (await file.exists()) {
        final length = await file.length();
        return length > 1000000; // >1MB valid model file
      }
    } catch (_) {}
    return false;
  }

  /// Returns size of model in bytes or 0 if not present
  Future<int> getModelSizeBytes() async {
    try {
      final file = await getModelFile();
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  /// Downloads the AI model with real-time progress broadcasting
  Future<bool> downloadModel({CancelToken? cancelToken}) async {
    if (_isDownloading) return false;
    _isDownloading = true;

    final targetFile = await getModelFile();
    final tempFile = File('${targetFile.path}.tmp');

    var lastBytes = 0;
    var lastTime = DateTime.now();
    var speedText = '';

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final response = await _dio.download(
        kModelDownloadUrl,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          if (elapsed >= 500) {
            final bytesDelta = received - lastBytes;
            final speedKb = (bytesDelta / 1024) / (elapsed / 1000);
            speedText = speedKb > 1024
                ? '${(speedKb / 1024).toStringAsFixed(1)} MB/s'
                : '${speedKb.toStringAsFixed(0)} KB/s';
            lastBytes = received;
            lastTime = now;
          }

          final effectiveTotal = total > 0 ? total : kApproxModelSizeBytes;
          final fraction = (received / effectiveTotal).clamp(0.0, 1.0);

          _progressController.add(ModelDownloadProgress(
            receivedBytes: received,
            totalBytes: effectiveTotal,
            progress: fraction,
            speedString: speedText,
          ));
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && await tempFile.exists()) {
        final len = await tempFile.length();
        if (len > 1000000) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);
          _isDownloading = false;
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AiModelManager: download error: $e');
      }
    } finally {
      _isDownloading = false;
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
    return false;
  }

  /// Deletes the local AI model to reclaim device storage
  Future<void> deleteModel() async {
    try {
      final file = await getModelFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
