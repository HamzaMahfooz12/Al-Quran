// lib/features/azkar/screens/azkar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';
import '../data/authentic_azkar.dart';

enum AzkarLanguageFilter {
  all,
  urdu,
  english,
  transliteration,
}

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  int _selectedCategoryIndex = 0;
  AzkarLanguageFilter _langFilter = AzkarLanguageFilter.all;
  final Map<String, int> _counts = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _tapDua(DuaItem item) {
    final cur = _counts[item.id] ?? 0;
    if (cur < item.count) {
      final next = cur + 1;
      setState(() => _counts[item.id] = next);
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
    Vibration.hasVibrator().then((has) {
      if (has == true) Vibration.vibrate(duration: 15);
    });
  }

  void _shareDua(DuaItem item) {
    final text = '🤲 ${item.title}\n\n'
        '${item.arabic}\n\n'
        '${item.transliteration}\n\n'
        'Urdu: ${item.urduTranslation}\n\n'
        'English: ${item.englishTranslation}\n\n'
        'Reference: ${item.reference}\n\n'
        '— Shared via Al Quran App';
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
        content: Text('Dua copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
    final categories = AuthenticAzkar.categories;
    final currentCat = categories[_selectedCategoryIndex];
    final activeItems = _searchQuery.isEmpty
        ? currentCat.items
        : categories.expand((c) => c.items).toList();
    final filteredItems = _getFilteredItems(activeItems);

    // Calculate progress for current category
    int completedCount = 0;
    for (final it in currentCat.items) {
      if ((_counts[it.id] ?? 0) >= it.count) {
        completedCount++;
      }
    }
    final progress = currentCat.items.isNotEmpty
        ? completedCount / currentCat.items.length
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Daily Duas & Azkar',
              style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const Text(
              'الأذكار',
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 18,
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search & Filter Controls ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 10),
                  _buildLanguageSelector(),
                  const SizedBox(height: 12),
                  if (_searchQuery.isEmpty) ...[
                    _buildCategoryChips(categories),
                    const SizedBox(height: 12),
                    _buildProgressBanner(currentCat, completedCount, progress),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // ── Duas List ───────────────────────────────────────────────────
          filteredItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No supplications found for "$_searchQuery"',
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final item = filteredItems[idx];
                        return _buildDuaCard(item);
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
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search supplications (e.g. morning, sleep, forgiveness)...',
          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Language: ',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          _langChip('All (سب)', AzkarLanguageFilter.all),
          const SizedBox(width: 6),
          _langChip('اردو (Urdu)', AzkarLanguageFilter.urdu),
          const SizedBox(width: 6),
          _langChip('English', AzkarLanguageFilter.english),
          const SizedBox(width: 6),
          _langChip('Transliteration', AzkarLanguageFilter.transliteration),
        ],
      ),
    );
  }

  Widget _langChip(String label, AzkarLanguageFilter filter) {
    final isSelected = _langFilter == filter;
    return InkWell(
      onTap: () => setState(() => _langFilter = filter),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8E4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<AzkarCategory> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (idx) {
          final cat = categories[idx];
          final isSelected = idx == _selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryIndex = idx),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : const Color(0xFFE2E8E4),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cat.items.length}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressBanner(AzkarCategory cat, int completed, double progress) {
    final isAllDone = completed == cat.items.length && cat.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAllDone ? const Color(0xFFE8F5E9) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAllDone ? const Color(0xFF81C784) : const Color(0xFFE8ECE9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllDone ? Icons.check_circle_rounded : Icons.pie_chart_outline_rounded,
            color: isAllDone ? const Color(0xFF2E7D32) : AppTheme.primary,
            size: 20,
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
                      isAllDone ? 'All Recitations Completed! 🎉' : '${cat.title} Progress',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isAllDone ? const Color(0xFF1B4332) : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$completed / ${cat.items.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8E4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? const Color(0xFF2E7D32) : AppTheme.primary,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(DuaItem item) {
    final currentCount = _counts[item.id] ?? 0;
    final isDone = currentCount >= item.count;

    final showTranslit = _langFilter == AzkarLanguageFilter.all ||
        _langFilter == AzkarLanguageFilter.transliteration;
    final showUrdu = _langFilter == AzkarLanguageFilter.all ||
        _langFilter == AzkarLanguageFilter.urdu;
    final showEnglish = _langFilter == AzkarLanguageFilter.all ||
        _langFilter == AzkarLanguageFilter.english;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF2F9F4) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? const Color(0xFF81C784) : const Color(0xFFE8ECE9),
          width: isDone ? 1.5 : 1.0,
        ),
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
          // ── Card Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${item.count}x recitation',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Action icons: Copy & Share
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textMuted),
                  tooltip: 'Copy',
                  onPressed: () => _copyDua(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 18, color: AppTheme.textMuted),
                  tooltip: 'Share',
                  onPressed: () => _shareDua(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEF2EF)),

          // ── Arabic Text ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              item.arabic,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                height: 1.85,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),

          // ── Transliteration ─────────────────────────────────────────────
          if (showTranslit && item.transliteration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5EBE6)),
                ),
                child: Text(
                  item.transliteration,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF37474F),
                    height: 1.45,
                  ),
                ),
              ),
            ),

          // ── Urdu Translation ────────────────────────────────────────────
          if (showUrdu && item.urduTranslation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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

          // ── English Translation ─────────────────────────────────────────
          if (showEnglish && item.englishTranslation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                item.englishTranslation,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
            ),

          // ── Benefit / Virtues Banner ────────────────────────────────────
          if (item.benefit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFECB3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFF57F17), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.benefit,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE65100), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Reference Tag ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '📖 ${item.reference}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom Interactive Counter Row ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBF9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: Color(0xFFEEF2EF))),
            ),
            child: Row(
              children: [
                // Reset Button
                if (currentCount > 0) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textMuted),
                    tooltip: 'Reset counter',
                    onPressed: () => _resetDua(item),
                  ),
                  const SizedBox(width: 4),
                ],

                // Big Tap Counter Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isDone ? null : () => _tapDua(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone ? const Color(0xFF2E7D32) : AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF2E7D32),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isDone ? 0 : 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone ? Icons.check_circle : Icons.touch_app_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? 'Completed ($currentCount/${item.count})' : 'Tap to Recite ($currentCount / ${item.count})',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
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