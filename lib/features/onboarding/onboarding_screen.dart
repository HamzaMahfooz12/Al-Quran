// lib/features/onboarding/onboarding_screen.dart
// 5-step onboarding flow — shown only on first launch
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/models/edition.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Step 2 — Languages
  final Set<String> _selectedLanguages = {'ur'};

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
    'ur': 'Urdu',
    'en': 'English',
    'hi': 'Hindi (हिंदी)',
    'ar': 'Arabic',
    'fr': 'French',
    'de': 'German',
    'tr': 'Turkish',
    'id': 'Indonesian',
    'ms': 'Malay',
    'bn': 'Bengali',
    'fa': 'Persian',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcome(),
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

  // ── Step 1: Welcome ───────────────────────────────────────────────────────
  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                '☪',
                style: TextStyle(fontSize: 58, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Al Quran',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Read. Listen. Reflect.',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Let\'s get you set up in just a few steps.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 40),
          _stepHeader(
            '🌐',
            'Choose Languages',
            'Which language(s) do you want for translations?',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
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
          const SizedBox(height: 40),
          _stepHeader(
            '📖',
            'Translation & Tafseer',
            'Pick your default translation and tafseer.',
          ),
          const SizedBox(height: 24),
          if (_loadingEditions)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                children: [
                  _sectionLabel('Translation'),
                  ..._translations.map((e) => _radioTile(
                        title: e.name,
                        subtitle: e.language.toUpperCase(),
                        selected: _selectedTranslation?.id == e.id,
                        onTap: () =>
                            setState(() => _selectedTranslation = e),
                      )),
                  const SizedBox(height: 16),
                  _sectionLabel('Tafseer'),
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

  // ── Step 4: Reciter ───────────────────────────────────────────────────────
  Widget _buildReciterStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          _stepHeader(
            '🎙️',
            'Choose Reciter',
            'Pick your preferred reciter for audio.',
          ),
          const SizedBox(height: 24),
          if (_loadingReciters)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _reciters.length,
                itemBuilder: (ctx, i) {
                  final r = _reciters[i];
                  return _radioTile(
                    title: r.name,
                    subtitle: r.style ?? '',
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

  // ── Step 5: Done ──────────────────────────────────────────────────────────
  Widget _buildDoneStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 60, color: AppTheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your preferences have been saved.\nMay your reading be blessed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageCtrl,
            count: 5,
            effect: ExpandingDotsEffect(
              activeDotColor: AppTheme.primary,
              dotColor: AppTheme.divider,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onNext,
              child: Text(_currentPage == 4 ? 'Start Reading' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation Logic ──────────────────────────────────────────────────────
  Future<void> _onNext() async {
    if (_currentPage == 1) {
      // Going to Step 3 — load editions filtered by selected languages
      await _loadEditions();
    } else if (_currentPage == 2) {
      // Going to Step 4 — load reciters
      await _loadReciters();
    } else if (_currentPage == 3) {
      // Going to Step 5 — save all settings
      await _saveSettings();
    } else if (_currentPage == 4) {
      // Done — navigate to home
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

    // Fetch and sync all worldwide translation & tafseer editions from API
    await repo.fetchAndSyncApiEditions('translation');
    await repo.fetchAndSyncApiEditions('tafseer');

    final allTranslations = await repo.getAllEditions(type: 'translation');
    final allTafseers = await repo.getAllEditions(type: 'tafseer');

    final filteredT = allTranslations
        .where((e) => langs.contains(e.language))
        .toList();
    final filteredTf = allTafseers
        .where((e) => langs.contains(e.language))
        .toList();

    // Default selections
    Edition? defaultTranslation;
    try {
      defaultTranslation = filteredT.firstWhere((e) => e.apiKey.contains('jalandhry') || e.apiKey.contains('ahmedali'));
    } catch (_) {
      defaultTranslation = filteredT.isNotEmpty ? filteredT.first : null;
    }

    Edition? defaultTafseer;
    try {
      defaultTafseer = filteredTf.firstWhere((e) => e.apiKey.contains('ibn-e-kaseer') || e.apiKey.contains('bayan-ul-quran'));
    } catch (_) {
      defaultTafseer = filteredTf.isNotEmpty ? filteredTf.first : null;
    }

    setState(() {
      _translations = filteredT.isNotEmpty ? filteredT : allTranslations;
      _tafseers = filteredTf.isNotEmpty ? filteredTf : allTafseers;
      _selectedTranslation = defaultTranslation;
      _selectedTafseer = defaultTafseer;
      _loadingEditions = false;
    });
  }

  Future<void> _loadReciters() async {
    setState(() => _loadingReciters = true);
    final reciters =
        await ref.read(reciterRepositoryProvider).getReciters();

    // Pre-select Al-Sudais
    Reciter? defaultReciter;
    try {
      defaultReciter = reciters.firstWhere(
          (r) => r.id.contains('abdurrahmaansudais'));
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

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _stepHeader(String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 1.0)),
    );
  }

  Widget _checkTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySurface : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySurface : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
