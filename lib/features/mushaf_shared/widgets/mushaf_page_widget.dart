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
import 'indopak_sajda_marginal_badge.dart';
import 'surah_header_cartouche.dart';
import 'waqf_helper.dart';

class MushafPageWidget extends ConsumerStatefulWidget {
  final int pageNumber;
  final String mushafType; // '15_line' | '16_line'
  final bool isMarkMistakesMode;
  final Set<String> markedWordIds;
  final Function(String wordId) onToggleWordMistake;
  final String? activePlayingWordId;
  final String? activePlayingVerseKey;
  final Function(int surah, int ayah)? onWordTap;
  final Function(int surah, int ayah)? onWordDoubleTap;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    required this.mushafType,
    required this.isMarkMistakesMode,
    required this.markedWordIds,
    required this.onToggleWordMistake,
    this.activePlayingWordId,
    this.activePlayingVerseKey,
    this.onWordTap,
    this.onWordDoubleTap,
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: const Color(0xFFFBF9F4), // Authentic warm antique paper
      padding: EdgeInsets.fromLTRB(4, 3, 4, 8 + bottomInset),
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
                                  // Check if line contains a verse-end marker of a Ruku or Sajda
                                  RukuInfo? rukuInfo;
                                  bool isSajdaLine = false;

                                  for (final word in line.words) {
                                    if (word.ayah > 0) {
                                      final isVerseEnd = (word.wordId.endsWith(':end') ||
                                              word.glyphCode.contains('﴿') ||
                                              (word.glyphCode.contains('\u06DF') ||
                                                  word.glyphCode.codeUnits.any((u) => u >= 0xF500 && u <= 0xF5FF))) &&
                                          !word.glyphCode.contains(RegExp(r'[\u0621-\u064A\u0671-\u06D3]'));

                                      if (isVerseEnd) {
                                        final key = '${word.surah}:${word.ayah}';
                                        const sajdas = {
                                          '7:206', '13:15', '16:50', '17:109', '19:58', '22:18', '22:77',
                                          '25:60', '27:26', '32:15', '38:24', '41:38', '53:62', '84:21', '96:19'
                                        };
                                        if (sajdas.contains(key)) {
                                          isSajdaLine = true;
                                        }

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
                                      child: isSajdaLine
                                          ? const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: IndoPakSajdaMarginalBadge(),
                                            )
                                          : (rukuInfo != null
                                              ? FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: IndoPakRukuMarginalBadge(rukuInfo: rukuInfo),
                                                )
                                              : null),
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

                    // ── 2. Authentic Double-Ruled Page Frame (Themed Midnight Sapphire & Gold) ──
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1E3A60), width: 1.2), // Outer Midnight Sapphire hairline
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(2.5), // Frame Gutter
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD97706), width: 1.4), // Inner Gold solid border
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            children: [
                              // ── Top Header Bar (Surah Name, Page Number, Juz Title) ──
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.0),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0F4FA), // Soft tinted sapphire background
                                  border: Border(bottom: BorderSide(color: Color(0xFF1E3A60), width: 1.0)),
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
                                        color: Color(0xFF0F172A),
                                        height: 1.1,
                                      ),
                                    ),

                                    // Top Center: Page Number in Eastern Arabic Numerals (e.g. ۵)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFC5D5E8), width: 0.8),
                                      ),
                                      child: Text(
                                        ArabicNumerals.format(widget.pageNumber),
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A60),
                                          height: 1.1,
                                        ),
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
                                        color: Color(0xFF0F172A),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5D5E8), width: 0.8),
                  ),
                  child: Text(
                    'مَنْزِل ${ArabicNumerals.format(_manzilNumber)}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A60),
                      height: 1.0,
                    ),
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

    // ── If line is exclusively headers ──
    if (ayahWords.isEmpty && (surahNameWord != null || basmallahWord != null)) {
      if (widget.mushafType == '16_line') {
        if (surahNameWord != null && basmallahWord != null) {
          // 1-line budget: Bismillah, Surah details, & Verses/Rukus are integrated in the SAME single line!
          final sNum = surahNameWord.surah;
          final sName = surahNameWord.glyphCode.isNotEmpty ? surahNameWord.glyphCode : _surahNameArabic;
          final bText = basmallahWord.glyphCode.isNotEmpty ? basmallahWord.glyphCode : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';
          return Center(
            child: SurahHeader16Widget(
              surahNumber: sNum,
              fallbackSurahName: sName,
              bismillahText: bText,
            ),
          );
        } else if (surahNameWord != null) {
          // 2-line layout: Line 1 is the Surah Cartouche ONLY
          return Center(child: _build15LineSurahHeader(surahNameWord));
        } else {
          // 2-line layout: Line 2 is the Bismillah line ONLY (never repeat SurahHeader16Widget)
          return Center(child: _build15LineBasmallah(basmallahWord!));
        }
      } else {
        // In 15-Line Mushaf: 2-line layout (Line 1 cartouche, Line 2 Bismillah)
        if (surahNameWord != null && basmallahWord != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _build15LineSurahHeader(surahNameWord),
                const SizedBox(height: 2),
                _build15LineBasmallah(basmallahWord),
              ],
            ),
          );
        } else if (surahNameWord != null) {
          return Center(child: _build15LineSurahHeader(surahNameWord));
        } else {
          return Center(child: _build15LineBasmallah(basmallahWord!));
        }
      }
    }

    // ── If line contains both headers and ayah words (e.g. Surah starts mid-page) ──
    if (surahNameWord != null || basmallahWord != null) {
      if (widget.mushafType == '16_line') {
        Widget headerWidget;
        if (surahNameWord != null && basmallahWord != null) {
          final sNum = surahNameWord.surah;
          final sName = surahNameWord.glyphCode.isNotEmpty ? surahNameWord.glyphCode : _surahNameArabic;
          final bText = basmallahWord.glyphCode.isNotEmpty ? basmallahWord.glyphCode : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';
          headerWidget = SurahHeader16Widget(
            surahNumber: sNum,
            fallbackSurahName: sName,
            bismillahText: bText,
          );
        } else if (surahNameWord != null) {
          headerWidget = _build15LineSurahHeader(surahNameWord);
        } else {
          headerWidget = _build15LineBasmallah(basmallahWord!);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            headerWidget,
            if (ayahWords.isNotEmpty) ...[
              const SizedBox(height: 2),
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
          ],
        );
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (surahNameWord != null) _build15LineSurahHeader(surahNameWord),
            if (basmallahWord != null) _build15LineBasmallah(basmallahWord),
            if (ayahWords.isNotEmpty) ...[
              const SizedBox(height: 2),
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
          ],
        );
      }
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

  // ── 15-Line Mushaf: Line 1 of 2 (Royal Illuminated Cartouche) ──────────────
  Widget _build15LineSurahHeader(WordLayoutData word) {
    final surahNum = (word.surah >= 1 && word.surah <= 114) ? word.surah : _surahNumber;
    final surahName = word.glyphCode.isNotEmpty ? word.glyphCode : _surahNameArabic;
    return SurahHeader15Widget(
      surahNumber: surahNum,
      fallbackSurahName: surahName,
    );
  }

  // ── 15-Line Mushaf: Line 2 of 2 (Dedicated Centered Bismillah) ─────────────
  Widget _build15LineBasmallah(WordLayoutData word) {
    return Bismillah15Widget(
      text: word.glyphCode.isNotEmpty ? word.glyphCode : 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
    );
  }


  static (String baseWord, String waqfMark) _splitWordAndWaqf(String rawText) {
    if (rawText.isEmpty) return ('', '');

    final parts = rawText.trimRight().split(' ');
    if (parts.length > 1) {
      final lastPart = parts.sublist(1).join(' ');
      if (lastPart.split('').any((c) => WaqfHelper.waqfChars.contains(c))) {
        return (parts[0], lastPart.replaceAll(' ', ''));
      }
    }

    final chars = rawText.split('');
    final waqfList = <String>[];
    while (chars.isNotEmpty && (WaqfHelper.waqfChars.contains(chars.last) || chars.last == ' ')) {
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
      final matches = RegExp(r'[\u0614\u0615\u0617\u06D6\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06E0\u06E2\u06E6\u06EA\u06EB\u06EC\u06ED]').allMatches(word.glyphCode);
      final waqfMark = matches.map((m) => m.group(0) ?? '').join('');

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
    final waqfItems = WaqfHelper.parseMarks(waqfMark);

    Widget wordTextWidget;
    if (waqfItems.isEmpty) {
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
        crossAxisAlignment: CrossAxisAlignment.start, // Top-align so waqf floats as superscript
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
          // Clean guaranteed spacing so stopping symbols NEVER touch or mix with the word
          const SizedBox(width: 3.5),
          // Layered stopping marks (stacked vertically above each other with clean spacing)
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < waqfItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 1.5), // Space between stacked layers
                  Text(
                    waqfItems[i].text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Scheherazade New',
                      fontFamilyFallback: const ['Amiri', 'Noto Nastaliq Urdu'],
                      fontSize: waqfItems.length > 1 ? 8.5 : 10.5,
                      fontWeight: FontWeight.bold,
                      color: waqfItems[i].color,
                      height: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final isWordActive = (widget.activePlayingWordId != null && widget.activePlayingWordId == word.wordId);
    final isVerseActive = (widget.activePlayingWordId == null &&
        widget.activePlayingVerseKey != null &&
        widget.activePlayingVerseKey == '${word.surah}:${word.ayah}');

    Color containerBgColor = Colors.transparent;
    BoxBorder? border;
    List<BoxShadow>? shadows;
    Widget currentWordChild = wordTextWidget;

    if (isMarked) {
      containerBgColor = Colors.red.withValues(alpha: 0.18);
      border = const Border(bottom: BorderSide(color: Color(0xFFD32F2F), width: 2.2));
    } else if (isWordActive) {
      containerBgColor = const Color(0xFFFFE082).withValues(alpha: 0.95); // Golden amber highlight
      border = Border.all(color: const Color(0xFFFFB300), width: 1.0);
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFB300).withValues(alpha: 0.35),
          blurRadius: 4,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isVerseActive) {
      containerBgColor = const Color(0xFFBFDBFE).withValues(alpha: 0.40); // Soft sapphire verse tint
    }

    Widget wordChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      decoration: BoxDecoration(
        color: containerBgColor,
        borderRadius: BorderRadius.circular(3.5),
        border: border,
        boxShadow: shadows,
      ),
      child: currentWordChild,
    );

    if (widget.isMarkMistakesMode && !word.glyphCode.contains('﴿')) {
      return InkWell(
        onTap: () => widget.onToggleWordMistake(word.wordId),
        borderRadius: BorderRadius.circular(3.5),
        child: wordChild,
      );
    } else if ((widget.onWordTap != null || widget.onWordDoubleTap != null) && word.surah > 0 && word.ayah > 0) {
      return InkWell(
        onTap: widget.onWordTap != null ? () => widget.onWordTap!(word.surah, word.ayah) : null,
        onDoubleTap: widget.onWordDoubleTap != null ? () => widget.onWordDoubleTap!(word.surah, word.ayah) : null,
        borderRadius: BorderRadius.circular(3.5),
        splashColor: const Color(0xFFFFE082).withValues(alpha: 0.3),
        child: wordChild,
      );
    }

    return wordChild;
  }
}
