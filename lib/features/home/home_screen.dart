// lib/features/home/home_screen.dart
// World-class Islamic Hub — Prayer times hero, utility grid, last-read, Surah & Juz tabs
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final lr = await repo.getLastReadMushaf();
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
      backgroundColor: const Color(0xFFF1EFE8),
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── 1. Dynamic Islamic Hero Header with Fiqh Badge ───────────────
          SliverToBoxAdapter(
            child: _buildHeroCard(prayerTimesAsync, location),
          ),

          // ── 2. Quick Resume Last Read Banner ────────────────────────────
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
      toolbarHeight: 68,
      backgroundColor: const Color(0xFFF1EFE8),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Center(
        child: Builder(
          builder: (ctx) => Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDED6C6), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A6F715C),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF68705C), size: 20),
              tooltip: 'Open Menu',
              padding: EdgeInsets.zero,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF46513F),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 13, height: 1, color: const Color(0xFFC7AE78)),
              const SizedBox(width: 6),
              Text(
                'Hifz ul Quran',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.25,
                  color: const Color(0xFFA17D42),
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 13, height: 1, color: const Color(0xFFC7AE78)),
            ],
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
          icon: Icons.bookmark_border_rounded,
          tooltip: 'Bookmarks & Sajdas',
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
      width: 33,
      height: 33,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDED6C6), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A6F715C),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF68705C), size: 17),
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
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFD9C9A7), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18625A45),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Mosque Photo
            Positioned.fill(
              child: Image.asset(
                'assets/images/madinah_hero_bg.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
              ),
            ),

            // Daylight Atmospheric Warm Parchment Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xE8F8F4EA),
                      Color(0xC7F8F4EA),
                      Color(0x99F8F4EA),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Content Layer
            Padding(
              padding: const EdgeInsets.all(14),
              child: prayerTimesAsync.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFC6A15B))),
                ),
                error: (err, stack) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(location.displayName, style: GoogleFonts.inter(color: const Color(0xFF354033), fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => LocationPickerBottomSheet.show(context),
                          child: const Text('Select City', style: TextStyle(color: Color(0xFF987238))),
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
                      // Top Row: Location Pill + Date Pill + Hanafi Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () => LocationPickerBottomSheet.show(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xCFFFFDF2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFD8CFBE), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Color(0xFF80632F), size: 13),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        location.cityName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4F584A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xCFFFFDF2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFD8CFBE), width: 1.0),
                                ),
                                child: Text(
                                  model.hijriDate,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4F584A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9BD7B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HANAFI',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF4B432F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Next Prayer & Countdown Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT PRAYER',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF987238),
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextPrayer.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF394234),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'starts at ${model.formatTime(nextPrayer.time)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF73786E),
                                ),
                              ),
                            ],
                          ),

                          // Countdown Box
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'BEGINS IN',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF987238),
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDuration(nextPrayer.timeRemaining),
                                style: GoogleFonts.outfit(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF80632F),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Hours   Min   Sec',
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

                      const SizedBox(height: 14),

                      // Bottom Timetable Strip (6 Prayers: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0x2C8E896F), width: 1.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            _prayerStripItem('Fajr', model.formatTime(model.fajr), '◒', nextPrayer.prayer == PrayerType.fajr),
                            _prayerStripItem('Sunrise', model.formatTime(model.sunrise), '○', nextPrayer.prayer == PrayerType.sunrise),
                            _prayerStripItem('Dhuhr', model.formatTime(model.dhuhr), '◐', nextPrayer.prayer == PrayerType.dhuhr),
                            _prayerStripItem('Asr', model.formatTime(model.asr), '◒', nextPrayer.prayer == PrayerType.asr),
                            _prayerStripItem('Maghrib', model.formatTime(model.maghrib), '◑', nextPrayer.prayer == PrayerType.maghrib),
                            _prayerStripItem('Isha', model.formatTime(model.isha), '●', nextPrayer.prayer == PrayerType.isha),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Photo by Haidan / Unsplash',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 6,
                            color: const Color(0x7A485042),
                          ),
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

  Widget _prayerStripItem(String name, String time, String symbol, bool isNext) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xE8FFFDF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isNext ? Border.all(color: const Color(0xFFC9A961), width: 1.2) : null,
          boxShadow: isNext ? const [
            BoxShadow(
              color: Color(0x10625A45),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF987238),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: isNext ? const Color(0xFF495242) : const Color(0xFF70776C),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              time.split(' ').first,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                color: isNext ? const Color(0xFF987238) : const Color(0xFF60685E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadBanner() {
    final lastReadData = _lastRead ?? {
      'surah': 18,
      'ayah': 28,
      'page': 297,
      'juz': 15,
      'section': 'mushaf_16',
    };

    final surahNum = lastReadData['surah'] as int? ?? 18;
    final ayahNum = lastReadData['ayah'] as int? ?? 28;
    final pageNum = lastReadData['page'] as int? ?? 297;
    final juzNum = lastReadData['juz'] as int? ?? 15;
    final section = lastReadData['section'] as String? ?? 'mushaf_16';

    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final progress = (ayahNum / sInfo.ayahCount).clamp(0.05, 1.0);
    final percent = _lastRead == null ? 68 : (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDCFB3),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D625A45),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Gold circular medallion
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFC5A465),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: Color(0xFFFFFDF7), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE READING',
                    style: GoogleFonts.outfit(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF977438),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Surah ${sInfo.nameTransliteration} (${sInfo.nameArabic})',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF394234),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ayah $ayahNum  •  Page $pageNum  •  Juz $juzNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: const Color(0xFF7C8178),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _lastRead == null ? 0.68 : progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFEBE6DC),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A45F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF99763B),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (section == 'mushaf_15') {
                      context.goNamed('mushaf-15', queryParameters: {'page': '$pageNum'});
                    } else {
                      context.goNamed('mushaf-16', queryParameters: {'page': '$pageNum'});
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE1C5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Resume',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5B4A2D),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF5B4A2D)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahOfTheDayCard() {
    final ayahIndex = ref.watch(dailyAyahIndexProvider);
    final verse = kDailyVerses[ayahIndex % kDailyVerses.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFDF7),
            Color(0xFFF8F1E3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFCCB37E), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A8D7848),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Today's Ayah + Copy & Share
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Ayah",
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4D5945),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD5C5)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF6B7463)),
                        tooltip: 'Copy Verse',
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(
                            text: '${verse.arabic}\n\n${verse.english}\n\n— Surah ${verse.surahName} [${verse.surahNumber}:${verse.ayahNumber}]',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Verse copied'),
                            backgroundColor: Color(0xFF59634A),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Share button
                    Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD5C5)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_rounded, size: 14, color: Color(0xFF6B7463)),
                        tooltip: 'Share Verse',
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          AyahShareDialog.show(
                            context,
                            surahName: verse.surahName,
                            ayahNumber: verse.ayahNumber,
                            arabicText: verse.arabic,
                            translationText: verse.english,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Inner Verse Feature Box with Floating Sage Medallion (AYAH 152)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.fromLTRB(14, 26, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDED2B9), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      // Arabic Verse
                      Text(
                        verse.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3F493A),
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: const Color(0xFFE8E0D0),
                      ),
                      const SizedBox(height: 8),
                      // Translation Text
                      Text(
                        '“${verse.english}”',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF62695F),
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Floating Medallion overlapping the top border
                Positioned(
                  top: -2,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF748164),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFFDF8), width: 3.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x35657056),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'AYAH',
                          style: GoogleFonts.outfit(
                            fontSize: 6,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          '${verse.ayahNumber}',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD9C69F)),
                  ),
                  child: Text(
                    '${verse.surahName.toUpperCase()} · ${verse.surahNumber}:${verse.ayahNumber}',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: const Color(0xFF8B6B35),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed(
                      'verse-by-verse',
                      pathParameters: {'surahNumber': '${verse.surahNumber}'},
                      queryParameters: {
                        'ayah': '${verse.ayahNumber}',
                        'scrollToAyah': '${verse.ayahNumber}',
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE8D6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read in Surah',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B5943),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF4B5943)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                    height: 19,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD8B873), Color(0xFFC4A364)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Holy Quran Mushafs',
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF414B3D),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EADB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PRINT FORMAT',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: const Color(0xFF876A39),
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
                  cardColor: const Color(0xFFF2EDDF),
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
                  cardColor: const Color(0xFFE8EFE6),
                  onTap: () => context.goNamed('mushaf-15', queryParameters: {'page': '1'}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Section 2: Quran Study & Utilities (with VIEW ALL → pill) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 19,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD8B873), Color(0xFFC4A364)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quran Study & Utilities',
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF414B3D),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EADB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VIEW ALL →',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: const Color(0xFF876A39),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Study Tools Grid ──
          Row(
            children: [
              Expanded(
                child: _studyUtilityCard(
                  title: 'Surah Index',
                  subtitle: 'Audio & translations',
                  badge: '114 SURAHS',
                  icon: Icons.menu_book_rounded,
                  onTap: () => context.goNamed('simple-quran', queryParameters: {'tab': '0'}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Juz Explorer',
                  subtitle: 'Read Quran by Paras',
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
                  subtitle: 'Hifz & Tajweed tracker',
                  badge: 'HIFZ TRACKER',
                  icon: Icons.fact_check_rounded,
                  onTap: () => context.goNamed('mistakes-report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Mutashabihat',
                  subtitle: 'Similar verses by Ayah',
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
                  subtitle: 'Search 6,236 verses',
                  badge: 'FAST SEARCH',
                  icon: Icons.search_rounded,
                  onTap: () => context.goNamed('search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _studyUtilityCard(
                  title: 'Bookmarks & Sajdas',
                  subtitle: 'Saved Quran moments',
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
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD9CAA9),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10625A45),
            blurRadius: 20,
            offset: Offset(0, 8),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC5A465),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD9C69E)),
                      ),
                      child: Text(
                        arabicBadge,
                        style: GoogleFonts.amiri(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF896B36),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3F493C),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: const Color(0xFF737970),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Open Mushaf',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF846632),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Color(0xFF846632),
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
          color: const Color(0xFFE3DED3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09625A45),
            blurRadius: 18,
            offset: Offset(0, 7),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE1E8DB),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, color: const Color(0xFF626D58), size: 22),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEBE0C8),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.outfit(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                          color: const Color(0xFF8E6D37),
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
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF404A3D),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: const Color(0xFF857E70),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4E9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEBE0C8),
                        width: 0.8,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: Color(0xFF8E6D37),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}