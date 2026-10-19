// lib/features/azkar/screens/azkar_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../data/authentic_azkar.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  int _selectedCategoryIndex = 0; // 0 = All Duas, 1..N = categories, N+1 = Custom
  String _displayLanguage = 'ur'; // 'ur', 'en', 'both'
  final Map<String, int> _counts = {};
  final Set<String> _bookmarkedIds = {};
  final Set<String> _expandedVirtues = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _customDuas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _loadPreferences();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('azkar_display_language') ?? 'ur';
    final bookmarksList = prefs.getStringList('azkar_bookmarked_ids') ?? [];
    final customRaw = prefs.getString('azkar_custom_duas_list');
    List<Map<String, dynamic>> customList = [];
    if (customRaw != null) {
      try {
        final decoded = jsonDecode(customRaw) as List;
        customList = decoded.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    // Daily Count Persistence & Next Day Auto-Reset
    final today = _todayDateStr();
    final savedDate = prefs.getString('azkar_counts_date');
    final Map<String, int> loadedCounts = {};

    if (savedDate == today) {
      final countsRaw = prefs.getString('azkar_daily_counts');
      if (countsRaw != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(countsRaw);
          for (final entry in decoded.entries) {
            if (entry.value is int) {
              loadedCounts[entry.key] = entry.value as int;
            }
          }
        } catch (_) {}
      }
    } else {
      await prefs.setString('azkar_counts_date', today);
      await prefs.remove('azkar_daily_counts');
    }

    if (mounted) {
      setState(() {
        _displayLanguage = lang;
        _bookmarkedIds.addAll(bookmarksList);
        _customDuas = customList;
        _counts.clear();
        _counts.addAll(loadedCounts);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_counts_date', _todayDateStr());
    await prefs.setString('azkar_daily_counts', jsonEncode(_counts));
  }

  Future<void> _toggleBookmark(String id) async {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('azkar_bookmarked_ids', _bookmarkedIds.toList());
  }

  Future<void> _incrementDua(String id, int target) async {
    final current = _counts[id] ?? 0;
    final next = (current >= target) ? 0 : current + 1;

    setState(() {
      _counts[id] = next;
    });
    await _saveCounts();

    if (next == target) {
      HapticFeedback.heavyImpact();
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(pattern: [0, 80, 50, 160]);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Completed! May Allah accept your recitation.',
                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 25);
      });
    }
  }

  Future<void> _resetCategoryCounts(List<DuaItem> list) async {
    setState(() {
      for (final d in list) {
        _counts.remove(d.id);
      }
    });
    await _saveCounts();
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category progress reset for today', style: GoogleFonts.outfit(fontSize: 12.5)),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  List<DuaItem> _getAllItems() {
    final List<DuaItem> all = [];
    for (final cat in AuthenticAzkar.categories) {
      all.addAll(cat.items);
    }
    for (int i = 0; i < _customDuas.length; i++) {
      final cd = _customDuas[i];
      all.add(
        DuaItem(
          id: 'custom_$i',
          title: cd['title'] ?? 'Custom Supplication',
          arabic: cd['arabic'] ?? '',
          transliteration: '',
          englishTranslation: cd['translation'] ?? '',
          urduTranslation: cd['translation'] ?? '',
          reference: cd['reference'] ?? 'Personal Supplication',
          count: cd['targetCount'] ?? 1,
          benefit: cd['notes'] ?? '',
        ),
      );
    }
    return all;
  }

  List<DuaItem> _getActiveCategoryItems() {
    if (_selectedCategoryIndex == 0) {
      return _getAllItems();
    }
    final int catIdx = _selectedCategoryIndex - 1;
    if (catIdx < AuthenticAzkar.categories.length) {
      return AuthenticAzkar.categories[catIdx].items;
    }
    // Custom Duas category
    final List<DuaItem> customItems = [];
    for (int i = 0; i < _customDuas.length; i++) {
      final cd = _customDuas[i];
      customItems.add(
        DuaItem(
          id: 'custom_$i',
          title: cd['title'] ?? 'Custom Supplication',
          arabic: cd['arabic'] ?? '',
          transliteration: '',
          englishTranslation: cd['translation'] ?? '',
          urduTranslation: cd['translation'] ?? '',
          reference: cd['reference'] ?? 'Personal Supplication',
          count: cd['targetCount'] ?? 1,
          benefit: cd['notes'] ?? '',
        ),
      );
    }
    return customItems;
  }

  List<DuaItem> _getFilteredItems() {
    final list = _getActiveCategoryItems();
    if (_searchQuery.isEmpty) return list;
    return list.where((d) {
      return d.title.toLowerCase().contains(_searchQuery) ||
          d.arabic.toLowerCase().contains(_searchQuery) ||
          d.urduTranslation.toLowerCase().contains(_searchQuery) ||
          d.englishTranslation.toLowerCase().contains(_searchQuery) ||
          d.transliteration.toLowerCase().contains(_searchQuery) ||
          d.reference.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openAddCustomDuaModal() {
    final titleCtrl = TextEditingController();
    final arabicCtrl = TextEditingController();
    final transCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    int target = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomPad = MediaQuery.paddingOf(ctx).bottom;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECDDC5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Custom Supplication',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title / Occasion',
                        hintText: 'e.g., Dua for Exams, Health, Rizq',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: arabicCtrl,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(fontSize: 18, height: 1.8),
                      decoration: InputDecoration(
                        labelText: 'Arabic Text',
                        hintText: 'أدخل النص القرآني أو النبوي',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transCtrl,
                      decoration: InputDecoration(
                        labelText: 'Urdu or English Translation',
                        hintText: 'Meaning of this supplication',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: 'Reference or Source (Optional)',
                        hintText: 'e.g. Quran 2:201 / Bukhari',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFECDDC5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Repetitions:', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                        Row(
                          children: [1, 3, 7, 33, 100].map((n) {
                            final sel = target == n;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: InkWell(
                                onTap: () => setModalState(() => target = n),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFFB8860B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: sel ? const Color(0xFFB8860B) : const Color(0xFFECDDC5)),
                                  ),
                                  child: Text('$num', style: TextStyle(color: sel ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty && arabicCtrl.text.trim().isEmpty) return;
                        final newDua = {
                          'title': titleCtrl.text.trim().isEmpty ? 'Personal Supplication' : titleCtrl.text.trim(),
                          'arabic': arabicCtrl.text.trim(),
                          'translation': transCtrl.text.trim(),
                          'reference': refCtrl.text.trim().isEmpty ? 'Personal' : refCtrl.text.trim(),
                          'targetCount': target,
                        };
                        setState(() {
                          _customDuas.add(newDua);
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('azkar_custom_duas_list', jsonEncode(_customDuas));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8860B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save Supplication', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB8860B))),
      );
    }

    final activeItems = _getActiveCategoryItems();
    final filteredItems = _getFilteredItems();

    // Calculate completed count for active category
    int completedCount = 0;
    for (final d in activeItems) {
      if ((_counts[d.id] ?? 0) >= d.count) {
        completedCount++;
      }
    }
    final int totalCount = activeItems.length;
    final double progressRatio = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final int progressPercent = (progressRatio * 100).toInt();
    final int remainingCount = totalCount - completedCount;

    String categoryTitle = 'All Authentic Duas';
    if (_selectedCategoryIndex == 0) {
      categoryTitle = 'ALL DUAS PROGRESS';
    } else if (_selectedCategoryIndex <= AuthenticAzkar.categories.length) {
      categoryTitle = '${AuthenticAzkar.categories[_selectedCategoryIndex - 1].title.toUpperCase()} PROGRESS';
    } else {
      categoryTitle = 'CUSTOM DUAS PROGRESS';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP APP BAR ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                border: Border(bottom: BorderSide(color: Color(0xFFECDDC5), width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
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
                        border: Border.all(color: const Color(0xFFECDDC5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x081B1C1E),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
                    ),
                  ),

                  // Center Title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daily Azkar & Duas',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'الأذكار اليومية والأدعية المأثورة',
                        style: GoogleFonts.amiri(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB8860B),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),

                  // Settings Action
                  InkWell(
                    onTap: () async {
                      await context.pushNamed('duas-settings');
                      _loadPreferences();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFECDDC5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x081B1C1E),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE BODY ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECDDC5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x061B1C1E),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 19, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Search in Arabic, Urdu, English, or reference...',
                              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchCtrl.clear(),
                            child: const Icon(Icons.close_rounded, size: 17, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Horizontal Quick-Filter Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip(0, 'All Duas', _getAllItems().length),
                        ...AuthenticAzkar.categories.asMap().entries.map((entry) {
                          return _buildCategoryChip(
                            entry.key + 1,
                            entry.value.title,
                            entry.value.items.length,
                          );
                        }),
                        _buildCategoryChip(
                          AuthenticAzkar.categories.length + 1,
                          'Custom Duas (أدعيتي)',
                          _customDuas.length,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Category Progress Hero Card
                  _buildProgressHeroCard(
                    title: categoryTitle,
                    completed: completedCount,
                    total: totalCount,
                    remaining: remainingCount,
                    progressRatio: progressRatio,
                    progressPercent: progressPercent,
                    onReset: () => _resetCategoryCounts(activeItems),
                  ),

                  const SizedBox(height: 16),

                  // 4. Dua Cards List
                  if (filteredItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 8),
                          Text(
                            'No supplications found for "$_searchQuery"',
                            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final dua = entry.value;
                      return _buildDuaCard(dua, idx + 1);
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index, String label, int count) {
    final bool isSelected = _selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFECDDC5),
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x28B8860B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x061B1C1E),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFFAF5E8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFECDDC5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF996515),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeroCard({
    required String title,
    required int completed,
    required int total,
    required int remaining,
    required double progressRatio,
    required int progressPercent,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B1C1E),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Title + Completed badge + Reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2DF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFECD9B8)),
                        ),
                        child: Text(
                          '$completed/$total Completed',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF996515),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFB8860B)),
                      const SizedBox(width: 3),
                      Text(
                        remaining > 0
                            ? 'Complete remaining $remaining to finish daily goal'
                            : 'All done for this category! Alhamdulillah',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Reset Button
              InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFECD9B8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF996515)),
                      const SizedBox(width: 3),
                      Text(
                        'Reset',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF996515),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              color: const Color(0xFFEADBCA),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressRatio,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Percentage & Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8860B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$progressPercent% Completed',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF996515),
                    ),
                  ),
                ],
              ),
              Text(
                'Target: $total Azkar',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEADBCA), height: 1),
          const SizedBox(height: 10),

          // Bottom Bar of Card: Haptic Active & Add Custom Dua
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.vibration_rounded, size: 13, color: Color(0xFFB8860B)),
                  const SizedBox(width: 4),
                  Text(
                    'Haptic tap feedback active',
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              InkWell(
                onTap: _openAddCustomDuaModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF2DF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFECD9B8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Color(0xFF996515)),
                      const SizedBox(width: 3),
                      Text(
                        'Add Custom Dua',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF996515),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(DuaItem dua, int index) {
    final int currentCount = _counts[dua.id] ?? 0;
    final bool isCompleted = currentCount >= dua.count;
    final bool isBookmarked = _bookmarkedIds.contains(dua.id);
    final bool isVirtueExpanded = _expandedVirtues.contains(dua.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECDDC5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B1C1E),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── TOP ROW ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // #01 Number badge
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5E8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFECDDC5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${index.toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF996515),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dua.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF354033),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (dua.transliteration.isNotEmpty)
                              Text(
                                dua.transliteration,
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right action buttons: Completed badge, Copy, Share, Bookmark
                Row(
                  children: [
                    if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5E8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFECDDC5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFFB8860B)),
                            const SizedBox(width: 3),
                            Text(
                              'Completed',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF85581A),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Copy Button
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: 'Copy Dua',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: '${dua.title}\n\n${dua.arabic}\n\n${dua.urduTranslation}\n\n${dua.reference}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dua copied to clipboard', style: GoogleFonts.outfit(fontSize: 12)),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),

                    // Share Button
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF64748B)),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: 'Share Dua',
                      onPressed: () {
                        Share.share(
                          '${dua.title}\n\n${dua.arabic}\n\n${dua.urduTranslation}\n\n${dua.reference}\n\nShared from Al-Quran App',
                        );
                      },
                    ),

                    // Bookmark Button
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 18,
                        color: isBookmarked ? const Color(0xFFB8860B) : const Color(0xFF64748B),
                      ),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: 'Bookmark',
                      onPressed: () => _toggleBookmark(dua.id),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF4EDE0), height: 1),

          // ── ARABIC TEXT SECTION ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Text(
                dua.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B192C),
                  height: 2.2,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // ── URDU & ENGLISH TRANSLATIONS ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_displayLanguage == 'ur' || _displayLanguage == 'both')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      dua.urduTranslation,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.scheherazadeNew(
                        fontSize: 14.5,
                        color: const Color(0xFF1E293B),
                        height: 2.0,
                      ),
                    ),
                  ),
                if (_displayLanguage == 'en' || _displayLanguage == 'both')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      dua.englishTranslation,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const Divider(color: Color(0xFFF4EDE0), height: 1),

          // ── RECITATION TARGET & TAP COUNTER ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recitation Target',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      isCompleted
                          ? '${dua.count} of ${dua.count} Recited ✓'
                          : 'Target: ${dua.count} Time${dua.count > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF85581A) : const Color(0xFF354033),
                      ),
                    ),
                  ],
                ),

                // Tap Button
                if (isCompleted)
                  InkWell(
                    onTap: () => _incrementDua(dua.id, dua.count),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFECDDC5)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x061B1C1E),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 14, color: Color(0xFFB8860B)),
                          const SizedBox(width: 4),
                          Text(
                            '${dua.count} / ${dua.count} Done',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF996515),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _incrementDua(dua.id, dua.count),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x28B8860B),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${currentCount + 1}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap Counter ($currentCount / ${dua.count})',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── AUTHENTIC REFERENCE & VIRTUE ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(color: Color(0xFFF4EDE0), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5E8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF3E5C8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFFB8860B)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                dua.reference,
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF996515),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (dua.benefit.isNotEmpty)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_expandedVirtues.contains(dua.id)) {
                              _expandedVirtues.remove(dua.id);
                            } else {
                              _expandedVirtues.add(dua.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isVirtueExpanded ? const Color(0xFFF3E5C8) : const Color(0xFFFAF5E8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFECDDC5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                isVirtueExpanded ? 'Hide Virtue' : 'Virtue & Rewards',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF85581A),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                isVirtueExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 13,
                                color: const Color(0xFF85581A),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (dua.benefit.isNotEmpty && isVirtueExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5E8).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF3E5C8)),
                    ),
                    child: Text(
                      '✨ Virtue: ${dua.benefit}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF85581A),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}