// lib/services/prayer_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/prayer_times/models/prayer_times_model.dart';

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Create Notification Channel for Adhan / Prayers
    const androidChannel = AndroidNotificationChannel(
      'prayer_times_channel',
      'Prayer Times & Adhan',
      description: 'Daily prayer notifications and Adhan reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static const _kPrefPrefix = 'prayer_notif_enabled_';

  static Future<bool> isPrayerNotificationEnabled(PrayerType prayer) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kPrefPrefix${prayer.name}') ?? true;
  }

  static Future<void> setPrayerNotificationEnabled(PrayerType prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPrefPrefix${prayer.name}', enabled);
  }

  /// Schedules local notifications for upcoming daily prayer times
  static Future<void> schedulePrayerNotifications(PrayerTimesModel model) async {
    await init();

    final prayers = model.allPrayers;
    final now = DateTime.now();

    for (final entry in prayers.entries) {
      final prayer = entry.key;
      final time = entry.value;

      // Only schedule notifications for the 5 Fardh prayers
      if (prayer == PrayerType.sunrise ||
          prayer == PrayerType.ishraq ||
          prayer == PrayerType.chasht ||
          prayer == PrayerType.zawal ||
          prayer == PrayerType.sunset) {
        continue;
      }

      final isEnabled = await isPrayerNotificationEnabled(prayer);
      if (!isEnabled) continue;

      if (time.isAfter(now)) {
        final id = prayer.index + 100;
        final prayerName = PrayerTimesModel.getPrayerName(prayer);
        final arabicName = PrayerTimesModel.getArabicPrayerName(prayer);

        await _notificationsPlugin.show(
          id,
          'Time for $prayerName Prayer ($arabicName)',
          'It is now time for $prayerName in ${model.locationName}.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_times_channel',
              'Prayer Times & Adhan',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
      }
    }
  }
}
