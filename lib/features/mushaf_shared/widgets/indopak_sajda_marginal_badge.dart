// lib/features/mushaf_shared/widgets/indopak_sajda_marginal_badge.dart
import 'package:flutter/material.dart';

/// Marginal Sajda (سجدة) vertical cartouche badge matching authentic printed mushafs
class IndoPakSajdaMarginalBadge extends StatelessWidget {
  const IndoPakSajdaMarginalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: 20,
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD84315), width: 1.0),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 7, color: Color(0xFFD84315)),
            SizedBox(height: 1),
            Text(
              'سَجْدَة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD84315),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
