// lib/features/tafseer/widgets/ayah_tafseer_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/ayah.dart';
import '../../../data/models/edition.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../services/settings_service.dart';

/// Displays the dedicated Ayah Tafseer Modal Window matching the user's reference design:
/// - Top Blue/Teal Header Banner: "Surat No.X Ayat No.Y" with Share & Close buttons
/// - Tafseer Selector Dropdown Card: Dark container with green border, round emblem, active Tafseer name & dropdown
/// - Scrollable rich Nastaliq Urdu / Arabic / English Tafseer content
/// - Instant Tafseer switching across bundled & downloadable editions
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
    barrierColor: Colors.black.withValues(alpha: 0.65),
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
  double _fontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _fontSize = ref.read(urduFontSizeProvider);
    _currentEdition = widget.initialEdition;
    _tafseerText = null;
    _loadAllTafseerEditions();
    _fetchTafseerForAyah(_currentEdition);
  }

  Future<void> _loadAllTafseerEditions() async {
    final repo = ref.read(quranRepositoryProvider);
    final editions = await repo.getAllEditions(type: 'tafseer');
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
      final text = await repo.getContent(widget.ayah.id, edition.id);

      if (mounted) {
        setState(() {
          final cleaned = (text != null && text.trim().isNotEmpty)
              ? _cleanHtml(text).trim()
              : null;
          _tafseerText = (cleaned != null && cleaned.isNotEmpty) ? cleaned : null;
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
    await ref
        .read(settingsServiceProvider)
        .setSelectedTafseerEditionId(edition.id);

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
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Tafseer copied to clipboard',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2038),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahInfo = widget.ayah.surah <= kSurahList.length
        ? kSurahList[widget.ayah.surah - 1]
        : null;
    final surahTitle = 'Surat No.${widget.ayah.surah} Ayat No.${widget.ayah.ayahNumber}';
    final isUrduOrArabic = _currentEdition.language == 'ur' || _currentEdition.language == 'ar';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2228), // Deep obsidian background matching reference
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Top Blue Header Banner ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A60), Color(0xFF0F2038)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            surahInfo != null
                                ? '$surahTitle (${surahInfo.nameTransliteration})'
                                : surahTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Share Button
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 21),
                    tooltip: 'Share Tafseer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: _shareTafseer,
                  ),

                  const SizedBox(width: 4),

                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Tafseer Selection Dropdown Bar ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: InkWell(
              onTap: () {
                setState(() => _showDropdown = !_showDropdown);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF252D34),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    // Emblem badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A60), Color(0xFF0F2038)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'تفسير',
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD54F),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Active Tafseer name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentEdition.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to switch or select another Tafseer',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      _showDropdown
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFD4AF37),
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Dropdown Menu List (shown when tapped) ─────────────────────
          if (_showDropdown)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              constraints: const BoxConstraints(maxHeight: 230),
              decoration: BoxDecoration(
                color: const Color(0xFF222B32),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF37474F)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _availableTafseers.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Color(0xFF2E3842), height: 1),
                itemBuilder: (ctx, i) {
                  final ed = _availableTafseers[i];
                  final isSelected = ed.id == _currentEdition.id;

                  return InkWell(
                    onTap: () => _onSelectNewEdition(ed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF37474F),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                ed.language.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                                  ed.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : Colors.white,
                                  ),
                                ),
                                if (ed.language == 'ur')
                                  Text(
                                    'Urdu Tafseer',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF78909C)),
                                  )
                                else if (ed.language == 'ar')
                                  Text(
                                    'Arabic Tafseer',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF78909C)),
                                  )
                                else
                                  Text(
                                    'English / Other',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF78909C)),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                color: Color(0xFFD4AF37), size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── 4. Main Tafseer Content Window ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arabic Ayah Preview Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14191E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF2C3E50), width: 1),
                          ),
                          child: Text(
                            widget.ayah.arabicText,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFE082),
                              height: 2.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tafseer Heading Divider
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFF37474F))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${_currentEdition.name} • تفصيل و تفسير',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFF37474F))),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Tafseer Main Text Body or Standard Styled Empty State
                        if (_tafseerText != null && _tafseerText!.isNotEmpty)
                          SelectableText(
                            _tafseerText!,
                            textAlign: isUrduOrArabic
                                ? TextAlign.right
                                : TextAlign.left,
                            textDirection: isUrduOrArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: isUrduOrArabic
                                ? TextStyle(
                                    fontFamily: _currentEdition.language == 'ur'
                                        ? 'Jameel Noori Nastaleeq'
                                        : 'Amiri',
                                    fontSize: _fontSize + 4,
                                    height: 2.2,
                                    color: const Color(0xFFECEFF1),
                                  )
                                : GoogleFonts.inter(
                                    fontSize: _fontSize,
                                    height: 1.7,
                                    color: const Color(0xFFECEFF1),
                                  ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 32),
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'تفسير غير متوفر في هذه النسخة',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFD54F),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tafseer commentary is not available for this Ayah in the selected edition.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF90A4AE),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2038)
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'You can select another Tafseer from the dropdown above.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFFC5D5E8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // ── 5. Bottom Action Bar (Font size controls & Copy) ───────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF14191E),
              border: Border(top: BorderSide(color: Color(0xFF2C3E50))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Font decrease
                  IconButton(
                    icon: const Icon(Icons.text_decrease_rounded,
                        color: Color(0xFF90A4AE), size: 20),
                    tooltip: 'Decrease Font',
                    onPressed: () {
                      if (_fontSize > 13) setState(() => _fontSize -= 1.5);
                    },
                  ),
                  Text(
                    '${_fontSize.toInt()}pt',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF90A4AE)),
                  ),
                  // Font increase
                  IconButton(
                    icon: const Icon(Icons.text_increase_rounded,
                        color: Color(0xFF90A4AE), size: 20),
                    tooltip: 'Increase Font',
                    onPressed: () {
                      if (_fontSize < 28) setState(() => _fontSize += 1.5);
                    },
                  ),

                  const Spacer(),

                  // Copy button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    onPressed: _copyTafseer,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      'Copy Tafseer',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600),
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
}

/// Helper function to strip HTML tags from Tafseer strings
String _cleanHtml(String text) {
  var s = text;
  s = s.replaceAll(RegExp(r'</p>|<br\s*/?>|</div>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'");
  s = s.replaceAll(RegExp(r'p\s+class="[^"]*"|div\s+lang="[^"]*"'), '');
  s = s.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
  return s.trim();
}
