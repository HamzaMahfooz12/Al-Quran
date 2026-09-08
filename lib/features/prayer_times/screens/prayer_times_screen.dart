// lib/features/prayer_times/screens/prayer_times_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Re-render every second for real-time countdown updates
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void activate() {
    super.activate();
    // Reset to today whenever the user switches back to this tab
    // Prevents showing yesterday/tomorrow when returning from another screen
    if (mounted) {
      setState(() => _selectedDate = DateTime.now());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _resetToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesForDateProvider(_selectedDate));
    final location = ref.watch(selectedLocationProvider);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

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
                onPressed: () => ref.refresh(prayerTimesForDateProvider(_selectedDate)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (model) {
          final now = DateTime.now();
          final nextPrayer = isToday ? model.getNextPrayer(now) : model.getNextPrayer(model.date.add(const Duration(hours: 6)));
          final currentPrayer = isToday ? model.getCurrentPrayer(now) : model.getCurrentPrayer(model.date.add(const Duration(hours: 12)));

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 110 + MediaQuery.paddingOf(context).bottom),
            children: [
              // ── 1. Hero Countdown Card (Madinah Backdrop & Dynamic Timer) ────
              _buildHeroCountdownCard(context, model, nextPrayer, currentPrayer, isToday),

              const SizedBox(height: 12),

              // ── 2. Date Navigation Bar (< Date > with interactive controls) ──
              _buildDateNavigationBar(isToday, model.hijriDate),

              const SizedBox(height: 14),

              // ── 3. Symmetrical Sunrise & Sunset Bar (Matched Icon Sizes) ───────
              _buildSunriseSunsetBar(model),

              const SizedBox(height: 18),

              // ── 4. Main Prayer Schedule Header ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prayer Schedule',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      model.fiqhName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── 5. Core Daily Prayer Times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) ──
              _buildPrayerList(model, nextPrayer, currentPrayer, isToday),

              const SizedBox(height: 16),

              // ── 6. Voluntary & Night Timings ───────
              _buildVoluntaryAndNightCard(model),
            ],
          );
        },
      ),
    );
  }

  // ── Date Navigation Bar (< Wednesday, 02 September 2026 >) ─────────────────
  Widget _buildDateNavigationBar(bool isToday, String hijriDate) {
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day Button
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary, size: 28),
            tooltip: 'Previous Day',
            visualDensity: VisualDensity.compact,
          ),

          // Center Date — tap to jump back to today when on a different day
          Expanded(
            child: GestureDetector(
              onTap: isToday ? null : _resetToday,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  if (hijriDate.isNotEmpty)
                    Text(
                      hijriDate,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Next Day Button
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 28),
            tooltip: 'Next Day',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Hero Countdown Card ───────────────────────────────────────────────────
  Widget _buildHeroCountdownCard(
    BuildContext context,
    PrayerTimesModel model,
    NextPrayerInfo nextPrayer,
    CurrentPrayerInfo currentPrayer,
    bool isToday,
  ) {
    return Container(
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
                            isToday ? 'NEXT PRAYER' : 'UPCOMING PRAYER',
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

                      if (isToday)
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
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (isToday) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Symmetrical Sunrise & Sunset Bar (Matched Dimensions & Scale) ──────────
  Widget _buildSunriseSunsetBar(PrayerTimesModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Sunrise Box (Matched 38x38 container, icon size 20) ──
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Warm amber soft surface
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sunrise',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الشروق',
                            style: GoogleFonts.amiri(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        model.formatTime(model.sunrise),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 32,
            width: 1,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // ── Sunset Box (Matched 38x38 container, icon size 20) ──
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5), // Warm sunset soft surface
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.wb_twilight_rounded, color: Color(0xFFEA580C), size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sunset',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الغروب',
                            style: GoogleFonts.amiri(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        model.formatTime(model.sunset),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFEA580C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Core Daily Prayer List (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) ──
  Widget _buildPrayerList(
    PrayerTimesModel model,
    NextPrayerInfo nextPrayer,
    CurrentPrayerInfo currentPrayer,
    bool isToday,
  ) {
    return Column(
      children: [
        _prayerRow(
          type: PrayerType.fajr,
          name: 'Fajr',
          arabicName: 'الفجر',
          tag: 'FARDH',
          time: model.formatTime(model.fajr),
          icon: Icons.brightness_2_outlined,
          isNext: isToday && nextPrayer.prayer == PrayerType.fajr,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.fajr,
        ),
        _prayerRow(
          type: PrayerType.sunrise,
          name: 'Sunrise',
          arabicName: 'الشروق',
          tag: 'TIME',
          time: model.formatTime(model.sunrise),
          icon: Icons.wb_sunny_outlined,
          isNext: isToday && nextPrayer.prayer == PrayerType.sunrise,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.sunrise,
        ),
        _prayerRow(
          type: PrayerType.dhuhr,
          name: 'Dhuhr',
          arabicName: 'الظهر',
          tag: 'FARDH',
          time: model.formatTime(model.dhuhr),
          icon: Icons.wb_sunny,
          isNext: isToday && nextPrayer.prayer == PrayerType.dhuhr,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.dhuhr,
        ),
        _prayerRow(
          type: PrayerType.asr,
          name: 'Asr',
          arabicName: 'العصر',
          tag: 'FARDH',
          time: model.formatTime(model.asr),
          icon: Icons.wb_cloudy_outlined,
          isNext: isToday && nextPrayer.prayer == PrayerType.asr,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.asr,
        ),
        _prayerRow(
          type: PrayerType.maghrib,
          name: 'Maghrib',
          arabicName: 'المغرب',
          tag: 'FARDH',
          time: model.formatTime(model.maghrib),
          icon: Icons.nights_stay_outlined,
          isNext: isToday && nextPrayer.prayer == PrayerType.maghrib,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.maghrib,
        ),
        _prayerRow(
          type: PrayerType.isha,
          name: 'Isha',
          arabicName: 'العشاء',
          tag: 'FARDH',
          time: model.formatTime(model.isha),
          icon: Icons.bedtime_outlined,
          isNext: isToday && nextPrayer.prayer == PrayerType.isha,
          isCurrent: isToday && currentPrayer.prayer == PrayerType.isha,
        ),
      ],
    );
  }

  Widget _prayerRow({
    required PrayerType type,
    required String name,
    required String arabicName,
    required String tag,
    required String time,
    required IconData icon,
    required bool isNext,
    required bool isCurrent,
    Color? accentColor,
  }) {
    final effectiveAccent = accentColor ?? (isNext ? AppTheme.primary : AppTheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isNext ? AppTheme.primary : effectiveAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isNext ? Colors.white : effectiveAccent,
                size: 18,
              ),
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
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: (isNext || isCurrent) ? FontWeight.w700 : FontWeight.w600,
                        color: isNext ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isNext
                            ? AppTheme.primary
                            : tag == 'NO PRAYER'
                                ? const Color(0xFFFEE2E2)
                                : effectiveAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNext ? 'NEXT' : tag,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isNext
                              ? Colors.white
                              : tag == 'NO PRAYER'
                                  ? const Color(0xFFDC2626)
                                  : effectiveAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  arabicName,
                  style: GoogleFonts.amiri(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: isNext ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Voluntary & Night Timings (Ishraq, Chasht, Zawal, Sunset, Imsak, Tahajjud, Midnight) ─
  Widget _buildVoluntaryAndNightCard(PrayerTimesModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                'Voluntary & Night Timings',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'النوافل والسنن',
                style: GoogleFonts.amiri(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Daytime Voluntary
          _extraTimeRow('Ishraq', model.formatTime(model.ishraq), 'الإشراق', Icons.flare_rounded, const Color(0xFF0284C7)),
          _extraTimeRow('Chasht (Duha)', model.formatTime(model.chasht), 'الضحى', Icons.wb_sunny_rounded, const Color(0xFF0D9488)),
          _extraTimeRow('Zawal (Prohibited)', model.formatTime(model.zawal), 'الزوال', Icons.do_not_disturb_on_outlined, const Color(0xFFDC2626)),
          _extraTimeRow('Sunset', model.formatTime(model.sunset), 'الغروب', Icons.wb_twilight_rounded, const Color(0xFFEA580C)),
          if (model.imsak != null) ...[
            const Divider(height: 16),
            _extraTimeRow('Imsak (Sehri End)', model.formatTime(model.imsak!), 'الإمساك', Icons.no_meals_rounded, const Color(0xFF7C3AED)),
          ],
          if (model.lastThird != null)
            _extraTimeRow('Tahajjud (Best Window)', model.formatTime(model.lastThird!), 'التهجد', Icons.bedtime_rounded, const Color(0xFF4F46E5)),
          if (model.midnight != null)
            _extraTimeRow('Islamic Midnight', model.formatTime(model.midnight!), 'منتصف الليل', Icons.brightness_3_rounded, const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _extraTimeRow(String label, String value, String arabicName, IconData icon, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, size: 15, color: accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text(arabicName, style: GoogleFonts.amiri(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}
