import 'package:flutter/material.dart';

/// Single item representing a parsed Waqf stopping symbol with its styling.
class WaqfMarkItem {
  final String text;
  final Color color;
  const WaqfMarkItem({required this.text, this.color = const Color(0xFF1E293B)});
}

/// Helper to parse and render Quranic Waqf symbols in authentic layered Indo-Pak style.
class WaqfHelper {
  static const Map<String, WaqfMarkItem> _charMap = {
    '\u0615': WaqfMarkItem(text: 'ط', color: Color(0xFF1E293B)), // Waqf Mutlaq (Tah)
    '\u0617': WaqfMarkItem(text: 'ز', color: Color(0xFF1E293B)), // Waqf Mujawwaz (Zain)
    '\u0614': WaqfMarkItem(text: 'ص', color: Color(0xFF1E293B)), // Waqf Murakhkhas (Saad)
    '\u06EA': WaqfMarkItem(text: 'ص', color: Color(0xFF1E293B)), // Waqf Murakhkhas (Saad)
    '\u06EB': WaqfMarkItem(text: 'ق', color: Color(0xFF1E293B)), // Al-Waqf Awla (Qaf)
    '\u06EC': WaqfMarkItem(text: 'قف', color: Color(0xFF1E293B)), // Waqf Qif
    '\u06D6': WaqfMarkItem(text: 'صلے', color: Color(0xFF1E293B)), // Wasl Awla (never connect with next)
    '\u06D7': WaqfMarkItem(text: 'قلى', color: Color(0xFF1E293B)), // Qalā (Waqf Awla)
    '\u06D8': WaqfMarkItem(text: 'مـ', color: Color(0xFF1E293B)), // Waqf Lazim (Small Meem)
    '\u06D9': WaqfMarkItem(text: 'لا', color: Color(0xFFC62828)), // Lā Waqf (Quranic Red)
    '\u06DA': WaqfMarkItem(text: 'ج', color: Color(0xFF1E293B)), // Waqf Jaiz
    '\u06DB': WaqfMarkItem(text: '؞', color: Color(0xFF1E293B)), // Mu'anaqah (Three dots)
    '\u06DC': WaqfMarkItem(text: 'س', color: Color(0xFF1E293B)), // Saktah
    '\u06E0': WaqfMarkItem(text: '∘', color: Color(0xFF1E293B)), // Rounded zero
    '\u06E2': WaqfMarkItem(text: 'مـ', color: Color(0xFF1E293B)), // Small High Meem
    '\u06ED': WaqfMarkItem(text: 'مـ', color: Color(0xFF1E293B)), // Small Low Meem
    '\u06E6': WaqfMarkItem(text: 'و', color: Color(0xFF1E293B)), // Small Waw
  };

  /// Set of all characters recognized as waqf / pause indicators
  static final Set<String> waqfChars = {
    ..._charMap.keys,
    'ط', 'ز', 'ص', 'ق', 'قف', 'صلے', 'صلى', 'قلى', 'م', 'لا', 'ج', '؞', 'س',
  };

  /// Parses a raw waqf string into a list of independent, non-joined stopping marks.
  static List<WaqfMarkItem> parseMarks(String raw) {
    if (raw.isEmpty) return const [];
    final list = <WaqfMarkItem>[];
    for (final ch in raw.split('')) {
      if (_charMap.containsKey(ch)) {
        list.add(_charMap[ch]!);
      } else if (ch.trim().isNotEmpty &&
          ch != '۟' &&
          (ch.codeUnitAt(0) < 0xF500 || ch.codeUnitAt(0) > 0xF5FF)) {
        list.add(WaqfMarkItem(
          text: ch == 'صلى' ? 'صلے' : ch,
          color: ch == 'لا' ? const Color(0xFFC62828) : const Color(0xFF1E293B),
        ));
      }
    }
    return list;
  }
}
