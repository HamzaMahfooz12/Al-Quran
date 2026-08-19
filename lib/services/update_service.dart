// lib/services/update_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Self-hosted OTA update service using GitHub Releases
// Checks https://raw.githubusercontent.com/HamzaMahfooz12/Al-Quran/main/version.json
// for the latest version and downloads APK from GitHub Releases.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String changelog;
  final bool isUpdateAvailable;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.changelog,
    required this.isUpdateAvailable,
  });
}

class UpdateService {
  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/HamzaMahfooz12/Al-Quran/main/version.json';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Check for updates by comparing current version with remote version.json
  static Future<AppUpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version; // e.g. "1.0.0"
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

    try {
      final response = await _dio.get(_versionJsonUrl);
      final data = response.data as Map<String, dynamic>;

      final latestVersion = data['version'] as String? ?? currentVersion;
      final latestBuild = data['build_number'] as int? ?? currentBuild;
      final downloadUrl = data['download_url'] as String? ?? '';
      final changelog = data['changelog'] as String? ?? 'Bug fixes and improvements.';

      final isNewer = _isVersionNewer(currentVersion, latestVersion) ||
          (currentVersion == latestVersion && latestBuild > currentBuild);

      return AppUpdateInfo(
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        downloadUrl: downloadUrl,
        changelog: changelog,
        isUpdateAvailable: isNewer,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return AppUpdateInfo(
        latestVersion: currentVersion,
        latestBuildNumber: currentBuild,
        downloadUrl: '',
        changelog: '',
        isUpdateAvailable: false,
      );
    }
  }

  /// Download APK to temp directory and trigger Android installer
  static Future<void> downloadAndInstall(
    String downloadUrl, {
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
    required void Function() onComplete,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/al_quran_update.apk';

      // Delete old APK if exists
      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      onComplete();

      // Trigger Android APK installer
      final result = await OpenFilex.open(filePath,
          type: 'application/vnd.android.package-archive');

      if (result.type != ResultType.done) {
        onError('Could not open installer: ${result.message}');
      }
    } catch (e) {
      onError('Download failed: $e');
    }
  }

  /// Compare two semantic versions (e.g. "1.0.0" vs "1.1.0")
  static bool _isVersionNewer(String current, String latest) {
    final currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    // Pad to same length
    while (currentParts.length < 3) currentParts.add(0);
    while (latestParts.length < 3) latestParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
