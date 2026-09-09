// lib/features/onboarding/onboarding_screen.dart
// Luxury Onboarding flow with inspiring Quranic quotes, rich animations & personalization
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/edition.dart';
import '../../data/models/reciter.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../services/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Step 2 — Languages
  final Set<String> _selectedLanguages = {'ur', 'en'};

  // Step 3 — Translation & Tafseer
  Edition? _selectedTranslation;
  Edition? _selectedTafseer;
  List<Edition> _translations = [];
  List<Edition> _tafseers = [];
  bool _loadingEditions = false;

  // Step 4 — Reciter
  Reciter? _selectedReciter;
  List<Reciter> _reciters = [];
  bool _loadingReciters = false;

  static const _supportedLanguages = {
    'ur': 'Urdu (اردو)',
    'en': 'English',
    'hi': 'Hindi (हिंदी)',
    'ar': 'Arabic (العربية)',
    'bn': 'Bengali (বাংলা)',
    'tr': 'Turkish (Türkçe)',
    'id': 'Indonesian (Bahasa)',
    'ms': 'Malay (Melayu)',
    'fa': 'Persian (فارسی)',
    'fr': 'French (Français)',
    'de': 'German (Deutsch)',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1728),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip & Step Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Step ${_currentPage + 1} of 5',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: _skipToEnd,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  if (i == 2 && _translations.isEmpty) {
                    _loadEditions();
                  } else if (i == 3 && _reciters.isEmpty) {
                    _loadReciters();
                  }
                },
                children: [
                  _buildWelcomeQuoteStep(),
                  _buildLanguageStep(),
                  _buildEditionStep(),
                  _buildReciterStep(),
                  _buildDoneStep(),
                ],
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Welcome & Sacred Quranic Quote ─────────────────────────────────
  Widget _buildWelcomeQuoteStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Glowing App Emblem
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
                border: Border.all(color: AppTheme.gold, width: 2.5),
              ),
              child: Image.asset(
                'assets/images/app_logo_emblem.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'حَافِظُ الْقُرْآنِ',
            style: GoogleFonts.amiri(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
              height: 1.2,
            ),
          ),

          Text(
            'Hifz ul Quran',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Sacred Quote Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2038), Color(0xFF1E3A60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_quote_rounded, color: AppTheme.gold.withValues(alpha: 0.8), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'Surah Al-Qamar • 54:17',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Scheherazade New',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF9E6),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"And We have certainly made the Quran easy to remember, so is there any who will remember?"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اور ہم نے قرآن کو یاد کرنے اور سمجھنے کے لیے آسان بنا دیا ہے، تو کیا ہے کوئی یاد رکھنے والا؟',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 13,
                    color: AppTheme.gold.withValues(alpha: 0.9),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Highlights Grid
          Row(
            children: [
              _featurePill(Icons.auto_stories_rounded, '15 & 16 Line Mushaf'),
              const SizedBox(width: 8),
              _featurePill(Icons.record_voice_over_rounded, 'Audio Recitations'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _featurePill(Icons.explore_rounded, 'Qibla & Prayer Times'),
              const SizedBox(width: 8),
              _featurePill(Icons.spa_rounded, 'Azkar & Tasbeeh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Language Selection ────────────────────────────────────────────
  Widget _buildLanguageStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            '🌐',
            'Select Translation Languages',
            'Choose your preferred languages for Quran translations & Tafseer.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: _supportedLanguages.entries.map((entry) {
                final selected = _selectedLanguages.contains(entry.key);
                return _checkTile(
                  title: entry.value,
                  subtitle: entry.key.toUpperCase(),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        if (_selectedLanguages.length > 1) {
                          _selectedLanguages.remove(entry.key);
                        }
                      } else {
                        _selectedLanguages.add(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Translation & Tafseer ─────────────────────────────────────────
  Widget _buildEditionStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            '📖',
            'Default Translation & Tafseer',
            'Select your default primary translation and authentic Tafseer.',
          ),
          const SizedBox(height: 16),
          if (_loadingEditions)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
            )
          else
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _sectionLabel('Primary Translation'),
                  ..._translations.map((e) => _radioTile(
                        title: e.name,
                        subtitle: e.language.toUpperCase(),
                        selected: _selectedTranslation?.id == e.id,
                        onTap: () => setState(() => _selectedTranslation = e),
                      )),
                  const SizedBox(height: 16),
                  _sectionLabel('Default Tafseer'),
                  ..._tafseers.map((e) => _radioTile(
                        title: e.name,
                        subtitle: e.language.toUpperCase(),
                        selected: _selectedTafseer?.id == e.id,
                        onTap: () => setState(() => _selectedTafseer = e),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 4: Reciter Selection ─────────────────────────────────────────────
  Widget _buildReciterStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            '🎙️',
            'Favorite Qari (Reciter)',
            'Choose your preferred voice for verse-by-verse and page audio.',
          ),
          const SizedBox(height: 16),
          if (_loadingReciters)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _reciters.length,
                itemBuilder: (ctx, i) {
                  final r = _reciters[i];
                  return _radioTile(
                    title: r.name,
                    subtitle: r.style ?? 'Murattal',
                    selected: _selectedReciter?.id == r.id,
                    onTap: () => setState(() => _selectedReciter = r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 5: Done & Du'a Card ──────────────────────────────────────────────
  Widget _buildDoneStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.18),
              border: Border.all(color: AppTheme.gold, width: 2),
            ),
            child: const Icon(Icons.check_rounded, size: 48, color: AppTheme.gold),
          ),
          const SizedBox(height: 20),
          Text(
            'مَاشَاءَ اللّٰهُ',
            style: GoogleFonts.amiri(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
            ),
          ),
          Text(
            'You are All Set!',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'اللَّهُمَّ اجْعَلِ الْقُرْآنَ رَبِيعَ قُلُوبِنَا وَنُورَ صُدُورِنَا',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Scheherazade New',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF9E6),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"O Allah, make the Quran the spring of our hearts and the light of our chests."',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'May your journey with the Holy Quran bring tranquility and blessings into your life.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 16 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF07101C),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageCtrl,
            count: 5,
            effect: ExpandingDotsEffect(
              activeDotColor: AppTheme.gold,
              dotColor: Colors.white24,
              dotHeight: 7,
              dotWidth: 7,
              expansionFactor: 3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: const Color(0xFF0F2038),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _currentPage == 4 ? 'Bismillah — Start Reading' : 'Continue',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI Components ─────────────────────────────────────────────────────────
  Widget _stepHeader(String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.gold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _checkTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.gold : Colors.white.withValues(alpha: 0.12),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.gold.withValues(alpha: 0.8)),
        ),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: selected ? AppTheme.gold : Colors.white30,
          size: 20,
        ),
      ),
    );
  }

  Widget _radioTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.gold : Colors.white.withValues(alpha: 0.12),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.gold.withValues(alpha: 0.8)),
        ),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppTheme.gold : Colors.white30,
          size: 20,
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _skipToEnd() async {
    await _saveSettings();
    await ref.read(settingsServiceProvider).setOnboardingDone();
    if (mounted) context.go('/home');
  }

  Future<void> _onNext() async {
    if (_currentPage == 1) {
      await _loadEditions();
    } else if (_currentPage == 2) {
      await _loadReciters();
    } else if (_currentPage == 3) {
      await _saveSettings();
    } else if (_currentPage == 4) {
      await _saveSettings();
      await ref.read(settingsServiceProvider).setOnboardingDone();
      if (mounted) context.go('/home');
      return;
    }

    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadEditions() async {
    setState(() => _loadingEditions = true);
    final repo = ref.read(quranRepositoryProvider);
    final langs = _selectedLanguages.toList();

    await repo.fetchAndSyncApiEditions('translation');
    await repo.fetchAndSyncApiEditions('tafseer');

    final allTranslations = await repo.getAllEditions(type: 'translation');
    final allTafseers = await repo.getAllEditions(type: 'tafseer');

    final filteredT = allTranslations.where((e) => langs.contains(e.language)).toList();
    final filteredTf = allTafseers.where((e) => langs.contains(e.language)).toList();

    Edition? defaultTranslation;
    try {
      defaultTranslation = filteredT.firstWhere(
        (e) => e.apiKey.contains('jalandhry') || e.apiKey.contains('ahmedali'),
      );
    } catch (_) {
      defaultTranslation = filteredT.isNotEmpty ? filteredT.first : null;
    }

    Edition? defaultTafseer;
    try {
      defaultTafseer = filteredTf.firstWhere(
        (e) => e.apiKey.contains('ibn-e-kaseer') || e.apiKey.contains('bayan-ul-quran'),
      );
    } catch (_) {
      defaultTafseer = filteredTf.isNotEmpty ? filteredTf.first : null;
    }

    setState(() {
      _translations = filteredT.isNotEmpty ? filteredT : allTranslations;
      _tafseers = filteredTf.isNotEmpty ? filteredTf : allTafseers;
      _selectedTranslation = defaultTranslation ?? (_translations.isNotEmpty ? _translations.first : null);
      _selectedTafseer = defaultTafseer ?? (_tafseers.isNotEmpty ? _tafseers.first : null);
      _loadingEditions = false;
    });
  }

  Future<void> _loadReciters() async {
    setState(() => _loadingReciters = true);
    final reciterRepo = ref.read(reciterRepositoryProvider);
    final reciters = await reciterRepo.getReciters();

    Reciter? defaultReciter;
    try {
      defaultReciter = reciters.firstWhere((r) => r.id.contains('alafasy') || r.id.contains('sudais'));
    } catch (_) {
      defaultReciter = reciters.isNotEmpty ? reciters.first : null;
    }

    setState(() {
      _reciters = reciters;
      _selectedReciter = defaultReciter;
      _loadingReciters = false;
    });
  }

  Future<void> _saveSettings() async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setSelectedLanguages(_selectedLanguages.toList());
    if (_selectedTranslation != null) {
      await settings.setSelectedTranslationId(_selectedTranslation!.id);
    }
    if (_selectedTafseer != null) {
      await settings.setSelectedTafseerEditionId(_selectedTafseer!.id);
    }
    if (_selectedReciter != null) {
      await settings.setSelectedReciterId(_selectedReciter!.id);
    }
  }
}
