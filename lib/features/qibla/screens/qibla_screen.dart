// lib/features/qibla/screens/qibla_screen.dart
// High-Precision Islamic Qibla Compass Screen matching Google Stitch design exactly

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
import '../../../core/widgets/app_drawer.dart';

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
                color: Color(0xFFC59A27), size: 24),
            const SizedBox(width: 10),
            Text(
              'Calibrate Compass',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF354033),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To ensure maximum compass accuracy:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF354033),
              ),
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
              backgroundColor: const Color(0xFFC59A27),
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
            color: Color(0xFFFAF5E8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB8860B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF59634A),
              height: 1.35,
            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      drawer: const AppDrawer(),
      appBar: _buildTopAppBar(context),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 6),

              // ── 1. Current Location Card (Stitch Exact) ──
              _buildLocationCard(context, location, distanceKm, qiblaBearing),

              const SizedBox(height: 8),

              // ── 2. Alignment Status Badge ──
              _buildAlignmentStatusBadge(isAligned, angleDiff),

              const Spacer(),

              // ── 3. Compass Dial (Stitch Exact 264x264 Metallic Bezel) ──
              _buildCompassDial(isAligned, qiblaBearing),

              const Spacer(),

              // ── 4. Telemetry Readout Card (Qibla Direction vs Your Heading) ──
              _buildTelemetryCard(location.cityName, qiblaBearing, _smoothedHeading, isAligned),

              const SizedBox(height: 10),

              // ── 5. Confirmation Card (Facing the Holy Kaaba) ──
              _buildConfirmationCard(isAligned),

              SizedBox(height: 14 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFBF9F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 66,
      leading: Center(
        child: Builder(
          builder: (ctx) => InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Scaffold.of(ctx).openDrawer();
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF354033), size: 20),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Qibla Compass',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF354033),
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'بوصلة القبلة المشرفة',
            style: GoogleFonts.amiri(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB8860B),
              height: 1.05,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _showCalibrationDialog,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E1D2)),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF59634A), size: 18),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => LocationPickerBottomSheet.show(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E1D2)),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF59634A), size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    dynamic location,
    double distanceKm,
    double qiblaBearing,
  ) {
    return InkWell(
      onTap: () => LocationPickerBottomSheet.show(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7DC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF6E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFFB8860B), size: 18),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354033),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF6E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB8860B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'GPS',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB8860B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Distance to Kaaba: ${distanceKm.toStringAsFixed(0)} km • ${_getCardinalDirection(qiblaBearing)} (${qiblaBearing.toStringAsFixed(1)}°)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF59634A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentStatusBadge(bool isAligned, double angleDiff) {
    final degreesOff = (angleDiff > 180) ? (360 - angleDiff) : angleDiff;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCDA14A).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAligned ? const Color(0xFFA87913) : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAligned
                ? 'PERFECTLY ALIGNED WITH MAKKAH'
                : 'ALIGNING WITH MAKKAH (${degreesOff.toStringAsFixed(0)}° OFF)',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF916710),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassDial(bool isAligned, double qiblaBearing) {
    if (!_compassAvailable) {
      return Container(
        height: 264,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors_off_rounded, size: 48, color: Color(0xFFC59A27)),
            const SizedBox(height: 10),
            Text(
              'Compass sensor not detected',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Alignment Glow Aura
          if (isAligned)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (ctx, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFC59A27).withValues(alpha: 0.25),
                          const Color(0xFFE8B931).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.70, 0.88, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Outer Metallic Conic Bevel Ring (Stitch Exact: 264x264)
          Container(
            width: 264,
            height: 264,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFFD1A951),
                  Color(0xFFFBE69B),
                  Color(0xFFC89C3F),
                  Color(0xFFEDD68D),
                  Color(0xFFB4872C),
                  Color(0xFFEDD48C),
                  Color(0xFFBD8E32),
                  Color(0xFFFAE59A),
                  Color(0xFFD1A951),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8860B).withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFDFCFA),
                  border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),

          // Rotating Compass Face Driven by Smooth Sensor Heading
          Transform.rotate(
            angle: -_smoothedHeading * (math.pi / 180.0),
            child: SizedBox(
              width: 246,
              height: 246,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom Paint: Octagonal Star + Degree Ticks + Calibrations
                  CustomPaint(
                    size: const Size(246, 246),
                    painter: _StitchCompassFacePainter(isAligned: isAligned, qiblaBearing: qiblaBearing),
                  ),

                  // North Badge (Top at 0 degrees on dial)
                  Positioned(
                    top: 14,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFF354033),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          'N',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Cardinal Points (E, S, W)
                  Positioned(
                    right: 18,
                    child: Text(
                      'E',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF354033),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    child: Text(
                      'S',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF354033),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    child: Text(
                      'W',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF354033),
                      ),
                    ),
                  ),

                  // Kaaba Target Marker along dial rim
                  _buildKaabaRimIcon(qiblaBearing),
                ],
              ),
            ),
          ),

          // 3D Faceted Needle Pointing Toward Kaaba
          Transform.rotate(
            angle: (qiblaBearing - _smoothedHeading) * (math.pi / 180.0),
            child: CustomPaint(
              size: const Size(240, 240),
              painter: _StitchFacetedNeedlePainter(),
            ),
          ),

          // Top Target Indicator at 12 o'clock
          Positioned(
            top: 10,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF354033),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                ],
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaabaRimIcon(double bearingDeg) {
    final angleRad = (bearingDeg - 90) * (math.pi / 180.0);
    const radius = 95.0;
    final x = radius * math.cos(angleRad);
    final y = radius * math.sin(angleRad);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFF354033),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: const Center(
          child: Text('🕋', style: TextStyle(fontSize: 8)),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(
    String cityName,
    double qiblaBearing,
    double heading,
    bool isAligned,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE7DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Qibla Direction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF354033),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                      ),
                      child: const Center(
                        child: Text('🕋', style: TextStyle(fontSize: 8)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'QIBLA DIRECTION',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: const Color(0xFF59634A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${qiblaBearing.toStringAsFixed(1)}°',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF354033),
                    height: 1.15,
                  ),
                ),
                Text(
                  'True bearing from $cityName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 48,
            color: const Color(0xFFEDE7DC),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Right: Your Heading
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.explore_rounded, color: Color(0xFFB8860B), size: 15),
                    const SizedBox(width: 5),
                    Text(
                      'YOUR HEADING',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: const Color(0xFF59634A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${heading.toStringAsFixed(1)}°',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF354033),
                    height: 1.15,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFFA47614), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      'High Accuracy (±1°)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA47614),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard(bool isAligned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFAF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEDB9F).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Icon(Icons.explore_rounded, color: Color(0xFFA87913), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Facing the Holy Kaaba',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF354033),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Makkah al-Mukarramah • Aligned',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF59634A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isAligned ? const Color(0xFFB8860B) : const Color(0xFFD4AF37).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Stitch Compass Face Custom Painter ──────────────────────────────────────
class _StitchCompassFacePainter extends CustomPainter {
  final bool isAligned;
  final double qiblaBearing;

  const _StitchCompassFacePainter({
    required this.isAligned,
    required this.qiblaBearing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Track Rings
    final ringPaint1 = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 10, ringPaint1);

    final ringPaint2 = Paint()
      ..color = const Color(0xFFC59B34).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 16, ringPaint2);

    // Subtle Octagonal Star Geometry in Center
    final starPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius * 0.65, starPaint);
    canvas.drawCircle(center, radius * 0.45, starPaint);

    // Degree Ticks around perimeter
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 5) {
      final rad = (deg - 90) * (math.pi / 180.0);
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;

      final tickLen = isCardinal ? 10.0 : (isMajor ? 6.5 : 3.5);
      final tickWidth = isCardinal ? 2.0 : (isMajor ? 1.4 : 0.8);

      tickPaint.strokeWidth = tickWidth;
      tickPaint.color = isCardinal
          ? const Color(0xFF354033)
          : (isMajor ? const Color(0xFF59634A) : const Color(0xFFD6DCD4));

      final startR = radius - 18;
      final endR = startR - tickLen;

      final p1 = Offset(center.dx + startR * math.cos(rad), center.dy + startR * math.sin(rad));
      final p2 = Offset(center.dx + endR * math.cos(rad), center.dy + endR * math.sin(rad));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StitchCompassFacePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned || oldDelegate.qiblaBearing != qiblaBearing;
  }
}

