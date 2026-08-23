// lib/features/prayer_times/services/prayer_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart';
import 'location_search_service.dart';
import 'prayer_calculator_service.dart';

import '../../../services/settings_service.dart';

final prayerServiceProvider = Provider<PrayerService>((ref) {
  return PrayerService();
});

final selectedLocationProvider = StateNotifierProvider<SelectedLocationNotifier, CityLocation>((ref) {
  return SelectedLocationNotifier();
});

final prayerTimesProvider = FutureProvider.autoDispose<PrayerTimesModel>((ref) async {
  final location = ref.watch(selectedLocationProvider);
  final fiqh = ref.watch(selectedFiqhProvider);
  final service = ref.watch(prayerServiceProvider);
  return service.getPrayerTimes(location, fiqh: fiqh);
});

class SelectedLocationNotifier extends StateNotifier<CityLocation> {
  SelectedLocationNotifier() : super(LocationSearchService.defaultLocation) {
    _load();
  }

  static const _kLocationKey = 'saved_prayer_location';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kLocationKey);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = CityLocation.fromMap(map);
      } catch (_) {}
    }
  }

  Future<void> setLocation(CityLocation loc) async {
    state = loc;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocationKey, jsonEncode(loc.toMap()));
  }
}

class PrayerService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Fetches prayer times from Aladhan API with instant offline astronomical fallback
  Future<PrayerTimesModel> getPrayerTimes(
    CityLocation location, {
    String fiqh = 'hanafi',
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final isHanafi = fiqh == 'hanafi';
    final fiqhLabel = isHanafi ? 'Hanafi • حَنَفِي' : 'Shafi\'i • شَافِعِي';

    // 1. Attempt live online fetch via Aladhan API
    try {
      final dateFormatted = '${targetDate.day.toString().padLeft(2, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}';
      final response = await _dio.get(
        'https://api.aladhan.com/v1/timings/$dateFormatted',
        queryParameters: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'method': 1, // 1 = University of Islamic Sciences, Karachi
          'school': isHanafi ? 1 : 0, // 1 = Hanafi, 0 = Shafi'i/Standard
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return PrayerTimesModel.fromAladhanApi(
            data: data,
            locationName: location.displayName,
            fiqhName: fiqhLabel,
          );
        }
      }
    } catch (_) {
      // Offline fallback: Use astronomical calculation engine
    }

    // 2. Offline astronomical solar formula calculation
    return PrayerCalculatorService.calculate(
      date: targetDate,
      latitude: location.latitude,
      longitude: location.longitude,
      method: CalculationMethod.karachi,
      juristic: isHanafi ? JuristicMethod.hanafi : JuristicMethod.standard,
      locationName: location.displayName,
    );
  }
}
