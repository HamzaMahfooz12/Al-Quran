// lib/features/home/home_screen.dart
// World-class Islamic Hub — Prayer times hero, utility grid, last-read, Surah & Juz tabs
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../prayer_times/models/prayer_times_model.dart';
import '../prayer_times/services/prayer_service.dart';
import '../prayer_times/widgets/location_picker_bottom_sheet.dart';
import '../share/widgets/ayah_share_dialog.dart';

class DailyVerse {
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String urdu;
  final String english;

  const DailyVerse({
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.urdu,
    required this.english,
  });
}

const List<DailyVerse> kDailyVerses = [
  DailyVerse(
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    ayahNumber: 152,
    arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    urdu: 'سو تم مجھے یاد رکھو، میں تمہیں یاد رکھوں گا، اور میرا شکر ادا کرو اور ناشکری نہ کرو۔',
    english: 'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
  ),
  DailyVerse(
    surahName: 'Ash-Sharh',
    surahNumber: 94,
    ayahNumber: 6,
    arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    urdu: 'بے شک تنگی کے ساتھ آسانی ہے۔',
    english: 'Indeed, with hardship [will be] ease.',
  ),
  DailyVerse(
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    ayahNumber: 186,
    arabic: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
    urdu: 'اور جب میرے بندے آپ سے میرے بارے میں پوچھیں تو کہہ دیجیے کہ میں قریب ہوں، پکارنے والے کی پکار کا جواب دیتا ہوں۔',
    english: 'And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me.',
  ),
  DailyVerse(
    surahName: 'Az-Zumar',
    surahNumber: 39,
    ayahNumber: 53,
    arabic: 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنْفُسِهِمْ لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا',
    urdu: 'کہہ دیجیے کہ اے میرے بندو جنہوں نے اپنی جانوں پر زیادتی کی ہے! اللہ کی رحمت سے ناامید نہ ہو، بے شک اللہ تمام گناہوں کو بخش دیتا ہے۔',
    english: 'Say, "O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins."',
  ),
  DailyVerse(
    surahName: 'At-Talaq',
    surahNumber: 65,
    ayahNumber: 3,
    arabic: 'وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ۚ إِنَّ اللَّهَ بَالِغُ أَمْرِهِ',
    urdu: 'اور جو شخص اللہ پر بھروسہ رکھے گا تو اللہ اسے کافی ہے، بے شک اللہ اپنا کام پورا کر کے رہتا ہے۔',
    english: 'And whoever relies upon Allah - then He is sufficient for him. Indeed, Allah will accomplish His purpose.',
  ),
  DailyVerse(
    surahName: 'Ar-Ra\'d',
    surahNumber: 13,
    ayahNumber: 28,
    arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    urdu: 'خبردار! اللہ کے ذکر سے ہی دلوں کو اطمینان نصیب ہوتا ہے۔',
    english: 'Unquestionably, by the remembrance of Allah hearts are assured.',
  ),
  DailyVerse(
    surahName: 'Ali \'Imran',
    surahNumber: 3,
    ayahNumber: 139,
    arabic: 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنْتُمُ الْأَعْلَوْنَ إِنْ كُنْتُمْ مُؤْمِنِينَ',
    urdu: 'اور تم ہمت نہ ہارو اور نہ غمگین ہو اور تم ہی غالب رہو گے اگر تم مومن ہو۔',
    english: 'So do not weaken and do not grieve, and you will be superior if you are [true] believers.',
  ),
  DailyVerse(
    surahName: 'Al-Anfal',
    surahNumber: 8,
    ayahNumber: 2,
    arabic: 'إِنَّمَا الْمُؤْمِنُونَ الَّذِينَ إِذَا ذُكِرَ اللَّهُ وَجِلَتْ قُلُوبُهُمْ وَإِذَا تُلِيَتْ عَلَيْهِمْ آيَاتُهُ زَادَتْهُمْ إِيمَانًا',
    urdu: 'سچے مومن تو وہی ہیں کہ جب اللہ کا ذکر کیا جائے تو ان کے دل ڈر جاتے ہیں اور جب ان پر اس کی آیتیں پڑھی جائیں تو وہ ان کے ایمان کو اور بڑھا دیتی ہیں۔',
    english: 'The believers are only those who, when Allah is mentioned, their hearts become fearful, and when His verses are recited to them, it increases them in faith.',
  ),
];

final dailyAyahIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _countdownTimer;
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    // Live countdown ticker every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final repo = ref.read(quranRepositoryProvider);
    final lr = await repo.getLastRead('verse_by_verse') ??
        await repo.getLastRead('mushaf_16') ??
        await repo.getLastRead('mushaf_15');
    if (mounted) setState(() => _lastRead = lr);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── 1. Dynamic Islamic Hero Header with Fiqh Badge ───────────────
          SliverToBoxAdapter(
            child: _buildHeroCard(prayerTimesAsync, location),
          ),

          // ── 2. Quick Resume Last Read Banner ────────────────────────────
          if (_lastRead != null)
            SliverToBoxAdapter(
              child: _buildLastReadBanner(),
            ),

          // ── 3. Daily Verse of the Day (Positioned Before Utilities) ─────
          SliverToBoxAdapter(
            child: _buildAyahOfTheDayCard(),
          ),

          // ── 4. Vertical Islamic Utilities Cards (Professional Table) ────
          SliverToBoxAdapter(
            child: _buildVerticalIslamicUtilities(),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: 28 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),

    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Text(
            'Al Quran',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'القرآن',
            style: const TextStyle(
              fontFamily: 'Scheherazade New',
              fontSize: 20,
              color: AppTheme.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          tooltip: 'Search Quran',
          onPressed: () => context.goNamed('search'),
        ),
        IconButton(
          icon: const Icon(Icons.bookmarks_outlined, color: AppTheme.primary),
          tooltip: 'Bookmarks',
          onPressed: () => context.goNamed('bookmarks'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
          tooltip: 'Settings',
          onPressed: () => context.goNamed('settings'),
        ),
      ],
    );
  }

  Widget _buildHeroCard(AsyncValue<PrayerTimesModel> prayerTimesAsync, dynamic location) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D5A34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: prayerTimesAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (err, stack) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(location.displayName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => LocationPickerBottomSheet.show(context),
                  child: const Text('Select City', style: TextStyle(color: Color(0xFFFFD54F))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Namaz times available offline', style: GoogleFonts.inter(color: Colors.white70)),
          ],
        ),
        data: (model) {
          final nextPrayer = model.getNextPrayer();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Location Selector & Fiqh Badge & Hijri Date ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => LocationPickerBottomSheet.show(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFFFD54F), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                location.cityName,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Fiqh Name Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          model.fiqhName,
                          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    model.hijriDate,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFFFD54F)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Middle Row: Next Prayer & Real-Time Countdown Timer ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT PRAYER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA5D6A7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            nextPrayer.name,
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${nextPrayer.arabicName})',
                            style: GoogleFonts.amiri(fontSize: 16, color: const Color(0xFFFFD54F), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'at ${model.formatTime(nextPrayer.time)}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),

                  // Big Countdown Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(nextPrayer.timeRemaining),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'REMAINING',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD54F),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Bottom Mini 5-Prayer Pills Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniPrayerPill('Fajr', model.formatTime(model.fajr), nextPrayer.prayer == PrayerType.fajr),
                  _miniPrayerPill('Dhuhr', model.formatTime(model.dhuhr), nextPrayer.prayer == PrayerType.dhuhr),
                  _miniPrayerPill('Asr', model.formatTime(model.asr), nextPrayer.prayer == PrayerType.asr),
                  _miniPrayerPill('Maghrib', model.formatTime(model.maghrib), nextPrayer.prayer == PrayerType.maghrib),
                  _miniPrayerPill('Isha', model.formatTime(model.isha), nextPrayer.prayer == PrayerType.isha),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniPrayerPill(String name, String time, bool isNext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFFFD54F) : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isNext ? const Color(0xFF1B4332) : Colors.white70,
            ),
          ),
          Text(
            time.split(' ').first,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isNext ? const Color(0xFF1B4332) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Professional Vertical Islamic Utilities Table List
  Widget _buildVerticalIslamicUtilities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Islamic Utilities',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const Text(
                'خدمات إسلامية',
                style: TextStyle(
                  fontFamily: 'Scheherazade New',
                  fontSize: 16,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Vertical Table of Utilities
          _verticalUtilityTile(
            title: 'Prayer Times & Adhan',
            subtitle: 'Accurate timetables with Fiqh schedule & notifications',
            arabicTitle: 'مواقيت الصلاة',
            icon: Icons.access_time_filled_rounded,
            accentColor: const Color(0xFF1B4332),
            badgeText: 'Live',
            onTap: () => context.goNamed('prayer-times'),
          ),
          _verticalUtilityTile(
            title: 'Qibla Direction Compass',
            subtitle: 'Real-time tilt-corrected direction to the Holy Kaaba',
            arabicTitle: 'اتجاه القبلة',
            icon: Icons.explore_rounded,
            accentColor: const Color(0xFF00796B),
            badgeText: 'Sensor',
            onTap: () => context.goNamed('qibla'),
          ),
          _verticalUtilityTile(
            title: 'Daily Duas & Azkar',
            subtitle: 'Hisn al-Muslim morning, evening & prayer supplications',
            arabicTitle: 'الأذكار والأدعية',
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFFC2185B),
            badgeText: 'Authentic',
            onTap: () => context.goNamed('azkar'),
          ),
          _verticalUtilityTile(
            title: 'Digital Tasbeeh Counter',
            subtitle: 'Interactive Dhikr counter with haptic vibration target',
            arabicTitle: 'المسبحة الإلكترونية',
            icon: Icons.fingerprint_rounded,
            accentColor: const Color(0xFF5D4037),
            badgeText: 'Haptic',
            onTap: () => context.goNamed('tasbeeh'),
          ),
          _verticalUtilityTile(
            title: 'Mistakes & Tajweed Report',
            subtitle: 'Track recitation accuracy and memorize Quran effectively',
            arabicTitle: 'سجل الأخطاء والتجويد',
            icon: Icons.fact_check_rounded,
            accentColor: const Color(0xFFE65100),
            badgeText: 'Practice',
            onTap: () => context.goNamed('mistakes-report'),
          ),
          _verticalUtilityTile(
            title: 'Mutashabihat (Similar Ayat)',
            subtitle: 'Comparative explorer for 2,700+ similar Quranic verses',
            arabicTitle: 'الآيات المتشابهات',
            icon: Icons.compare_arrows_rounded,
            accentColor: const Color(0xFFD84315),
            badgeText: 'Hifz Tool',
            onTap: () => context.goNamed('mutashabihat'),
          ),
          _verticalUtilityTile(
            title: 'Search Quran Verses',
            subtitle: 'Fast instant search across all 6,236 Arabic verses & Urdu',
            arabicTitle: 'البحث في القرآن',
            icon: Icons.search_rounded,
            accentColor: const Color(0xFF1565C0),
            badgeText: 'Instant',
            onTap: () => context.goNamed('search'),
          ),
          _verticalUtilityTile(
            title: 'Bookmarks & Saved Verses',
            subtitle: 'Quick access to your pinned Ayahs and favorite recitations',
            arabicTitle: 'العلامات المرجعية',
            icon: Icons.bookmarks_rounded,
            accentColor: const Color(0xFF6A1B9A),
            badgeText: 'Saved',
            onTap: () => context.goNamed('bookmarks'),
          ),
        ],
      ),
    );
  }

  Widget _verticalUtilityTile({
    required String title,
    required String subtitle,
    required String arabicTitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Leading Icon in Gradient Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.0),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Center Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Trailing Arrow & Arabic Sub-label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                    Text(
                      arabicTitle,
                      style: const TextStyle(
                        fontFamily: 'Scheherazade New',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadBanner() {
    final surahNum = _lastRead!['surah'] as int? ?? 1;
    final ayahNum = _lastRead!['ayah'] as int? ?? 1;
    final pageNum = _lastRead!['page'] as int? ?? 1;
    final section = _lastRead!['section'] as String? ?? 'verse_by_verse';

    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Reading',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
                Text(
                  'Surah ${sInfo.nameTransliteration} • Ayah $ayahNum',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (section == 'mushaf_15') {
                context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'});
              } else if (section == 'mushaf_16') {
                context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'});
              } else {
                context.goNamed('verse-by-verse', pathParameters: {'surahNumber': '$surahNum'}, queryParameters: {'ayah': '$ayahNum'});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahOfTheDayCard() {
    final ayahIndex = ref.watch(dailyAyahIndexProvider);
    final verse = kDailyVerses[ayahIndex % kDailyVerses.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: AppTheme.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Daily Verse of the Day',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
              Row(
                children: [
                  // Refresh new ayah button
                  InkWell(
                    onTap: () {
                      ref.read(dailyAyahIndexProvider.notifier).state = (ayahIndex + 1) % kDailyVerses.length;
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.refresh_rounded, size: 13, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text('New Ayah', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share Button
                  InkWell(
                    onTap: () {
                      AyahShareDialog.show(
                        context,
                        surahName: verse.surahName,
                        ayahNumber: verse.ayahNumber,
                        arabicText: verse.arabic,
                        translationText: '${verse.urdu}\n\n${verse.english}',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.share, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text('Share', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verse.arabic,
            style: const TextStyle(
              fontFamily: 'Scheherazade New',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.8,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            verse.urdu,
            style: const TextStyle(
              fontFamily: 'Noto Nastaliq Urdu',
              fontSize: 13.5,
              color: Color(0xFF2C3E50),
              height: 1.8,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          Text(
            verse.english,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Surah ${verse.surahName} [${verse.surahNumber}:${verse.ayahNumber}]',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              ),
              InkWell(
                onTap: () {
                  context.goNamed(
                    'verse-by-verse',
                    pathParameters: {'surahNumber': '${verse.surahNumber}'},
                    queryParameters: {'ayah': '${verse.ayahNumber}'},
                  );
                },
                child: Row(
                  children: [
                    Text('Read Surah', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // ── Islamic Green Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B4332), Color(0xFF2D5A34)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_book, color: Color(0xFFD4AF37), size: 26),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Al Quran',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'القرآن الكريم • Read, Listen, Reflect',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFD4AF37),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation List ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _drawerTile(
                  icon: Icons.format_list_bulleted,
                  title: 'Surah & Juz Index',
                  subtitle: 'Verse by verse reading',
                  onTap: () => Navigator.pop(context),
                ),
                _drawerTile(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Prayer Times',
                  subtitle: 'Accurate daily & monthly schedule',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('prayer-times');
                  },
                ),
                _drawerTile(
                  icon: Icons.explore_rounded,
                  title: 'Qibla Direction',
                  subtitle: 'Live compass to Kaaba',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('qibla');
                  },
                ),
                _drawerTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Digital Tasbeeh',
                  subtitle: 'Target counter with vibration',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('tasbeeh');
                  },
                ),
                _drawerTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Daily Duas & Azkar',
                  subtitle: 'Hisn al-Muslim supplications',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('azkar');
                  },
                ),
                _drawerTile(
                  icon: Icons.search_rounded,
                  title: 'Search Quran',
                  subtitle: 'Search across 6,236 verses',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('search');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _drawerTile(
                  icon: Icons.auto_stories,
                  title: '15-Line Mushaf',
                  subtitle: 'Saudi standard format',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mushaf-15', queryParameters: {'page': '1'});
                  },
                ),
                _drawerTile(
                  icon: Icons.menu_book,
                  title: '16-Line Mushaf',
                  subtitle: 'Indo-Pak standard format',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mushaf-16', queryParameters: {'page': '1'});
                  },
                ),
                _drawerTile(
                  icon: Icons.bookmarks,
                  title: 'Bookmarks',
                  subtitle: 'Saved verses',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('bookmarks');
                  },
                ),
                _drawerTile(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Mutashabihat (Similar Ayat)',
                  subtitle: 'Comparative verse explorer',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mutashabihat');
                  },
                ),
                _drawerTile(
                  icon: Icons.analytics_outlined,
                  title: 'Mistakes Report',
                  subtitle: 'Track your recitation errors',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('mistakes-report');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _drawerTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App preferences & audio',
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('settings');
                  },
                ),
              ],
            ),
          ),

          // ── Drawer Footer ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8ECE9))),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Al Quran App • v1.0.2',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
