// lib/features/home/home_screen.dart
// World-class Islamic Hub — Prayer times hero, utility grid, last-read, Surah & Juz tabs
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/widgets/app_drawer.dart';

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
    arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    urdu: 'پس یقیناً تنگی کے ساتھ آسانی ہے، بے شک تنگی کے ساتھ آسانی ہے۔',
    english: 'Indeed, with hardship [will be] ease.',
  ),
  DailyVerse(
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    ayahNumber: 186,
    arabic: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
    urdu: 'اور جب میرے بندے آپ سے میرے بارے میں پوچھیں تو کہہ دیجیے کہ میں قریب ہوں، پکارنے والے کی دعا قبول کرتا ہوں۔',
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
    arabic: 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    urdu: 'جو لوگ ایمان لائے ان کے دل اللہ کے ذکر سے اطمینان پاتے ہیں، خبردار! اللہ کے ذکر ہی سے دلوں کو سکون ملتا ہے۔',
    english: 'Unquestionably, by the remembrance of Allah hearts are assured.',
  ),
  DailyVerse(
    surahName: 'Ali \'Imran',
    surahNumber: 3,
    ayahNumber: 139,
    arabic: 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنْتُمُ الْأَعْلَوْنَ إِنْ كُنْتُمْ مُؤْمِنِينَ',
    urdu: 'اور تم ہمت نہ ہارو اور غم نہ کھاؤ، تم ہی غالب رہو گے اگر تم سچے مومن ہو۔',
    english: 'So do not weaken and do not grieve, and you will be superior if you are [true] believers.',
  ),
  DailyVerse(
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    ayahNumber: 255,
    arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
    urdu: 'اللہ وہ ہے جس کے سوا کوئی معبود نہیں، وہ ہمیشہ زندہ اور سب کا نگہبان ہے، اسے نہ اونگھ آتی ہے نہ نیند۔',
    english: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.',
  ),
  DailyVerse(
    surahName: 'Ad-Duha',
    surahNumber: 93,
    ayahNumber: 3,
    arabic: 'مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ • وَلَلْآخِرَةُ خَيْرٌ لَكَ مِنَ الْأُولَىٰ',
    urdu: 'آپ کے رب نے آپ کو نہ چھوڑا اور نہ وہ ناراض ہوا، اور یقیناً آخرت آپ کے لیے دنیا سے بہتر ہے۔',
    english: 'Your Lord has not taken leave of you, nor has He detested. And the Hereafter is better for you than the first [life].',
  ),
  DailyVerse(
    surahName: 'Al-Furqan',
    surahNumber: 25,
    ayahNumber: 74,
    arabic: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    urdu: 'اے ہمارے پروردگار! ہمیں ہماری بیویوں اور اولاد کی طرف سے آنکھوں کی ٹھنڈک عطا فرما اور ہمیں پرہیزگاروں کا پیشوا بنا۔',
    english: 'Our Lord, grant us from among our wives and offspring comfort to our eyes and make us an example for the righteous.',
  ),
  DailyVerse(
    surahName: 'Ibrahim',
    surahNumber: 14,
    ayahNumber: 7,
    arabic: 'لَئِنْ شَكَرْتُمْ لَأَزِيدَنَّكُمْ ۖ وَلَئِنْ كَفَرْتُمْ إِنَّ عَذَابِي لَشَدِيدٌ',
    urdu: 'اگر تم شکر ادا کرو گے تو میں تمہیں اور زیادہ دوں گا، اور اگر تم ناشکری کرو گے تو یقیناً میرا عذاب بہت سخت ہے۔',
    english: 'If you are grateful, I will surely increase you [in favor]; but if you deny, indeed, My punishment is severe.',
  ),
  DailyVerse(
    surahName: 'Taha',
    surahNumber: 20,
    ayahNumber: 114,
    arabic: 'رَبِّ زِدْنِي عِلْمًا',
    urdu: 'اے میرے رب! میرے علم میں اضافہ فرما۔',
    english: 'My Lord, increase me in knowledge.',
  ),
  DailyVerse(
    surahName: 'Al-Baqarah',
    surahNumber: 2,
    ayahNumber: 286,
    arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    urdu: 'اللہ کسی جان پر اس کی طاقت سے زیادہ بوجھ نہیں ڈالتا۔',
    english: 'Allah does not charge a soul except [with that within] its capacity.',
  ),
  DailyVerse(
    surahName: 'Al-Anbiya',
    surahNumber: 21,
    ayahNumber: 87,
    arabic: 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    urdu: 'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بے شک میں ہی قصورواروں میں سے تھا۔',
    english: 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
  ),
  DailyVerse(
    surahName: 'Al-Kahf',
    surahNumber: 18,
    ayahNumber: 10,
    arabic: 'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
    urdu: 'اے ہمارے رب! ہمیں اپنے پاس سے رحمت عطا فرما اور ہمارے معاملے میں ہمارے لیے بھلائی کا سامان پیدا فرما۔',
    english: 'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance.',
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
      drawer: const AppDrawer(),
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
            child: SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),

    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 66,
      leading: Center(
        child: Builder(
          builder: (ctx) => Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2038).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F2038), size: 22),
              tooltip: 'Open Menu',
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'حفظ القرآن',
            style: GoogleFonts.amiri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F2038),
              height: 1.1,
            ),
          ),
          Text(
            'HIFZ UL QURAN',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: const Color(0xFFB8860B),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _appBarActionButton(
          icon: Icons.search_rounded,
          tooltip: 'Search Quran',
          onTap: () => context.goNamed('search'),
        ),
        _appBarActionButton(
          icon: Icons.bookmarks_outlined,
          tooltip: 'Bookmarks',
          onTap: () => context.goNamed('bookmarks'),
        ),
        _appBarActionButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => context.goNamed('settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _appBarActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.28), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF0F2038), size: 20),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  Widget _buildHeroCard(AsyncValue<PrayerTimesModel> prayerTimesAsync, dynamic location) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Background Madinah Mosque Photo ──
            Positioned.fill(
              child: Image.asset(
                'assets/images/madinah_hero_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

            // ── Atmospheric Gradient Overlay ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F2038).withValues(alpha: 0.88),
                      const Color(0xFF1E3A60).withValues(alpha: 0.72),
                      const Color(0xFF0B192C).withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Content Layer ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: prayerTimesAsync.when(
                loading: () => const SizedBox(
                  height: 180,
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
                  ],
                ),
                data: (model) {
                  final nextPrayer = model.getNextPrayer();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Row: Location Selector & Hijri Date Chips ──
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
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 12),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        location.cityName,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFD54F),
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Middle Row: Next Prayer & Countdown Timer Card ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT PRAYER',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    nextPrayer.name,
                                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    nextPrayer.arabicName,
                                    style: GoogleFonts.amiri(fontSize: 20, color: const Color(0xFFFFD54F), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                'at ${model.formatTime(nextPrayer.time)}',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),

                          // Clean Countdown Box matching Reference 4
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F2038),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'REMAINING',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E3A60),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Bottom Timetable Strip (5 Prayers) ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _prayerStripItem('Fajr', model.formatTime(model.fajr), Icons.nightlight_round, nextPrayer.prayer == PrayerType.fajr),
                            _prayerStripItem('Dhuhr', model.formatTime(model.dhuhr), Icons.wb_sunny_rounded, nextPrayer.prayer == PrayerType.dhuhr),
                            _prayerStripItem('Asr', model.formatTime(model.asr), Icons.wb_cloudy_rounded, nextPrayer.prayer == PrayerType.asr),
                            _prayerStripItem('Maghrib', model.formatTime(model.maghrib), Icons.wb_twilight_rounded, nextPrayer.prayer == PrayerType.maghrib),
                            _prayerStripItem('Isha', model.formatTime(model.isha), Icons.nights_stay_rounded, nextPrayer.prayer == PrayerType.isha),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerStripItem(String name, String time, IconData icon, bool isNext) {
    if (isNext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2038),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.nightlight_round, color: const Color(0xFFFFD54F), size: 14),
            const SizedBox(height: 2),
            Text(
              name,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              time.split(' ').first,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1E3A60), size: 14),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF4A5568)),
          ),
          Text(
            time.split(' ').first,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F2038)),
          ),
        ],
      ),
    );
  }

  Widget _buildLastReadBanner() {
    final surahNum = _lastRead!['surah'] as int? ?? 1;
    final ayahNum = _lastRead!['ayah'] as int? ?? 1;
    final pageNum = _lastRead!['page'] as int? ?? 1;
    final section = _lastRead!['section'] as String? ?? 'verse_by_verse';

    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final progress = (ayahNum / sInfo.ayahCount).clamp(0.05, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2038),
            Color(0xFF162E4D),
            Color(0xFF0A1828),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ── Background Mosque Watermark on Right ──
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 150,
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/mosque_silhouette_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'CONTINUE READING',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Surah ${sInfo.nameTransliteration} (${sInfo.nameArabic})',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ayah $ayahNum • Page $pageNum',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$percent%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (section == 'mushaf_15') {
                        context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'});
                      } else if (section == 'mushaf_16') {
                        context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'});
                      } else {
                        context.goNamed('verse-by-verse', pathParameters: {'surahNumber': '$surahNum'}, queryParameters: {'ayah': '$ayahNum'});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0F2038),
                      elevation: 4,
                      shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Resume', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
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

  /// Quran Modes & Reading — Imperial Islamic Design System
  Widget _buildVerticalIslamicUtilities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Holy Quran Mushafs ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Holy Quran Mushafs',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F2038),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 0.8),
                ),
                child: Text(
                  'PRINT FORMAT',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF996515),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 1: Illuminated 16-Line & 15-Line Mushaf Cards ──
          Row(
            children: [
              Expanded(
                child: _mushafPrimaryCard(
                  title: '16-Line Mushaf',
                  arabicBadge: '١٦ سطر',
                  subtitle: 'Indo-Pak Taj Standard',
                  badge: 'INDO-PAK',
                  icon: Icons.menu_book_rounded,
                  gradientColors: const [Color(0xFF0A192F), Color(0xFF132B4F)],
                  onTap: () => context.goNamed('mushaf-16', queryParameters: {'page': '1'}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _mushafPrimaryCard(
                  title: '15-Line Mushaf',
                  arabicBadge: '١٥ سطر',
                  subtitle: 'Saudi Madinah Standard',
                  badge: 'MADINAH',
                  icon: Icons.auto_stories_rounded,
                  gradientColors: const [Color(0xFF09202D), Color(0xFF123447)],
                  onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Section 2: Quran Study & Utilities ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quran Study & Utilities',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F2038),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.goNamed('simple-quran', queryParameters: {'tab': '0'});
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F2038),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0F2038)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Study Tools Grid (Harmonized Royal Islamic Palette) ──
          Row(
            children: [
              Expanded(
                child: _studyUtilityCard(
                  title: 'Surah Index',
                  subtitle: '114 Surahs with Audio & Translations',
                  badge: '114 SURAHS',
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Juz Explorer',
                  subtitle: 'Browse & Read Quran by 30 Juz',
                  badge: '30 PARAS',
                  icon: Icons.layers_rounded,
                  onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '1'}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _studyUtilityCard(
                  title: 'Mistakes Report',
                  subtitle: 'Track Hifz & Tajweed Memorization',
                  badge: 'HIFZ TRACKER',
                  icon: Icons.fact_check_rounded,
                  onTap: () => context.goNamed('mistakes-report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Mutashabihat',
                  subtitle: 'Similar Verses Grouped by Ayah',
                  badge: 'SIMILAR VERSES',
                  icon: Icons.compare_arrows_rounded,
                  onTap: () => context.goNamed('mutashabihat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _studyUtilityCard(
                  title: 'Search Quran',
                  subtitle: 'Instant Search Across 6,236 Verses',
                  badge: 'FAST SEARCH',
                  icon: Icons.search_rounded,
                  onTap: () => context.goNamed('search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Bookmarks & Sajdas',
                  subtitle: 'Saved Bookmarks & 14 Sajda Verses',
                  badge: '14 SAJDAS',
                  icon: Icons.bookmarks_rounded,
                  onTap: () => context.goNamed('bookmarks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mushafPrimaryCard({
    required String title,
    required String arabicBadge,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                    ),
                    Text(
                      arabicBadge,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Open Mushaf',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Color(0xFFFFD54F),
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

  Widget _studyUtilityCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E2D5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2038),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2038).withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: const Color(0xFFFFD54F), size: 19),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.outfit(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: const Color(0xFF8C6D1F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F2038),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF55657E),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahOfTheDayCard() {
    final ayahIndex = ref.watch(dailyAyahIndexProvider);
    final verse = kDailyVerses[ayahIndex % kDailyVerses.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2038), Color(0xFF162D4A), Color(0xFF0B192C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8962E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Verse of the Day', style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 17, color: Color(0xFFD4AF37)),
                      tooltip: 'Copy Verse',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(
                          text: '${verse.arabic}\n\n${verse.english}\n\n— Surah ${verse.surahName} [${verse.surahNumber}:${verse.ayahNumber}]',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Copy verse'),
                          backgroundColor: Color(0xFF0F2038),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ));
                      },
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => AyahShareDialog.show(context, surahName: verse.surahName, ayahNumber: verse.ayahNumber, arabicText: verse.arabic, translationText: verse.english),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.share_outlined, size: 13.5, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text('Share', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
              ),
              child: Text(verse.arabic, style: const TextStyle(fontFamily: 'Scheherazade New', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.85), textAlign: TextAlign.center, textDirection: TextDirection.rtl),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(verse.english, style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFFFAF9F6), height: 1.65, fontStyle: FontStyle.italic), textAlign: TextAlign.left),
              ]),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.menu_book_rounded, size: 12.5, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 5),
                    Text('Surah ${verse.surahName} [${verse.surahNumber}:${verse.ayahNumber}]', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFFAF9F6))),
                  ]),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed(
                    'verse-by-verse',
                    pathParameters: {'surahNumber': '${verse.surahNumber}'},
                    queryParameters: {
                      'ayah': '${verse.ayahNumber}',
                      'scrollToAyah': '${verse.ayahNumber}',
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8962E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Read in Surah', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F2038))),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0F2038)),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}