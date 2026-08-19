import 'package:flutter/material.dart';
import '../../../data/arabic_numerals.dart';

/// Inline Ayah End Badge matching authentic IndoPak printed mushaf
/// Renders an open circle ⭕ with embedded Eastern Arabic numerals,
/// and displays 'ع' (Ayn) or waqf mark directly on top of the circle.
class AyahEndSymbol extends StatelessWidget {
  final int ayahNumber;
  final String waqfMark;
  final bool isRukuEnd;
  final Color color;

  const AyahEndSymbol({
    super.key,
    required this.ayahNumber,
    this.waqfMark = '',
    this.isRukuEnd = false,
    this.color = const Color(0xFF111111),
  });

  @override
  Widget build(BuildContext context) {
    final arabicNum = ArabicNumerals.format(ayahNumber);

    // Top mark: 'ع' if Ruku concludes, else Waqf sign
    final topMarkText = isRukuEnd ? 'ع' : waqfMark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Top Mark: 'ع' or Waqf Mark directly above the Ayah circle ──
          if (topMarkText.isNotEmpty)
            Positioned(
              top: isRukuEnd ? -11 : -9,
              child: Text(
                topMarkText,
                style: TextStyle(
                  fontFamily: isRukuEnd ? 'Amiri' : 'Scheherazade New',
                  fontSize: isRukuEnd ? 11.5 : 10,
                  fontWeight: FontWeight.bold,
                  color: isRukuEnd ? const Color(0xFF8B0000) : const Color(0xFF111111),
                  height: 1.0,
                ),
              ),
            ),

          // ── Circular Ayah End Ornament ──
          Container(
            width: 18.5,
            height: 18.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.0),
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
                    fontSize: arabicNum.length > 2 ? 7.5 : 8.5,
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
