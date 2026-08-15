import 'package:equatable/equatable.dart';

class WordLayoutData extends Equatable {
  final int id;
  final String mushaf; // '15_line' | '16_line'
  final int page;
  final int line;
  final int surah;
  final int ayah;
  final int wordPos;
  final String wordId; // 'surah:ayah:word_pos'
  final String glyphCode;
  final String fontFile;

  const WordLayoutData({
    required this.id,
    required this.mushaf,
    required this.page,
    required this.line,
    required this.surah,
    required this.ayah,
    required this.wordPos,
    required this.wordId,
    required this.glyphCode,
    required this.fontFile,
  });

  factory WordLayoutData.fromMap(Map<String, dynamic> map) {
    return WordLayoutData(
      id: map['id'] as int? ?? 0,
      mushaf: map['mushaf'] as String? ?? '15_line',
      page: map['page'] as int? ?? 1,
      line: map['line'] as int? ?? 1,
      surah: map['surah'] as int? ?? 1,
      ayah: map['ayah'] as int? ?? 1,
      wordPos: map['word_pos'] as int? ?? 1,
      wordId: map['word_id'] as String? ?? '',
      glyphCode: map['glyph_code'] as String? ?? '',
      fontFile: map['font_file'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mushaf': mushaf,
      'page': page,
      'line': line,
      'surah': surah,
      'ayah': ayah,
      'word_pos': wordPos,
      'word_id': wordId,
      'glyph_code': glyphCode,
      'font_file': fontFile,
    };
  }

  @override
  List<Object?> get props => [id, wordId, mushaf, page, line];
}

class MushafLineData {
  final int lineNumber;
  final List<WordLayoutData> words;

  const MushafLineData({
    required this.lineNumber,
    required this.words,
  });
}

class MushafPageData {
  final int pageNumber;
  final String mushafType; // '15_line' | '16_line'
  final List<MushafLineData> lines;
  final int surahNumber;
  final int juzNumber;

  const MushafPageData({
    required this.pageNumber,
    required this.mushafType,
    required this.lines,
    required this.surahNumber,
    required this.juzNumber,
  });
}
