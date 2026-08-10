// lib/features/splash/splash_screen.dart
// First-launch loading screen — shown while QuranSeeder downloads & seeds DB
// Never shown again once seeding is done (checked via isSeeded())
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/db_helper.dart';
import '../../data/db/quran_seeder.dart';
import '../../services/settings_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _message = 'Preparing Quran data...';
  bool _done = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _runSeeding();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSeeding() async {
    final db = DatabaseHelper.instance;
    final seeder = QuranSeeder(
      db,
      Dio(),
      onProgress: (progress, message) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _message = message;
          });
        }
      },
    );

    final alreadySeeded = await seeder.isAlreadySeeded();

    if (!alreadySeeded) {
      await seeder.seed();
    }

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _message = 'Ready!';
        _done = true;
      });

      // Short pause to show "Ready!" before navigating
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final settings = ref.read(settingsServiceProvider);
        if (!settings.isOnboardingDone) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        '☪',
                        style: TextStyle(fontSize: 66, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Al Quran',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Read. Listen. Reflect.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),

                const SizedBox(height: 60),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _message,
                    key: ValueKey(_message),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                if (_done) ...[
                  const SizedBox(height: 12),
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.gold, size: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
