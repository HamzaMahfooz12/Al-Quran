// lib/features/qibla/screens/qibla_screen.dart
// Premium Islamic Qibla Compass with 3D Faceted Needle, Smooth Damping, and Alignment Aura

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../../prayer_times/services/prayer_service.dart';
import '../../prayer_times/widgets/location_picker_bottom_sheet.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const QiblaScreen({super.key, this.isActive = true});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSub;
  double _smoothedHeading = 0.0;
  bool _hasVibratedForAlignment = false;
  DateTime? _lastVibratedTime;
  bool _compassAvailable = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Kaaba coordinates (Makkah al-Mukarramah)
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _startCompass();
    }
  }

  @override
  void didUpdateWidget(QiblaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startCompass();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopCompass();
    }
  }

  @override
  void dispose() {
    _stopCompass();
    _pulseController.dispose();
    super.dispose();
  }

  void _stopCompass() {
    _compassSub?.cancel();
    _compassSub = null;
  }

  void _startCompass() {
    if (!widget.isActive) return;
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (!mounted || !widget.isActive) return;
      final rawHeading = event.heading;
      if (rawHeading == null) {
        if (mounted) setState(() => _compassAvailable = false);
        return;
      }

      final targetHeading = ((rawHeading % 360) + 360) % 360;

      // Low-pass exponential smoothing filter for silky smooth compass rotation
      double diff = targetHeading - _smoothedHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      final smoothed = ((_smoothedHeading + diff * 0.28) + 360) % 360;

      final location = ref.read(selectedLocationProvider);
      final qiblaBearing =
          _calculateQiblaBearing(location.latitude, location.longitude);
      final angleDiff = (smoothed - qiblaBearing).abs();
      final isAligned = angleDiff < 3.5 || angleDiff > 356.5;

      if (isAligned) {
        final now = DateTime.now();
        final canVibrate = _lastVibratedTime == null ||
            now.difference(_lastVibratedTime!).inSeconds >= 4;
        if (!_hasVibratedForAlignment && canVibrate && widget.isActive) {
          _hasVibratedForAlignment = true;
          _lastVibratedTime = now;
          HapticFeedback.heavyImpact();
          Vibration.hasVibrator().then((hasVib) {
            if (hasVib == true && widget.isActive && mounted) {
              Vibration.vibrate(pattern: [0, 60, 40, 90]);
            }
          });
        }
      } else {
        _hasVibratedForAlignment = false;
      }

      if (mounted) {
        setState(() {
          _smoothedHeading = smoothed;
          _compassAvailable = true;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _compassAvailable = false);
    });
  }

  double _calculateQiblaBearing(double lat, double lng) {
    final lat1 = lat * (math.pi / 180.0);
    final lng1 = lng * (math.pi / 180.0);
    final lat2 = _kaabaLat * (math.pi / 180.0);
    final lng2 = _kaabaLng * (math.pi / 180.0);
    final dLng = lng2 - lng1;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    double bearing = math.atan2(y, x) * (180.0 / math.pi);
    if (bearing < 0) bearing += 360.0;
    return bearing;
  }

  double _calculateDistanceToKaaba(double lat, double lng) {
    const r = 6371.0;
    final dLat = (_kaabaLat - lat) * (math.pi / 180.0);
    final dLng = (_kaabaLng - lng) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * (math.pi / 180.0)) *
            math.cos(_kaabaLat * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _getCardinalDirection(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg + 22.5) % 360 ~/ 45);
    return dirs[idx];
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.screen_rotation_rounded,
                color: Color(0xFF2C7A39), size: 24),
            const SizedBox(width: 10),
            Text(
              'Calibrate Compass',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B2A1E)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To ensure maximum compass accuracy:',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B2A1E)),
            ),
            const SizedBox(height: 10),
            _calibrationStep(
                '1', 'Wave your phone in a Figure-8 motion in the air 3 times.'),
            const SizedBox(height: 8),
            _calibrationStep('2',
                'Hold your phone flat / horizontal on your palm parallel to the ground.'),
            const SizedBox(height: 8),
            _calibrationStep('3',
                'Keep away from strong metal objects, laptops, and magnetic cases.'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C7A39),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got It',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _calibrationStep(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF6EC),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C7A39),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
                fontSize: 12.5, color: const Color(0xFF4B5E50), height: 1.35),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final qiblaBearing =
        _calculateQiblaBearing(location.latitude, location.longitude);
    final distanceKm =
        _calculateDistanceToKaaba(location.latitude, location.longitude);

    final angleDiff = (_smoothedHeading - qiblaBearing).abs();
    final isAligned = angleDiff < 3.5 || angleDiff > 356.5;
    final alignmentDegreesOff = (angleDiff > 180) ? 360 - angleDiff : angleDiff;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF2C7A39), size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          children: [
            Text(
              'Qibla Compass',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2A1E),
              ),
            ),
            Text(
              'بوصلة القبلة المشرفة',
              style: GoogleFonts.amiri(
                fontSize: 12,
                color: const Color(0xFF2C7A39),
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: Color(0xFF2C7A39), size: 22),
            tooltip: 'Compass Calibration',
            onPressed: _showCalibrationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: Color(0xFF2C7A39), size: 22),
            tooltip: 'Change Location',
            onPressed: () => LocationPickerBottomSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 6),

            // ── 1. Top Location Banner ──
            InkWell(
              onTap: () => LocationPickerBottomSheet.show(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF2C7A39).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF2C7A39).withValues(alpha: 0.2),
                      width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2C7A39).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF6EC), Color(0xFFD6EEDB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2C7A39)
                                .withValues(alpha: 0.25)),
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on_rounded,
                            color: Color(0xFF2C7A39), size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                location.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B2A1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'GPS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Distance to Kaaba: ${distanceKm.toStringAsFixed(0)} km • ${_getCardinalDirection(qiblaBearing)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF526E5B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF2C7A39), size: 22),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── 2. Master Realistic Compass Dial with 3D Faceted Needle ──
            if (!_compassAvailable)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.sensors_off_rounded,
                        size: 54, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Compass sensor not detected on this device.\nPlease ensure location and orientation permissions are enabled.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Alignment Outer Glow Aura
                      if (isAligned)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (ctx, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 310,
                                height: 310,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF2C7A39)
                                          .withValues(alpha: 0.35),
                                      const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.65, 0.85, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Outer Fixed Brass Bezel & Shadow
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFAF7F2),
                              Color(0xFFEFE7D8),
                              Color(0xFFFAF7F2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isAligned
                                ? const Color(0xFF2C7A39)
                                : const Color(0xFFD4AF37),
                            width: isAligned ? 2.5 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isAligned
                                  ? const Color(0xFF2C7A39)
                                      .withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: isAligned ? 24 : 16,
                              spreadRadius: isAligned ? 4 : 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      // Inner Parchment Face
                      Container(
                        width: 278,
                        height: 278,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFFE8E1D2), width: 1.2),
                        ),
                      ),

                      // Rotating Compass Dial (Dial Rotates With Phone Heading)
                      Transform.rotate(
                        angle: -_smoothedHeading * (math.pi / 180.0),
                        child: SizedBox(
                          width: 278,
                          height: 278,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Custom Dial with Degree Ticks & Rosette Lines
                              CustomPaint(
                                size: const Size(278, 278),
                                painter: _RealisticCompassDialPainter(
                                  isAligned: isAligned,
                                  qiblaAngleDeg: qiblaBearing,
                                ),
                              ),

                              // North 'N' Badge
                              Positioned(
                                top: 22,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C7A39)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'N',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2C7A39),
                                    ),
                                  ),
                                ),
                              ),

                              // South 'S'
                              Positioned(
                                bottom: 24,
                                child: Text(
                                  'S',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),

                              // East 'E'
                              Positioned(
                                right: 24,
                                child: Text(
                                  'E',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),

                              // West 'W'
                              Positioned(
                                left: 24,
                                child: Text(
                                  'W',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),

                              // Kaaba Emblem at exact Qibla Bearing along the dial rim
                              _buildKaabaRimMarker(qiblaBearing, isAligned),
                            ],
                          ),
                        ),
                      ),

                      // Center 3D Faceted Qibla Needle Pointing Directly to Kaaba
                      Transform.rotate(
                        angle: (qiblaBearing - _smoothedHeading) *
                            (math.pi / 180.0),
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _Faceted3DQiblaNeedlePainter(
                            isAligned: isAligned,
                          ),
                        ),
                      ),

                      // Top Glass Highlight Layer
                      IgnorePointer(
                        child: Container(
                          width: 278,
                          height: 278,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.03),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // ── 3. Angle Readout Dashboard Card ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🕋', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Qibla Direction',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${qiblaBearing.toStringAsFixed(1)}°',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2A1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1, height: 46, color: const Color(0xFFE8E1D2)),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_rounded,
                              color: isAligned
                                  ? const Color(0xFF2C7A39)
                                  : const Color(0xFFF59E0B),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Your Direction',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_smoothedHeading.toStringAsFixed(1)}°',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isAligned
                                ? const Color(0xFF2C7A39)
                                : const Color(0xFF1B2A1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── 4. Dynamic Live Status Alignment Banner ──
            Container(
              margin: EdgeInsets.fromLTRB(
                  16, 0, 16, 14 + MediaQuery.paddingOf(context).bottom),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: isAligned
                    ? const LinearGradient(
                        colors: [Color(0xFF2C7A39), Color(0xFF1B4332)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isAligned ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isAligned
                      ? const Color(0xFF2C7A39)
                      : const Color(0xFFE8E1D2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAligned
                        ? const Color(0xFF2C7A39).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isAligned
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isAligned
                            ? Icons.check_circle_rounded
                            : Icons.near_me_rounded,
                        color: isAligned
                            ? const Color(0xFF1B4332)
                            : const Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAligned
                              ? 'Alhamdulillah! Perfectly Aligned'
                              : 'Rotate Device (${alignmentDegreesOff.toStringAsFixed(0)}° off)',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isAligned
                                ? Colors.white
                                : const Color(0xFF1B2A1E),
                          ),
                        ),
                        Text(
                          isAligned
                              ? 'You are now facing the Holy Kaaba in Makkah.'
                              : 'Turn until the golden needle points directly upward to the Kaaba.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isAligned
                                ? const Color(0xFFA5D6A7)
                                : const Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKaabaRimMarker(double qiblaAngleDeg, bool isAligned) {
    final rad = qiblaAngleDeg * (math.pi / 180.0);
    const radius = 106.0;
    final x = radius * math.sin(rad);
    final y = -radius * math.cos(rad);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A1E),
          shape: BoxShape.circle,
          border: Border.all(
            color: isAligned
                ? const Color(0xFFFFD54F)
                : const Color(0xFFD4AF37),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isAligned
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: isAligned ? 10 : 4,
              spreadRadius: isAligned ? 2 : 0,
            ),
          ],
        ),
        child: const Center(
          child: Text('🕋', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

// ── Realistic Compass Dial Painter with Sub-Degrees & Islamic Geometry ────────
class _RealisticCompassDialPainter extends CustomPainter {
  final bool isAligned;
  final double qiblaAngleDeg;

  _RealisticCompassDialPainter({
    required this.isAligned,
    required this.qiblaAngleDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer subtle circle
    final ringPaint = Paint()
      ..color = const Color(0xFFE8E1D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 10, ringPaint);
    canvas.drawCircle(center, radius - 26, ringPaint);

    // Minor & Major Ticks around 360 degrees
    final tickPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      final isCardinal = (i % 90 == 0);
      final isMajor = (i % 30 == 0);
      final isTen = (i % 10 == 0);

      final double tickLen = isCardinal
          ? 12.0
          : isMajor
              ? 9.0
              : isTen
                  ? 6.0
                  : 3.5;

      final rad = i * (math.pi / 180.0);
      final p1 = Offset(
        center.dx + (radius - 10) * math.sin(rad),
        center.dy - (radius - 10) * math.cos(rad),
      );
      final p2 = Offset(
        center.dx + (radius - 10 - tickLen) * math.sin(rad),
        center.dy - (radius - 10 - tickLen) * math.cos(rad),
      );

      tickPaint.strokeWidth = isCardinal
          ? 2.0
          : isMajor
              ? 1.5
              : 0.9;
      tickPaint.color = isCardinal
          ? (i == 0 ? const Color(0xFF2C7A39) : const Color(0xFF4B5E50))
          : isMajor
              ? const Color(0xFFD4AF37)
              : const Color(0xFFD1D5DB);

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticCompassDialPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.qiblaAngleDeg != qiblaAngleDeg;
  }
}

// ── 3D Faceted Realistic Islamic Needle Custom Painter ──────────────────────
class _Faceted3DQiblaNeedlePainter extends CustomPainter {
  final bool isAligned;

  _Faceted3DQiblaNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Needle Dimensions
    const pointerLength = 100.0;
    const tailLength = 62.0;
    const halfWidth = 14.0;
    const tailHalfWidth = 9.0;

    final tip = Offset(center.dx, center.dy - pointerLength);
    final tailTip = Offset(center.dx, center.dy + tailLength);
    final leftMid = Offset(center.dx - halfWidth, center.dy);
    final rightMid = Offset(center.dx + halfWidth, center.dy);
    final tailLeftMid = Offset(center.dx - tailHalfWidth, center.dy);
    final tailRightMid = Offset(center.dx + tailHalfWidth, center.dy);

    // ── 1. Needle Drop Shadow ──
    final shadowPath = Path()
      ..moveTo(tip.dx + 2, tip.dy + 3)
      ..lineTo(rightMid.dx + 2, rightMid.dy + 3)
      ..lineTo(tailTip.dx + 2, tailTip.dy + 3)
      ..lineTo(leftMid.dx + 2, leftMid.dy + 3)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(shadowPath, shadowPaint);

    // ── 2. Top Pointer: Left Facet (Illuminated Side) ──
    final leftPointerPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(leftMid.dx, leftMid.dy)
      ..close();

    final leftPointerPaint = Paint()
      ..shader = LinearGradient(
        colors: isAligned
            ? [const Color(0xFFFFE082), const Color(0xFFF59E0B)]
            : [const Color(0xFF56BA64), const Color(0xFF38A14A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(tip, leftMid));
    canvas.drawPath(leftPointerPath, leftPointerPaint);

    // ── 3. Top Pointer: Right Facet (Shadowed Side) ──
    final rightPointerPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(rightMid.dx, rightMid.dy)
      ..close();

    final rightPointerPaint = Paint()
      ..shader = LinearGradient(
        colors: isAligned
            ? [const Color(0xFFD97706), const Color(0xFFB45309)]
            : [const Color(0xFF2C7A39), const Color(0xFF1B4332)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(tip, rightMid));
    canvas.drawPath(rightPointerPath, rightPointerPaint);

    // ── 4. Bottom Tail: Left Facet (Silver Illuminated) ──
    final leftTailPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(tailTip.dx, tailTip.dy)
      ..lineTo(tailLeftMid.dx, tailLeftMid.dy)
      ..close();

    final leftTailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(center, tailTip));
    canvas.drawPath(leftTailPath, leftTailPaint);

    // ── 5. Bottom Tail: Right Facet (Silver Shadowed) ──
    final rightTailPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(tailTip.dx, tailTip.dy)
      ..lineTo(tailRightMid.dx, tailRightMid.dy)
      ..close();

    final rightTailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(center, tailTip));
    canvas.drawPath(rightTailPath, rightTailPaint);

    // ── 6. Needle Center Centerline Ridge ──
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(tip, center, ridgePaint);

    // ── 7. Multi-Layered Brass & Emerald Pivot Center Cap ──
    // Outer Gold Ring
    final pivotOuterPaint = Paint()
      ..shader = RadialGradient(
        colors: isAligned
            ? [const Color(0xFFFFD54F), const Color(0xFFB45309)]
            : [const Color(0xFFE5E7EB), const Color(0xFF6B7280)],
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawCircle(center, 14, pivotOuterPaint);

    // Inner Jewel Ring
    final pivotJewelPaint = Paint()
      ..color =
          isAligned ? const Color(0xFF1B4332) : const Color(0xFF2C7A39);
    canvas.drawCircle(center, 9, pivotJewelPaint);

    // Center Gold Gem Core
    final gemPaint = Paint()
      ..color =
          isAligned ? const Color(0xFFFFD54F) : const Color(0xFFFEF3C7);
    canvas.drawCircle(center, 4.5, gemPaint);

    // Center Specular Glint
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 1.5, glintPaint);
  }

  @override
  bool shouldRepaint(covariant _Faceted3DQiblaNeedlePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}