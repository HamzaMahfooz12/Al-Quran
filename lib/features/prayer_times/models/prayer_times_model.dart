// lib/features/prayer_times/models/prayer_times_model.dart
import 'package:intl/intl.dart';

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class NextPrayerInfo {
  final PrayerType prayer;
  final String name;
  final String arabicName;
  final DateTime time;
  final Duration timeRemaining;

  const NextPrayerInfo({
    required this.prayer,
    required this.name,
    required this.arabicName,
    required this.time,
    required this.timeRemaining,
  });
}

class CurrentPrayerInfo {
  final PrayerType prayer;
  final String name;
  final String arabicName;
  final DateTime startTime;
  final DateTime endTime;
  final double progress; // 0.0 to 1.0

  const CurrentPrayerInfo({
    required this.prayer,
    required this.name,
    required this.arabicName,
    required this.startTime,
    required this.endTime,
    required this.progress,
  });
}

class PrayerTimesModel {
  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? imsak;
  final DateTime? midnight;
  final DateTime? firstThird;
  final DateTime? lastThird; // Tahajjud recommended window
  final String hijriDate;
  final String locationName;
  final String calculationMethod;
  final String fiqhName;

  const PrayerTimesModel({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.imsak,
    this.midnight,
    this.firstThird,
    this.lastThird,
    required this.hijriDate,
    required this.locationName,
    required this.calculationMethod,
    this.fiqhName = 'Hanafi',
  });

  Map<PrayerType, DateTime> get allPrayers => {
        PrayerType.fajr: fajr,
        PrayerType.sunrise: sunrise,
        PrayerType.dhuhr: dhuhr,
        PrayerType.asr: asr,
        PrayerType.maghrib: maghrib,
        PrayerType.isha: isha,
      };

  static String getPrayerName(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.sunrise:
        return 'Sunrise';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  static String getArabicPrayerName(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
    }
  }

  String formatTime(DateTime time, {bool use24Hours = false}) {
    final format = use24Hours ? DateFormat('HH:mm') : DateFormat('hh:mm a');
    return format.format(time);
  }

  /// Calculates the next upcoming prayer from a given timestamp (default: now)
  NextPrayerInfo getNextPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();

    final schedule = [
      MapEntry(PrayerType.fajr, fajr),
      MapEntry(PrayerType.sunrise, sunrise),
      MapEntry(PrayerType.dhuhr, dhuhr),
      MapEntry(PrayerType.asr, asr),
      MapEntry(PrayerType.maghrib, maghrib),
      MapEntry(PrayerType.isha, isha),
    ];

    for (final entry in schedule) {
      if (entry.value.isAfter(now)) {
        return NextPrayerInfo(
          prayer: entry.key,
          name: getPrayerName(entry.key),
          arabicName: getArabicPrayerName(entry.key),
          time: entry.value,
          timeRemaining: entry.value.difference(now),
        );
      }
    }

