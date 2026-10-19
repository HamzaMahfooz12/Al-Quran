// lib/features/tasbeeh/screens/tasbeeh_screen.dart
// Luxury Digital Tasbeeh & Dhikr Counter Screen matching Google Stitch design
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class TasbeehPreset {
  final String arabic;
  final String transliteration;
  final String translation;
  final int defaultTarget;

  const TasbeehPreset({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.defaultTarget,
  });
}

class TasbeehSavedLap {
  final String presetName;
  final String arabic;
  final int count;
  final int lap;
  final DateTime timestamp;

  const TasbeehSavedLap({
    required this.presetName,
    required this.arabic,
    required this.count,
    required this.lap,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'presetName': presetName,
        'arabic': arabic,
        'count': count,
        'lap': lap,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TasbeehSavedLap.fromJson(Map<String, dynamic> json) => TasbeehSavedLap(
        presetName: json['presetName'] as String? ?? 'Dhikr',
        arabic: json['arabic'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        lap: json['lap'] as int? ?? 1,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Main Screen Widget ───────────────────────────────────────────────────────

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with TickerProviderStateMixin {
  // ── State variables ──
  int _count = 0;
  int _target = 33;
  int _lap = 1;
  int _lifetimeCount = 0;
  int _todayCount = 0;
  int _selectedPresetIdx = 0;

  bool _hapticEnabled = true;
  bool _soundEnabled = false;

  double _buttonScale = 1.0;
  bool _showCelebrationToast = false;
  String _toastTitle = 'Target 33 Completed!';
  Timer? _toastTimer;

  List<TasbeehSavedLap> _savedLaps = [];

  // Controllers
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacityAnimation;

  // ── 7 Authentic Presets matching Stitch Template ──
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
      translation: 'I seek forgiveness',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
      transliteration: 'La Ilaha Illallah',
      translation: 'None worthy of worship',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      transliteration: 'Durood Sharif',
      translation: 'Blessings upon Prophet',
      defaultTarget: 100,
    ),
    TasbeehPreset(
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ',
      transliteration: 'Hawqala',
      translation: 'No power except Allah',
      defaultTarget: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for gold aura and indicator dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple wave animation on dial tap
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rippleAnimation = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
    _rippleOpacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _loadState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    final savedDate = prefs.getString('tasbeeh_last_date') ?? todayKey;

    int loadedTodayCount = prefs.getInt('tasbeeh_today_count') ?? 0;
    if (savedDate != todayKey) {
      // New day rollover
      loadedTodayCount = 0;
      await prefs.setString('tasbeeh_last_date', todayKey);
      await prefs.setInt('tasbeeh_today_count', 0);
    }

    // Load saved laps
    final lapsRaw = prefs.getString('tasbeeh_saved_laps_json');
    List<TasbeehSavedLap> laps = [];
    if (lapsRaw != null && lapsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(lapsRaw) as List;
        laps = decoded.map((e) => TasbeehSavedLap.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _lifetimeCount = prefs.getInt('tasbeeh_lifetime_count') ?? 12450;
        _todayCount = loadedTodayCount;
        _count = prefs.getInt('tasbeeh_current_count') ?? 0;
        _target = prefs.getInt('tasbeeh_current_target') ?? 33;
        _lap = prefs.getInt('tasbeeh_current_lap') ?? 1;
        _selectedPresetIdx = (prefs.getInt('tasbeeh_preset_idx') ?? 0).clamp(0, _presets.length - 1);
        _hapticEnabled = prefs.getBool('tasbeeh_haptic_enabled') ?? true;
        _soundEnabled = prefs.getBool('tasbeeh_sound_enabled') ?? false;
        _savedLaps = laps;
      });
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_lifetime_count', _lifetimeCount);
    await prefs.setInt('tasbeeh_today_count', _todayCount);
    await prefs.setString('tasbeeh_last_date', _getTodayKey());
    await prefs.setInt('tasbeeh_current_count', _count);
    await prefs.setInt('tasbeeh_current_target', _target);
    await prefs.setInt('tasbeeh_current_lap', _lap);
    await prefs.setInt('tasbeeh_preset_idx', _selectedPresetIdx);
    await prefs.setBool('tasbeeh_haptic_enabled', _hapticEnabled);
    await prefs.setBool('tasbeeh_sound_enabled', _soundEnabled);
    await prefs.setString(
      'tasbeeh_saved_laps_json',
      jsonEncode(_savedLaps.map((l) => l.toJson()).toList()),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _incrementCount() {
    // Button tactile compress effect
    setState(() => _buttonScale = 0.96);
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });

    // Ripple wave animation
    _rippleController.forward(from: 0.0);

    final newCount = _count + 1;
    final newLifetime = _lifetimeCount + 1;
    final newToday = _todayCount + 1;
    final bool reachedMilestone = _target > 0 && newCount >= _target;

    // Haptic Feedback
    if (_hapticEnabled) {
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

    // Audio Chime Feedback
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      _count = newCount;
      _lifetimeCount = newLifetime;
      _todayCount = newToday;
    });

    if (reachedMilestone) {
      _triggerMilestoneCelebration();
    } else {
      _saveState();
    }
  }

  void _triggerMilestoneCelebration() {
    final currentTarget = _target;
    final currentLap = _lap;
    final currentPreset = _presets[_selectedPresetIdx];

    // Save lap record
    _savedLaps.insert(
      0,
      TasbeehSavedLap(
        presetName: currentPreset.transliteration,
        arabic: currentPreset.arabic,
        count: currentTarget,
        lap: currentLap,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _toastTitle = 'Target $currentTarget Completed!';
      _showCelebrationToast = true;
    });

    // Auto increment lap and reset current count
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _lap = currentLap + 1;
          _count = 0;
        });
        _saveState();
      }
    });

    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() => _showCelebrationToast = false);
      }
    });
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    setState(() => _showCelebrationToast = false);
  }

  void _selectPreset(int idx) {
    if (idx < 0 || idx >= _presets.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetIdx = idx;
      _target = _presets[idx].defaultTarget;
      _count = 0;
      _lap = 1;
    });
    _saveState();
  }

  void _setTarget(int newTarget) {
    if (newTarget <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _target = newTarget;
    });
    _saveState();
  }

  void _confirmReset() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFECE4D8)),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECE4D8)),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFFC5A059), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Counter?',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF354033),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset the current session count to 0? Your lifetime total will not be affected.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF59634A),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF59634A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _count = 0);
              _saveState();
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354033),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _saveLap() {
    if (_count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Count is at 0. Tap dial to count dhikr before saving lap.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF354033),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final currentPreset = _presets[_selectedPresetIdx];
    final savedLapNum = _lap;
    final savedCount = _count;

    _savedLaps.insert(
      0,
      TasbeehSavedLap(
        presetName: currentPreset.transliteration,
        arabic: currentPreset.arabic,
        count: savedCount,
        lap: savedLapNum,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _lap = savedLapNum + 1;
      _count = 0;
    });
    _saveState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFC5A059), size: 18),
            const SizedBox(width: 8),
            Text(
              'Lap $savedLapNum saved ($savedCount reps)! Starting Lap $_lap.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF354033),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTargetPickerSheet() {
    HapticFeedback.selectionClick();
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Color(0xFFC5A059), width: 1.5)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Recitation Target',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354033),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose milestone for count cycle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF59634A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F4EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF59634A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Targets Grid (33x, 34x, 99x, 100x)
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [33, 34, 99, 100].map((t) {
                  final isSelected = _target == t;
                  return InkWell(
                    onTap: () {
                      _setTarget(t);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFAF5E8) : const Color(0xFFF8F4EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFC5A059) : const Color(0xFFECE4D8),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Text(
                        '${t}x',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF8C6D34) : const Color(0xFF354033),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFECE4D8), height: 1),
              const SizedBox(height: 16),

              // Custom Target Input Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFECE4D8)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: customCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF354033)),
                        decoration: InputDecoration(
                          hintText: 'Enter custom target (e.g. 500)',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF7A8075)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(customCtrl.text.trim());
                        if (val != null && val > 0) {
                          _setTarget(val);
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A059),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(
                        'Set',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistorySheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.88,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Color(0xFFC5A059), width: 1.5)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5E8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD4AF37)),
                        ),
                        child: const Icon(Icons.history_rounded, color: Color(0xFF8C6D34), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Lifetime Dhikr History',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354033),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F4EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF59634A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Top 3 Stat summary boxes
              Row(
                children: [
                  Expanded(
                    child: _statPill(
                      label: 'TOTAL DHIKR',
                      value: NumberFormat('#,###').format(_lifetimeCount),
                      color: const Color(0xFFC5A059),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill(
                      label: "TODAY'S REPS",
                      value: '+$_todayCount',
                      color: const Color(0xFF354033),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill(
                      label: 'TOTAL LAPS',
                      value: '${_savedLaps.length}',
                      color: const Color(0xFF8C6D34),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Saved Laps List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT SESSIONS & LAPS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: const Color(0xFF59634A),
                    ),
                  ),
                  if (_savedLaps.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() => _savedLaps.clear());
                        _saveState();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Clear Log',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Laps list
              Expanded(
                child: _savedLaps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'No saved laps yet',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF59634A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Complete targets or tap "Save Lap" to record sessions.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF7A8075),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _savedLaps.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final lap = _savedLaps[i];
                          final formattedTime = DateFormat('MMM d, h:mm a').format(lap.timestamp);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFECE4D8)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F4EC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE8DFD0)),
                                  ),
                                  child: Text(
                                    'Lap ${lap.lap}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7C633E),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lap.presetName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF354033),
                                        ),
                                      ),
                                      Text(
                                        formattedTime,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: const Color(0xFF7A8075),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${lap.count} reps',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFC5A059),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE4D8)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: const Color(0xFF59634A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build Method ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activePreset = _presets[_selectedPresetIdx];
    final progress = _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;
    final progressPercent = (progress * 100).round();
    final remaining = math.max(0, _target - _count);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        children: [
          // ── Ambient Background Pattern & Gold Glow Spots ──
          Positioned.fill(
            child: CustomPaint(
              painter: _SubtleBackgroundDotsPainter(),
            ),
          ),
          // Top warm ambient glow spot
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC5A059).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Center pulsating aura
          Positioned(
            top: 260,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (ctx, child) => Center(
                child: Container(
                  width: 290 * _pulseAnimation.value,
                  height: 290 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC5A059).withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main Content View ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Top Header Bar
                _buildHeader(context),

                // Scrollable Central Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),

                        // 2. Dual Lifetime Stats & Target Cards
                        _buildTopStatsCards(),
                        const SizedBox(height: 12),

                        // 3. Preset Dhikr Carousel Header & Cards
                        _buildPresetSelector(),
                        const SizedBox(height: 16),

                        // 4. Central Hero Dial Counter (Jewel Bezel + 33 Beads)
                        _buildHeroDialCounter(activePreset, progress),
                        const SizedBox(height: 12),

                        // 5. Completion Percentage Banner
                        _buildCompletionIndicator(progressPercent, remaining),
                        const SizedBox(height: 16),

                        // 6. Bottom 3 Utility Buttons (Reset, Set Target, Save Lap)
                        _buildBottomActionButtons(),
                        SizedBox(height: 18 + MediaQuery.paddingOf(context).bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Milestone Celebration Toast Overlay ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            bottom: _showCelebrationToast ? 80 : -120,
            left: 16,
            right: 16,
            child: _buildCelebrationToast(),
          ),
        ],
      ),
    );
  }

  // ── Header Widget ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Navigation Button
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECE4D8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D1B1C1E),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: Color(0xFF354033),
              ),
            ),
          ),

          // Centered Title & Arabic Calligraphy Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Digital Tasbeeh',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF354033),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC5A059),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              const Text(
                'المسبحة الذكية',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA68238),
                  height: 1.1,
                ),
              ),
            ],
          ),

          // Right Controls: Haptic, Sound, Lifetime Log
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Haptic Vibrate Toggle
              InkWell(
                onTap: () {
                  setState(() => _hapticEnabled = !_hapticEnabled);
                  _saveState();
                  if (_hapticEnabled) HapticFeedback.mediumImpact();
                },
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hapticEnabled ? const Color(0xFFC5A059) : const Color(0xFFECE4D8),
                          width: _hapticEnabled ? 1.5 : 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D1B1C1E),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.vibration_rounded,
                        size: 18,
                        color: _hapticEnabled ? const Color(0xFFA68238) : const Color(0xFF59634A),
                      ),
                    ),
                    if (_hapticEnabled)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5A059),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFAF7F2), width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // 2. Sound Toggle Button
              InkWell(
                onTap: () {
                  setState(() => _soundEnabled = !_soundEnabled);
                  _saveState();
                  if (_soundEnabled) SystemSound.play(SystemSoundType.click);
                },
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _soundEnabled ? const Color(0xFFC5A059) : const Color(0xFFECE4D8),
                      width: _soundEnabled ? 1.5 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D1B1C1E),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 18,
                    color: _soundEnabled ? const Color(0xFFA68238) : const Color(0xFF59634A),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 3. History / Lifetime Log Button
              InkWell(
                onTap: _showHistorySheet,
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFECE4D8)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D1B1C1E),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Color(0xFF59634A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Top Stats Cards (Lifetime Dhikr & Current Target) ─────────────────────

  Widget _buildTopStatsCards() {
    return Row(
      children: [
        // Left: Total Lifetime Dhikr
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFECE4D8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1B1C1E),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFFC5A059)),
                    const SizedBox(width: 4),
                    Text(
                      'LIFETIME DHIKR',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: const Color(0xFF59634A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  NumberFormat('#,###').format(_lifetimeCount),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF354033),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE8DFD0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC5A059),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$_todayCount today',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C633E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Current Target Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFECE4D8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1B1C1E),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.track_changes_rounded, size: 14, color: Color(0xFFC5A059)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'TARGET',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: const Color(0xFF59634A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8DFD0)),
                      ),
                      child: Text(
                        'Lap $_lap',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C633E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_target',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF354033),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'reps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF59634A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showTargetPickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE8DFD0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Change',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C633E),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFFC5A059)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Preset Dhikr Carousel ─────────────────────────────────────────────────

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT DHIKR & SUPPLICATION',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: const Color(0xFF59634A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8DFD0)),
              ),
              child: Text(
                '7 Authentic Presets',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C633E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final preset = _presets[i];
              final isSelected = (i == _selectedPresetIdx);

              return GestureDetector(
                onTap: () => _selectPreset(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFAF5E8) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFECE4D8),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        const BoxShadow(
                          color: Color(0x2EB8860B),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        )
                      else
                        const BoxShadow(
                          color: Color(0x081B1C1E),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Target pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F4EC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE8DFD0)),
                            ),
                            child: Text(
                              '${preset.defaultTarget}x',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C633E),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Arabic Calligraphy
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          preset.arabic,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF354033),
                            height: 1.2,
                          ),
                        ),
                      ),

                      // Transliteration & Translation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.transliteration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF7C633E) : const Color(0xFF354033),
                            ),
                          ),
                          Text(
                            preset.translation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: const Color(0xFF59634A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Central Hero Counter Dial ─────────────────────────────────────────────

  Widget _buildHeroDialCounter(TasbeehPreset activePreset, double progress) {
    return Center(
      child: GestureDetector(
        onTap: _incrementCount,
        child: AnimatedScale(
          scale: _buttonScale,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: 275,
            height: 275,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Custom Progress Track & 33 Bead Ring Painter
                CustomPaint(
                  size: const Size(275, 275),
                  painter: _TasbeehDialProgressPainter(
                    progress: progress,
                    currentCount: _count,
                    target: _target,
                  ),
                ),

                // 2. Horological Conic Gold Bezel Ring
                Container(
                  width: 228,
                  height: 228,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      transform: GradientRotation(215 * math.pi / 180),
                      colors: [
                        Color(0xFFD2AA39),
                        Color(0xFFFDE7A0),
                        Color(0xFFAA7D1A),
                        Color(0xFFECD181),
                        Color(0xFF8E6510),
                        Color(0xFFFFE8A8),
                        Color(0xFFB68A20),
                        Color(0xFFF8DE8D),
                        Color(0xFFD2AA39),
                      ],
                      stops: [
                        0.0,
                        35 / 360,
                        85 / 360,
                        135 / 360,
                        180 / 360,
                        225 / 360,
                        270 / 360,
                        315 / 360,
                        1.0,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x38B8860B),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x100F172A),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),

                  // 3. Inner Tactile Alabaster Porcelain Medallion
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFAF8F3),
                          Color(0xFFF5EFE6),
                        ],
                      ),
                      border: Border.all(color: const Color(0xFFECE4D8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14B8860B),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Delicate Islamic 8-Point Rosette Star Watermark
                        CustomPaint(
                          size: const Size(180, 180),
                          painter: _IslamicStarRosettePainter(),
                        ),

                        // Animated Ripple Ring Layer on Tap
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            if (_rippleController.value == 0 || _rippleController.value == 1) {
                              return const SizedBox.shrink();
                            }
                            return Transform.scale(
                              scale: _rippleAnimation.value,
                              child: Opacity(
                                opacity: _rippleOpacityAnimation.value,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37),
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Medallion Foreground Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Arabic Supplication Text
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                activePreset.arabic,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF354033),
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Oversized Digital Counter Value
                            Text(
                              '$_count',
                              style: GoogleFonts.outfit(
                                fontSize: 66,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF354033),
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // TAP ANYWHERE TO COUNT Subtitle
                            Text(
                              'TAP ANYWHERE TO COUNT',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8C6D34),
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Target & Lap Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4EC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE8DFD0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) => Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFC5A059),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Target: $_target • Lap $_lap',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7C633E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // ── Completion Percentage Indicator ───────────────────────────────────────

  Widget _buildCompletionIndicator(int progressPercent, int remaining) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$progressPercent% Completed',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8C6D34),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$remaining remaining for current lap',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF59634A),
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Utility Buttons ─────────────────────────────────────────

  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        // 1. Reset Button
        Expanded(
          child: InkWell(
            onTap: _confirmReset,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECE4D8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1B1C1E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFECE4D8)),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 19, color: Color(0xFF59634A)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Reset',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF59634A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Set Target Button (Highlighted with Gold border & badge)
        Expanded(
          child: InkWell(
            onTap: _showTargetPickerSheet,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18B8860B),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.flag_rounded, size: 19, color: Color(0xFF8C6D34)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Set Target',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8C6D34),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Save Lap Button
        Expanded(
          child: InkWell(
            onTap: _saveLap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECE4D8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1B1C1E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFECE4D8)),
                    ),
                    child: const Icon(Icons.bookmark_outline_rounded, size: 19, color: Color(0xFF59634A)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Save Lap',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF59634A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Milestone Celebration Toast ───────────────────────────────────────────

  Widget _buildCelebrationToast() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF8F4EC),
            Colors.white,
            Color(0xFFF8F4EC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5A059), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2EB8860B),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFC5A059),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _toastTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF354033),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE8DFD0)),
                      ),
                      child: Text(
                        'Alhamdulillah',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C633E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'May Allah accept your Dhikr & reward you.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF59634A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _dismissToast,
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF7A8075)),
          ),
        ],
      ),
    );
  }

}

