// lib/features/qibla/screens/qibla_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';
import '../../prayer_times/services/prayer_service.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0.0;
  bool _hasVibratedForAlignment = false;
  bool _compassAvailable = true;

  // Kaaba coordinates (Makkah)
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      final heading = event.heading;
      if (heading == null) {
        if (mounted) setState(() => _compassAvailable = false);
        return;
      }

      final h = ((heading % 360) + 360) % 360;

      final location = ref.read(selectedLocationProvider);
      final qiblaBearing = _calculateQiblaBearing(location.latitude, location.longitude);
      final diff = (h - qiblaBearing).abs();
      final isAligned = diff < 3.5 || diff > 356.5;

      if (isAligned) {
        if (!_hasVibratedForAlignment) {
          _hasVibratedForAlignment = true;
          Vibration.hasVibrator().then((hasVib) {
            if (hasVib == true) Vibration.vibrate(duration: 60);
          });
        }
      } else {
        _hasVibratedForAlignment = false;
      }

      if (mounted) setState(() { _heading = h; _compassAvailable = true; });
    }, onError: (_) {
      if (mounted) setState(() => _compassAvailable = false);
    });
  }

  /// Haversine forward-azimuth bearing to Kaaba
  double _calculateQiblaBearing(double lat, double lng) {
    final lat1 = lat * (math.pi / 180.0);
    final lng1 = lng * (math.pi / 180.0);
    final lat2 = _kaabaLat * (math.pi / 180.0);
    final lng2 = _kaabaLng * (math.pi / 180.0);
    final dLng = lng2 - lng1;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    double bearing = math.atan2(y, x) * (180.0 / math.pi);
    if (bearing < 0) bearing += 360.0;
    return bearing;
  }

  double _calculateDistanceToKaaba(double lat, double lng) {
    const r = 6371.0;
    final dLat = (_kaabaLat - lat) * (math.pi / 180.0);
    final dLng = (_kaabaLng - lng) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * (math.pi / 180.0)) * math.cos(_kaabaLat * (math.pi / 180.0)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final qiblaBearing = _calculateQiblaBearing(location.latitude, location.longitude);
    final distanceKm = _calculateDistanceToKaaba(location.latitude, location.longitude);

    final angleDiff = (_heading - qiblaBearing).abs();
    final isAligned = angleDiff < 3.5 || angleDiff > 356.5;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Qibla Direction', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Location badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECE9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primarySurface, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Distance to Kaaba: ${distanceKm.toStringAsFixed(0)} km', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (!_compassAvailable)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.sensors_off, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text('Compass sensor not available on this device.', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              // Compass dial
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow when aligned
                    if (isAligned)
                      Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: 8)],
                        ),
                      ),

                    // Rotating compass ring
                    Transform.rotate(
                      angle: -_heading * (math.pi / 180.0),
                      child: Container(
                        width: 280, height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardBg,
                          border: Border.all(color: isAligned ? AppTheme.primary : const Color(0xFFDCE4DF), width: isAligned ? 3.0 : 2.0),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(top: 10, child: Text('N', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                            Positioned(bottom: 10, child: Text('S', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
                            Positioned(right: 12, child: Text('E', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
                            Positioned(left: 12, child: Text('W', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
                            Transform.rotate(
                              angle: qiblaBearing * (math.pi / 180.0),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Color(0xFF1B4332), shape: BoxShape.circle),
                                    child: const Icon(Icons.mosque, color: Color(0xFFFFD54F), size: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center needle pointing to Qibla
                    Transform.rotate(
                      angle: (qiblaBearing - _heading) * (math.pi / 180.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14, height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isAligned
                                    ? [const Color(0xFFFFD54F), const Color(0xFF1B4332)]
                                    : [AppTheme.primary, const Color(0xFF81C784)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              boxShadow: [BoxShadow(color: isAligned ? const Color(0xFFFFD54F).withValues(alpha: 0.5) : Colors.black26, blurRadius: 8)],
                            ),
                            child: const Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white))),
                          ),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: const Color(0xFF1B4332), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD54F), width: 2)),
                          ),
                          Container(
                            width: 8, height: 60,
                            decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // ── Angle Readout Panel ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECE9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.mosque, color: Color(0xFFFFD54F), size: 14),
                          const SizedBox(width: 4),
                          Text('Qibla Direction', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                        ]),
                        const SizedBox(height: 4),
                        Text('${qiblaBearing.toStringAsFixed(1)}°', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: const Color(0xFFE8ECE9)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.phone_android, color: AppTheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('Your Direction', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                        ]),
                        const SizedBox(height: 4),
                        Text('${_heading.toStringAsFixed(1)}°', style: GoogleFonts.outfit(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: isAligned ? AppTheme.primary : AppTheme.textPrimary,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Alignment status ─────────────────────────────────────────────
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 14 + MediaQuery.paddingOf(context).bottom),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAligned ? AppTheme.primarySurface : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isAligned ? AppTheme.primary : const Color(0xFFE8ECE9)),
              ),
              child: Row(
                children: [
                  Text(isAligned ? '🕋' : '🧭', style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAligned
                          ? 'You are now facing the Qibla (Kaaba)! 🎉'
                          : 'Rotate your phone until the needle turns gold and both angles match.',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: isAligned ? FontWeight.w700 : FontWeight.w500, color: isAligned ? AppTheme.primary : AppTheme.textSecondary),
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
}