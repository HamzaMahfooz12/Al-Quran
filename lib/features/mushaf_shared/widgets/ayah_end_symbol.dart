import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/ruku_data.dart';

class AyahEndSymbol extends StatelessWidget {
  final int ayahNumber;
  final String waqfMark;
  final RukuInfo? rukuInfo;
  final Color color;

  const AyahEndSymbol({
    super.key,
    required this.ayahNumber,
    this.waqfMark = '',
    this.rukuInfo,
    this.color = const Color(0xFF1B4332),
  });

  static String toArabicIndic(int number) {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? digits[digit] : char;
    }).join('');
  }

  @override
  Widget build(BuildContext context) {
    final arabicNum = toArabicIndic(ayahNumber);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Ruku (Rukh) Badge if this Ayah is a Ruku End ─────────────────
          if (rukuInfo != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFD4A843), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ع',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B4F00),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    toArabicIndic(rukuInfo!.rukuInSurah),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7B4F00),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Waqf (Stop Mark) Symbol if present ────────────────────────────
          if (waqfMark.isNotEmpty) ...[
            Text(
              waqfMark,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4A843),
                height: 1.0,
              ),
            ),
          ],

          // ── Ayah End Ornament Symbol (Matches Reference Image) ────────────
          CustomPaint(
            size: const Size(26, 30),
            painter: AyahSymbolPainter(color: color),
            child: SizedBox(
              width: 26,
              height: 30,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    arabicNum,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the IndoPak Ayah End Ornament
/// Top curved arch + double circle frame + bottom curved arch
class AyahSymbolPainter extends CustomPainter {
  final Color color;

  AyahSymbolPainter({this.color = const Color(0xFF1B4332)});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 2.5;

    // 1. Center Circle (Double outline for classic IndoPak look)
    canvas.drawCircle(Offset(cx, cy), r, strokePaint);
    canvas.drawCircle(Offset(cx, cy), r - 1.8, strokePaint..strokeWidth = 0.7);

    // Reset stroke width
    strokePaint.strokeWidth = 1.1;

    // 2. Top Decorative Flourish (Curved arch cap with center dot)
    final topPath = Path();
    topPath.moveTo(cx - 7, cy - r + 1);
    topPath.quadraticBezierTo(cx - 3.5, cy - r - 4, cx, cy - r - 4.5);
    topPath.quadraticBezierTo(cx + 3.5, cy - r - 4, cx + 7, cy - r + 1);
    canvas.drawPath(topPath, strokePaint);

    // Top Dot •
    canvas.drawCircle(Offset(cx, cy - r - 3), 1.1, fillPaint);

    // 3. Bottom Decorative Flourish (Inverted curved arch cap with center dot)
    final bottomPath = Path();
    bottomPath.moveTo(cx - 7, cy + r - 1);
    bottomPath.quadraticBezierTo(cx - 3.5, cy + r + 4, cx, cy + r + 4.5);
    bottomPath.quadraticBezierTo(cx + 3.5, cy + r + 4, cx + 7, cy + r - 1);
    canvas.drawPath(bottomPath, strokePaint);

    // Bottom Dot •
    canvas.drawCircle(Offset(cx, cy + r + 3), 1.1, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
