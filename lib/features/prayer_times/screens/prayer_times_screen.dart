// lib/features/prayer_times/screens/prayer_times_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/prayer_times_model.dart';
import '../services/prayer_service.dart';
import '../widgets/location_picker_bottom_sheet.dart';
import '../../../core/widgets/app_drawer.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render every second for real-time countdown updates
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final location = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.primary, size: 26),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Prayer Times',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => LocationPickerBottomSheet.show(context),
            icon: const Icon(Icons.location_on, size: 16, color: AppTheme.primary),
            label: Text(
              location.cityName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: prayerTimesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Failed to load prayer times: $err', style: GoogleFonts.inter()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(prayerTimesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (model) {
          final nextPrayer = model.getNextPrayer();
          final currentPrayer = model.getCurrentPrayer();

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 110 + MediaQuery.paddingOf(context).bottom),
            children: [
              // ── Hero Countdown Card (Matching Image 4) ─────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Background Madinah Photo
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/madinah_hero_bg.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1B2A1E).withValues(alpha: 0.88),
                                const Color(0xFF2C7A39).withValues(alpha: 0.72),
                                const Color(0xFF1B2A1E).withValues(alpha: 0.92),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            // Location & Hijri Date Chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: InkWell(
                                    onTap: () => LocationPickerBottomSheet.show(context),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.38),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Color(0xFFA5D6A7), size: 12),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              model.locationName,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.38),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 10.5, color: Color(0xFFFFD54F)),
                                      const SizedBox(width: 4),
                                      Text(
                                        model.hijriDate,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: const Color(0xFFFFD54F),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Next Prayer & Countdown Box
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT PRAYER',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          nextPrayer.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          nextPrayer.arabicName,
                                          style: GoogleFonts.amiri(
                                            fontSize: 20,
                                            color: const Color(0xFFFFD54F),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'at ${model.formatTime(nextPrayer.time)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F8F3),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _formatDuration(nextPrayer.timeRemaining),
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1B4332),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        'REMAINING',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2D6A4F),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Current Prayer Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Current: ${currentPrayer.name}',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${(currentPrayer.progress * 100).toInt()}% Elapsed',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFFFD54F), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: currentPrayer.progress,
                                    minHeight: 5,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 5 Daily Prayer Cards ────────────────────────────────────
              Text(
                'Today\'s Prayer Schedule',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _prayerRow(
                type: PrayerType.fajr,
                name: 'Fajr',
                arabicName: 'الفجر',
                time: model.formatTime(model.fajr),
                icon: Icons.brightness_2_outlined,
                isNext: nextPrayer.prayer == PrayerType.fajr,
                isCurrent: currentPrayer.prayer == PrayerType.fajr,
              ),
              _prayerRow(
                type: PrayerType.sunrise,
                name: 'Sunrise / Ishraq',
                arabicName: 'الشروق',
                time: model.formatTime(model.sunrise),
                icon: Icons.wb_sunny_outlined,
                isNext: nextPrayer.prayer == PrayerType.sunrise,
                isCurrent: currentPrayer.prayer == PrayerType.sunrise,
              ),
              _prayerRow(
                type: PrayerType.dhuhr,
                name: 'Dhuhr',
                arabicName: 'الظهر',
                time: model.formatTime(model.dhuhr),
                icon: Icons.wb_sunny,
                isNext: nextPrayer.prayer == PrayerType.dhuhr,
                isCurrent: currentPrayer.prayer == PrayerType.dhuhr,
              ),
              _prayerRow(
                type: PrayerType.asr,
                name: 'Asr',
                arabicName: 'العصر',
                time: model.formatTime(model.asr),
                icon: Icons.wb_cloudy_outlined,
                isNext: nextPrayer.prayer == PrayerType.asr,
                isCurrent: currentPrayer.prayer == PrayerType.asr,
              ),
              _prayerRow(
                type: PrayerType.maghrib,
                name: 'Maghrib',
                arabicName: 'المغرب',
                time: model.formatTime(model.maghrib),
                icon: Icons.nights_stay_outlined,
                isNext: nextPrayer.prayer == PrayerType.maghrib,
                isCurrent: currentPrayer.prayer == PrayerType.maghrib,
              ),
              _prayerRow(
                type: PrayerType.isha,
                name: 'Isha',
                arabicName: 'العشاء',
                time: model.formatTime(model.isha),
                icon: Icons.bedtime_outlined,
                isNext: nextPrayer.prayer == PrayerType.isha,
                isCurrent: currentPrayer.prayer == PrayerType.isha,
              ),

              const SizedBox(height: 16),

              // ── Night & Voluntary Times ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8ECE9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voluntary & Night Timings',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (model.imsak != null)
                      _extraTimeRow('Imsak (Sehri End)', model.formatTime(model.imsak!)),
                    if (model.lastThird != null)
                      _extraTimeRow('Tahajjud (Best Time)', model.formatTime(model.lastThird!)),
                    if (model.midnight != null)
                      _extraTimeRow('Islamic Midnight', model.formatTime(model.midnight!)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _prayerRow({
    required PrayerType type,
    required String name,
    required String arabicName,
    required String time,
    required IconData icon,
    required bool isNext,
    required bool isCurrent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isNext
            ? AppTheme.primarySurface
            : isCurrent
                ? const Color(0xFFF1F8F3)
                : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext
              ? AppTheme.primary
              : isCurrent
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : const Color(0xFFE8ECE9),
          width: isNext ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext ? AppTheme.primary : AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isNext ? Colors.white : AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: (isNext || isCurrent) ? FontWeight.w700 : FontWeight.w600,
                        color: isNext ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NEXT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  arabicName,
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isNext ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraTimeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
