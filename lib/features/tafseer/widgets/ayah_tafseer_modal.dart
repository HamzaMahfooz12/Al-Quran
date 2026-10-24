// lib/features/tafseer/widgets/ayah_tafseer_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/edition_metadata.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/edition.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/settings_service.dart';
import '../../../services/tafseer_service.dart';

/// Displays the dedicated Ayah Tafseer Modal Window matching the app's signature
/// tactile parchment & ivory theme with modern pills and high readability.
void showAyahTafseerModal({
  required BuildContext context,
  required WidgetRef ref,
  required Ayah ayah,
  required Edition activeTafseerEdition,
  String? initialTafseerText,
  required void Function(Edition newEdition) onEditionChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => _AyahTafseerModalContent(
      ayah: ayah,
      initialEdition: activeTafseerEdition,
      initialTafseerText: initialTafseerText,
      onEditionChanged: onEditionChanged,
    ),
  );
}

class _AyahTafseerModalContent extends ConsumerStatefulWidget {
  final Ayah ayah;
  final Edition initialEdition;
  final String? initialTafseerText;
  final void Function(Edition newEdition) onEditionChanged;

  const _AyahTafseerModalContent({
    required this.ayah,
    required this.initialEdition,
    required this.initialTafseerText,
    required this.onEditionChanged,
  });

  @override
  ConsumerState<_AyahTafseerModalContent> createState() =>
      _AyahTafseerModalContentState();
}

