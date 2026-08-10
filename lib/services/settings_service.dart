// lib/services/settings_service.dart
// Global app settings — backed by SharedPreferences + Riverpod Notifiers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

// Reactive provider for Arabic font size
final arabicFontSizeProvider = StateNotifierProvider<ArabicFontSizeNotifier, double>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return ArabicFontSizeNotifier(settings);
});

class ArabicFontSizeNotifier extends StateNotifier<double> {
  final SettingsService _settings;
  ArabicFontSizeNotifier(this._settings) : super(_settings.arabicFontSize);

  void updateSize(double newSize) {
    final clamped = newSize.clamp(18.0, 48.0);
    state = clamped;
    _settings.setArabicFontSize(clamped);
  }
}

class SettingsService {
  final SharedPreferences _prefs;
  SettingsService(this._prefs);

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kOnboardingDone        = 'onboarding_complete';
  static const _kReciter               = 'selected_reciter';
  static const _kTranslationId         = 'selected_translation_id';
  static const _kTafseerEditionId      = 'selected_tafseer_id';
  static const _kLanguages             = 'selected_languages';
  static const _kAutoScrollSpeed       = 'auto_scroll_speed';
  static const _kArabicFontSize        = 'arabic_font_size';

  // ── Defaults ───────────────────────────────────────────────────────────────
  static const String defaultReciterId  = 'ar.abdurrahmaansudais';
  static const double defaultFontSize   = 28.0;
  static const int    defaultScrollSpeed = 1;

  // ── Onboarding ─────────────────────────────────────────────────────────────
  bool get isOnboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() =>
      _prefs.setBool(_kOnboardingDone, true);

  // ── Reciter ───────────────────────────────────────────────────────────────
  String get selectedReciterId =>
      _prefs.getString(_kReciter) ?? defaultReciterId;
  Future<void> setSelectedReciterId(String id) =>
      _prefs.setString(_kReciter, id);

  // ── Translation ───────────────────────────────────────────────────────────
  int? get selectedTranslationId => _prefs.getInt(_kTranslationId);
  Future<void> setSelectedTranslationId(int id) =>
      _prefs.setInt(_kTranslationId, id);

  // ── Tafseer ───────────────────────────────────────────────────────────────
  int? get selectedTafseerEditionId => _prefs.getInt(_kTafseerEditionId);
  Future<void> setSelectedTafseerEditionId(int id) =>
      _prefs.setInt(_kTafseerEditionId, id);

  // ── Languages ─────────────────────────────────────────────────────────────
  List<String> get selectedLanguages =>
      _prefs.getStringList(_kLanguages) ?? ['ur'];
  Future<void> setSelectedLanguages(List<String> langs) =>
      _prefs.setStringList(_kLanguages, langs);

  // ── Auto-scroll speed (1/2/3) ─────────────────────────────────────────────
  int get autoScrollSpeed =>
      _prefs.getInt(_kAutoScrollSpeed) ?? defaultScrollSpeed;
  Future<void> setAutoScrollSpeed(int speed) =>
      _prefs.setInt(_kAutoScrollSpeed, speed);

  // ── Arabic font size ──────────────────────────────────────────────────────
  double get arabicFontSize =>
      _prefs.getDouble(_kArabicFontSize) ?? defaultFontSize;
  Future<void> setArabicFontSize(double size) =>
      _prefs.setDouble(_kArabicFontSize, size);
}