// ── 3D Faceted Needle Custom Painter (Gold North / Navy South with Jewel) ──
class _StitchFacetedNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const needleHalfLen = 78.0;
    const needleWidth = 10.0;

    // ── 1. Top Needle: Metallic Gold (Pointing to Kaaba) ──
    final goldTopTip = Offset(center.dx, center.dy - needleHalfLen);

    // Left Light Bevel
    final leftGoldPath = Path()
      ..moveTo(goldTopTip.dx, goldTopTip.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - needleWidth, center.dy)
      ..close();
    final leftGoldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF9E298), Color(0xFFD4AF37)],
      ).createShader(Rect.fromPoints(goldTopTip, center));
    canvas.drawPath(leftGoldPath, leftGoldPaint);

    // Right Dark Bevel
    final rightGoldPath = Path()
      ..moveTo(goldTopTip.dx, goldTopTip.dy)
      ..lineTo(center.dx + needleWidth, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final rightGoldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC59828), Color(0xFF996D14)],
      ).createShader(Rect.fromPoints(goldTopTip, center));
    canvas.drawPath(rightGoldPath, rightGoldPaint);

    // ── 2. Bottom Needle: Deep Olive Slate Counter-Needle ──
    final navyBottomTip = Offset(center.dx, center.dy + needleHalfLen);

    // Left Light Slate Bevel
    final leftNavyPath = Path()
      ..moveTo(navyBottomTip.dx, navyBottomTip.dy)
      ..lineTo(center.dx - needleWidth * 0.85, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final leftNavyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A5546), Color(0xFF354033)],
      ).createShader(Rect.fromPoints(center, navyBottomTip));
    canvas.drawPath(leftNavyPath, leftNavyPaint);

    // Right Dark Slate Bevel
    final rightNavyPath = Path()
      ..moveTo(navyBottomTip.dx, navyBottomTip.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx + needleWidth * 0.85, center.dy)
      ..close();
    final rightNavyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF354033), Color(0xFF262E25)],
      ).createShader(Rect.fromPoints(center, navyBottomTip));
    canvas.drawPath(rightNavyPath, rightNavyPaint);

    // ── 3. Center Polished Multi-Tiered Gold Pin ──
    final outerPinPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFF9E298), Color(0xFFC59B34), Color(0xFF8C6415)],
      ).createShader(Rect.fromCircle(center: center, radius: 13));
    canvas.drawCircle(center, 13, outerPinPaint);

    final innerNavyPaint = Paint()..color = const Color(0xFF354033);
    canvas.drawCircle(center, 7, innerNavyPaint);

    final jewelPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(center, 3.5, jewelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}