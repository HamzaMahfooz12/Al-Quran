// lib/features/prayer_times/screens/prayer_times_screen.dart
// Islamic Prayer Times Screen matching Google Stitch design exactly
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void activate() {
    super.activate();
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
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _resetToday() {
    HapticFeedback.lightImpact();
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
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: _buildTopAppBar(context, location),
      drawer: const AppDrawer(),
      body: prayerTimesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC59A27)),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Failed to load prayer times: $err', style: GoogleFonts.plusJakartaSans()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(prayerTimesForDateProvider(_selectedDate)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC59A27)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (model) {
          final now = DateTime.now();
          final nextPrayer = isToday
              ? model.getNextPrayer(now)
              : model.getNextPrayer(model.date.add(const Duration(hours: 6)));
          final currentPrayer = isToday
              ? model.getCurrentPrayer(now)
              : model.getCurrentPrayer(model.date.add(const Duration(hours: 12)));

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 4, 16, 100 + MediaQuery.paddingOf(context).bottom),
            children: [
              // ── 1. Hero Countdown Card (Daylight Theme with 6-Prayer Strip) ──
              _buildHeroCountdownCard(context, model, nextPrayer, currentPrayer, isToday),

              const SizedBox(height: 12),

              // ── 2. Interactive Date Navigation Strip ──
              _buildDateNavigationStrip(isToday, model.hijriDate),

              const SizedBox(height: 12),

              // ── 3. Sunrise & Sunset Solar Summary Card ──
              _buildSunriseSunsetSolarCard(model),

              const SizedBox(height: 16),

              // ── 4. Main Prayer Schedule ──
              _buildPrayerScheduleSection(model, nextPrayer, currentPrayer, isToday),

              const SizedBox(height: 16),

              // ── 5. Voluntary & Night Prayers (2x2 Grid) ──
              _buildVoluntaryPrayersGrid(model),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, dynamic location) {
    return AppBar(
      backgroundColor: const Color(0xFFFAF7F2),
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
      title: Text(
        'Prayer Times',
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF354033),
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        Center(
          child: InkWell(
            onTap: () => LocationPickerBottomSheet.show(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 14),
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
              child: const Icon(Icons.settings_outlined, color: Color(0xFF354033), size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCountdownCard(
    BuildContext context,
    PrayerTimesModel model,
    NextPrayerInfo nextPrayer,
    CurrentPrayerInfo currentPrayer,
    bool isToday,
  ) {
    final countdown = isToday
        ? _formatDuration(nextPrayer.timeRemaining)
        : model.formatTime(nextPrayer.time);

    // 6 Prayers list matching Picture 2: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
    // Highlight the CURRENT prayer in the strip!
    final prayerList = [
      {
        'name': 'Fajr',
        'time': model.formatTime(model.fajr),
        'symbol': '◒',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.fajr,
      },
      {
        'name': 'Sunrise',
        'time': model.formatTime(model.sunrise),
        'symbol': '○',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.sunrise,
      },
      {
        'name': 'Dhuhr',
        'time': model.formatTime(model.dhuhr),
        'symbol': '◐',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.dhuhr,
      },
      {
        'name': 'Asr',
        'time': model.formatTime(model.asr),
        'symbol': '◒',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.asr,
      },
      {
        'name': 'Maghrib',
        'time': model.formatTime(model.maghrib),
        'symbol': '◑',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.maghrib,
      },
      {
        'name': 'Isha',
        'time': model.formatTime(model.isha),
        'symbol': '●',
        'isCurrent': isToday && currentPrayer.prayer == PrayerType.isha,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9C9A7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF625A45).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/madinah_hero_bg.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
              ),
            ),

            // Warm Daylight Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF8F4EA).withValues(alpha: 0.94),
                      const Color(0xFFF8F4EA).withValues(alpha: 0.82),
                      const Color(0xFFF8F4EA).withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location + Date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => LocationPickerBottomSheet.show(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF2).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD8CFBE), width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFF987238), size: 13),
                              const SizedBox(width: 4),
                              Text(
                                model.locationName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4F584A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF2).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD8CFBE), width: 1.0),
                            ),
                            child: Text(
                              model.hijriDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFF4F584A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9BD7B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'HANAFI',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4B432F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Next prayer & countdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? 'NEXT PRAYER' : 'UPCOMING PRAYER',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: const Color(0xFF987238),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  nextPrayer.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF394234),
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nextPrayer.arabicName,
                                  style: GoogleFonts.amiri(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF987238),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'starts at ${model.formatTime(nextPrayer.time)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: const Color(0xFF73786E),
                              ),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isToday ? 'BEGINS IN' : 'TIME',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: const Color(0xFF987238),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              countdown,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF80632F),
                                letterSpacing: 0.5,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              isToday ? 'Hours   Min   Sec' : 'Scheduled',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                color: const Color(0xFF73786E),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Prayer Strip (6 items) matching Picture 2
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF8E896F).withValues(alpha: 0.22),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: prayerList.map((item) {
                        final isHighlighted = item['isCurrent'] as bool;
                        return Expanded(
                          child: Container(
                            height: 68,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFFFFFDF0).withValues(alpha: 0.96)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isHighlighted
                                  ? Border.all(color: const Color(0xFFC9A961), width: 1.2)
                                  : null,
                              boxShadow: isHighlighted
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF625A45).withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['symbol'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF987238),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.0,
                                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                    color: isHighlighted ? const Color(0xFF495242) : const Color(0xFF70776C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (item['time'] as String).split(' ').first,
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: isHighlighted ? const Color(0xFF495242) : const Color(0xFF60685E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildDateNavigationStrip(bool isToday, String hijriDate) {
    final dateStr = DateFormat('EEEE, dd MMM').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          InkWell(
            onTap: _previousDay,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF7C7365), size: 20),
            ),
          ),

          // Date Text
          GestureDetector(
            onTap: isToday ? null : _resetToday,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF354033),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EBD0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TODAY',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF876510),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  hijriDate,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7C7365),
                  ),
                ),
              ],
            ),
          ),

          // Next button
          InkWell(
            onTap: _nextDay,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C7365), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunsetSolarCard(PrayerTimesModel model) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sunrise
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sunrise (Shurooq)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF7C7365),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          model.formatTime(model.sunrise),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF354033),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE8E1D2),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Sunset
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E7FF)),
                      ),
                      child: const Icon(Icons.wb_twilight_rounded, color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sunset (Ghurub)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF7C7365),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          model.formatTime(model.sunset),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF354033),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0EBE1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF7C7365)),
                    children: [
                      const TextSpan(text: 'Daylight: '),
                      TextSpan(
                        text: _calculateDaylight(model.sunrise, model.sunset),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF354033)),
                      ),
                    ],
                  ),
                ),
                Text('•', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7C7365))),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF7C7365)),
                    children: [
                      const TextSpan(text: 'Zawal (Solar Noon): '),
                      TextSpan(
                        text: model.formatTime(model.zawal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF354033)),
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

  String _calculateDaylight(DateTime sunrise, DateTime sunset) {
    final diff = sunset.difference(sunrise);
    if (diff.isNegative) return '11h 15m';
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }

  Widget _buildPrayerScheduleSection(
    PrayerTimesModel model,
    NextPrayerInfo nextPrayer,
    CurrentPrayerInfo currentPrayer,
    bool isToday,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Schedule",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF354033),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC59A27),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${model.locationName} / Hanafi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC59A27),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        _stitchPrayerRow(
          name: 'Fajr',
          arabic: 'الفجر',
          time: model.formatTime(model.fajr),
          status: isToday && currentPrayer.prayer == PrayerType.fajr
              ? 'Sunrise at ${model.formatTime(model.sunrise)}'
              : 'Passed • Sunrise at ${model.formatTime(model.sunrise)}',
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFFC59A27),
          isCurrent: isToday && currentPrayer.prayer == PrayerType.fajr,
        ),
        _stitchPrayerRow(
          name: 'Dhuhr',
          arabic: 'الظهر',
          time: model.formatTime(model.dhuhr),
          status: isToday && currentPrayer.prayer == PrayerType.dhuhr
              ? 'Ends at ${model.formatTime(model.asr)}'
              : 'Passed • Ended at ${model.formatTime(model.asr)}',
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFF59E0B),
          isCurrent: isToday && currentPrayer.prayer == PrayerType.dhuhr,
        ),
        _stitchPrayerRow(
          name: 'Asr',
          arabic: 'العصر',
          time: model.formatTime(model.asr),
          status: isToday && currentPrayer.prayer == PrayerType.asr
              ? 'Ends at ${model.formatTime(model.maghrib)}'
              : (isToday && nextPrayer.prayer == PrayerType.asr
                  ? 'Starts in ${_formatDuration(nextPrayer.timeRemaining).substring(0, 5)}'
                  : 'Mid-afternoon prayer'),
          icon: Icons.wb_cloudy_rounded,
          iconColor: const Color(0xFFC59A27),
          isCurrent: isToday && currentPrayer.prayer == PrayerType.asr,
        ),
        _stitchPrayerRow(
          name: 'Maghrib',
          arabic: 'المغرب',
          time: model.formatTime(model.maghrib),
          status: isToday && currentPrayer.prayer == PrayerType.maghrib
              ? 'Iftar time • Ends at ${model.formatTime(model.isha)}'
              : 'Iftar time at ${model.formatTime(model.maghrib)}',
          icon: Icons.wb_twilight_rounded,
          iconColor: const Color(0xFFEA580C),
          isCurrent: isToday && currentPrayer.prayer == PrayerType.maghrib,
        ),
        _stitchPrayerRow(
          name: 'Isha',
          arabic: 'العشاء',
          time: model.formatTime(model.isha),
          status: 'Night prayer',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF3730A3),
          isCurrent: isToday && currentPrayer.prayer == PrayerType.isha,
        ),
      ],
    );
  }

  Widget _stitchPrayerRow({
    required String name,
    required String arabic,
    required String time,
    required String status,
    required IconData icon,
    required Color iconColor,
    required bool isCurrent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFFFDF8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFC59A27).withValues(alpha: 0.70)
              : const Color(0xFFE8E1D2),
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? const Color(0xFFC59A27).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (isCurrent)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8B931), Color(0xFFC59A27)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFFFFDF8) : const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFC59A27).withValues(alpha: 0.4)
                            : const Color(0xFFE8E1D2),
                      ),
                    ),
                    child: Icon(icon, color: isCurrent ? const Color(0xFFC59A27) : const Color(0xFF9E9484), size: 20),
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
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF354033),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              arabic,
                              style: GoogleFonts.amiri(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? const Color(0xFF354033) : const Color(0xFF7C7365),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF7C7365),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          fontSize: isCurrent ? 15.5 : 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354033),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC59A27),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoluntaryPrayersGrid(PrayerTimesModel model) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E1D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC59A27),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VOLUNTARY & NIGHT PRAYERS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF354033),
                    ),
                  ),
                ],
              ),
              Text(
                'Sunnah',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC59A27),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              // 1. Tahajjud
              _nawafilCard(
                title: 'Tahajjud (Qiyam)',
                time: model.lastThird != null
                    ? '${model.formatTime(model.lastThird!)} - ${model.formatTime(model.fajr)}'
                    : '02:15 AM - 04:45 AM',
                desc: 'Last 3rd of night',
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFFC59A27),
              ),

              // 2. Ishraq
              _nawafilCard(
                title: 'Ishraq',
                time: model.formatTime(model.ishraq),
                desc: '15m post sunrise',
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),

              // 3. Duha
              _nawafilCard(
                title: 'Duha (Chasht)',
                time: '${model.formatTime(model.chasht)} - ${model.formatTime(model.zawal)}',
                desc: 'Mid-morning prayer',
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFEA580C),
              ),

              // 4. Nisf al-Layl
              _nawafilCard(
                title: 'Nisf al-Layl',
                time: model.midnight != null
                    ? model.formatTime(model.midnight!)
                    : '11:36 PM',
                desc: 'Islamic midnight',
                icon: Icons.brightness_3_rounded,
                iconColor: const Color(0xFF818CF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nawafilCard({
    required String title,
    required String time,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E1D2).withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF354033),
                ),
              ),
              Icon(icon, color: iconColor, size: 14),
            ],
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC59A27),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: const Color(0xFF7C7365),
            ),
          ),
        ],
      ),
    );
  }
}
