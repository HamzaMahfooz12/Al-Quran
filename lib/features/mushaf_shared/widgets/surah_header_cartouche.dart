import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/arabic_numerals.dart';
import '../../../data/models/surah_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 15-LINE MUSHAF: SURAH HEADER CARTOUCHE (LINE 1 OF 2)
// ─────────────────────────────────────────────────────────────────────────────

/// Royal illuminated gold & ivory cartouche matching authentic classical
/// Quran manuscript unwan art, strictly following the approved light-theme design.
class SurahHeader15Widget extends StatelessWidget {
  final int surahNumber;
  final String fallbackSurahName;

  const SurahHeader15Widget({
    super.key,
    required this.surahNumber,
    required this.fallbackSurahName,
  });

  @override
  Widget build(BuildContext context) {
    final surahInfo = (surahNumber >= 1 && surahNumber <= 114)
        ? kSurahList[surahNumber - 1]
        : null;

    final isMeccan = surahInfo?.isMeccan ?? true;
    final ayahCountArabic = ArabicNumerals.format(surahInfo?.ayahCount ?? 0);
    final rukuCountArabic = ArabicNumerals.format(surahInfo?.rukuCount ?? 0);
    final surahName = surahInfo?.nameArabic ?? fallbackSurahName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Optimal aspect ratio matching the mockup (~7.5 : 1)
        final double height = (width / 7.2).clamp(38.0, 48.0);

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: const SurahHeader15Painter(),
            child: Stack(
              children: [
                // ── Left Medallion: Revelation (مكية / مدنية) ───────────────
                Positioned(
                  left: width * 0.08,
                  top: height * 0.12,
                  bottom: height * 0.12,
                  width: width * 0.17,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Center Plaque: Surah Name (سورة ...) ─────────────────────
                Positioned(
                  left: width * 0.28,
                  right: width * 0.28,
                  top: height * 0.15,
                  bottom: height * 0.15,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'سُورَةُ $surahName',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111111),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Right Medallion: Verses & Rukus (١٦٥ آية \n ٢٠ ركوع) ────
                Positioned(
                  right: width * 0.08,
                  top: height * 0.12,
                  bottom: height * 0.12,
                  width: width * 0.17,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$ayahCountArabic آيَة',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$rukuCountArabic رُكُوْع',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 15-LINE MUSHAF: DEDICATED BISMILLAH (LINE 2 OF 2)
// ─────────────────────────────────────────────────────────────────────────────

/// Dedicated Bismillah line with symmetric golden arabesque floral vine flourishes.
class Bismillah15Widget extends StatelessWidget {
  final String text;

  const Bismillah15Widget({
    super.key,
    this.text = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = (width / 14.0).clamp(24.0, 32.0);

        return SizedBox(
          width: width,
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Flourish
              Expanded(
                child: SizedBox(
                  height: height,
                  child: const CustomPaint(
                    painter: BismillahFlourishPainter(isLeft: true),
                  ),
                ),
              ),

              // Centered Bismillah Calligraphy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text.isNotEmpty ? text : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111111),
                      height: 1.1,
                    ),
                  ),
                ),
              ),

              // Right Flourish
              Expanded(
                child: SizedBox(
                  height: height,
                  child: const CustomPaint(
                    painter: BismillahFlourishPainter(isLeft: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 16-LINE MUSHAF: INTEGRATED SINGLE-LINE SURAH HEADER
// ─────────────────────────────────────────────────────────────────────────────

/// Single-line integrated illuminated ribbon header where Bismillah, Surah Name,
/// Revelation, and Verse/Ruku counts are all adjusted into the exact same line.
class SurahHeader16Widget extends StatelessWidget {
  final int surahNumber;
  final String fallbackSurahName;
  final String bismillahText;

  const SurahHeader16Widget({
    super.key,
    required this.surahNumber,
    required this.fallbackSurahName,
    this.bismillahText = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
  });

  @override
  Widget build(BuildContext context) {
    final surahInfo = (surahNumber >= 1 && surahNumber <= 114)
        ? kSurahList[surahNumber - 1]
        : null;

    final isMeccan = surahInfo?.isMeccan ?? true;
    final ayahCountArabic = ArabicNumerals.format(surahInfo?.ayahCount ?? 0);
    final rukuCountArabic = ArabicNumerals.format(surahInfo?.rukuCount ?? 0);
    final rawSurahName = (surahInfo?.nameArabic ?? fallbackSurahName).trim();
    final surahDisplayName = (rawSurahName.startsWith('سُورَة') || rawSurahName.startsWith('سورة'))
        ? rawSurahName
        : 'سُورَةُ $rawSurahName';

    // Surah 9 (At-Tawbah) does not have Bismillah
    final hasBismillah = surahNumber != 9;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Match line row budget with graceful clamping for Arabic ascenders
        final double height = (constraints.maxHeight.isFinite && constraints.maxHeight > 0)
            ? constraints.maxHeight.clamp(34.0, 44.0)
            : (width / 8.2).clamp(36.0, 44.0);

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: const SurahHeader16Painter(),
            child: Stack(
              children: [
                // ── Left Capsule: Verses & Rukus ────────────────────────────
                Positioned(
                  left: width * 0.070,
                  width: width * 0.225,
                  top: height * 0.14,
                  bottom: height * 0.14,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$ayahCountArabic آيَة',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$rukuCountArabic رُكُوْع',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Center Capsule: Bismillah in same line ───────────────────
                Positioned(
                  left: width * 0.315,
                  width: width * 0.370,
                  top: height * 0.14,
                  bottom: height * 0.14,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hasBismillah
                              ? (bismillahText.isNotEmpty ? bismillahText : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ')
                              : surahDisplayName,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111111),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Right Capsule: Surah Name & Revelation ──────────────────
                Positioned(
                  left: width * 0.705,
                  width: width * 0.225,
                  top: height * 0.14,
                  bottom: height * 0.14,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              surahDisplayName,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111111),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VECTOR PAINTER: 15-LINE SURAH CARTOUCHE
// ─────────────────────────────────────────────────────────────────────────────

class SurahHeader15Painter extends CustomPainter {
  const SurahHeader15Painter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Palette tokens (Champagne gold & antique gold)
    const goldDeep = Color(0xFFB8860B);
    const goldMid = Color(0xFFC59B27);
    const goldLight = Color(0xFFD4AF37);
    const goldFill = Color(0xFFF6EBD4);
    const goldFillLight = Color(0xFFFDF7EB);
    const ivoryWhite = Color(0xFFFFFDF8);

    // ── 1. Outer Cartouche Path with Top Arch Crest & Finials ─────────────
    final Path outerPath = Path();
    final double midY = h * 0.5;

    // Left Palmette Tip (Pointed Finial Spearhead)
    outerPath.moveTo(0, midY);
    outerPath.cubicTo(w * 0.02, midY - h * 0.18, w * 0.04, h * 0.18, w * 0.07, h * 0.18);
    // Scalloped outer bracket
    outerPath.cubicTo(w * 0.09, h * 0.18, w * 0.10, h * 0.14, w * 0.13, h * 0.14);
    // Top bar toward center arch
    outerPath.lineTo(w * 0.35, h * 0.14);
    // Center Arch Rising to Apex
    outerPath.cubicTo(w * 0.38, h * 0.14, w * 0.40, h * 0.05, w * 0.44, h * 0.07);
    outerPath.cubicTo(w * 0.46, h * 0.02, w * 0.48, 0, w * 0.5, 0); // Crown Tip
    outerPath.cubicTo(w * 0.52, 0, w * 0.54, h * 0.02, w * 0.56, h * 0.07);
    outerPath.cubicTo(w * 0.60, h * 0.05, w * 0.62, h * 0.14, w * 0.65, h * 0.14);
    // Top bar to right bracket
    outerPath.lineTo(w * 0.87, h * 0.14);
    outerPath.cubicTo(w * 0.90, h * 0.14, w * 0.91, h * 0.18, w * 0.93, h * 0.18);
    // Right Palmette Tip
    outerPath.cubicTo(w * 0.96, h * 0.18, w * 0.98, midY - h * 0.18, w, midY);
    outerPath.cubicTo(w * 0.98, midY + h * 0.18, w * 0.96, h * 0.82, w * 0.93, h * 0.82);
    // Bottom bracket
    outerPath.cubicTo(w * 0.91, h * 0.82, w * 0.90, h * 0.86, w * 0.87, h * 0.86);
    // Bottom bar
    outerPath.lineTo(w * 0.13, h * 0.86);
    outerPath.cubicTo(w * 0.10, h * 0.86, w * 0.09, h * 0.82, w * 0.07, h * 0.82);
    outerPath.cubicTo(w * 0.04, h * 0.82, w * 0.02, midY + h * 0.18, 0, midY);
    outerPath.close();

    // Fill Outer Cartouche
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [goldFillLight, goldFill, goldFillLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(outerPath, fillPaint);

    // Outer Dual Gold Border
    final Paint strokePaintOuter = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerPath, strokePaintOuter);

    // Inset Hairline Border
    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.scale(0.975, 0.93);
    canvas.translate(-w * 0.5, -h * 0.5);
    final Paint strokePaintInner = Paint()
      ..color = goldLight.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(outerPath, strokePaintInner);
    canvas.restore();

    // ── 2. Floral Arabesque Scrollwork on Left and Right Wings ─────────────
    _drawArabesqueWing(canvas, w * 0.18, midY, w * 0.08, h * 0.35, isLeft: true);
    _drawArabesqueWing(canvas, w * 0.82, midY, w * 0.08, h * 0.35, isLeft: false);

    // ── 3. Left & Right Circular Gold Medallions ───────────────────────────
    final double medRadius = h * 0.35;
    final double leftMedX = w * 0.165;
    final double rightMedX = w * 0.835;

    _drawCircularMedallion(canvas, leftMedX, midY, medRadius);
    _drawCircularMedallion(canvas, rightMedX, midY, medRadius);

    // ── 4. Center Arched Ivory Plaque (سورة ...) ───────────────────────────
    final double plaqueLeft = w * 0.28;
    final double plaqueRight = w * 0.72;
    final double plaqueWidth = plaqueRight - plaqueLeft;
    final double plaqueHeight = h * 0.72;
    final double plaqueTop = h * 0.14;

    final RRect plaqueRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(plaqueLeft, plaqueTop, plaqueWidth, plaqueHeight),
      Radius.circular(plaqueHeight * 0.42),
    );

    // Ivory Fill with subtle radial lighting
    final Paint plaqueFillPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, ivoryWhite, Color(0xFFF9F3E5)],
        radius: 0.85,
        center: Alignment.center,
      ).createShader(plaqueRRect.outerRect);
    canvas.drawRRect(plaqueRRect, plaqueFillPaint);

    // Double Gold Frame around Center Plaque
    final Paint plaqueBorderOuter = Paint()
      ..color = goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(plaqueRRect, plaqueBorderOuter);

    final RRect plaqueInnerRRect = plaqueRRect.deflate(2.0);
    final Paint plaqueBorderInner = Paint()
      ..color = goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(plaqueInnerRRect, plaqueBorderInner);

    // Scalloped Cusps at Plaque Ends (Left & Right arches)
    _drawPlaqueCusp(canvas, plaqueLeft + 2, midY, h * 0.24, isLeft: true);
    _drawPlaqueCusp(canvas, plaqueRight - 2, midY, h * 0.24, isLeft: false);
  }

  void _drawCircularMedallion(Canvas canvas, double cx, double cy, double r) {
    const goldMid = Color(0xFFC59B27);
    const goldLight = Color(0xFFD4AF37);

    // Radial Gold Fill
    final Paint medFill = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFFDF8), Color(0xFFF5E6C8), Color(0xFFEEDBBE)],
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, medFill);

    // Outer Ring
    final Paint ringOuter = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), r, ringOuter);

    // Inner Concentric Ring
    final Paint ringInner = Paint()
      ..color = goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy), r - 2.2, ringInner);
  }

  void _drawPlaqueCusp(Canvas canvas, double x, double y, double r, {required bool isLeft}) {
    final Paint cuspPaint = Paint()
      ..color = const Color(0xFFC59B27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final Path cuspPath = Path();
    final double dir = isLeft ? 1 : -1;
    cuspPath.moveTo(x, y - r);
    cuspPath.cubicTo(x + dir * (r * 0.6), y - r * 0.5, x + dir * (r * 0.6), y + r * 0.5, x, y + r);
    canvas.drawPath(cuspPath, cuspPaint);
  }

  void _drawArabesqueWing(Canvas canvas, double cx, double cy, double rx, double ry, {required bool isLeft}) {
    final Paint vinePaint = Paint()
      ..color = const Color(0xFFC59B27).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    final Path vinePath = Path();
    final double dir = isLeft ? -1 : 1;

    // Graceful S-vine with curling tendrils
    vinePath.moveTo(cx, cy);
    vinePath.cubicTo(cx + dir * rx * 0.5, cy - ry * 0.7, cx + dir * rx * 0.8, cy - ry * 0.3, cx + dir * rx, cy);
    vinePath.cubicTo(cx + dir * rx * 0.8, cy + ry * 0.3, cx + dir * rx * 0.5, cy + ry * 0.7, cx, cy);

    canvas.drawPath(vinePath, vinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// VECTOR PAINTER: BISMILLAH ARABESQUE FLOURISHES
// ─────────────────────────────────────────────────────────────────────────────

class BismillahFlourishPainter extends CustomPainter {
  final bool isLeft;

  const BismillahFlourishPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midY = h * 0.5;

    final Paint goldPaint = Paint()
      ..color = const Color(0xFFC59B27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFC59B27).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final Path flourish = Path();

    if (isLeft) {
      // Flowing from right (near text) toward left (margin)
      flourish.moveTo(w - 4, midY);
      flourish.cubicTo(w * 0.7, midY - h * 0.35, w * 0.5, midY + h * 0.35, w * 0.25, midY);
      flourish.cubicTo(w * 0.15, midY - h * 0.25, w * 0.08, midY - h * 0.1, 4, midY);

      // Upper curled tendril
      flourish.moveTo(w * 0.6, midY - h * 0.18);
      flourish.quadraticBezierTo(w * 0.5, midY - h * 0.45, w * 0.42, midY - h * 0.35);

      // Lower curled tendril
      flourish.moveTo(w * 0.45, midY + h * 0.15);
      flourish.quadraticBezierTo(w * 0.35, midY + h * 0.45, w * 0.28, midY + h * 0.32);

      canvas.drawPath(flourish, goldPaint);

      // Terminal bud / rosette diamond at outer tip
      final Path bud = Path();
      bud.moveTo(2, midY);
      bud.lineTo(6, midY - 2.5);
      bud.lineTo(10, midY);
      bud.lineTo(6, midY + 2.5);
      bud.close();
      canvas.drawPath(bud, fillPaint);
    } else {
      // Flowing from left (near text) toward right (margin)
      flourish.moveTo(4, midY);
      flourish.cubicTo(w * 0.3, midY - h * 0.35, w * 0.5, midY + h * 0.35, w * 0.75, midY);
      flourish.cubicTo(w * 0.85, midY - h * 0.25, w * 0.92, midY - h * 0.1, w - 4, midY);

      // Upper curled tendril
      flourish.moveTo(w * 0.4, midY - h * 0.18);
      flourish.quadraticBezierTo(w * 0.5, midY - h * 0.45, w * 0.58, midY - h * 0.35);

      // Lower curled tendril
      flourish.moveTo(w * 0.55, midY + h * 0.15);
      flourish.quadraticBezierTo(w * 0.65, midY + h * 0.45, w * 0.72, midY + h * 0.32);

      canvas.drawPath(flourish, goldPaint);

      // Terminal bud / rosette diamond at outer tip
      final Path bud = Path();
      bud.moveTo(w - 2, midY);
      bud.lineTo(w - 6, midY - 2.5);
      bud.lineTo(w - 10, midY);
      bud.lineTo(w - 6, midY + 2.5);
      bud.close();
      canvas.drawPath(bud, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// VECTOR PAINTER: 16-LINE INTEGRATED RIBBON BANNER
// ─────────────────────────────────────────────────────────────────────────────

class SurahHeader16Painter extends CustomPainter {
  const SurahHeader16Painter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midY = h * 0.5;

    const goldMid = Color(0xFFC59B27);
    const goldLight = Color(0xFFD4AF37);
    const goldFill = Color(0xFFF6EBD4);
    const goldFillLight = Color(0xFFFDF7EB);

    // ── 1. Ribbon Tails (Swallowtail / Folded ends on left & right) ────────
    final Paint tailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEADBBE), Color(0xFFF5E6C8)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final Paint tailBorder = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Left Ribbon Tail with swallowtail notch
    final Path leftTail = Path();
    leftTail.moveTo(w * 0.070, h * 0.18);
    leftTail.lineTo(w * 0.008, h * 0.18);
    leftTail.lineTo(w * 0.030, midY); // V-notch apex
    leftTail.lineTo(w * 0.008, h * 0.82);
    leftTail.lineTo(w * 0.070, h * 0.82);
    leftTail.close();
    canvas.drawPath(leftTail, tailPaint);
    canvas.drawPath(leftTail, tailBorder);

    // Right Ribbon Tail with swallowtail notch
    final Path rightTail = Path();
    rightTail.moveTo(w * 0.930, h * 0.18);
    rightTail.lineTo(w * 0.992, h * 0.18);
    rightTail.lineTo(w * 0.970, midY); // V-notch apex
    rightTail.lineTo(w * 0.992, h * 0.82);
    rightTail.lineTo(w * 0.930, h * 0.82);
    rightTail.close();
    canvas.drawPath(rightTail, tailPaint);
    canvas.drawPath(rightTail, tailBorder);

    // ── 2. Main Ribbon Cartouche Body ─────────────────────────────────────
    final double bodyLeft = w * 0.055;
    final double bodyRight = w * 0.945;
    final double bodyWidth = bodyRight - bodyLeft;
    final double bodyHeight = h * 0.82;
    final double bodyTop = h * 0.09;

    final RRect bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight),
      Radius.circular(bodyHeight * 0.26),
    );

    final Paint bodyFill = Paint()
      ..shader = const LinearGradient(
        colors: [goldFillLight, goldFill, goldFillLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bodyRRect.outerRect);
    canvas.drawRRect(bodyRRect, bodyFill);

    final Paint bodyStroke = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(bodyRRect, bodyStroke);

    final Paint bodyInnerStroke = Paint()
      ..color = goldLight.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(bodyRRect.deflate(1.8), bodyInnerStroke);

    // ── 3. Three Integrated Rectangular Capsules (Left, Center, Right) ────
    final double plaqueTop = h * 0.14;
    final double plaqueHeight = h * 0.72;
    final double cornerRadius = plaqueHeight * 0.38;

    // Left Capsule: Verses & Rukus
    final Rect leftRect = Rect.fromLTWH(w * 0.070, plaqueTop, w * 0.225, plaqueHeight);
    _drawCartouche(canvas, leftRect, cornerRadius);

    // Center Capsule: Bismillah Calligraphy
    final Rect centerRect = Rect.fromLTWH(w * 0.315, plaqueTop, w * 0.370, plaqueHeight);
    _drawCartouche(canvas, centerRect, cornerRadius);

    // Right Capsule: Surah Name & Revelation
    final Rect rightRect = Rect.fromLTWH(w * 0.705, plaqueTop, w * 0.225, plaqueHeight);
    _drawCartouche(canvas, rightRect, cornerRadius);

    // ── 4. Golden Rosette Dividers in the 2 Gaps ──────────────────────────
    _drawDividerRosette(canvas, w * 0.305, midY, h * 0.08);
    _drawDividerRosette(canvas, w * 0.695, midY, h * 0.08);
  }

  void _drawCartouche(Canvas canvas, Rect rect, double radius) {
    const goldMid = Color(0xFFC59B27);
    const goldLight = Color(0xFFD4AF37);
    const ivoryWhite = Color(0xFFFFFDF8);

    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Ivory Fill with subtle radial illumination
    final Paint fillPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, ivoryWhite, Color(0xFFF9F3E5)],
        radius: 0.95,
        center: Alignment.center,
      ).createShader(rect);
    canvas.drawRRect(rrect, fillPaint);

    // Outer Gold Border
    final Paint borderOuter = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderOuter);

    // Inset Hairline Gold Border
    final Paint borderInner = Paint()
      ..color = goldLight.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawRRect(rrect.deflate(1.8), borderInner);
  }

  void _drawDividerRosette(Canvas canvas, double cx, double cy, double size) {
    const goldMid = Color(0xFFC59B27);
    final Paint paint = Paint()
      ..color = goldMid
      ..style = PaintingStyle.fill;

    // Graceful 4-point diamond rosette
    final Path path = Path();
    path.moveTo(cx, cy - size);
    path.quadraticBezierTo(cx + size * 0.25, cy - size * 0.25, cx + size, cy);
    path.quadraticBezierTo(cx + size * 0.25, cy + size * 0.25, cx, cy + size);
    path.quadraticBezierTo(cx - size * 0.25, cy + size * 0.25, cx - size, cy);
    path.quadraticBezierTo(cx - size * 0.25, cy - size * 0.25, cx, cy - size);
    path.close();
    canvas.drawPath(path, paint);

    // Micro gold dots above and below for illuminated balance
    final Paint dotPaint = Paint()
      ..color = goldMid.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - size * 1.8), 0.9, dotPaint);
    canvas.drawCircle(Offset(cx, cy + size * 1.8), 0.9, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
