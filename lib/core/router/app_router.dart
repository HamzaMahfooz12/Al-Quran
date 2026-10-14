// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/verse_by_verse/ayah_list_screen.dart';
import '../../features/juz/juz_screen.dart';
import '../../features/mushaf_15/mushaf_15_screen.dart';
import '../../features/mushaf_16/mushaf_16_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/mark_mistakes/mistakes_report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/prayer_times/screens/prayer_times_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/tasbeeh/screens/tasbeeh_screen.dart';
import '../../features/azkar/screens/azkar_screen.dart';
import '../../features/azkar/screens/duas_settings_screen.dart';
import '../../features/search/screens/quran_search_screen.dart';
import '../../features/mutashabihat/screens/mutashabihat_screen.dart';
import '../../features/quran/simple_quran_index_screen.dart';
import '../../features/full_surah_audio/screens/full_surah_audio_index_screen.dart';
import '../../features/full_surah_audio/screens/full_surah_audio_player_screen.dart';
import '../../features/full_surah_audio/screens/full_surah_downloads_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (ctx, state) => const MainShell(),
        routes: [
          GoRoute(
            path: 'simple-quran',
            name: 'simple-quran',
            builder: (ctx, state) {
              final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
              return SimpleQuranIndexScreen(initialTabIndex: tab);
            },
          ),
          GoRoute(
            path: 'surah/:surahNumber',
            name: 'verse-by-verse',
            builder: (ctx, state) {
              final surah = int.parse(state.pathParameters['surahNumber']!);
              final ayah = int.tryParse(state.uri.queryParameters['ayah'] ?? '') ??
                  int.tryParse(state.uri.queryParameters['scrollToAyah'] ?? '') ??
                  1;
              return AyahListScreen(
                key: ValueKey('surah_${surah}_ayah_$ayah'),
                surahNumber: surah,
                scrollToAyah: ayah,
              );
            },
          ),
          GoRoute(
            path: 'juz/:juzNumber',
            name: 'juz',
            builder: (ctx, state) {
              final juz = int.parse(state.pathParameters['juzNumber']!);
              return JuzScreen(juzNumber: juz);
            },
          ),
          GoRoute(
            path: 'mushaf-15',
            name: 'mushaf-15',
            builder: (ctx, state) {
              final page = int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1;
              return Mushaf15Screen(initialPage: page);
            },
          ),
          GoRoute(
            path: 'mushaf-16',
            name: 'mushaf-16',
            builder: (ctx, state) {
              final page = int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1;
              return Mushaf16Screen(initialPage: page);
            },
          ),
          GoRoute(path: 'bookmarks', name: 'bookmarks', builder: (ctx, state) => const BookmarksScreen()),
          GoRoute(path: 'mistakes-report', name: 'mistakes-report', builder: (ctx, state) => const MistakesReportScreen()),
          GoRoute(path: 'settings', name: 'settings', builder: (ctx, state) => const SettingsScreen()),
          GoRoute(path: 'prayer-times', name: 'prayer-times', builder: (ctx, state) => const PrayerTimesScreen()),
          GoRoute(path: 'qibla', name: 'qibla', builder: (ctx, state) => const QiblaScreen()),
          GoRoute(path: 'tasbeeh', name: 'tasbeeh', builder: (ctx, state) => const TasbeehScreen()),
          GoRoute(path: 'azkar', name: 'azkar', builder: (ctx, state) => const AzkarScreen()),
          GoRoute(path: 'azkar/settings', name: 'duas-settings', builder: (ctx, state) => const DuasSettingsScreen()),
          GoRoute(path: 'search', name: 'search', builder: (ctx, state) => const QuranSearchScreen()),
          GoRoute(
            path: 'mutashabihat',
            name: 'mutashabihat',
            builder: (ctx, state) {
              final juz = int.tryParse(state.uri.queryParameters['juz'] ?? '') ?? 1;
              return MutashabihatScreen(initialJuz: juz);
            },
          ),
          GoRoute(
            path: 'full-surah-audio',
            name: 'full-surah-audio',
            builder: (ctx, state) => const FullSurahAudioIndexScreen(),
            routes: [
              GoRoute(
                path: 'player',
                name: 'full-surah-audio-player',
                builder: (ctx, state) {
                  final surah = int.tryParse(state.uri.queryParameters['surah'] ?? '') ?? 1;
                  return FullSurahAudioPlayerScreen(initialSurah: surah);
                },
              ),
              GoRoute(
                path: 'downloads',
                name: 'full-surah-audio-downloads',
                builder: (ctx, state) => const FullSurahDownloadsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});