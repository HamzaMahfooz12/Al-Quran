import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/mushaf_page_model.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/ruku_data.dart';
import 'ayah_end_symbol.dart';

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
  String _surahName = '';

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

  String _toArabicIndic(int number) {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? digits[digit] : char;
    }).join('');
  }

  static int _toInt(dynamic v, [int defaultValue = 0]) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final str = v.toString().trim();
    return int.tryParse(str) ?? defaultValue;
  }

  static String _toStr(dynamic v) => v?.toString() ?? '';

  Future<void> _loadPageContent() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);

    // Try to load layout data from database
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

      // Bug fix: skip surah_name/basmallah lines (ayah==0) to find a real ayah
      // for correct Juz number lookup
      WordLayoutData? firstRealWord;
      for (final line in dbLines) {
        final realWords = line.words.where((w) => w.ayah > 0).toList();
        if (realWords.isNotEmpty) {
          firstRealWord = realWords.first;
          break;
        }
      }
      // Fall back to the very first word if entire page is surah headers
      firstRealWord ??= dbLines.first.words.first;

      _surahNumber = firstRealWord.surah;
      _surahName = (_surahNumber >= 1 && _surahNumber <= 114)
          ? kSurahList[_surahNumber - 1].nameTransliteration
          : '';
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

    // Fetch actual ayahs from the SQLite database
    final ayahs = await repo.getAyahsByPage(widget.pageNumber);
    if (ayahs.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    _juzNumber = ayahs.first.juz;
    _surahNumber = ayahs.first.surah;
    _surahName = kSurahList[_surahNumber - 1].nameTransliteration;

    // Convert Uthmani Arabic ayahs into individual WordLayoutData list
    final List<WordLayoutData> allWords = [];
    int globalWordId = 0;

    for (final ayah in ayahs) {
      // Split ayah text into words
      final rawWords = ayah.arabicText.trim().split(RegExp(r'\s+'));
      
      // Clean Uthmani Bismillah from start of verse 1 (except Surah 1) for layout neatness
      List<String> cleanWords = List.from(rawWords);
      if (ayah.ayahNumber == 1 && ayah.surah != 1) {
        // Strip Bismillah prefix if present
        final text = cleanWords.join(' ');
        final bare = text.replaceAll(RegExp(r'[\u064B-\u065F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06EF\u0670\u06E1\uFC60-\uFC62]'), '');
        final m = RegExp(r'^بسم\s*[اٱ]لله\s*[اٱ]لرحمن\s*[اٱ]لرحيم\s*').firstMatch(bare);
        if (m != null) {
          // Skip first 4 words of Bismillah
          if (cleanWords.length > 4) {
            cleanWords = cleanWords.sublist(4);
          }
        }
      }

      for (int wIdx = 0; wIdx < cleanWords.length; wIdx++) {
        final text = cleanWords[wIdx];
        if (text.isEmpty) continue;

        allWords.add(WordLayoutData(
          id: globalWordId++,
          mushaf: widget.mushafType,
          page: widget.pageNumber,
          line: 0,
          surah: ayah.surah,
          ayah: ayah.ayahNumber,
          wordPos: wIdx + 1,
          wordId: '${ayah.surah}:${ayah.ayahNumber}:${wIdx + 1}',
          glyphCode: text,
          fontFile: 'Amiri',
        ));
      }

      // Append verse end indicator glyph (e.g. ﴿۱﴾)
      allWords.add(WordLayoutData(
        id: globalWordId++,
        mushaf: widget.mushafType,
        page: widget.pageNumber,
        line: 0,
        surah: ayah.surah,
        ayah: ayah.ayahNumber,
        wordPos: cleanWords.length + 1,
        wordId: '${ayah.surah}:${ayah.ayahNumber}:end',
        glyphCode: ' ﴿${_toArabicIndic(ayah.ayahNumber)}﴾ ',
        fontFile: 'Amiri',
      ));
    }

    // Distribute words evenly across lines
    final lineCount = widget.mushafType == '15_line' ? 15 : 16;
    final List<MushafLineData> distributedLines = [];
    int start = 0;

    for (int i = 0; i < lineCount; i++) {
      int remainingLines = lineCount - i;
      int remainingWords = allWords.length - start;
      int chunkSize = (remainingWords / remainingLines).round();

      final end = (start + chunkSize).clamp(0, allWords.length);
      final lineWords = allWords.sublist(start, end).map((w) {
        return WordLayoutData(
          id: w.id,
          mushaf: w.mushaf,
          page: w.page,
          line: i + 1, // assign final line position
          surah: w.surah,
          ayah: w.ayah,
          wordPos: w.wordPos,
          wordId: w.wordId,
          glyphCode: w.glyphCode,
          fontFile: w.fontFile,
        );
      }).toList();

      distributedLines.add(MushafLineData(
        lineNumber: i + 1,
        words: lineWords,
      ));
      start = end;
    }

    if (mounted) {
      setState(() {
        _lines = distributedLines;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFFFFFDF7),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1B4332)),
        ),
      );
    }

    return Container(
      color: const Color(0xFFFFFDF7), // Soft cream page background (Madani Mushaf style)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Header Bar — Surah Name & Juz Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Juz $_juzNumber',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
              ),
              Text(
                _surahName,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332)),
              ),
              Text(
                'Page ${widget.pageNumber}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
              ),
            ],
          ),
          const Divider(height: 12, color: Color(0xFFD4A843)),

          // Lines View
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _lines.map((line) => _buildLine(line)).toList(),
              ),
            ),
          ),

          const Divider(height: 12, color: Color(0xFFD4A843)),
          // Footer Page Number
          Text(
            '${widget.pageNumber}',
            style: GoogleFonts.amiri(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332)),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(MushafLineData line) {
    // Check if line contains header elements (surah_name or basmallah)
    final surahNameWord = line.words.where((w) => w.wordId.startsWith('surah_name:')).firstOrNull;
    final basmallahWord = line.words.where((w) => w.wordId.startsWith('basmallah:')).firstOrNull;
    final ayahWords = line.words.where((w) => !w.wordId.startsWith('surah_name:') && !w.wordId.startsWith('basmallah:')).toList();

    // If line is exclusively headers (surah_name and/or basmallah)
    if (ayahWords.isEmpty && (surahNameWord != null || basmallahWord != null)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (surahNameWord != null) _buildSurahNameLine(surahNameWord),
          if (basmallahWord != null) _buildBasmallahLine(basmallahWord),
        ],
      );
    }

    // If line has headers followed by ayah words
    if (surahNameWord != null || basmallahWord != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (surahNameWord != null) _buildSurahNameLine(surahNameWord),
          if (basmallahWord != null) _buildBasmallahLine(basmallahWord),
          if (ayahWords.isNotEmpty)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: ayahWords.map((word) => _buildWord(word)).toList(),
              ),
            ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: line.words.map((word) => _buildWord(word)).toList(),
      ),
    );
  }

  // ── Surah Name Header (decorative box) ─────────────────────────────────────
  Widget _buildSurahNameLine(WordLayoutData word) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4A843), width: 1.5),
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E7), Color(0xFFFFF3D0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Text(
          'سُورَةُ ${word.glyphCode}',
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B4F00),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Basmallah Line ─────────────────────────────────────────────────────────
  Widget _buildBasmallahLine(WordLayoutData word) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          word.glyphCode,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  Widget _buildWord(WordLayoutData word) {
    final isMarked = widget.markedWordIds.contains(word.wordId);

    // Check if this word represents an Ayah End Marker
    final isVerseEnd = word.wordId.endsWith(':end') ||
        word.glyphCode.contains('﴿') ||
        word.glyphCode.codeUnits.any((u) => u >= 0xF500 && u <= 0xF6FE);

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
        rukuInfo: rukuInfo,
      );
    }

    final hasFontFile = word.fontFile.isNotEmpty && word.fontFile != 'Amiri';
    final fontFamily = hasFontFile ? word.fontFile : (word.glyphCode.contains('﴿') ? 'Amiri' : 'Scheherazade New');
    final double fontSize = hasFontFile ? 26 : (word.glyphCode.contains('﴿') ? 18 : 22);

    Widget wordChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: isMarked ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isMarked
            ? const Border(bottom: BorderSide(color: Color(0xFFE53935), width: 2.5))
            : null,
      ),
      child: Text(
        word.glyphCode,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: word.glyphCode.contains('﴿') ? FontWeight.bold : FontWeight.normal,
          color: isMarked
              ? const Color(0xFFD32F2F)
              : (word.glyphCode.contains('﴿') ? const Color(0xFFD4A843) : const Color(0xFF1A1A1A)),
          height: 1.5,
        ),
      ),
    );

    if (widget.isMarkMistakesMode && !word.glyphCode.contains('﴿')) {
      return InkWell(
        onTap: () => widget.onToggleWordMistake(word.wordId),
        borderRadius: BorderRadius.circular(4),
        child: wordChild,
      );
    }

    return wordChild;
  }
}
