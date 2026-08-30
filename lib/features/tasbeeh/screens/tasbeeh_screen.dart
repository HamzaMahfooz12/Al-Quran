// lib/features/tasbeeh/screens/tasbeeh_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  int _totalCount = 0;
  int _selectedPresetIdx = 0;
  bool _soundVibrate = true;
  double _buttonScale = 1.0;
  bool _showMilestoneGlow = false;

  late AnimationController _glowController;

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
      translation: 'All praise is due to Allah',
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
      translation: 'There is no god worthy of worship except Allah',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      transliteration: 'Allahumma Salli Ala Muhammad',
      translation: 'O Allah, send blessings upon Muhammad',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ',
      transliteration: 'La Hawla Wala Quwwata Illa Billah',
      translation: 'There is no power and no strength except with Allah',
      defaultTarget: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
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
    // Micro-scale tap animation
    setState(() {
      _buttonScale = 0.94;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });

    final newCount = _count + 1;
    final newTotal = _totalCount + 1;
    final bool reachedMilestone = _target > 0 && newCount % _target == 0;

    // Haptic feedback & milestone celebration
    if (_soundVibrate) {
      if (reachedMilestone) {
        HapticFeedback.heavyImpact();
        Vibration.hasVibrator().then((has) {
          if (has == true) Vibration.vibrate(pattern: [0, 90, 60, 180]);
        });
      } else {
        HapticFeedback.lightImpact();
        Vibration.hasVibrator().then((has) {
          if (has == true) Vibration.vibrate(duration: 22);
        });
      }
    }

    if (reachedMilestone) {
      _triggerMilestoneCelebration();
    }

    setState(() {
      _count = newCount;
      _totalCount = newTotal;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_total_lifetime_count', newTotal);
    await prefs.setInt('tasbeeh_current_session_count', newCount);
  }

  void _triggerMilestoneCelebration() {
    setState(() => _showMilestoneGlow = true);
    _glowController.forward(from: 0.0).then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showMilestoneGlow = false);
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 22),
            const SizedBox(width: 10),
            Text(
              'Target of $_target Dhikr completed! May Allah accept.',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetCurrent() async {
    setState(() => _count = 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_current_session_count', 0);
    HapticFeedback.mediumImpact();
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
    HapticFeedback.selectionClick();
  }

  void _openCustomTargetDialog() {
    final ctrl = TextEditingController(text: '$_target');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Custom Target',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A1E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter desired repetition target (or 0 for infinite):', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 500',
                filled: true,
                fillColor: const Color(0xFFFAF7F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E1D2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2C7A39), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                _setTarget(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C7A39),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPresetIdx];
    final progress = _target > 0 ? (_count % _target) / _target : 0.0;
    final rounds = _target > 0 ? (_count ~/ _target) : 0;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Digital Tasbeeh',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A1E)),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _soundVibrate ? const Color(0xFFEAF6EC) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: _soundVibrate ? const Color(0xFFC7E6CE) : const Color(0xFFE5E7EB)),
              ),
              child: Icon(
                _soundVibrate ? Icons.vibration_rounded : Icons.smartphone_rounded,
                color: _soundVibrate ? const Color(0xFF2C7A39) : const Color(0xFF9CA3AF),
                size: 18,
              ),
            ),
            tooltip: 'Haptic Feedback',
            onPressed: () => setState(() => _soundVibrate = !_soundVibrate),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC7E6CE)),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF2C7A39), size: 18),
            ),
            tooltip: 'Reset Counter',
            onPressed: _resetCurrent,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // ── 1. Preset Selector Carousel ──
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final isSelected = (i == _selectedPresetIdx);
                  return GestureDetector(
                    onTap: () => _selectPreset(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF2C7A39), Color(0xFF1B4332)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2C7A39) : const Color(0xFFE8E1D2),
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF2C7A39).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _presets[i].transliteration,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1B2A1E),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── 2. Current Dhikr Display Card ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  Text(
                    preset.arabic,
                    style: const TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2A1E),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.translation,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6B7280),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── 3. Tactile Animated Circular Tap Counter Centerpiece ──
            GestureDetector(
              onTap: _incrementCount,
              child: AnimatedScale(
                scale: _buttonScale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutBack,
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Progress Ring Custom Painter
                      CustomPaint(
                        size: const Size(256, 256),
                        painter: _TasbeehProgressPainter(
                          progress: progress,
                          isMilestone: _showMilestoneGlow,
                        ),
                      ),

                      // Center Sphere Tap Button
                      Container(
                        width: 216,
                        height: 216,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C7A39), Color(0xFF1B4332)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: _showMilestoneGlow ? const Color(0xFFFFD54F) : const Color(0xFF56BA64),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _showMilestoneGlow
                                  ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                                  : const Color(0xFF2C7A39).withValues(alpha: 0.35),
                              blurRadius: _showMilestoneGlow ? 32 : 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_count',
                              style: GoogleFonts.outfit(
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.6), width: 0.8),
                              ),
                              child: Text(
                                _target > 0 ? 'Target: $_target' : 'Infinite (∞)',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'TAP TO COUNT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFA5D6A7),
                                letterSpacing: 1.8,
                              ),
                            ),
                            if (rounds > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$rounds round${rounds > 1 ? 's' : ''} completed',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ── 4. Target Selector Pills & Lifetime Counter ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E1D2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _targetPill(33),
                      const SizedBox(width: 6),
                      _targetPill(99),
                      const SizedBox(width: 6),
                      _targetPill(100),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _openCustomTargetDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8E1D2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF2C7A39)),
                              const SizedBox(width: 3),
                              Text(
                                'Custom',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C7A39),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Lifetime Total',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$_totalCount',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C7A39),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 + bottomPad),
          ],
        ),
      ),
    );
  }

  Widget _targetPill(int t) {
    final isCur = (_target == t);
    return GestureDetector(
      onTap: () => _setTarget(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCur ? const Color(0xFF2C7A39) : const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCur ? const Color(0xFF2C7A39) : const Color(0xFFE8E1D2),
          ),
        ),
        child: Text(
          '$t',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isCur ? Colors.white : const Color(0xFF4B5E50),
          ),
        ),
      ),
    );
  }
}

// ── Circular Animated Progress Ring Custom Painter ──────────────────────────
class _TasbeehProgressPainter extends CustomPainter {
  final double progress;
  final bool isMilestone;

  _TasbeehProgressPainter({required this.progress, required this.isMilestone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = const Color(0xFFE2ECE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Animated Progress Arc
      final progressPaint = Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF56BA64),
            Color(0xFF2C7A39),
            Color(0xFFF59E0B),
          ],
          stops: [0.0, 0.7, 1.0],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.5
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TasbeehProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isMilestone != isMilestone;
  }
}
