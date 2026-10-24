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
    '\u065A': WaqfMarkItem(text: 'قف', color: Color(0xFF1E293B)), // Waqf Saktah
    '\u06AB': WaqfMarkItem(text: 'ق', color: Color(0xFF1E293B)), // Waqf Awla
    '\u06AC': WaqfMarkItem(text: 'صلے', color: Color(0xFF1E293B)), // Waqf Wasl Awla
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
    'ط': WaqfMarkItem(text: 'ط', color: Color(0xFF1E293B)),
    'ز': WaqfMarkItem(text: 'ز', color: Color(0xFF1E293B)),
    'ص': WaqfMarkItem(text: 'ص', color: Color(0xFF1E293B)),
    'ق': WaqfMarkItem(text: 'ق', color: Color(0xFF1E293B)),
    'قف': WaqfMarkItem(text: 'قف', color: Color(0xFF1E293B)),
    'صلے': WaqfMarkItem(text: 'صلے', color: Color(0xFF1E293B)),
    'صلى': WaqfMarkItem(text: 'صلے', color: Color(0xFF1E293B)),
    'قلى': WaqfMarkItem(text: 'قلى', color: Color(0xFF1E293B)),
    'مـ': WaqfMarkItem(text: 'مـ', color: Color(0xFF1E293B)),
    'لا': WaqfMarkItem(text: 'لا', color: Color(0xFFC62828)),
    'ج': WaqfMarkItem(text: 'ج', color: Color(0xFF1E293B)),
    '؞': WaqfMarkItem(text: '؞', color: Color(0xFF1E293B)),
    'س': WaqfMarkItem(text: 'س', color: Color(0xFF1E293B)),
    'ع': WaqfMarkItem(text: 'ع', color: Color(0xFF8B0000)),
  };

  /// Authentic Unicode Quranic stopping annotation codepoints.
  /// Never includes regular Arabic alphabet letters (such as س, ج, ق, ص)
  /// so that regular Arabic words are never split or truncated.
  static final Set<String> waqfCodepoints = {
    '\u0614', '\u0615', '\u0617', '\u065A', '\u06AB', '\u06AC',
    '\u06D6', '\u06D7', '\u06D8', '\u06D9', '\u06DA', '\u06DB',
    '\u06DC', '\u06E0', '\u06E2', '\u06E6', '\u06EA', '\u06EB',
    '\u06EC', '\u06ED',
  };

  /// Set of all characters recognized as waqf / pause indicators
  static final Set<String> waqfChars = {
    ...waqfCodepoints,
  };

  /// Returns true if character is a recognized Quranic waqf codepoint
  static bool isWaqfCodepoint(String ch) => waqfCodepoints.contains(ch);

  /// Parses a raw waqf string into a list of independent, non-joined stopping marks.
  /// Strictly caps result to at most 3 items to avoid vertical layout inflation.
  static List<WaqfMarkItem> parseMarks(String raw) {
    if (raw.isEmpty) return const [];
    final list = <WaqfMarkItem>[];

    String remaining = raw.trim();
    while (remaining.isNotEmpty && list.length < 3) {
      bool matched = false;
      for (final key in const ['صلے', 'صلى', 'قلى', 'قف', 'لا']) {
        if (remaining.startsWith(key)) {
          list.add(_charMap[key]!);
          remaining = remaining.substring(key.length).trim();
          matched = true;
          break;
        }
      }
      if (matched) continue;

      final ch = remaining[0];
      remaining = remaining.substring(1).trim();

      if (_charMap.containsKey(ch)) {
        list.add(_charMap[ch]!);
      } else if (waqfCodepoints.contains(ch)) {
        list.add(WaqfMarkItem(
          text: ch,
          color: const Color(0xFF1E293B),
        ));
      }
      // Non-waqf characters (especially arbitrary Arabic word letters) are safely ignored!
    }
    return list;
  }
}
