// lib/features/shared/widgets/unified_ayah_card.dart
// Single reusable Ayat Card component across the entire application.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ayah.dart';

// ── Strips Arabic Diacritical Marks ──────────────────────────────────────────
String stripArabicTashkeel(String s) {
  return s.replaceAll(
    RegExp(
        r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06EF\u0670\u06E1\uFC60-\uFC62]'),
    '',
  );
}

// ── Helper to Strip Bismillah Prefix from Ayah 1 of any Surah > 1 ────────────
String cleanAyahText(Ayah ayah) {
  if (ayah.ayahNumber == 1 && ayah.surah != 1) {
    final text = ayah.arabicText.trim();
    final bare = stripArabicTashkeel(text);
    final m = RegExp(r'^بسم\s*[اٱ]لله\s*[اٱ]لرحمن\s*[اٱ]لرحيم\s*').firstMatch(bare);
    if (m != null) {
      final bareLen = m.group(0)!.length;
      int bareCount = 0;
      int idx = 0;
      final diacriticRe = RegExp(
          r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06EF\u0670\u06E1\uFC60-\uFC62]');
      while (idx < text.length && bareCount < bareLen) {
        if (!diacriticRe.hasMatch(text[idx])) bareCount++;
        idx++;
      }
      while (idx < text.length && (text[idx] == ' ' || text[idx] == '\u200C')) {
        idx++;
      }
      final remaining = text.substring(idx).trim();
      if (remaining.isNotEmpty) return remaining;
    }
  }
  return ayah.arabicText;
}

// ── 1. Scalloped Rosette Ayah Badge (Top Left of Card) ─────────────────────────
class ScallopedAyahBadge extends StatelessWidget {
  final int number;
  final double size;

