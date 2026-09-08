// lib/services/app_version_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Centralized App Version Service
// Authoritative source of app version, loaded from version.json across the entire app
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionService {
  static String _version = '1.0.4';
  static int _buildNumber = 5;
  static bool _initialized = false;

  /// Semantic version string (e.g. "1.0.4")
  static String get version => _version;

  /// Numeric build number (e.g. 5)
  static int get buildNumber => _buildNumber;

  /// Formatted display version (e.g. "v1.0.4")
  static String get displayVersion => 'v$_version';

  /// Full version with build number (e.g. "1.0.4+5")
  static String get fullVersion => '$_version+$_buildNumber';

  /// Whether the service has been initialized
  static bool get isInitialized => _initialized;

  /// Initialize version info from local bundled version.json and cached prefs
  static Future<void> init() async {
    if (_initialized) return;

    // 1. Try reading from SharedPreferences if previously cached
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVer = prefs.getString('app_cached_version');
      final cachedBuild = prefs.getInt('app_cached_build');
      if (cachedVer != null && cachedVer.isNotEmpty) {
        _version = cachedVer;
        if (cachedBuild != null && cachedBuild > 0) {
          _buildNumber = cachedBuild;
        }
      }
    } catch (_) {}

    // 2. Load authoritative version from bundled version.json
    try {
      String? jsonStr;
      try {
        jsonStr = await rootBundle.loadString('assets/version.json');
      } catch (_) {
        jsonStr = await rootBundle.loadString('version.json');
      }

      if (jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        final v = data['version'] as String?;
        final b = data['build_number'] as int?;
        if (v != null && v.isNotEmpty) {
          _version = v;
        }
        if (b != null && b > 0) {
          _buildNumber = b;
        }
      }
    } catch (e) {
      debugPrint('Error loading bundled version.json: $e');
    }

    // 3. Check PackageInfo as fallback/supplement if available and valid
    try {
      final info = await PackageInfo.fromPlatform();
      // If PackageInfo has a valid non-default version (> 1.0.0 or higher build)
      if (info.version.isNotEmpty && info.version != '1.0.0') {
        _version = info.version;
        final bNum = int.tryParse(info.buildNumber);
        if (bNum != null && bNum > 0) {
          _buildNumber = bNum;
        }
      }
    } catch (_) {}

    _initialized = true;
  }

  /// Update cached version when a new version is fetched
  static Future<void> updateCachedVersion(String newVersion, int newBuild) async {
    _version = newVersion;
    _buildNumber = newBuild;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_cached_version', newVersion);
      await prefs.setInt('app_cached_build', newBuild);
    } catch (_) {}
  }
}