// ── Custom Dial Painter (33 Beads & Smooth Metallic Progress Arc) ────────────

class _TasbeehDialProgressPainter extends CustomPainter {
  final double progress;
  final int currentCount;
  final int target;

  _TasbeehDialProgressPainter({
    required this.progress,
    required this.currentCount,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final trackRadius = size.width / 2 - 6;
    final beadRadius = size.width / 2 - 16;
    const totalBeads = 33;

    // 1. Background Inactive Track
    final backgroundTrackPaint = Paint()
      ..color = const Color(0xFFEBE3D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, trackRadius, backgroundTrackPaint);

    // 2. Active Smooth Metallic Gold Progress Arc
    if (progress > 0) {
      final activeArcPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(-math.pi / 2),
          colors: [
            Color(0xFFE8D4A8),
            Color(0xFFC5A059),
            Color(0xFFB8934A),
            Color(0xFF8C6D34),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: trackRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        activeArcPaint,
      );
    }

    // 3. 33 Beads Distributed Around Perimeter
    final progressBeadIndex = target > 0 ? ((currentCount / target) * totalBeads).floor() : 0;

    for (int i = 0; i < totalBeads; i++) {
      // Rotate 33 beads evenly starting from top (-pi / 2)
      final angle = -math.pi / 2 + (i / totalBeads) * 2 * math.pi;
      final bx = center.dx + beadRadius * math.cos(angle);
      final by = center.dy + beadRadius * math.sin(angle);
      final beadCenter = Offset(bx, by);

      final bool isBeadActive = i < progressBeadIndex;

      if (isBeadActive) {
        // Glowing active bead in rich gold
        final glowPaint = Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(beadCenter, 4.5, glowPaint);

        final activePaint = Paint()..color = const Color(0xFFB8860B);
        canvas.drawCircle(beadCenter, 3.2, activePaint);
      } else {
        // Warm parchment inactive bead
        final inactivePaint = Paint()..color = const Color(0xFFEADBCA).withValues(alpha: 0.85);
        canvas.drawCircle(beadCenter, 2.8, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TasbeehDialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentCount != currentCount ||
        oldDelegate.target != target;
  }
}

// ── Delicate 8-Point Islamic Star Rosette Watermark Painter ──────────────────

class _IslamicStarRosettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFC5A059).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final double outerR = size.width * 0.44;
    final double innerR = size.width * 0.26;

    // Outer 8-point polygon star 1
    final path1 = Path();
    for (int i = 0; i < 8; i++) {
      final angle1 = (i * 45) * math.pi / 180;
      final angle2 = (i * 45 + 22.5) * math.pi / 180;
      final p1 = Offset(center.dx + outerR * math.cos(angle1), center.dy + outerR * math.sin(angle1));
      final p2 = Offset(center.dx + innerR * math.cos(angle2), center.dy + innerR * math.sin(angle2));
      if (i == 0) {
        path1.moveTo(p1.dx, p1.dy);
      } else {
        path1.lineTo(p1.dx, p1.dy);
      }
      path1.lineTo(p2.dx, p2.dy);
    }
    path1.close();
    canvas.drawPath(path1, paint);

    // Inner concentric ring
    canvas.drawCircle(center, innerR * 0.82, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarRosettePainter oldDelegate) => false;
}

// ── Subtle Background Dots Painter ──────────────────────────────────────────

class _SubtleBackgroundDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB8860B).withValues(alpha: 0.035);
    const step = 20.0;
    for (double x = 8; x < size.width; x += step) {
      for (double y = 8; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleBackgroundDotsPainter oldDelegate) => false;
}
