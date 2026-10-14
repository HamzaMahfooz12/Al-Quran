import 'package:flutter/material.dart';
import '../../../data/arabic_numerals.dart';

import 'waqf_helper.dart';

/// Inline Ayah End Badge matching authentic IndoPak printed mushaf
/// Renders an open circle ⭕ with embedded Eastern Arabic numerals,
/// and displays 'ع' (Ayn) or stopping symbols (ط, لا, ج, مـ, قلى, صلے, etc.)
/// layered vertically with clean spacing directly above the circle.
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
    this.color = const Color(0xFF1E3A60),
    this.circleSize = 19.0,
  });

  @override
  Widget build(BuildContext context) {
    final arabicNum = ArabicNumerals.format(ayahNumber);

    // Collect marks to layer above circle: 'ع' for Ruku conclusion + any Waqf marks
    final marks = <WaqfMarkItem>[];
    if (isRukuEnd) {
      marks.add(const WaqfMarkItem(text: 'ع', color: Color(0xFF8B0000)));
    }
    marks.addAll(WaqfHelper.parseMarks(waqfMark));

    final double topOffset = marks.length > 1
        ? (circleSize > 20 ? -17.0 : -15.0)
        : (circleSize > 20 ? -13.0 : -10.5);
    final double numFontSize = arabicNum.length > 2
        ? (circleSize * 0.40).clamp(7.0, 11.0)
        : (circleSize * 0.48).clamp(8.0, 12.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Top Marks: 'ع' and/or Waqf Marks layered vertically above the circle ──
          if (marks.isNotEmpty)
            Positioned(
              top: topOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < marks.length; i++) ...[
                    if (i > 0) const SizedBox(height: 1.0),
                    Text(
                      marks[i].text,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: marks[i].text == 'ع'
                            ? 11.5
                            : (marks.length > 1 ? 8.0 : 10.0),
                        fontWeight: FontWeight.bold,
                        color: marks[i].color,
                        height: 1.0,
                      ),
                    ),
                  ],
                ],
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
