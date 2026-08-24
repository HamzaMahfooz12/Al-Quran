// lib/features/share/widgets/ayah_share_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';

class AyahShareDialog extends StatefulWidget {
  final String surahName;
  final int ayahNumber;
  final String arabicText;
  final String translationText;

  const AyahShareDialog({
    super.key,
    required this.surahName,
    required this.ayahNumber,
    required this.arabicText,
    required this.translationText,
  });

  static Future<void> show(
    BuildContext context, {
    required String surahName,
    required int ayahNumber,
    required String arabicText,
    required String translationText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AyahShareDialog(
        surahName: surahName,
        ayahNumber: ayahNumber,
        arabicText: arabicText,
        translationText: translationText,
      ),
    );
  }

  @override
  State<AyahShareDialog> createState() => _AyahShareDialogState();
}

class _AyahShareDialogState extends State<AyahShareDialog> {
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  bool _sharing = false;
  String? _selectedBackdrop;

  static const List<Map<String, String>> _kBackdrops = [
    {
      'id': 'assets/images/quran_share_bg.jpg',
      'name': 'Sanctuary',
      'arabic': 'المصحف',
    },
    {
      'id': 'assets/images/quran_share_celestial.jpg',
      'name': 'Celestial',
      'arabic': 'السماء',
    },
    {
      'id': 'assets/images/quran_share_dawn.jpg',
      'name': 'Dawn Light',
      'arabic': 'الفجر والضحى',
    },
    {
      'id': 'assets/images/quran_share_dark.jpg',
      'name': 'Arabesque',
      'arabic': 'الزخرفة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedBackdrop = _getDynamicBackdropAsset();
  }

  /// Intelligent dynamic backdrop resolver based on Ayah content & Surah themes
  String _getDynamicBackdropAsset() {
    final text = '${widget.arabicText} ${widget.translationText} ${widget.surahName}'.toLowerCase();
    
    // 1. Celestial Night theme (stars, night, heavens, unseen, protection)
    if (text.contains('ليل') ||
        text.contains('سماء') ||
        text.contains('نجوم') ||
        text.contains('night') ||
        text.contains('star') ||
        text.contains('heaven') ||
        text.contains('kursi') ||
        widget.surahName.contains('Mulk') ||
        widget.surahName.contains('Lail') ||
        widget.surahName.contains('Najm') ||
        widget.surahName.contains('Qadr') ||
        widget.surahName.contains('Buruuj')) {
      return 'assets/images/quran_share_celestial.jpg';
    }

    // 2. Golden Dawn theme (light, morning, hope, ease, mercy, victory)
    if (text.contains('نور') ||
        text.contains('صبح') ||
        text.contains('ضحى') ||
        text.contains('يسر') ||
        text.contains('light') ||
        text.contains('morning') ||
        text.contains('dawn') ||
        text.contains('ease') ||
        text.contains('mercy') ||
        text.contains('rahma') ||
        widget.surahName.contains('Nur') ||
        widget.surahName.contains('Duha') ||
        widget.surahName.contains('Sharh') ||
        widget.surahName.contains('Rahman') ||
        widget.surahName.contains('Fath')) {
      return 'assets/images/quran_share_dawn.jpg';
    }

    // 3. Emerald Arabesque theme (covenant, law, wisdom, patience)
    if (text.contains('صبر') ||
        text.contains('حق') ||
        text.contains('حكمة') ||
        text.contains('patience') ||
        text.contains('truth') ||
        text.contains('wisdom') ||
        widget.ayahNumber % 2 == 0) {
      return 'assets/images/quran_share_dark.jpg';
    }

    // 4. Default Quran Sanctuary (Open Quran on wooden stand)
    return 'assets/images/quran_share_bg.jpg';
  }

  Future<void> _shareImage() async {
    setState(() => _sharing = true);
    try {
      final imageBytes = await _screenshotCtrl.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/ayah_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Quran • Surah ${widget.surahName} [${widget.ayahNumber}]\n\n${widget.arabicText}\n\n${widget.translationText}\n\n— Shared via Al Quran App',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _copyFormattedText() {
    final text = 'Surah ${widget.surahName} : Verse ${widget.ayahNumber}\n\n'
        '${widget.arabicText}\n\n'
        '${widget.translationText}\n\n'
        '— Al Quran App';
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayah text copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header & Drag handle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Share Verse Card',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Background Wallpaper Selector Chips ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kBackdrops.map((bd) {
                  final isSelected = (_selectedBackdrop ?? _getDynamicBackdropAsset()) == bd['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedBackdrop = bd['id']);
                        }
                      },
                      avatar: CircleAvatar(
                        radius: 8,
                        backgroundImage: AssetImage(bd['id']!),
                      ),
                      label: Text('${bd['name']} • ${bd['arabic']}'),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8E4)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Card Preview (Dynamically generated for this specific Ayah) ───
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Screenshot(
                controller: _screenshotCtrl,
                child: _buildShareCard(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Share & Copy Buttons ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyFormattedText,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _shareImage,
                    icon: _sharing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.share, size: 18),
                    label: Text(_sharing ? 'Generating...' : 'Share Picture Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildShareCard() {
    final bgAsset = _selectedBackdrop ?? _getDynamicBackdropAsset();
    const goldColor = Color(0xFFFFD54F);
    const transColor = Color(0xFFF1F8F3);
    const footerColor = Colors.white70;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgAsset),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(Color(0xB8080E0A), BlendMode.darken),
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Surah Name & Ayah Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: goldColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'سُورَةُ ${widget.surahName}',
                      style: const TextStyle(
                        fontFamily: 'Scheherazade New',
                        fontSize: 15,
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Text(
                  'Ayah ${widget.ayahNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Arabic Text
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.arabicText,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 25,
                height: 1.85,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),

          if (widget.translationText.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.6),
              ),
              child: Text(
                widget.translationText,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: transColor,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Reference tag: [القرآن : سورة 3:92]
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 0.8),
              ),
              child: Text(
                '[ القرآن الكريم • Surah ${widget.surahName} : ${widget.ayahNumber} ]',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: goldColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Card Footer
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, color: goldColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Al Quran App',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: footerColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Read • Listen • Reflect',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: footerColor.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
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