    // After Isha: Next prayer is tomorrow's Fajr
    final tomorrowFajr = fajr.add(const Duration(days: 1));
    return NextPrayerInfo(
      prayer: PrayerType.fajr,
      name: 'Fajr',
      arabicName: 'الفجر',
      time: tomorrowFajr,
      timeRemaining: tomorrowFajr.difference(now),
    );
  }

  /// Calculates currently active prayer window and progress
  CurrentPrayerInfo getCurrentPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();

    if (now.isBefore(fajr)) {
      // Last night's Isha until Fajr
      final yesterdayIsha = isha.subtract(const Duration(days: 1));
      final total = fajr.difference(yesterdayIsha).inSeconds;
      final elapsed = now.difference(yesterdayIsha).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.isha,
        name: 'Isha',
        arabicName: 'العشاء',
        startTime: yesterdayIsha,
        endTime: fajr,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else if (now.isBefore(sunrise)) {
      final total = sunrise.difference(fajr).inSeconds;
      final elapsed = now.difference(fajr).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.fajr,
        name: 'Fajr',
        arabicName: 'الفجر',
        startTime: fajr,
        endTime: sunrise,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else if (now.isBefore(dhuhr)) {
      final total = dhuhr.difference(sunrise).inSeconds;
      final elapsed = now.difference(sunrise).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.sunrise,
        name: 'Sunrise / Ishraq',
        arabicName: 'الشروق',
        startTime: sunrise,
        endTime: dhuhr,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else if (now.isBefore(asr)) {
      final total = asr.difference(dhuhr).inSeconds;
      final elapsed = now.difference(dhuhr).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.dhuhr,
        name: 'Dhuhr',
        arabicName: 'الظهر',
        startTime: dhuhr,
        endTime: asr,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else if (now.isBefore(maghrib)) {
      final total = maghrib.difference(asr).inSeconds;
      final elapsed = now.difference(asr).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.asr,
        name: 'Asr',
        arabicName: 'العصر',
        startTime: asr,
        endTime: maghrib,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else if (now.isBefore(isha)) {
      final total = isha.difference(maghrib).inSeconds;
      final elapsed = now.difference(maghrib).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.maghrib,
        name: 'Maghrib',
        arabicName: 'المغرب',
        startTime: maghrib,
        endTime: isha,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    } else {
      // Tonight's Isha until tomorrow's Fajr
      final tomorrowFajr = fajr.add(const Duration(days: 1));
      final total = tomorrowFajr.difference(isha).inSeconds;
      final elapsed = now.difference(isha).inSeconds;
      return CurrentPrayerInfo(
        prayer: PrayerType.isha,
        name: 'Isha',
        arabicName: 'العشاء',
        startTime: isha,
        endTime: tomorrowFajr,
        progress: total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0,
      );
    }
  }

  factory PrayerTimesModel.fromAladhanApi({
    required Map<String, dynamic> data,
    required String locationName,
    String fiqhName = 'Hanafi',
  }) {
    final timings = data['timings'] as Map<String, dynamic>;
    final dateMap = data['date'] as Map<String, dynamic>?;
    final gregorian = dateMap?['gregorian'] as Map<String, dynamic>?;
    final dateStr = gregorian?['date'] as String? ?? ''; // "19-08-2026"

    DateTime baseDate = DateTime.now();
    if (dateStr.isNotEmpty) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          baseDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    DateTime parseTime(String timeStr) {
      // e.g. "04:32 (PKT)" or "04:32"
      final clean = timeStr.split(' ').first;
      final parts = clean.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, min);
    }

    final hijri = dateMap?['hijri'] as Map<String, dynamic>?;
    String hijriFormatted = '';
    if (hijri != null) {
      final hDay = hijri['day'] ?? '';
      final hMonth = hijri['month']?['en'] ?? '';
      final hYear = hijri['year'] ?? '';
      hijriFormatted = '$hDay $hMonth $hYear AH';
    }

    final meta = data['meta'] as Map<String, dynamic>?;
    final methodName = meta?['method']?['name'] as String? ?? 'Karachi';

    return PrayerTimesModel(
      date: baseDate,
      fajr: parseTime(timings['Fajr'] as String),
      sunrise: parseTime(timings['Sunrise'] as String),
      dhuhr: parseTime(timings['Dhuhr'] as String),
      asr: parseTime(timings['Asr'] as String),
      maghrib: parseTime(timings['Maghrib'] as String),
      isha: parseTime(timings['Isha'] as String),
      imsak: timings['Imsak'] != null ? parseTime(timings['Imsak'] as String) : null,
      midnight: timings['Midnight'] != null ? parseTime(timings['Midnight'] as String) : null,
      firstThird: timings['Firstthird'] != null ? parseTime(timings['Firstthird'] as String) : null,
      lastThird: timings['Lastthird'] != null ? parseTime(timings['Lastthird'] as String) : null,
      hijriDate: hijriFormatted,
      locationName: locationName,
      calculationMethod: methodName,
      fiqhName: fiqhName,
    );
  }
}
