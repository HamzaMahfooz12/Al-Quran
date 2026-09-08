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
  int _selectedCategoryIndex = 0;
  String _displayLanguage = 'ur'; // Default to Urdu
  final Map<String, int> _counts = {};
  final Set<String> _bookmarkedIds = {};
  final Set<String> _expandedIds = {};
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

    // ── Daily Count Persistence & Next Day 12:00 AM Auto-Reset ─────────
    final today = _todayDateStr();
    final savedDate = prefs.getString('azkar_counts_date');
    final Map<String, int> loadedCounts = {};

    if (savedDate == today) {
      // Same day: restore progress
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
      // Next day (12:00 AM midnight has passed): reset all counts to 0
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
    final today = _todayDateStr();
    await prefs.setString('azkar_counts_date', today);
    await prefs.setString('azkar_daily_counts', jsonEncode(_counts));
  }

  Future<void> _toggleBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
    await prefs.setStringList('azkar_bookmarked_ids', _bookmarkedIds.toList());
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _tapDua(DuaItem item) {
    final cur = _counts[item.id] ?? 0;
    if (cur < item.count) {
      final next = cur + 1;
      setState(() => _counts[item.id] = next);
      _saveCounts();
      Vibration.hasVibrator().then((has) {
        if (has == true) {
          if (next == item.count) {
            Vibration.vibrate(pattern: [0, 80, 50, 150]);
          } else {
            Vibration.vibrate(duration: 25);
          }
        }
      });
    }
  }

  void _resetDua(DuaItem item) {
    setState(() => _counts[item.id] = 0);
    _saveCounts();
    Vibration.hasVibrator().then((has) {
      if (has == true) Vibration.vibrate(duration: 15);
    });
  }

  void _resetCategory(List<DuaItem> items) {
    setState(() {
      for (final it in items) {
        _counts[it.id] = 0;
      }
    });
    _saveCounts();
    Vibration.hasVibrator().then((has) {
      if (has == true) Vibration.vibrate(duration: 30);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Category progress reset for today'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareDua(DuaItem item) {
    final text = '🤲 ${item.title}\n\n'
        '${item.arabic}\n\n'
        '${item.transliteration}\n\n'
        'Urdu: ${item.urduTranslation}\n\n'
        'English: ${item.englishTranslation}\n\n'
        'Reference: ${item.reference}\n\n'
        '— Shared via Hifz ul Quran App';
    Share.share(text);
  }

  void _copyDua(DuaItem item) {
    final text = '${item.title}\n\n'
        '${item.arabic}\n\n'
        '${item.urduTranslation}\n\n'
        '${item.englishTranslation}\n\n'
        '${item.reference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Supplication copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<DuaItem> _getAllItemsForCategory(AzkarCategory cat) {
    final items = List<DuaItem>.from(cat.items);
    for (final cd in _customDuas) {
      final categoryName = cd['category'] as String? ?? '';
      if (categoryName.contains(cat.title) || cat.title.contains(categoryName.split(' ').first)) {
        items.add(
          DuaItem(
            id: cd['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
            title: cd['title'] as String? ?? 'Custom Supplication',
            arabic: cd['arabic'] as String? ?? '',
            urduTranslation: cd['urduTranslation'] as String? ?? '',
            englishTranslation: cd['englishTranslation'] as String? ?? '',
            transliteration: cd['transliteration'] as String? ?? '',
            reference: cd['reference'] as String? ?? 'Personal Collection',
            count: cd['count'] as int? ?? 1,
            benefit: '',
          ),
        );
      }
    }
    return items;
  }

  List<DuaItem> _getFilteredItems(List<DuaItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((item) {
      return item.title.toLowerCase().contains(_searchQuery) ||
          item.arabic.contains(_searchQuery) ||
          item.transliteration.toLowerCase().contains(_searchQuery) ||
          item.englishTranslation.toLowerCase().contains(_searchQuery) ||
          item.urduTranslation.contains(_searchQuery) ||
          item.reference.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2C7A39))),
      );
    }

    final categories = AuthenticAzkar.categories;
    final currentCat = categories[_selectedCategoryIndex];
    final activeItems = _searchQuery.isEmpty
        ? _getAllItemsForCategory(currentCat)
        : categories.expand((c) => _getAllItemsForCategory(c)).toList();
    final filteredItems = _getFilteredItems(activeItems);

    // Calculate progress for current category
    int completedCount = 0;
    for (final it in activeItems) {
      if ((_counts[it.id] ?? 0) >= it.count) {
        completedCount++;
      }
    }
    final progress = activeItems.isNotEmpty ? completedCount / activeItems.length : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'Daily Duas',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2A1E),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7E6CE)),
              ),
              child: const Text(
                'الأذكار',
                style: TextStyle(
                  fontFamily: 'Scheherazade New',
                  fontSize: 14,
                  color: Color(0xFF2C7A39),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC7E6CE)),
              ),
              child: const Icon(Icons.settings_outlined, color: Color(0xFF2C7A39), size: 20),
            ),
            tooltip: 'Duas Settings',
            onPressed: () async {
              await context.pushNamed('duas-settings');
              _loadPreferences();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search & Filter Controls ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  if (_searchQuery.isEmpty) ...[
                    _buildCategoryCards(categories),
                    const SizedBox(height: 12),
                    _buildProgressBanner(currentCat, completedCount, activeItems.length, progress, activeItems),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // ── Duas List with Smooth Animations ─────────────────────────────
          filteredItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(
                          'No supplications found for "$_searchQuery"',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 110 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final item = filteredItems[idx];
                        return _buildDuaCard(item, idx);
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search supplications (e.g. morning, sleep, travel)...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2C7A39), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryCards(List<AzkarCategory> categories) {
    final categoryStyles = [
      {'color': const Color(0xFF2C7A39), 'icon': Icons.wb_sunny_rounded, 'sub': 'صبح و شام'},
      {'color': const Color(0xFF1E3A8A), 'icon': Icons.mosque_rounded, 'sub': 'نماز کے بعد'},
      {'color': const Color(0xFF581C87), 'icon': Icons.bedtime_rounded, 'sub': 'سوتے وقت'},
      {'color': const Color(0xFFBE185D), 'icon': Icons.flight_takeoff_rounded, 'sub': 'سفر'},
      {'color': const Color(0xFF047857), 'icon': Icons.restaurant_rounded, 'sub': 'طعام و شراب'},
      {'color': const Color(0xFFB45309), 'icon': Icons.shield_rounded, 'sub': 'حفاظت'},
      {'color': const Color(0xFF0284C7), 'icon': Icons.favorite_rounded, 'sub': 'استغفار'},
      {'color': const Color(0xFFD97706), 'icon': Icons.menu_book_rounded, 'sub': 'قرآنی دعائیں'},
      {'color': const Color(0xFF4B5563), 'icon': Icons.spa_rounded, 'sub': 'روزمرہ'},
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, idx) {
          final cat = categories[idx];
          final isSelected = _selectedCategoryIndex == idx;
          final styleInfo = categoryStyles[idx % categoryStyles.length];
          final Color themeColor = styleInfo['color'] as Color;
          final IconData icon = styleInfo['icon'] as IconData;
          final String subArabic = styleInfo['sub'] as String;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = idx;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 138,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [themeColor, themeColor.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, themeColor.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? themeColor : const Color(0xFFE8E1D2),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.22) : themeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : themeColor,
                          size: 16,
                        ),
                      ),
                      Text(
                        subArabic,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFFFFD54F) : themeColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cat.title.split(' (').first,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1B2A1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBanner(
      AzkarCategory cat, int completed, int total, double progress, List<DuaItem> items) {
    final isAllDone = completed == total && total > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAllDone ? const Color(0xFFEAF6EC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllDone ? const Color(0xFF81C784) : const Color(0xFFE8E1D2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isAllDone ? Icons.check_circle_rounded : Icons.pie_chart_outline_rounded,
            color: const Color(0xFF2C7A39),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAllDone
                          ? 'Category Completed! 🎉'
                          : '${cat.title.split(' (').first} Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAllDone ? const Color(0xFF1B4332) : const Color(0xFF1B2A1E),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completed / $total',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2C7A39),
                          ),
                        ),
                        if (completed > 0) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _resetCategory(items),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Reset',
                                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5EBE6),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2C7A39)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 10.5, color: Color(0xFF6B7280)),
                    const SizedBox(width: 3),
                    Text(
                      'Saved for today • Auto-resets daily at 12:00 AM',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(DuaItem item, int index) {
    final currentCount = _counts[item.id] ?? 0;
    final isDone = currentCount >= item.count;
    final isBookmarked = _bookmarkedIds.contains(item.id);
    final isExpanded = _expandedIds.contains(item.id) || _searchQuery.isNotEmpty;

    final showUrdu = _displayLanguage == 'ur' || _displayLanguage == 'all';
    final showEnglish = _displayLanguage == 'en' || _displayLanguage == 'all';
    final showTranslit = _displayLanguage == 'transliteration' || _displayLanguage == 'all';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF2F8F4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? const Color(0xFF81C784) : const Color(0xFFE8E1D2),
          width: isDone ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header (Tap to Expand/Collapse) ──
          InkWell(
            onTap: () => _toggleExpanded(item.id),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EC),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C7A39),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B2A1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Repeat: ${item.count}x',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bookmark Button with Bounce Micro-Animation
                  TweenAnimationBuilder<double>(
                    key: ValueKey(isBookmarked),
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    builder: (ctx, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          tooltip: isBookmarked ? 'Bookmarked' : 'Bookmark',
                          onPressed: () => _toggleBookmark(item.id),
                        ),
                      );
                    },
                  ),

                  // Copy & Share
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    tooltip: 'Copy',
                    onPressed: () => _copyDua(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    tooltip: 'Share',
                    onPressed: () => _shareDua(item),
                  ),

                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // ── Arabic Text ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              item.arabic,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                height: 1.85,
                color: Color(0xFF1B2A1E),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),

          // ── Expandable Section (Translations & Transliterations) ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transliteration
                if (showTranslit && item.transliteration.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Text(
                        item.transliteration,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF4B5563),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),

                // Urdu Translation
                if (showUrdu && item.urduTranslation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAF8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8EDE9)),
                      ),
                      child: Text(
                        item.urduTranslation,
                        style: const TextStyle(
                          fontFamily: 'Noto Nastaliq Urdu',
                          fontSize: 13.5,
                          height: 1.85,
                          color: Color(0xFF2C3E50),
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),

                // English Translation
                if (showEnglish && item.englishTranslation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      item.englishTranslation,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                  ),

                // Benefit / Virtues Note
                if (item.benefit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.benefit,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Reference Tag
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '📖 ${item.reference}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          const SizedBox(height: 10),

          // ── Bottom Interactive Counter Button ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBF9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                if (currentCount > 0) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF6B7280)),
                    tooltip: 'Reset counter',
                    onPressed: () => _resetDua(item),
                  ),
                  const SizedBox(width: 4),
                ],

                Expanded(
                  child: ElevatedButton(
                    onPressed: isDone ? null : () => _tapDua(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone ? const Color(0xFF2C7A39) : const Color(0xFF2C7A39),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF2C7A39),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isDone ? 0 : 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone
                              ? 'Completed ($currentCount / ${item.count})'
                              : 'Tap to Recite ($currentCount / ${item.count})',
                          style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}