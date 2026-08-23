// lib/features/search/screens/quran_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/settings_service.dart';

class SearchResultItem {
  final Ayah ayah;
  final SurahInfo surahInfo;
  final String translationText;

  const SearchResultItem({
    required this.ayah,
    required this.surahInfo,
    required this.translationText,
  });
}

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<SearchResultItem> _results = [];
  bool _searching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.length < 2) {
      setState(() {
        _results = [];
        _lastQuery = clean;
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _lastQuery = clean;
    });

    final repo = ref.read(quranRepositoryProvider);
    final settings = ref.read(settingsServiceProvider);
    final translationId = settings.selectedTranslationId ?? 2;

    final matchingAyahs = await repo.searchAyahs(clean);
    final surahMap = {for (final s in kSurahList) s.number: s};

    final ayahIds = matchingAyahs.map((a) => a.id).toList();
    final transMap = await repo.getContentBulk(ayahIds, translationId);

    final list = <SearchResultItem>[];
    for (final a in matchingAyahs) {
      final sInfo = surahMap[a.surah];
      if (sInfo != null) {
        list.add(SearchResultItem(
          ayah: a,
          surahInfo: sInfo,
          translationText: transMap[a.id] ?? '',
        ));
      }
    }

    if (mounted) {
      setState(() {
        _results = list;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) {
            if (v.length >= 2 || v.isEmpty) {
              _performSearch(v);
            }
          },
          decoration: InputDecoration(
            hintText: 'Search Arabic, English, or Urdu...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppTheme.primary),
                    onPressed: () {
                      _searchCtrl.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _lastQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Type to search across all 6,236 Ayahs',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No matching verses found for "$_lastQuery"',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final res = _results[idx];
                        return InkWell(
                          onTap: () {
                            context.goNamed(
                              'verse-by-verse',
                              pathParameters: {'surahNumber': res.ayah.surah.toString()},
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8ECE9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Surah & Ayah Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Surah ${res.surahInfo.nameTransliteration} • Ayah ${res.ayah.ayahNumber}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      res.surahInfo.nameArabic,
                                      style: const TextStyle(
                                        fontFamily: 'Scheherazade New',
                                        fontSize: 16,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Arabic Text
                                Text(
                                  res.ayah.arabicText,
                                  style: GoogleFonts.amiri(
                                    fontSize: 18,
                                    height: 1.6,
                                    color: AppTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),

                                if (res.translationText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    res.translationText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
