import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/arabic_numerals.dart';
import '../../../data/indopak_glyph_mapper.dart';
import '../../../data/models/mushaf_page_model.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/ruku_data.dart';
import 'ayah_end_symbol.dart';
import 'indopak_ruku_marginal_badge.dart';

class MushafPageWidget extends ConsumerStatefulWidget {
  final int pageNumber;
  final String mushafType; // '15_line' | '16_line'
  final bool isMarkMistakesMode;
  final Set<String> markedWordIds;
  final Function(String wordId) onToggleWordMistake;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    required this.mushafType,
    required this.isMarkMistakesMode,
    required this.markedWordIds,
    required this.onToggleWordMistake,
  });

  @override
  ConsumerState<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends ConsumerState<MushafPageWidget> {
  bool _loading = true;
  List<MushafLineData> _lines = [];
  int _juzNumber = 1;
  int _surahNumber = 1;
  String _surahNameArabic = '';
  int _manzilNumber = 1;

  static const List<String> kJuzNamesArabic = [
    'الٓمّٓ ۱',
    'سَیَقُوْلُ ۲',
    'تِلْكَ الرُّسُلُ ۳',
    'لَنْ تَنَالُوا ٤',
    'وَالْمُحْصَنٰتُ ۵',
    'لَا یُحِبُّ اللّٰهُ ٦',
    'وَاِذَا سَمِعُوْا ۷',
    'وَلَوْ اَنَّنَا ۸',
    'قَالَ الْمَلَاُ ۹',
    'وَاعْلَمُوْۤا ۱۰',
    'یَعْتَذِرُوْنَ ۱۱',
    'وَمَا مِنْ دَآبَّةٍ ۱۲',
    'وَمَاۤ اُبَرِّئُ ۱۳',
    'رُبَمَا ۱٤',
    'سُبْحٰنَ الَّذِیْۤ ۱۵',
    'قَالَ اَلَمْ ۱٦',
    'اقْتَرَبَ ۱۷',
    'قَدْ اَفْلَحَ ۱۸',
    'وَقَالَ الَّذِیْنَ ۱۹',
    'اَمَّنْ خَلَقَ ۲۰',
    'اتْلُ مَاۤ اُوْحِیَ ۲۱',
    'وَمَنْ یَّقْنُتْ ۲۲',
    'وَمَا لِیَ ۲۳',
    'فَمَنْ اَظْلَمُ ۲٤',
    'اِلَیْهِ یُرَدُّ ۲۵',
    'حٰمٓ ۲٦',
    'قَالَ فَمَا خَطْبُكُمْ ۲۷',
    'قَدْ سَمِعَ اللّٰهُ ۲۸',
    'تَبٰرَكَ الَّذِیْ ۲۹',
    'عَمَّ ۳۰',
  ];

  @override
  void initState() {
    super.initState();
    _loadPageContent();
  }

  @override
  void didUpdateWidget(covariant MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.mushafType != widget.mushafType) {
      _loadPageContent();
    }
  }

  static int _toInt(dynamic v, [int defaultValue = 0]) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final str = v.toString().trim();
    return int.tryParse(str) ?? defaultValue;
  }

  static String _toStr(dynamic v) => v?.toString() ?? '';

  static String _sanitizeWordText(String text) => IndoPakGlyphMapper.sanitize(text);

  int _getManzil(int surah) {
    if (surah <= 4) return 1;
    if (surah <= 9) return 2;
    if (surah <= 16) return 3;
    if (surah <= 25) return 4;
    if (surah <= 36) return 5;
    if (surah <= 49) return 6;
    return 7;
  }

  Future<void> _loadPageContent() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);

    final layoutRows = await repo.getMushafPageWords(widget.pageNumber, widget.mushafType);
    if (layoutRows.isNotEmpty) {
      final Map<int, List<WordLayoutData>> lineGroups = {};
      for (final row in layoutRows) {
        final w = WordLayoutData(
          id: _toInt(row['id']),
          mushaf: _toStr(row['mushaf']),
          page: _toInt(row['page']),
          line: _toInt(row['line']),
          surah: _toInt(row['surah']),
          ayah: _toInt(row['ayah']),
          wordPos: _toInt(row['word_pos']),
          wordId: _toStr(row['word_id']),
          glyphCode: _toStr(row['glyph_code']),
          fontFile: _toStr(row['font_file']),
        );
        lineGroups.putIfAbsent(w.line, () => []).add(w);
      }

      final sortedLines = lineGroups.keys.toList()..sort();
      final List<MushafLineData> dbLines = sortedLines.map((lineNum) {
        final words = lineGroups[lineNum]!;
        words.sort((a, b) => a.wordPos.compareTo(b.wordPos));
        return MushafLineData(lineNumber: lineNum, words: words);
      }).toList();

      WordLayoutData? firstRealWord;
      for (final line in dbLines) {
        final realWords = line.words.where((w) => w.ayah > 0).toList();
        if (realWords.isNotEmpty) {
          firstRealWord = realWords.first;
          break;
        }
      }
      firstRealWord ??= dbLines.first.words.first;

      _surahNumber = firstRealWord.surah;
      _surahNameArabic = (_surahNumber >= 1 && _surahNumber <= 114)
          ? kSurahList[_surahNumber - 1].nameArabic
          : '';
      _manzilNumber = _getManzil(_surahNumber);

      if (firstRealWord.ayah > 0) {
        final firstAyah = await repo.getAyah(_surahNumber, firstRealWord.ayah);
        _juzNumber = firstAyah?.juz ?? 1;
      }

      if (mounted) {
        setState(() {
          _lines = dbLines;
          _loading = false;
        });
      }
      return;
    }

    final ayahs = await repo.getAyahsByPage(widget.pageNumber);
    if (ayahs.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _juzNumber = ayahs.first.juz;
    _surahNumber = ayahs.first.surah;
    _surahNameArabic = kSurahList[_surahNumber - 1].nameArabic;
    _manzilNumber = _getManzil(_surahNumber);

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFFFBF9F4),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF111111), strokeWidth: 2),
        ),
      );
    }

    final juzName = (_juzNumber >= 1 && _juzNumber <= 30)
        ? kJuzNamesArabic[_juzNumber - 1]
        : 'الجزء ${ArabicNumerals.format(_juzNumber)}';

    return Container(
      color: const Color(0xFFFBF9F4), // Authentic warm antique paper
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // ── Main Page Content with Left Marginal Ruku Column ────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Left Margin (OUTSIDE border): Ruku Cartouche Badges ──
                    SizedBox(
                      width: 22,
                      child: Column(
                        children: [
                          // Spacer matching top header bar height (~28px)
                          const SizedBox(height: 28),
                          // Vertical list of Ruku Badges aligned with lines
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _lines.map((line) {
                                  // Check if line contains a verse-end marker of a Ruku
                                  RukuInfo? rukuInfo;
                                  for (final word in line.words) {
                                    if (word.ayah > 0) {
                                      final isVerseEnd = (word.wordId.endsWith(':end') ||
                                              word.glyphCode.contains('﴿') ||
                                              (word.glyphCode.contains('\u06DF') ||
                                                  word.glyphCode.codeUnits.any((u) => u >= 0xF500 && u <= 0xF5FF))) &&
                                          !word.glyphCode.contains(RegExp(r'[\u0621-\u064A\u0671-\u06D3]'));

                                      if (isVerseEnd) {
                                        final info = RukuData.getRukuEndInfo(word.surah, word.ayah);
                                        if (info != null) {
                                          rukuInfo = info;
                                          break;
                                        }
                                      }
                                    }
                                  }

                                  return Expanded(
                                    child: Center(
                                      child: rukuInfo != null
                                          ? FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: IndoPakRukuMarginalBadge(rukuInfo: rukuInfo),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 2),

                    // ── 2. Authentic Double-Ruled Page Frame (Full-Width Justified) ──
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1F1F1F), width: 0.9), // Outer hairline
                          borderRadius: BorderRadius.circular(3),
                        ),
                        padding: const EdgeInsets.all(2.5), // Frame Gutter
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1F1F1F), width: 1.6), // Inner solid border
                          ),
                          child: Column(
                            children: [
                              // ── Top Header Bar (Surah Name, Page Number, Juz Title) ──
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F), width: 1.0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Top Left: Surah Reference (e.g. البقرة ۲)
                                    Text(
                                      '$_surahNameArabic ${ArabicNumerals.format(_surahNumber)}',
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111111),
                                        height: 1.1,
                                      ),
                                    ),

                                    // Top Center: Page Number in Eastern Arabic Numerals (e.g. ۵)
                                    Text(
                                      ArabicNumerals.format(widget.pageNumber),
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111111),
                                        height: 1.1,
                                      ),
                                    ),

                                    // Top Right: Juz / Para Title with Crown Flourish (e.g. الم ۱)
                                    Text(
                                      juzName,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111111),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Text Content Area (15 or 16 Lines: FULL JUSTIFIED with SCALE-DOWN PROTECTION) ──
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (ctx, textConstraints) {
                                    final double availableWidth = textConstraints.maxWidth - 12;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: _lines.map((line) {
                                          return Expanded(
                                            child: Center(
                                              child: _buildLine(line, availableWidth),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    // ── 3. Right Margin (Symmetric Balance to Left Margin) ──
                    const SizedBox(width: 22),
                  ],
                ),
              ),

              // ── Bottom Footer: Manzil Indicator (منزل X) ────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'مَنْزِل ${ArabicNumerals.format(_manzilNumber)}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLine(MushafLineData line, double availableWidth) {
    final surahNameWord = line.words.where((w) => w.wordId.startsWith('surah_name:')).firstOrNull;
    final basmallahWord = line.words.where((w) => w.wordId.startsWith('basmallah:')).firstOrNull;
    final ayahWords = line.words.where((w) => !w.wordId.startsWith('surah_name:') && !w.wordId.startsWith('basmallah:')).toList();

    // If line is exclusively headers
    if (ayahWords.isEmpty && (surahNameWord != null || basmallahWord != null)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (surahNameWord != null) _buildSurahNameLine(surahNameWord),
            if (basmallahWord != null) _buildBasmallahLine(basmallahWord),
          ],
        ),
      );
    }

    // If line contains both headers and ayah words
    if (surahNameWord != null || basmallahWord != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (surahNameWord != null) _buildSurahNameLine(surahNameWord),
          if (basmallahWord != null) _buildBasmallahLine(basmallahWord),
          if (ayahWords.isNotEmpty)
            SizedBox(
              width: availableWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Container(
                  constraints: BoxConstraints(minWidth: availableWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: ayahWords.map((word) => _buildWord(word)).toList(),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Standard Quranic Line: 100% Full-Width Justified with automatic scale-down protection
    return SizedBox(
      width: availableWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(minWidth: availableWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: line.words.map((word) => _buildWord(word)).toList(),
          ),
        ),
      ),
    );
  }

  // ── Surah Name Header (Decorative lithograph box) ──────────────────────────
  Widget _buildSurahNameLine(WordLayoutData word) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1F1F1F), width: 1.3),
        borderRadius: BorderRadius.circular(3),
        color: const Color(0xFFFAF6EB),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1.5),
      child: Text(
        'سُورَةُ ${word.glyphCode}',
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111111),
          height: 1.1,
        ),
      ),
    );
  }

  // ── Basmallah Line (Centered authentic ink) ────────────────────────────────
  Widget _buildBasmallahLine(WordLayoutData word) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        word.glyphCode,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111111),
          height: 1.1,
        ),
      ),
    );
  }

  static (String baseWord, String waqfMark) _splitWordAndWaqf(String rawText) {
    if (rawText.isEmpty) return ('', '');

    // Common Arabic Waqf / Stop mark characters:
    // ؕ (\u0615), ؗ (\u0617), ۖ (\u06D6), ۗ (\u06D7), ۘ (\u06D8), ۙ (\u06D9), ۚ (\u06DA), ۛ (\u06DB), ۜ (\u06DC), ۬ (\u06EC), ۠ (\u06E0), ۦ (\u06E6)
    const waqfChars = {
      '\u0615', '\u0617', '\u06D6', '\u06D7', '\u06D8', '\u06D9',
      '\u06DA', '\u06DB', '\u06DC', '\u06EC', '\u06E0', '\u06E6'
    };

    final parts = rawText.trimRight().split(' ');
    if (parts.length > 1) {
      final lastPart = parts.sublist(1).join(' ');
      if (lastPart.split('').any((c) => waqfChars.contains(c))) {
        return (parts[0], lastPart.replaceAll(' ', ''));
      }
    }

    final chars = rawText.split('');
    final waqfList = <String>[];
    while (chars.isNotEmpty && (waqfChars.contains(chars.last) || chars.last == ' ')) {
      final c = chars.removeLast();
      if (c != ' ') {
        waqfList.insert(0, c);
      }
    }

    if (waqfList.isNotEmpty && chars.isNotEmpty) {
      return (chars.join('').trimRight(), waqfList.join(''));
    }

    return (rawText, '');
  }

  // ── Word Token & Inline Ayah Badge ─────────────────────────────────────────
  Widget _buildWord(WordLayoutData word) {
    final isMarked = widget.markedWordIds.contains(word.wordId);

    // Check if this token is a standalone Verse End marker (not a word with ligatures)
    final isVerseEnd = (word.wordId.endsWith(':end') ||
            word.glyphCode.contains('﴿') ||
            (word.glyphCode.contains('\u06DF') ||
                word.glyphCode.codeUnits.any((u) => u >= 0xF500 && u <= 0xF5FF))) &&
        !word.glyphCode.contains(RegExp(r'[\u0621-\u064A\u0671-\u06D3]'));

    if (isVerseEnd && word.ayah > 0) {
      String waqfMark = '';
      final match = RegExp(r'[\u06D6-\u06DC\u06DF-\u06E8]').firstMatch(word.glyphCode);
      if (match != null) {
        waqfMark = match.group(0) ?? '';
      }

      final rukuInfo = RukuData.getRukuEndInfo(word.surah, word.ayah);

      return AyahEndSymbol(
        ayahNumber: word.ayah,
        waqfMark: waqfMark,
        isRukuEnd: rukuInfo != null,
        color: const Color(0xFF111111),
      );
    }

    final hasFontFile = word.fontFile.isNotEmpty && word.fontFile != 'Amiri';
    final fontFamily = hasFontFile ? word.fontFile : (word.glyphCode.contains('﴿') ? 'Amiri' : 'Scheherazade New');
    final double fontSize = hasFontFile ? 20 : (word.glyphCode.contains('﴿') ? 13 : (widget.mushafType == '16_line' ? 15.5 : 17.0));

    // Sanitize non-standard PUA ligature glyphs so they render cleanly in standard fonts without tofu [] boxes
    final sanitizedText = hasFontFile ? word.glyphCode : _sanitizeWordText(word.glyphCode);
    final (baseWord, waqfMark) = _splitWordAndWaqf(sanitizedText);

    Widget wordTextWidget;
    if (waqfMark.isEmpty) {
      wordTextWidget = Text(
        baseWord,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: word.glyphCode.contains('﴿') ? FontWeight.bold : FontWeight.normal,
          color: isMarked ? const Color(0xFFD32F2F) : const Color(0xFF111111),
          height: 1.25,
        ),
      );
    } else {
      wordTextWidget = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Base word in pure RTL
          Text(
            baseWord,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: word.glyphCode.contains('﴿') ? FontWeight.bold : FontWeight.normal,
              color: isMarked ? const Color(0xFFD32F2F) : const Color(0xFF111111),
              height: 1.25,
            ),
          ),
          // Waqf stop sign exactly centered within the same line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Text(
              waqfMark,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
                height: 1.25,
              ),
            ),
          ),
        ],
      );
    }

    Widget wordChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      decoration: BoxDecoration(
        color: isMarked ? Colors.red.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: isMarked
            ? const Border(bottom: BorderSide(color: Color(0xFFD32F2F), width: 2.2))
            : null,
      ),
      child: wordTextWidget,
    );

    if (widget.isMarkMistakesMode && !word.glyphCode.contains('﴿')) {
      return InkWell(
        onTap: () => widget.onToggleWordMistake(word.wordId),
        borderRadius: BorderRadius.circular(3),
        child: wordChild,
      );
    }

    return wordChild;
  }
}
