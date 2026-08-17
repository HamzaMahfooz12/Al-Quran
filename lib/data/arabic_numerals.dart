/// Centralized Arabic / IndoPak numeral converter
class ArabicNumerals {
  /// Authentic IndoPak Arabic-Indic digits:
  /// 0: ۰, 1: ۱, 2: ۲, 3: ۳, 4: ٤, 5: ۵, 6: ٦, 7: ۷, 8: ۸, 9: ۹
  static const List<String> digits = [
    '۰', // 0 (U+06F0)
    '۱', // 1 (U+06F1)
    '۲', // 2 (U+06F2)
    '۳', // 3 (U+06F3)
    '٤', // 4 (U+0664 - authentic IndoPak Quranic 4)
    '۵', // 5 (U+06F5 - authentic IndoPak Quranic 5)
    '٦', // 6 (U+0666 - authentic IndoPak Quranic 6)
    '۷', // 7 (U+06F7 - authentic IndoPak Quranic 7)
    '۸', // 8 (U+06F8)
    '۹', // 9 (U+06F9)
  ];

  static String format(int number) {
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? digits[digit] : char;
    }).join('');
  }
}
