// lib/features/prayer_times/services/prayer_calculator_service.dart
import 'dart:math' as math;
import '../models/prayer_times_model.dart';
import 'package:hijri/hijri_calendar.dart';

enum CalculationMethod {
  karachi,      // Univ. of Islamic Sciences, Karachi (18° Fajr, 18° Isha)
  mwl,          // Muslim World League (18° Fajr, 17° Isha)
  isna,         // ISNA (15° Fajr, 15° Isha)
  ummAlQura,    // Makkah (18.5° Fajr, 90min interval for Isha)
  egyptian,     // Egyptian General Authority (19.5° Fajr, 17.5° Isha)
  tehran,       // Univ. of Tehran (17.7° Fajr, 14° Isha)
  gulf,         // Gulf region (19.5° Fajr, 90min interval for Isha)
}

enum JuristicMethod {
  standard, // Shafi'i, Maliki, Hanbali (Shadow length factor = 1)
  hanafi,   // Hanafi (Shadow length factor = 2)
}

class PrayerCalculatorService {
  /// Converts degrees to radians
  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Converts radians to degrees
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);

  /// Computes accurate prayer times 100% offline based on astronomical solar formulas
  static PrayerTimesModel calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    double? timezoneOffsetHours,
    CalculationMethod method = CalculationMethod.karachi,
    JuristicMethod juristic = JuristicMethod.hanafi,
    String locationName = 'Current Location',
  }) {
    final tz = timezoneOffsetHours ?? (date.timeZoneOffset.inMinutes / 60.0);

    // Julian Date
    final year = date.year;
    final month = date.month;
    final day = date.day;

    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;

    final d = jd - 2451545.0; // days since J2000.0

    // Solar mean anomaly
    final g = (357.529 + 0.98560028 * d) % 360.0;
    final gRad = _degToRad(g);

    // Solar mean longitude
    final q = (280.459 + 0.98564736 * d) % 360.0;

    // Apparent solar longitude
    final l = (q + 1.915 * math.sin(gRad) + 0.020 * math.sin(2 * gRad)) % 360.0;
    final lRad = _degToRad(l);

    // Obliquity of the ecliptic
    final e = 23.439 - 0.00000036 * d;
    final eRad = _degToRad(e);

    // Right ascension & Declination
    final ra = (_radToDeg(math.atan2(math.cos(eRad) * math.sin(lRad), math.cos(lRad))) / 15.0) % 24.0;
    final dec = math.asin(math.sin(eRad) * math.sin(lRad)); // in radians
    final latRad = _degToRad(latitude);

    // Equation of time (in hours)
    final eqt = (q / 15.0) - ra;

    // Solar transit (Dhuhr) in hours (local solar noon)
    final noon = 12.0 + tz - (longitude / 15.0) - eqt;

    // Calculation Method parameters
    double fajrAngle = 18.0;
    double ishaAngle = 18.0;
    bool ishaInterval = false;
    double ishaIntervalMinutes = 90.0;

    switch (method) {
      case CalculationMethod.karachi:
        fajrAngle = 18.0;
        ishaAngle = 18.0;
        break;
      case CalculationMethod.mwl:
        fajrAngle = 18.0;
        ishaAngle = 17.0;
        break;
      case CalculationMethod.isna:
        fajrAngle = 15.0;
        ishaAngle = 15.0;
        break;
      case CalculationMethod.ummAlQura:
        fajrAngle = 18.5;
        ishaInterval = true;
        ishaIntervalMinutes = 90.0;
        break;
      case CalculationMethod.egyptian:
        fajrAngle = 19.5;
        ishaAngle = 17.5;
        break;
      case CalculationMethod.tehran:
        fajrAngle = 17.7;
        ishaAngle = 14.0;
        break;
      case CalculationMethod.gulf:
        fajrAngle = 19.5;
        ishaInterval = true;
        ishaIntervalMinutes = 90.0;
        break;
    }

    // Helper: Hour angle calculation for a given zenith angle (in degrees)
    double? getHourAngle(double angle) {
      final zenithRad = _degToRad(angle);
      final cosHa = (math.cos(zenithRad) - math.sin(latRad) * math.sin(dec)) /
          (math.cos(latRad) * math.cos(dec));

      if (cosHa < -1.0 || cosHa > 1.0) return null; // Extreme latitude
      return _radToDeg(math.acos(cosHa)) / 15.0; // in hours
    }

    // Sunrise & Sunset (Zenith angle = 90° + 0.833° refraction)
    final sunHa = getHourAngle(90.833) ?? 6.0;
    final sunriseHour = noon - sunHa;
    final sunsetHour = noon + sunHa;

    // Fajr (Zenith angle = 90° + fajrAngle)
    final fajrHa = getHourAngle(90.0 + fajrAngle) ?? (sunHa + 1.25);
    final fajrHour = noon - fajrHa;

    // Maghrib = sunset
    final maghribHour = sunsetHour;

    // Asr (Shadow length)
    final shadowFactor = (juristic == JuristicMethod.hanafi) ? 2.0 : 1.0;
    final asrZenith = _radToDeg(math.atan(shadowFactor + math.tan((latRad - dec).abs())));
    final asrHa = getHourAngle(asrZenith) ?? (sunHa * 0.5);
    final asrHour = noon + asrHa;

    // Isha
    double ishaHour;
    if (ishaInterval) {
      ishaHour = maghribHour + (ishaIntervalMinutes / 60.0);
    } else {
      final ishaHa = getHourAngle(90.0 + ishaAngle) ?? (sunHa + 1.25);
      ishaHour = noon + ishaHa;
    }

    // Helper: converts float hours to DateTime
    DateTime hourToDateTime(double h) {
      var normH = h % 24.0;
      if (normH < 0) normH += 24.0;
      final intHour = normH.floor();
      final fracMin = (normH - intHour) * 60.0;
      final intMin = fracMin.floor();
      final intSec = ((fracMin - intMin) * 60.0).round();
      return DateTime(year, month, day, intHour, intMin, intSec);
    }

    final fajrDt = hourToDateTime(fajrHour);
    final sunriseDt = hourToDateTime(sunriseHour);
    final dhuhrDt = hourToDateTime(noon);
    final asrDt = hourToDateTime(asrHour);
    final maghribDt = hourToDateTime(maghribHour);
    final ishaDt = hourToDateTime(ishaHour);

    // Hijri date conversion
    final hijri = HijriCalendar.fromDate(date);
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return PrayerTimesModel(
      date: date,
      fajr: fajrDt,
      sunrise: sunriseDt,
      dhuhr: dhuhrDt,
      asr: asrDt,
      maghrib: maghribDt,
      isha: ishaDt,
      imsak: fajrDt.subtract(const Duration(minutes: 10)),
      midnight: maghribDt.add(fajrDt.add(const Duration(days: 1)).difference(maghribDt) ~/ 2),
      hijriDate: hijriStr,
      locationName: locationName,
      calculationMethod: method.name.toUpperCase(),
      fiqhName: juristic == JuristicMethod.hanafi ? 'Hanafi • حَنَفِي' : 'Shafi\'i • شَافِعِي',
    );
  }
}
