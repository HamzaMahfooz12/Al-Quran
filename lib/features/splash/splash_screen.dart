// lib/features/splash/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/db/db_helper.dart';
import '../../services/settings_service.dart';

// ── Logo colours extracted from the blue/silver emblem ─────────────────────
const _kDeepNavy    = Color(0xFF060E2B); // darkest — background deep
const _kRoyalBlue   = Color(0xFF1A3A9E); // logo main blue
const _kMidBlue     = Color(0xFF2652CC); // brighter logo highlight
const _kSilver      = Color(0xFFCDD5E8); // silver calligraphy colour
const _kSilverGlow  = Color(0xFFE8EDF8); // bright silver highlight

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // Logo entrance — scale + fade
  late final AnimationController _enterCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // Continuous glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Shimmer particles rotation
  late final AnimationController _shimmerCtrl;

  bool _seedingDone = false;
  bool _minTimeDone = false;

  @override
  void initState() {
    super.initState();

    // ── 1. Logo entrance animation (600ms) ────────────────────────────────
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );
    _enterCtrl.forward();

    // ── 2. Continuous glow pulse ──────────────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ── 3. Slow rotating shimmer ring ────────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // ── 4. Enforce minimum 2-second splash + run seeding ─────────────────
    Future.wait([
      Future.delayed(const Duration(seconds: 2), () => _minTimeDone = true),
      _runSeeding(),
    ]).then((_) => _navigateAway());
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSeeding() async {
    final db = DatabaseHelper.instance;
    await db.database;
    _seedingDone = true;
  }

  void _navigateAway() {
    if (!mounted) return;
    final settings = ref.read(settingsServiceProvider);
    if (!settings.isOnboardingDone) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _kDeepNavy,
      body: Stack(
        children: [
          // ── Background gradient (deep navy → royal blue → midnight) ──────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.3,
                  colors: [
                    _kMidBlue,
                    _kRoyalBlue,
                    Color(0xFF0D1E5C),
                    _kDeepNavy,
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── Subtle Islamic geometric overlay (rotates slowly) ─────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => CustomPaint(
                painter: _IslamicPatternPainter(
                  rotation: _shimmerCtrl.value * 2 * math.pi,
                  color: _kSilver.withValues(alpha: 0.04),
                ),
              ),
            ),
          ),

          // ── Centre content ────────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Glowing logo ───────────────────────────────────────
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) => Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // Inner royal blue glow
                            BoxShadow(
                              color: _kMidBlue.withValues(alpha: 0.55 * _glowAnim.value),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            // Outer silver shimmer
                            BoxShadow(
                              color: _kSilverGlow.withValues(alpha: 0.22 * _glowAnim.value),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo_emblem.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Arabic name ───────────────────────────────────────
                    Text(
                      'حفظ القرآن',
                      style: GoogleFonts.amiri(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: _kSilverGlow,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: _kMidBlue.withValues(alpha: 0.8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── English name ──────────────────────────────────────
                    Text(
                      'Hifz ul Quran',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tagline ───────────────────────────────────────────
                    Text(
                      'Read • Memorize • Reflect',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: _kSilver.withValues(alpha: 0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom — silver shimmer line + loading dots ───────────────────
          Positioned(
            bottom: 56 + MediaQuery.paddingOf(context).bottom,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Thin silver divider with gradient
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _kSilver.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Loading dots animation
                  _LoadingDots(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated loading dots ─────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (math.sin(t * math.pi)).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kSilver,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Islamic geometric star pattern painter ────────────────────────────────────
class _IslamicPatternPainter extends CustomPainter {
  final double rotation;
  final Color color;

  const _IslamicPatternPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const patternSize = 120.0;
    final cols = (size.width / patternSize).ceil() + 2;
    final rows = (size.height / patternSize).ceil() + 2;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation * 0.05); // very slow rotation
    canvas.translate(-size.width / 2, -size.height / 2);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * patternSize + (row.isOdd ? patternSize / 2 : 0);
        final cy = row * patternSize;
        _drawStar8(canvas, paint, Offset(cx, cy), patternSize * 0.38);
      }
    }
    canvas.restore();
  }

  void _drawStar8(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    const points = 8;
    const innerRatio = 0.42;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : r * innerRatio;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IslamicPatternPainter old) =>
      old.rotation != rotation || old.color != color;
}
