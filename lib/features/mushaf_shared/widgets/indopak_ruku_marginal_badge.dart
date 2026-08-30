import 'package:flutter/material.dart';
import '../../../data/arabic_numerals.dart';
import '../../../data/ruku_data.dart';

/// Marginal Ruku (ع) vertical cartouche badge matching authentic IndoPak printed mushaf
class IndoPakRukuMarginalBadge extends StatelessWidget {
  final RukuInfo rukuInfo;

  const IndoPakRukuMarginalBadge({
    super.key,
    required this.rukuInfo,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: 19,
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(9.5),
          border: Border.all(color: const Color(0xFF2C7A39), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top Number: Ruku in Surah (e.g. ۷) ──
            Text(
              ArabicNumerals.format(rukuInfo.rukuInSurah),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 9.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2A1E),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1.0),

            // ── Middle Symbol: Stylized Arabic Letter 'ع' ──
            const Text(
              'ع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C7A39), // Islamic Forest Green Ayn
                height: 0.95,
              ),
            ),
            const SizedBox(height: 1.8), // Balanced bottom spacing matching the top gap

            // ── Bottom Number: Global Ruku count (e.g. ۹۲) ──
            Text(
              ArabicNumerals.format(rukuInfo.globalRuku),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
