// lib/core/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/verse_by_verse/verse_by_verse_screen.dart';
import '../../features/verse_by_verse/ayah_list_screen.dart';
import '../../features/mushaf_15/mushaf_15_screen.dart';
import '../../features/mushaf_16/mushaf_16_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/settings/settings_screen.dart';

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
        builder: (ctx, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'surah/:surahNumber',
            name: 'verse-by-verse',
            builder: (ctx, state) {
              final surah = int.parse(state.pathParameters['surahNumber']!);
              final ayah = int.tryParse(
                      state.uri.queryParameters['ayah'] ?? '') ??
                  1;
              return AyahListScreen(surahNumber: surah, scrollToAyah: ayah);
            },
          ),
          GoRoute(
            path: 'mushaf-15',
            name: 'mushaf-15',
            builder: (ctx, state) {
              final page = int.tryParse(
                      state.uri.queryParameters['page'] ?? '') ??
                  1;
              return Mushaf15Screen(initialPage: page);
            },
          ),
          GoRoute(
            path: 'mushaf-16',
            name: 'mushaf-16',
            builder: (ctx, state) {
              final page = int.tryParse(
                      state.uri.queryParameters['page'] ?? '') ??
                  1;
              return Mushaf16Screen(initialPage: page);
            },
          ),
          GoRoute(
            path: 'bookmarks',
            name: 'bookmarks',
            builder: (ctx, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (ctx, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