  const ScallopedAyahBadge({
    super.key,
    required this.number,
    this.size = 33,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScallopedRosettePainter(),
        child: Center(
          child: Text(
            number.toString(),
            style: GoogleFonts.inter(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScallopedRosettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.76;
    const numPoints = 16;
    final path = Path();

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi) / numPoints - (math.pi / 2);
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill with rich Midnight Sapphire gradient
    final fillPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1E3A60), Color(0xFF0F2038)],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawPath(path, fillPaint);

    // Fine Radiant Gold outline
    final strokePaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);

    // Inner subtle Radiant Gold ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, innerR * 0.88, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 2. Ornate Inline Ayah End Marker (Inside Arabic text) ─────────────────────
class OrnateAyahEndMarker extends StatelessWidget {
  final int ayahNumber;
  final double circleSize;

  const OrnateAyahEndMarker({
    super.key,
    required this.ayahNumber,
    this.circleSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: CustomPaint(
        painter: _OrnateEndMarkerPainter(),
        child: Center(
          child: Text(
            ayahNumber.toString(),
            style: GoogleFonts.scheherazadeNew(
              fontSize: circleSize * 0.44,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A60),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrnateEndMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.82;
    const numPoints = 8;
    final path = Path();

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi) / numPoints - (math.pi / 2);
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Soft amber background fill
    final bgPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // Warm Amber floral frame
    final strokePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);

    // Subtle inner ring
    final innerStroke = Paint()
      ..color = const Color(0xFF1E3A60).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawCircle(center, innerR * 0.72, innerStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 3. Islamic Floral Center Divider ──────────────────────────────────────────
class IslamicDivider extends StatelessWidget {
  const IslamicDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Transform.rotate(
                  angle: 0.785398, // 45 degrees
                  child: Container(
                    width: 13.5,
                    height: 13.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A60),
                      borderRadius: BorderRadius.circular(2),
                      border:
                          Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.star, size: 6.5, color: Color(0xFFFEF3C7)),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8E1D2).withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Unified Ayat Card Component ───────────────────────────────────────────
class UnifiedAyahCard extends StatelessWidget {
  final Ayah ayah;
  final String? translationText;
  final String? tafseerText;
  final String translationName;
  final String tafseerName;
  final double arabicFontSize;
  final double urduFontSize;
  final bool isPlaying;
  final bool isBuffering;
  final bool isBookmarked;
  final String? activeWordId;
  final VoidCallback onOpenTafseer;
  final VoidCallback onSelectTranslation;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onShareTap;
  final VoidCallback onMutashabihatTap;
  final VoidCallback onCopyTap;
  final bool isHighlighted;

  const UnifiedAyahCard({
    super.key,
    required this.ayah,
    required this.translationText,
    this.tafseerText,
    required this.translationName,
    required this.tafseerName,
    required this.arabicFontSize,
    required this.urduFontSize,
    required this.isPlaying,
    required this.isBuffering,
    required this.isBookmarked,
    this.activeWordId,
    this.isHighlighted = false,
    required this.onOpenTafseer,
    required this.onSelectTranslation,
    required this.onPlayTap,
    required this.onBookmarkTap,
    required this.onShareTap,
    required this.onMutashabihatTap,
    required this.onCopyTap,
  });

  Widget _buildArabicText() {
    final rawText = cleanAyahText(ayah);
    final words = rawText.trim().split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];

    for (var i = 0; i < words.length; i++) {
      final wordText = words[i];
      final wordIndex = i + 1;
      final wordKey = '${ayah.surah}:${ayah.ayahNumber}:$wordIndex';
      final isWordActive = (isPlaying && activeWordId == wordKey);

      spans.add(
        TextSpan(
          text: '$wordText ',
          style: GoogleFonts.amiri(
            fontSize: arabicFontSize,
            fontWeight: FontWeight.bold,
            color: isWordActive
                ? const Color(0xFF0F172A)
                : const Color(0xFF0F172A),
            backgroundColor: isWordActive
                ? const Color(0xFFFDE68A) // Soft Golden Amber highlight
                : null,
            height: 2.1,
          ),
        ),
      );
    }

    // Ayah End Symbol (Ornate Frame with Ayah Number)
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2.0, left: 2.0),
          child: OrnateAyahEndMarker(
            ayahNumber: ayah.ayahNumber,
            circleSize: (arabicFontSize * 0.95).clamp(26.0, 34.0),
          ),
        ),
      ),
    );

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFFDF5) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFD4AF37)
              : (isPlaying ? const Color(0xFF1E3A60) : const Color(0xFFE2E8F0)),
          width: isHighlighted ? 2.5 : (isPlaying ? 2.0 : 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                : (isPlaying
                    ? const Color(0xFF1E3A60).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03)),
            blurRadius: isHighlighted ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Header Row ──────────────────────────────────────────────────
          Row(
            children: [
              // 1. Scalloped Rosette Ayah Badge
              ScallopedAyahBadge(number: ayah.ayahNumber, size: 33),

              const SizedBox(width: 7),

              // 2. Tafseer Pill — opens dedicated Tafseer modal
              InkWell(
                onTap: onOpenTafseer,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: Color(0xFF1E3A60),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tafseer',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 3. Translation Pill — opens Translation selector bottom sheet to switch translations
              InkWell(
                onTap: onSelectTranslation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 12.5,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Translation',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 4. Bookmark Outline / Active Button
              IconButton(
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: isBookmarked
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF64748B),
                ),
                onPressed: onBookmarkTap,
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayah',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),

              const SizedBox(width: 3),

              // 5. Circular Royal Midnight Sapphire Play Button
              GestureDetector(
                onTap: onPlayTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A60),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A60).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Arabic Verse Text with Uthmani Script & Inline Ornate Marker ──────
          _buildArabicText(),

          // ── Islamic Floral Center Divider (Between Arabic & Translation) ───────
          if (translationText != null && translationText!.isNotEmpty)
            const IslamicDivider(),

          // ── Translation Section (Always permanently visible & styled) ─────────
          if (translationText != null && translationText!.isNotEmpty)
            Builder(
              builder: (context) {
                final isUrduOrArabic =
                    translationText!.contains(RegExp(r'[\u0600-\u06FF]'));
                final isHindi =
                    translationText!.contains(RegExp(r'[\u0900-\u097F]'));

                return Text(
                  translationText!,
                  textAlign: isUrduOrArabic ? TextAlign.right : TextAlign.left,
                  textDirection:
                      isUrduOrArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: isUrduOrArabic
                      ? GoogleFonts.notoNastaliqUrdu(
                          fontSize: urduFontSize,
                          height: 2.35,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        )
                      : (isHindi
                          ? GoogleFonts.notoSansDevanagari(
                              fontSize: urduFontSize * 0.88,
                              height: 1.8,
                              color: const Color(0xFF0F172A),
                            )
                          : GoogleFonts.outfit(
                              fontSize: urduFontSize * 0.85,
                              height: 1.65,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w500,
                            )),
                );
              },
            ),

          // ── Quick Secondary Action Strip (Share, Copy, Mutashabihat) ─────────
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Similar / Mutashabihat Button
              InkWell(
                onTap: onMutashabihatTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows_rounded,
                          size: 15, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        'Similar',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Copy Button
              InkWell(
                onTap: onCopyTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          size: 14, color: Color(0xFF334155)),
                      const SizedBox(width: 3),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Share Button
              InkWell(
                onTap: onShareTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share_outlined,
                          size: 14, color: Color(0xFF334155)),
                      const SizedBox(width: 3),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155)),
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
}
