// lib/features/tasbeeh/screens/tasbeeh_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';

class TasbeehPreset {
  final String arabic;
  final String transliteration;
  final String translation;
  final int defaultTarget;

  const TasbeehPreset({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.defaultTarget = 33,
  });
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _count = 0;
  int _target = 33;
  int _totalCount = 0;
  int _selectedPresetIdx = 0;
  bool _soundVibrate = true;

  static const List<TasbeehPreset> _presets = [
    TasbeehPreset(
      arabic: 'سُبْحَانَ ٱللَّٰهِ',
      transliteration: 'SubhanAllah',
      translation: 'Glory be to Allah',
      defaultTarget: 33,
    ),
    TasbeehPreset(
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
      transliteration: 'Alhamdulillah',
      translation: 'Praise be to Allah',
      defaultTarget: 33,
    ),
    TasbeehPreset(
      arabic: 'ٱللَّٰهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      defaultTarget: 34,
    ),
    TasbeehPreset(
      arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
      transliteration: 'La ilaha illallah',
      translation: 'There is no god but Allah',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      transliteration: 'Allahumma Salli Ala Muhammad',
      translation: 'O Allah, send blessings upon Muhammad',
      defaultTarget: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCount = prefs.getInt('tasbeeh_total_lifetime_count') ?? 0;
      _count = prefs.getInt('tasbeeh_current_session_count') ?? 0;
      _target = prefs.getInt('tasbeeh_current_target') ?? 33;
      _selectedPresetIdx = prefs.getInt('tasbeeh_selected_preset_idx') ?? 0;
    });
  }

  Future<void> _incrementCount() async {
    final newCount = _count + 1;
    final newTotal = _totalCount + 1;

    // Haptic feedback
    if (_soundVibrate) {
      if (newCount == _target) {
        // Double vibration on target reached
        Vibration.hasVibrator().then((has) {
          if (has == true) Vibration.vibrate(pattern: [0, 80, 50, 150]);
        });
      } else {
        Vibration.hasVibrator().then((has) {
          if (has == true) Vibration.vibrate(duration: 25);
        });
      }
    }

    setState(() {
      _count = newCount;
      _totalCount = newTotal;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_total_lifetime_count', newTotal);
    await prefs.setInt('tasbeeh_current_session_count', newCount);
  }

  Future<void> _resetCurrent() async {
    setState(() => _count = 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_current_session_count', 0);
  }

  void _selectPreset(int idx) {
    setState(() {
      _selectedPresetIdx = idx;
      _target = _presets[idx].defaultTarget;
      _count = 0;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('tasbeeh_selected_preset_idx', idx);
      prefs.setInt('tasbeeh_current_target', _target);
      prefs.setInt('tasbeeh_current_session_count', 0);
    });
  }

  void _setTarget(int t) {
    setState(() {
      _target = t;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('tasbeeh_current_target', t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPresetIdx];
    final progress = _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Digital Tasbeeh', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_soundVibrate ? Icons.vibration : Icons.smartphone, color: AppTheme.primary),
            tooltip: 'Haptic Feedback',
            onPressed: () => setState(() => _soundVibrate = !_soundVibrate),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            tooltip: 'Reset Counter',
            onPressed: _resetCurrent,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
        children: [
          // ── Preset Selector Chips ───────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final isSelected = (i == _selectedPresetIdx);
                return ChoiceChip(
                  label: Text(_presets[i].transliteration),
                  selected: isSelected,
                  selectedColor: AppTheme.primarySurface,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) _selectPreset(i);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Current Dhikr Card ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECE9)),
            ),
            child: Column(
              children: [
                Text(
                  preset.arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  preset.translation,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Interactive Circular Tap Counter ────────────────────────────
          GestureDetector(
            onTap: _incrementCount,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress indicator
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFE0EAE3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),

                // Center Count Sphere
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF2D5A34)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4332).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_count',
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Target: $_target',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TAP ANYWHERE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA5D6A7),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Target Switchers & Lifetime Total ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [33, 99, 100].map((t) {
                    final isCur = (_target == t);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _setTarget(t),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCur ? AppTheme.primary : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isCur ? AppTheme.primary : const Color(0xFFE2E8E4)),
                          ),
                          child: Text(
                            '$t',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCur ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  'Lifetime: $_totalCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

            SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
