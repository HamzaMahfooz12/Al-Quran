// ─────────────────────────────────────────────────────────────────────────────
// lib/main.dart
// App entry point — Riverpod + GoRouter + first-launch seeding guard
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/db/db_helper.dart';
import 'data/db/tafseer_import_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit backend for just_audio on Windows/Linux/macOS
  JustAudioMediaKit.ensureInitialized();

  // Initialize FFI for Desktop (Windows / Linux / macOS)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Pre-initialize DB helper (will seed on first launch inside)
  final dbHelper = DatabaseHelper.instance;
  final mainDb = await dbHelper.database; // triggers onCreate if first launch

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlQuranApp(),
    ),
  );

  // One-time: import bundled tafseer AFTER UI is up (non-blocking)
  TafseerImportService.importOnce(mainDb);
}

// Provider for SharedPreferences — accessed anywhere via ref.read
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences not initialized'),
);

class AlQuranApp extends ConsumerWidget {
  const AlQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Al Quran',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
