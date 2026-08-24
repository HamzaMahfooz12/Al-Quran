import 'package:flutter/material.dart';
import '../../../data/arabic_numerals.dart';

/// Inline Ayah End Badge matching authentic IndoPak printed mushaf
/// Renders an open circle ⭕ with embedded Eastern Arabic numerals,
/// and displays 'ع' (Ayn) or stopping symbol (ط, لا, ج, مـ, قلی, صلی, etc.)
/// directly on top of the circle.
class AyahEndSymbol extends StatelessWidget {
  final int ayahNumber;
  final String waqfMark;
  final bool isRukuEnd;
  final Color color;
  final double circleSize;

  const AyahEndSymbol({
    super.key,
    required this.ayahNumber,
    this.waqfMark = '',
    this.isRukuEnd = false,
    this.color = const Color(0xFF111111),
    this.circleSize = 19.0,
  });

  static const Map<String, String> _waqfDisplayMap = {
    '\u0615': 'ط',
    '\u06d9': 'لا',
    '\u06da': 'ج',
    '\u06d8': 'مـ',
    '\u06d7': 'قلی',
    '\u06d6': 'صلی',
    '\u0617': 'ز',
    '\u0614': 'ص',
    '\u06dc': 'س',
    '\u06db': 'ۛ',
    '\u06e0': 'ع',
    '\u06ea': 'قف',
    '\u06eb': 'ك',
  };

  static String resolveWaqfDisplay(String mark) {
    if (mark.isEmpty) return '';
    for (final e in _waqfDisplayMap.entries) {
      if (mark.contains(e.key)) return e.value;
    }
    return _waqfDisplayMap[mark] ?? mark;
  }

  @override
  Widget build(BuildContext context) {
    final arabicNum = ArabicNumerals.format(ayahNumber);

    // Top mark: 'ع' if Ruku concludes, else Waqf stopping sign
    final topMarkText = isRukuEnd ? 'ع' : resolveWaqfDisplay(waqfMark);

    final double topOffset = circleSize > 20 ? -13.0 : -10.5;
    final double numFontSize = arabicNum.length > 2
        ? (circleSize * 0.40).clamp(7.0, 11.0)
        : (circleSize * 0.48).clamp(8.0, 12.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Top Mark: 'ع' or Waqf Mark (ط, لا, ج, etc.) directly above the circle ──
          if (topMarkText.isNotEmpty)
            Positioned(
              top: topOffset,
              child: Text(
                topMarkText,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: isRukuEnd ? 11.5 : (topMarkText.length > 2 ? 8.5 : 10.0),
                  fontWeight: FontWeight.bold,
                  color: isRukuEnd
                      ? const Color(0xFF8B0000)
                      : (topMarkText == 'لا' ? const Color(0xFFC62828) : const Color(0xFF1B4332)),
                  height: 1.0,
                ),
              ),
            ),

          // ── Circular Ayah End Ornament ──
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.1),
              color: Colors.transparent,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 0.5),
                child: Text(
                  arabicNum,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: numFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
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