class _AyahTafseerModalContentState
    extends ConsumerState<_AyahTafseerModalContent> {
  late Edition _currentEdition;
  String? _tafseerText;
  bool _isLoading = true;
  List<Edition> _availableTafseers = [];
  bool _showDropdown = false;
  String _selectedLangFilter = 'all';
  double _fontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _fontSize = ref.read(urduFontSizeProvider);
    _currentEdition = widget.initialEdition;
    _selectedLangFilter = widget.initialEdition.language.isNotEmpty
        ? widget.initialEdition.language
        : 'ur';
    _tafseerText = widget.initialTafseerText;
    _loadAllTafseerEditions();
    _fetchTafseerForAyah(_currentEdition);
  }

  Future<void> _loadAllTafseerEditions() async {
    final repo = ref.read(quranRepositoryProvider);
    final editions = await repo.getAllEditions(type: 'tafseer');

    // Sort: Downloaded/bundled first, then alphabetically
    editions.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return a.name.compareTo(b.name);
    });

    if (mounted) {
      setState(() {
        _availableTafseers = editions;
      });
    }
  }

  Future<void> _fetchTafseerForAyah(Edition edition) async {
    setState(() {
      _isLoading = true;
      _tafseerText = null;
    });

    final repo = ref.read(quranRepositoryProvider);

    try {
      final text = await TafseerService.fetchTafseerForAyah(
        surah: widget.ayah.surah,
        ayah: widget.ayah.ayahNumber,
        ayahId: widget.ayah.id,
        edition: edition,
        repo: repo,
      );

      if (mounted) {
        setState(() {
          _tafseerText = (text != null && text.trim().isNotEmpty) ? text.trim() : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tafseerText = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSelectNewEdition(Edition edition) async {
    setState(() {
      _currentEdition = edition;
      _showDropdown = false;
    });

    widget.onEditionChanged(edition);
    await ref.read(settingsServiceProvider).setSelectedTafseerEditionId(edition.id);
    await _fetchTafseerForAyah(edition);
  }

  void _shareTafseer() {
    final surahInfo = widget.ayah.surah <= kSurahList.length
        ? kSurahList[widget.ayah.surah - 1]
        : null;
    final surahName = surahInfo?.nameTransliteration ?? 'Surah ${widget.ayah.surah}';
    final content = StringBuffer();
    content.writeln('📖 $surahName — Ayah ${widget.ayah.ayahNumber}');
    content.writeln('----------------------------------------');
    content.writeln(widget.ayah.arabicText);
    content.writeln();
    content.writeln('🔍 Tafseer (${_currentEdition.name}):');
    content.writeln(_tafseerText ?? 'The author has not provided a tafsir for this ayah.');
    content.writeln('----------------------------------------');
    content.writeln('Shared from Al-Quran App');

    Share.share(content.toString(), subject: 'Tafseer: $surahName Ayah ${widget.ayah.ayahNumber}');
  }

  void _copyTafseer() {
    final textToCopy = _tafseerText ?? 'The author has not provided a tafsir for this ayah.';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Tafseer copied to clipboard',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Edition> _getFilteredTafseers() {
    if (_selectedLangFilter == 'all') return _availableTafseers;
    return _availableTafseers
        .where((e) => e.language.toLowerCase() == _selectedLangFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final surahInfo = widget.ayah.surah <= kSurahList.length
        ? kSurahList[widget.ayah.surah - 1]
        : null;
    final surahTitle = 'Surat No.${widget.ayah.surah} • Ayat No.${widget.ayah.ayahNumber}';
    final isUrdu = _currentEdition.language == 'ur';
    final isArabic = _currentEdition.language == 'ar';
    final isUrduOrArabic = isUrdu || isArabic;
    final filteredTafseers = _getFilteredTafseers();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Top Drag Handle ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppTheme.borderWarm,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // ── 2. Top Header Banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.divider, width: 1.0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.goldSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.goldDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        surahInfo != null
                            ? '${surahInfo.nameTransliteration} (${surahInfo.nameTranslation})'
                            : 'Surah ${widget.ayah.surah}',
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

                // Share Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _shareTafseer,
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
                        Icons.share_rounded,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Close Button
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

          // ── 3. Language Filter Pills ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildLangPill(label: 'Urdu (اردو)', code: 'ur'),
                  _buildLangPill(label: 'Arabic (العربية)', code: 'ar'),
                  _buildLangPill(label: 'English (EN)', code: 'en'),
                  _buildLangPill(label: 'Hindi (हिंदी)', code: 'hi'),
                  _buildLangPill(label: 'All Books', code: 'all'),
                ],
              ),
            ),
          ),

          // ── 4. Tafseer Book Selector Card (Dropdown Toggle) ───────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: () => setState(() => _showDropdown = !_showDropdown),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _showDropdown ? AppTheme.gold : AppTheme.divider,
                    width: _showDropdown ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Scholar / Emblem Avatar
                    _buildTafseerAvatar(
                      EditionMetadataRegistry.getMetadata(
                        _currentEdition.apiKey,
                        fallbackName: _currentEdition.name,
                      ),
                      _currentEdition,
                      true,
                      size: 38,
                    ),
                    const SizedBox(width: 12),

                    // Active Tafseer name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            EditionMetadataRegistry.getMetadata(
                              _currentEdition.apiKey,
                              fallbackName: _currentEdition.name,
                            ).bookTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            EditionMetadataRegistry.getMetadata(
                              _currentEdition.apiKey,
                              fallbackName: _currentEdition.name,
                            ).scholarName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      _showDropdown
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.gold,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 5. Dropdown Menu List ─────────────────────────────────────────
          if (_showDropdown)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: filteredTafseers.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppTheme.divider, height: 1),
                itemBuilder: (ctx, i) {
                  final ed = filteredTafseers[i];
                  final isSelected = ed.id == _currentEdition.id;
                  final meta = EditionMetadataRegistry.getMetadata(
                    ed.apiKey,
                    fallbackName: ed.name,
                  );

                  return InkWell(
                    onTap: () => _onSelectNewEdition(ed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _buildTafseerAvatar(meta, ed, isSelected, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.bookTitle,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.goldDark
                                        : AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  meta.scholarName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.gold,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── 6. Main Tafseer Content Window ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading Tafseer commentary...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arabic Ayah Preview Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.borderWarm,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'Ayat ${widget.ayah.ayahNumber}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.goldDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.ayah.arabicText,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.amiri(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  height: 2.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tafseer Heading Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppTheme.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${_currentEdition.name} • تفصيل و تفسير',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.goldDark,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppTheme.divider)),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Tafseer Main Text Body or Clean Styled Empty State
                        if (_tafseerText != null && _tafseerText!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: SelectableText(
                              _tafseerText!,
                              textAlign: isUrduOrArabic
                                  ? TextAlign.right
                                  : TextAlign.left,
                              textDirection: isUrduOrArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: isUrdu
                                  ? GoogleFonts.notoNastaliqUrdu(
                                      fontSize: _fontSize,
                                      height: 2.4,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    )
                                  : (isArabic
                                      ? GoogleFonts.amiri(
                                          fontSize: _fontSize + 3,
                                          height: 2.1,
                                          color: AppTheme.textPrimary,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: _fontSize,
                                          height: 1.75,
                                          color: AppTheme.textPrimary,
                                        )),
                            ),
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 46,
                                    color: AppTheme.textMuted.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'تفسير غير متوفر في هذه النسخة',
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.goldDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tafseer commentary is not available for this Ayah in the selected book.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: AppTheme.textMuted,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  InkWell(
                                    onTap: () => setState(() => _showDropdown = true),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.primary.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Switch to another Tafseer book',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
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
                      ],
                    ),
                  ),
          ),

          // ── 7. Bottom Action Bar (Font size controls & Copy) ───────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider, width: 1.0)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Font decrease
                  IconButton(
                    icon: const Icon(
                      Icons.text_decrease_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Decrease Font',
                    onPressed: () {
                      if (_fontSize > 13) setState(() => _fontSize -= 1.5);
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBgSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(
                      '${_fontSize.toInt()}pt',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Font increase
                  IconButton(
                    icon: const Icon(
                      Icons.text_increase_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Increase Font',
                    onPressed: () {
                      if (_fontSize < 28) setState(() => _fontSize += 1.5);
                    },
                  ),

                  const Spacer(),

                  // Copy button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                    ),
                    onPressed: _copyTafseer,
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: Text(
                      'Copy Tafseer',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangPill({required String label, required String code}) {
    final isSelected = _selectedLangFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedLangFilter = code;
            _showDropdown = true;
          }),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
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
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 5,
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
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
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

  Widget _buildTafseerAvatar(
    EditionMetadata meta,
    Edition ed,
    bool isSelected, {
    double size = 32.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.gold : AppTheme.borderWarm,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: meta.imageAsset != null
            ? Image.asset(
                meta.imageAsset!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _fallbackTafseerAvatar(ed, isSelected, size),
              )
            : _fallbackTafseerAvatar(ed, isSelected, size),
      ),
    );
  }

  Widget _fallbackTafseerAvatar(Edition ed, bool isSelected, double size) {
    return Container(
      color: isSelected ? AppTheme.primary : AppTheme.cardBgSecondary,
      child: Center(
        child: Text(
          ed.language.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.primary,
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
}
