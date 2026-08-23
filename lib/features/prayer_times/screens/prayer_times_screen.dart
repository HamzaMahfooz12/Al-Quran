// lib/features/prayer_times/screens/prayer_times_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/prayer_times_model.dart';
import '../services/prayer_service.dart';
import '../widgets/location_picker_bottom_sheet.dart';

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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.paddingOf(context).bottom),
            children: [
              // ── Hero Countdown Card ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D5A34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Location & Dates Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFA5D6A7), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              model.locationName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          model.hijriDate,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFFD54F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Next Prayer Badge & Countdown
                    Text(
                      'Next Prayer: ${nextPrayer.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(nextPrayer.timeRemaining),
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'at ${model.formatTime(nextPrayer.time)} (${nextPrayer.arabicName})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFA5D6A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Current Prayer progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current: ${currentPrayer.name}',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                            ),
                            Text(
                              '${(currentPrayer.progress * 100).toInt()}% elapsed',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentPrayer.progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                          ),
                        ),
                      ],
                    ),
                  ],
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
