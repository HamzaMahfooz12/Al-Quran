/// lib/data/indopak_glyph_mapper.dart
/// Complete mapping engine for IndoPak Quran calligraphy glyphs and Tajweed PUA codepoints.
/// Converts non-standard Private Use Area (PUA) characters to canonical Unicode Arabic standards.
class IndoPakGlyphMapper {
  /// Comprehensive lookup map of IndoPak PUA codepoints to standard Unicode equivalents
  static const Map<String, String> _puaMap = {
    // ── Wasla & Special Alef Ligatures ──
    '\uF61F': 'ٱ', // Alef Wasla on Allah (e.g. ٱللّٰهُ)
    '\uF665': 'نْثٰی', // In-word ligature (e.g. وَالْاُنْثٰی)
    '\uF667': 'ی',   // In-word ligature (e.g. وَاٰی)
    '\uF668': 'اِبْرٰهٖمَ', // In-word Ibrahim ligature
    '\uF669': 'كَّ',  // In-word ligature
    '\uF66A': 'سٌ',  // In-word ligature (e.g. نَفْسٌ)
    '\uF66B': 'ثٍ',  // In-word ligature (e.g. حَدِیْثٍ)

    // ── Tajweed & Pronunciation Marks ──
    '\uF66D': 'ۭ',  // Small Low Meem (Iqlab - U+06ED)
    '\uF65E': 'ۨ',  // Small High Noon (U+06E8)
    '\uF65D': '',   // Small Ikhfa/Ghunnah ligature connector
    '\uF653': '',   // Small ligature mark
    '\uF657': '',   // Small ligature mark
    '\uF658': 'ﷰ',  // Sajdah mark symbol / Waqf mark
    '\uF666': '',   // Ligature mark

    // ── Waqf (Stop Signs) ──
    '\uF64A': ' ۙ', // Waqf Lazim (U+06D9)
    '\uF64B': ' ۚ', // Waqf Ja'iz (U+06DA)
    '\uF64C': ' ؕ', // Waqf Mutlaq (Small Tah - U+0615)
    '\uF64D': ' ۖ', // Al-Waslu Awla (U+06D6)
    '\uF64E': ' ۛ', // Mu'anaqah (Three dots - U+06DB)
    '\uF64F': ' ۬', // Waqf mark
    '\uF652': ' ۘ', // Waqf mark
    '\uF65B': ' ۙ', // Waqf mark
    '\uF663': ' ۘ', // Waqf mark
    '\uF697': ' ۚ', // Waqf mark
    '\uF699': ' ؕ', // Waqf mark
  };

  /// Sanitizes text for display in standard Unicode Arabic fonts
  /// Replaces PUA symbols with their true Unicode equivalents and removes unmapped codes
  static String sanitize(String text) {
    if (text.isEmpty) return text;

    String result = text;
    _puaMap.forEach((pua, replacement) {
      if (result.contains(pua)) {
        result = result.replaceAll(pua, replacement);
      }
    });

    // Remove any remaining PUA characters (0xE000..0xF8FF) to guarantee 0 tofu boxes
    return result.replaceAll(RegExp(r'[\uE000-\uF8FF]'), '');
  }
}
