// lib/features/shared/widgets/edition_selection_sheet.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/edition_metadata.dart';
import '../../../data/models/edition.dart';
import '../../../data/repositories/quran_repository.dart';

/// Shows the modernized Translation or Tafseer Selection Bottom Sheet
/// matching the app's clean parchment & ivory design language.
Future<Edition?> showEditionSelectionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String type, // 'translation' | 'tafseer'
  Edition? currentEdition,
  required void Function(Edition selected) onEditionSelected,
}) {
  return showModalBottomSheet<Edition>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _EditionSelectionSheetContent(
      type: type,
      currentEdition: currentEdition,
      onEditionSelected: onEditionSelected,
    ),
  );
}

class _EditionSelectionSheetContent extends ConsumerStatefulWidget {
  final String type;
  final Edition? currentEdition;
  final void Function(Edition selected) onEditionSelected;

  const _EditionSelectionSheetContent({
    required this.type,
    required this.currentEdition,
    required this.onEditionSelected,
  });

  @override
  ConsumerState<_EditionSelectionSheetContent> createState() =>
      _EditionSelectionSheetContentState();
}

class _EditionSelectionSheetContentState
    extends ConsumerState<_EditionSelectionSheetContent> {
  String _selectedLang = 'ur';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  List<Edition> _allEditions = [];
  bool _loading = true;
  final Set<int> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _loadEditions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEditions() async {
    final repo = ref.read(quranRepositoryProvider);
    var editions = await repo.getAllEditions(type: widget.type);

    // If translation, strictly ensure only approved plan editions are visible
    if (widget.type == 'translation') {
      editions = editions.where((e) {
        return EditionMetadataRegistry.approvedTranslationKeys.contains(e.apiKey);
      }).toList();
    }

    // Sort: Downloaded/Bundled first, then preferred ordering
    editions.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return a.id.compareTo(b.id);
    });

    if (mounted) {
      setState(() {
        _allEditions = editions;
        _loading = false;
        if (widget.currentEdition != null && widget.currentEdition!.language.isNotEmpty) {
          // If translation and language is 'ar', default to 'ur'
          if (widget.type == 'translation' && widget.currentEdition!.language.toLowerCase() == 'ar') {
            _selectedLang = 'ur';
          } else {
            _selectedLang = widget.currentEdition!.language;
          }
        }
      });
    }
  }

  List<Edition> _getFilteredEditions() {
    return _allEditions.where((e) {
      final matchesLang = _selectedLang == 'all' ||
          e.language.toLowerCase() == _selectedLang.toLowerCase();
      if (!matchesLang) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final meta = EditionMetadataRegistry.getMetadata(e.apiKey, fallbackName: e.name);

      return e.name.toLowerCase().contains(q) ||
          e.apiKey.toLowerCase().contains(q) ||
          meta.bookTitle.toLowerCase().contains(q) ||
          meta.scholarName.toLowerCase().contains(q) ||
          meta.authorityBadge.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTranslation = widget.type == 'translation';
    final title = isTranslation ? 'Select Translation' : 'Select Tafseer';
    final subtitle = isTranslation
        ? 'Curated authentic translations with respected scholars'
        : 'Authoritative classical and contemporary Quranic commentaries';

    final filteredList = _getFilteredEditions();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Drag Handle ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppTheme.borderWarm,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // ── Header Row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    isTranslation
                        ? Icons.translate_rounded
                        : Icons.menu_book_rounded,
                    color: AppTheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  hintText: isTranslation
                      ? 'Search translation, book or scholar...'
                      : 'Search tafseer commentary or scholar...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
                  ),
                ),
              ),
            ),
          ),

          // ── Language Filter Pills (Arabic strictly removed for Translations) ─
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildPill(label: 'Urdu (اردو)', code: 'ur'),
                  _buildPill(label: 'English (EN)', code: 'en'),
                  if (!isTranslation) ...[
                    // Arabic only shown for Tafseers, never for Translations
                    _buildPill(label: 'Arabic (العربية)', code: 'ar'),
                  ],
                  if (isTranslation) ...[
                    _buildPill(label: 'Hindi (हिंदी)', code: 'hi'),
                  ],
                  _buildPill(label: 'All Editions', code: 'all'),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // ── Editions List ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 44,
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No editions found for this selection.',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final ed = filteredList[index];
                          final isSelected = widget.currentEdition?.id == ed.id;
                          final isDownloading = _downloadingIds.contains(ed.id);
                          final meta = EditionMetadataRegistry.getMetadata(
                            ed.apiKey,
                            fallbackName: ed.name,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: isSelected
                                  ? AppTheme.primarySurface
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: () {
                                  if (_downloadingIds.contains(ed.id)) return;
                                  if (!ed.isAvailable) {
                                    _downloadEdition(ed);
                                    return;
                                  }
                                  Navigator.of(context).pop(ed);
                                  widget.onEditionSelected(ed);
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.divider,
                                      width: isSelected ? 1.6 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppTheme.primary.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // ── Scholar Portrait Avatar ───────────
                                      _buildScholarAvatar(meta, ed, isSelected),
                                      const SizedBox(width: 14),

                                      // ── Scholar & Book Titles ─────────────
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Book title (Properly and fully displayable)
                                            Text(
                                              meta.bookTitle,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                                height: 1.25,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),

                                            // Scholar Name (Fully displayable)
                                            Text(
                                              meta.scholarName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                                height: 1.25,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),

                                            // Subtitle info
                                            Row(
                                              children: [
                                                Text(
                                                  _getLanguageLabel(ed.language),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                ),
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme.textMuted
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                Icon(
                                                  isDownloading
                                                      ? Icons.sync_rounded
                                                      : ed.isAvailable
                                                          ? Icons.offline_pin_rounded
                                                          : Icons.cloud_download_outlined,
                                                  size: 11,
                                                  color: isDownloading || ed.isAvailable
                                                      ? AppTheme.primary
                                                      : AppTheme.textMuted,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isDownloading
                                                      ? 'Downloading...'
                                                      : ed.isAvailable
                                                          ? 'Ready Offline'
                                                          : 'Tap to Download',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    color: isDownloading || ed.isAvailable
                                                        ? AppTheme.primary
                                                        : AppTheme.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // ── Trailing Selection Indicator ──────
                                      if (isSelected)
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 17,
                                          ),
                                        )
                                      else if (isDownloading)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primarySurface,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Downloading',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (ed.isAvailable)
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppTheme.borderWarm,
                                              width: 1.5,
                                            ),
                                          ),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => _downloadEdition(ed),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primarySurface,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.cloud_download_rounded,
                                                  size: 12,
                                                  color: AppTheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Get',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primary,
                                                  ),
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
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarAvatar(
    EditionMetadata meta,
    Edition ed,
    bool isSelected,
  ) {
    const avatarSize = 48.0;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppTheme.accentGold
              : AppTheme.borderWarm.withValues(alpha: 0.7),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: meta.imageAsset != null
            ? Image.asset(
                meta.imageAsset!,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackAvatar(ed, isSelected),
              )
            : _fallbackAvatar(ed, isSelected),
      ),
    );
  }

  Widget _fallbackAvatar(Edition ed, bool isSelected) {
    return Container(
      color: isSelected ? AppTheme.primary : AppTheme.cardBgSecondary,
      child: Center(
        child: Text(
          ed.language.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }


  Widget _buildPill({required String label, required String code}) {
    final isSelected = _selectedLang == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedLang = code),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel(String code) {
    switch (code.toLowerCase()) {
      case 'ur':
        return 'Urdu';
      case 'en':
        return 'English';
      case 'ar':
        return 'Arabic';
      case 'hi':
        return 'Hindi';
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _downloadEdition(Edition ed) async {
    setState(() {
      _downloadingIds.add(ed.id);
    });

    try {
      final repo = ref.read(quranRepositoryProvider);
      final List<Map<String, dynamic>> contentRows = [];

      // 1. Check local translation assets (e.g. Hindi, Urdu, English JSONs in assets/translations/)
      String? localAssetPath;
      if (ed.apiKey == 'hi.maududi') {
        localAssetPath = 'assets/translations/hindi/hin-muhammadfarooqk.min.json';
      } else if (ed.apiKey == 'hi.taqiusmani') {
        localAssetPath = 'assets/translations/hindi/hin-suhelfarooqkhan.min.json';
      } else if (ed.apiKey == 'ur.taqiusmani') {
        localAssetPath = 'assets/translations/urdu/taqi_usmani_urdu.json';
      } else if (ed.apiKey == 'en.maududi') {
        localAssetPath = 'assets/translations/english/en.maududi.json';
      }

      if (localAssetPath != null) {
        try {
          final jsonStr = await rootBundle.loadString(localAssetPath);
          final dynamic decoded = json.decode(jsonStr);
          if (decoded is Map && decoded.containsKey('quran') && decoded['quran'] is List) {
            final list = decoded['quran'] as List;
            for (final item in list) {
              final ch = item['chapter'] as int;
              final vr = item['verse'] as int;
              final text = (item['text'] ?? '').toString();
              final globalId = _getGlobalAyahId(ch, vr);
              contentRows.add({
                'ayah_id': globalId,
                'edition_id': ed.id,
                'text': text,
              });
            }
          }
        } catch (_) {}
      }

      // 2. Check local Tafseer files
      if (contentRows.isEmpty && ed.type == 'tafseer') {
        const tafseerPaths = {
          'ar-tafsir-al-tabari': r'D:\AL Quran\tafssir\arabic\ar-tafsir-al-tabari.json',
          'ar-tafseer-al-qurtubi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-qurtubi.json',
          'ar-tafseer-al-saddi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-saddi.json',
          'asseraj-fi-bayan-gharib-alquran': r'D:\AL Quran\tafssir\arabic\asseraj-fi-bayan-gharib-alquran.json',
          'tafsir-ibn-abi-hatim': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-abi-hatim.json',
          'tafsir-ibn-uthaymeen': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-uthaymeen.json',
          'tafsir-jalalayn': r'D:\AL Quran\tafssir\arabic\tafsir-jalalayn.json',
          'tafsir-as-saadi': r'D:\AL Quran\tafssir\urdu\tafsir-as-saadi.json',
          'tafsir-fe-zalul-quran-syed-qatab': r'D:\AL Quran\tafssir\urdu\tafsir-fe-zalul-quran-syed-qatab.json',
          'tazkiru-quran-ur': r'D:\AL Quran\tafssir\urdu\tazkiru-quran-ur.json',
          'Al-Mukhtasar': r'D:\AL Quran\tafssir\english\Al-Mukhtasar.json',
          'en-tafsir-maarif-ul-quran': r'D:\AL Quran\tafssir\english\en-tafsir-maarif-ul-quran.json',
          'tafsir-al-jalalayn': r'D:\AL Quran\tafssir\english\tafsir-al-jalalayn.json',
          'tazkirul-quran-en': r'D:\AL Quran\tafssir\english\tazkirul-quran-en.json',
          'hindi-mokhtasar': r'D:\AL Quran\tafssir\hindi\hindi-mokhtasar.json',
        };
        final localPath = tafseerPaths[ed.apiKey];
        if (localPath != null && File(localPath).existsSync()) {
          final jsonStr = await File(localPath).readAsString();
          final Map<String, dynamic> tafseerDict = json.decode(jsonStr);
          for (final entry in tafseerDict.entries) {
            final val = entry.value;
            if (val is! Map) continue;
            final rawText = (val['text'] ?? '').toString();
            if (rawText.trim().isEmpty) continue;
            final text = rawText.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
            final parts = entry.key.split(':');
            if (parts.length == 2) {
              final s = int.tryParse(parts[0]);
              final a = int.tryParse(parts[1]);
              if (s != null && a != null) {
                contentRows.add({
                  'ayah_id': _getGlobalAyahId(s, a),
                  'edition_id': ed.id,
                  'text': text,
                });
              }
            }
          }
        }
      }

      // 3. Fallback online API for translations
      if (contentRows.isEmpty && ed.type != 'tafseer') {
        final dio = Dio();
        final response = await dio.get('https://api.alquran.cloud/v1/quran/${ed.apiKey}');
        if (response.data != null && response.data['status'] == 'OK') {
          final surahs = (response.data['data']['surahs'] as List).cast<Map<String, dynamic>>();
          for (final surah in surahs) {
            final ayahs = (surah['ayahs'] as List).cast<Map<String, dynamic>>();
            for (final ayah in ayahs) {
              contentRows.add({
                'ayah_id': ayah['number'] as int,
                'edition_id': ed.id,
                'text': ayah['text'] as String,
              });
            }
          }
        }
      }

      // 4. Save to Database
      if (contentRows.isNotEmpty) {
        await repo.deleteEditionContent(ed.id);
        await repo.insertEditionContent(contentRows);
        await repo.markEditionDownloaded(ed.id);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Download error for ${ed.name}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(ed.id);
        });
        await _loadEditions();
      }
    }
  }

  static int _getGlobalAyahId(int surah, int ayah) {
    const counts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
      112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
      54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
      14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
      11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];
    int total = 0;
    for (int i = 0; i < surah - 1; i++) {
      total += counts[i];
    }
    return total + ayah;
  }
}
