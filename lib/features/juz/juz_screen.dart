// lib/features/juz/juz_screen.dart
// Juz reader — shows ONLY the ayahs within the selected Juz, grouped by Surah with headers.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ayah.dart';
import '../../data/models/edition.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';
import '../../services/audio_service.dart';
import '../../services/settings_service.dart';
import '../audio/audio_control_bar.dart';
import '../share/widgets/ayah_share_dialog.dart';
import '../tafseer/widgets/ayah_tafseer_modal.dart';
import '../shared/widgets/unified_ayah_card.dart';

// ── Juz metadata ──────────────────────────────────────────────────────────────
const _kJuzInfo = [
  {'name': 'Alif Laam Meem',        'arabic': 'الم'},
  {'name': 'Sayaqool',              'arabic': 'سَيَقُولُ'},
  {'name': 'Tilkar Rusul',          'arabic': 'تِلۡكَ ٱلرُّسُلُ'},
  {'name': 'Lan Tanaloo',           'arabic': 'لَن تَنَالُوا'},
  {'name': 'Wal Mohsanat',          'arabic': 'وَٱلۡمُحۡصَنَٰتُ'},
  {'name': 'La Yuhibbullah',        'arabic': 'لَّا يُحِبُّ ٱللَّهُ'},
  {'name': 'Wa Iza Samiu',          'arabic': 'وَإِذَا سَمِعُوا'},
  {'name': 'Wa Lau Annana',         'arabic': 'وَلَوۡ أَنَّنَا'},
  {'name': 'Qalal Malao',           'arabic': 'قَالَ ٱلۡمَلَأُ'},
  {'name': 'Wa Alamu',              'arabic': 'وَٱعۡلَمُوٓا'},
  {'name': 'Yatazeroon',            'arabic': 'يَعۡتَذِرُونَ'},
  {'name': 'Wa Ma Min Daabbah',     'arabic': 'وَمَا مِن دَآبَّةٍ'},
  {'name': 'Wa Ma Ubarrio',         'arabic': 'وَمَآ أُبَرِّئُ'},
  {'name': 'Rubama',                'arabic': 'رُّبَمَا'},
  {'name': 'Subhanallazi',          'arabic': 'سُبۡحَٰنَ ٱلَّذِي'},
  {'name': 'Qal Alam',              'arabic': 'قَالَ أَلَمۡ'},
  {'name': 'Iqtaraba',              'arabic': 'ٱقۡتَرَبَ'},
  {'name': 'Qad Aflaha',            'arabic': 'قَدۡ أَفۡلَحَ'},
  {'name': 'Wa Qalallazina',        'arabic': 'وَقَالَ ٱلَّذِينَ'},
  {'name': 'Amman Khalaq',          'arabic': 'أَمَّنۡ خَلَقَ'},
  {'name': 'Utlu Ma Oohiya',        'arabic': 'ٱتۡلُ مَآ أُوحِيَ'},
  {'name': 'Wa Manyaqnut',          'arabic': 'وَمَن يَقۡنُتۡ'},
  {'name': 'Wa Mali',               'arabic': 'وَمَالِيَ'},
  {'name': 'Faman Azlamu',          'arabic': 'فَمَنۡ أَظۡلَمُ'},
  {'name': 'Ilayhi Yuraddu',        'arabic': 'إِلَيۡهِ يُرَدُّ'},
  {'name': 'Ha Meem',               'arabic': 'حم'},
  {'name': 'Qala Fama Khatbukum',   'arabic': 'قَالَ فَمَا خَطۡبُكُمۡ'},
  {'name': 'Qad Sami Allah',        'arabic': 'قَدۡ سَمِعَ ٱللَّهُ'},
  {'name': 'Tabarakallazi',         'arabic': 'تَبَٰرَكَ ٱلَّذِي'},
  {'name': 'Amma Yatasaaloona',     'arabic': 'عَمَّ يَتَسَآءَلُونَ'},
];

// Juz boundary data — starting surah/ayah for each Juz (used for fallback fetching)
const _kJuzData = [
  {'surah': 2,  'ayah': 1},
  {'surah': 2,  'ayah': 142},
  {'surah': 2,  'ayah': 253},
  {'surah': 3,  'ayah': 92},
  {'surah': 4,  'ayah': 24},
  {'surah': 4,  'ayah': 148},
  {'surah': 5,  'ayah': 82},
  {'surah': 6,  'ayah': 111},
  {'surah': 7,  'ayah': 88},
  {'surah': 8,  'ayah': 41},
  {'surah': 9,  'ayah': 94},
  {'surah': 11, 'ayah': 6},
  {'surah': 12, 'ayah': 53},
  {'surah': 15, 'ayah': 1},
  {'surah': 17, 'ayah': 1},
  {'surah': 18, 'ayah': 75},
  {'surah': 21, 'ayah': 1},
  {'surah': 23, 'ayah': 1},
  {'surah': 25, 'ayah': 20},
  {'surah': 27, 'ayah': 60},
  {'surah': 29, 'ayah': 45},
  {'surah': 33, 'ayah': 31},
  {'surah': 36, 'ayah': 22},
  {'surah': 39, 'ayah': 32},
  {'surah': 41, 'ayah': 47},
  {'surah': 46, 'ayah': 1},
  {'surah': 51, 'ayah': 31},
  {'surah': 58, 'ayah': 1},
  {'surah': 67, 'ayah': 1},
  {'surah': 78, 'ayah': 1},
];

class JuzScreen extends ConsumerStatefulWidget {
  final int juzNumber; // 1–30

  const JuzScreen({super.key, required this.juzNumber});

  @override
  ConsumerState<JuzScreen> createState() => _JuzScreenState();
}

class _JuzScreenState extends ConsumerState<JuzScreen> {
  final _scrollCtrl = ScrollController();
  List<Ayah> _ayahs = [];
  Map<int, String> _translations = {};
  Map<int, String> _tafseers = {};
  bool _loading = true;

  Edition? _activeTranslationEdition;
  Edition? _activeTafseerEdition;

  bool _showTranslation = true;

  String _currentSurahName = '';
  int _currentSurahNumber = 0;
  Set<String> _bookmarkedAyahs = {};

  String get _juzName => _kJuzInfo[widget.juzNumber - 1]['name']!;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadJuzAyahs();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  static const Map<String, String> _localTafseerPaths = {
    // Arabic (8)
    'ar-tafsir-ibn-kathir': r'D:\AL Quran\tafssir\arabic\ar-tafsir-ibn-kathir.json',
    'ar-tafsir-al-tabari': r'D:\AL Quran\tafssir\arabic\ar-tafsir-al-tabari.json',
    'ar-tafseer-al-qurtubi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-qurtubi.json',
    'ar-tafseer-al-saddi': r'D:\AL Quran\tafssir\arabic\ar-tafseer-al-saddi.json',
    'asseraj-fi-bayan-gharib-alquran': r'D:\AL Quran\tafssir\arabic\asseraj-fi-bayan-gharib-alquran.json',
    'tafsir-ibn-abi-hatim': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-abi-hatim.json',
    'tafsir-ibn-uthaymeen': r'D:\AL Quran\tafssir\arabic\tafsir-ibn-uthaymeen.json',
    'tafsir-jalalayn': r'D:\AL Quran\tafssir\arabic\tafsir-jalalayn.json',

    // Urdu (5)
    'tafseer-ibn-e-kaseer-urdu': r'D:\AL Quran\tafssir\urdu\tafseer-ibn-e-kaseer-urdu.json',
    'tafsir-bayan-ul-quran': r'D:\AL Quran\tafssir\urdu\tafsir-bayan-ul-quran.json',
    'tafsir-as-saadi': r'D:\AL Quran\tafssir\urdu\tafsir-as-saadi.json',
    'tafsir-fe-zalul-quran-syed-qatab': r'D:\AL Quran\tafssir\urdu\tafsir-fe-zalul-quran-syed-qatab.json',
    'tazkiru-quran-ur': r'D:\AL Quran\tafssir\urdu\tazkiru-quran-ur.json',

    // English (5)
    'en-tafisr-ibn-kathir': r'D:\AL Quran\tafssir\english\en-tafisr-ibn-kathir.json',
    'Al-Mukhtasar': r'D:\AL Quran\tafssir\english\Al-Mukhtasar.json',
    'en-tafsir-maarif-ul-quran': r'D:\AL Quran\tafssir\english\en-tafsir-maarif-ul-quran.json',
    'tafsir-al-jalalayn': r'D:\AL Quran\tafssir\english\tafsir-al-jalalayn.json',
    'tazkirul-quran-en': r'D:\AL Quran\tafssir\english\tazkirul-quran-en.json',

    // Hindi (1)
    'hindi-mokhtasar': r'D:\AL Quran\tafssir\hindi\hindi-mokhtasar.json',
  };

  int _getGlobalAyahId(int surah, int ayah) {
    const counts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
      111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30,
      73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
      60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52,
      52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17,
      19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4,
      7, 3, 6, 3, 5, 4, 5, 6
    ];
    int total = 0;
    for (int i = 0; i < surah - 1; i++) {
      total += counts[i];
    }
    return total + ayah;
  }

  Future<void> _downloadAndSetEdition(Edition ed) async {
    final repo = ref.read(quranRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(
      content: Text('Downloading ${ed.name}...'),
      duration: const Duration(seconds: 3),
    ));

    try {
      final List<Map<String, dynamic>> contentRows = [];

      final localPath = _localTafseerPaths[ed.apiKey];
      if (localPath != null && File(localPath).existsSync()) {
        final jsonStr = await File(localPath).readAsString();
        final Map<String, dynamic> tafseerDict = json.decode(jsonStr);

        for (final entry in tafseerDict.entries) {
          final key = entry.key;
          final val = entry.value;
          // Only insert if entry contains actual commentary (skip pointer aliases like "3:1")
          if (val is! Map) continue;
          final rawText = (val['text'] ?? '').toString();
          if (rawText.trim().isEmpty) continue;
          final text = _cleanHtmlText(rawText);
          if (text.isEmpty) continue;

          final parts = key.split(':');
          if (parts.length == 2) {
            final surah = int.tryParse(parts[0]);
            final ayah = int.tryParse(parts[1]);
            if (surah != null && ayah != null) {
              final globalAyahId = _getGlobalAyahId(surah, ayah);
              contentRows.add({
                'ayah_id': globalAyahId,
                'edition_id': ed.id,
                'text': text,
              });
            }
          }
        }
      } else if (ed.type != 'tafseer') {
        final dio = Dio();
        final response = await dio.get('https://api.alquran.cloud/v1/quran/${ed.apiKey}');
        if (response.data != null && response.data['status'] == 'OK') {
          final surahs = (response.data['data']['surahs'] as List).cast<Map<String, dynamic>>();
          for (final surah in surahs) {
            final ayahs = (surah['ayahs'] as List).cast<Map<String, dynamic>>();
            for (final ayah in ayahs) {
              contentRows.add({
                'ayah_id': ayah['number'],
                'edition_id': ed.id,
                'text': ayah['text'],
              });
            }
          }
        }
      }

      if (contentRows.isNotEmpty) {
        await repo.insertEditionContent(contentRows);
        await repo.markEditionDownloaded(ed.id);
        if (mounted) {
          messenger.showSnackBar(SnackBar(
            content: Text('${ed.name} downloaded successfully!'),
            backgroundColor: AppTheme.primary,
          ));
          await _loadJuzAyahs();
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _cleanHtmlText(String text) {
    var s = text.replaceAll(RegExp(r'</p>|<br\s*/?>|</div>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    s = s.replaceAll('&nbsp;', ' ').replaceAll('&quot;', '"').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&#39;', "'");
    s = s.replaceAll(RegExp(r'p\s+class="[^"]*"|div\s+lang="[^"]*"'), '');
    s = s.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    return s.trim();
  }

  Future<void> _showEditionSelector(String type) async {
    final repo = ref.read(quranRepositoryProvider);
    final allEditions = await repo.getAllEditions(type: type);

    final currentLang = type == 'translation'
        ? (_activeTranslationEdition?.language.toLowerCase() ?? 'ur')
        : (_activeTafseerEdition?.language.toLowerCase() ?? 'ar');
    String selectedLangFilter = currentLang;

    if (!mounted) return;

    // Background sync without blocking the UI
    unawaited(repo.fetchAndSyncApiEditions(type).catchError((_) => <Edition>[]));

    // Pre-organize and pre-sort by language
    final Map<String, List<Edition>> langMap = {};
    for (final ed in allEditions) {
      final lang = ed.language.toLowerCase();
      langMap.putIfAbsent(lang, () => []).add(ed);
    }
    for (final list in langMap.values) {
      list.sort((a, b) {
        if (a.isAvailable && !b.isAvailable) return -1;
        if (!a.isAvailable && b.isAvailable) return 1;
        return a.name.compareTo(b.name);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = langMap[selectedLangFilter] ??
                (selectedLangFilter == 'all' ? allEditions : <Edition>[]);

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type == 'translation' ? 'Select Translation' : 'Select Tafseer',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLangChip('Arabic (AR)', 'ar', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('Urdu (UR)', 'ur', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('English (EN)', 'en', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                          _buildLangChip('Hindi (HI)', 'hi', selectedLangFilter, (lang) {
                            setModalState(() => selectedLangFilter = lang);
                          }),
                        ],
                      ),
                    ),

                    const Divider(height: 20),

                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Text(
                                'No editions found for this language.',
                                style: GoogleFonts.inter(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final ed = filteredList[index];
                                final isSelected = type == 'translation'
                                    ? _activeTranslationEdition?.id == ed.id
                                    : _activeTafseerEdition?.id == ed.id;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  title: Text(ed.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text('${ed.language.toUpperCase()} • ${ed.apiKey}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 24)
                                      : (ed.isAvailable
                                          ? const Icon(Icons.radio_button_unchecked, color: AppTheme.textMuted, size: 22)
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.cloud_download_outlined, color: AppTheme.primary, size: 20),
                                                const SizedBox(width: 4),
                                                Text('Download', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                              ],
                                            )),
                                  onTap: () async {
                                    Navigator.pop(ctx);

                                    if (type == 'translation') {
                                      setState(() {
                                        _activeTranslationEdition = ed;
                                        _showTranslation = true;
                                      });
                                      await ref.read(settingsServiceProvider).setSelectedTranslationId(ed.id);
                                    } else {
                                      setState(() {
                                        _activeTafseerEdition = ed;
                                      });
                                      await ref.read(settingsServiceProvider).setSelectedTafseerEditionId(ed.id);
                                    }

                                    await _loadJuzAyahs();

                                    if (!ed.isAvailable) {
                                      _downloadAndSetEdition(ed);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangChip(String label, String code, String current, Function(String) onSelect) {
    final isSelected = current == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primarySurface,
        checkmarkColor: AppTheme.primary,
        onSelected: (_) => onSelect(code),
      ),
    );
  }

  Future<void> _showMutashabihatBottomSheet(Ayah ayah) async {
    final repo = ref.read(quranRepositoryProvider);
    final pairs = await repo.getMutashabihatForAyah(ayah.surah, ayah.ayahNumber);

    if (!mounted) return;

    if (pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Mutashabihat (similar verses) registered for Ayah ${ayah.ayahNumber}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final surahInfo = kSurahList[ayah.surah - 1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows_rounded, color: Color(0xFFD84315), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Mutashabihat (Similar Verses)',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Similar verses for Surah ${surahInfo.nameTransliteration} [${ayah.surah}:${ayah.ayahNumber}]',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pairs.length,
                itemBuilder: (context, index) {
                  final p = pairs[index];
                  final isCurrentSource = p.srcSurah == ayah.surah && p.srcAyah == ayah.ayahNumber;
                  final otherSurah = isCurrentSource ? p.similarSurah : p.srcSurah;
                  final otherAyah = isCurrentSource ? p.similarAyah : p.srcAyah;
                  final otherName = isCurrentSource ? p.similarSurahName : p.srcSurahName;
                  final otherArabic = isCurrentSource ? p.similarArabic : p.srcArabic;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Similar in Surah $otherName [$otherSurah:$otherAyah]',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD84315)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.goNamed(
                                  'verse-by-verse',
                                  pathParameters: {'surahNumber': '$otherSurah'},
                                  queryParameters: {'ayah': '$otherAyah'},
                                );
                              },
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Open'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8ECE9)),
                          ),
                          child: Text(
                            otherArabic ?? '',
                            style: const TextStyle(
                              fontFamily: 'Scheherazade New',
                              fontSize: 19,
                              height: 1.85,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadJuzAyahs() async {
    final repo = ref.read(quranRepositoryProvider);
    final settings = ref.read(settingsServiceProvider);

    // Primary: query ayahs from DB by juz column
    List<Ayah> ayahs = await repo.getAyahsByJuz(widget.juzNumber);

    if (ayahs.isEmpty) {
      final startSurah = _kJuzData[widget.juzNumber - 1]['surah'] as int;
      final endSurah = widget.juzNumber < 30
          ? (_kJuzData[widget.juzNumber]['surah'] as int)
          : 114;

      for (int sNum = startSurah; sNum <= endSurah; sNum++) {
        final fetched = await repo.getAyahsBySurah(sNum);
        ayahs.addAll(fetched.where((a) => a.juz == widget.juzNumber));
      }
      ayahs.sort((a, b) => a.id.compareTo(b.id));
    }

    final ayahIds = ayahs.map((a) => a.id).toList();
    final availableTranslations = await repo.getAvailableEditions(type: 'translation');
    final availableTafseers = await repo.getAvailableEditions(type: 'tafseer');

    Edition? transEdition;
    final selectedTransId = settings.selectedTranslationId;
    if (selectedTransId != null) {
      final match = availableTranslations.where((e) => e.id == selectedTransId);
      if (match.isNotEmpty) transEdition = match.first;
    }
    transEdition ??= (availableTranslations.isNotEmpty
        ? availableTranslations.first
        : const Edition(id: 1, type: 'translation', language: 'ur', name: 'Fateh Muhammad Jalandhry', apiKey: 'ur.jalandhry', isBundled: true, isDownloaded: true));

    Edition? tafseerEdition;
    final selectedTafseerId = settings.selectedTafseerEditionId;
    if (selectedTafseerId != null) {
      final match = availableTafseers.where((e) => e.id == selectedTafseerId);
      if (match.isNotEmpty) tafseerEdition = match.first;
    }
    tafseerEdition ??= (availableTafseers.isNotEmpty
        ? availableTafseers.first
        : const Edition(id: 103, type: 'tafseer', language: 'ur', name: 'Tafseer Ibn e Kaseer', apiKey: 'tafseer-ibn-e-kaseer-urdu', isBundled: true, isDownloaded: true));

    Map<int, String> translations = await repo.getContentBulk(ayahIds, transEdition.id);
    Map<int, String> tafseers = await repo.getContentBulk(ayahIds, tafseerEdition.id);
    final bmarks = await repo.getBookmarks();
    final bookmarkedSet = bmarks.map((b) => '${b.surah}:${b.ayah}').toSet();

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _activeTranslationEdition = transEdition;
        _activeTafseerEdition = tafseerEdition;
        _translations = translations;
        _tafseers = tafseers;
        _bookmarkedAyahs = bookmarkedSet;
        _loading = false;
        if (ayahs.isNotEmpty) {
          _currentSurahNumber = ayahs.first.surah;
          _currentSurahName =
              kSurahList[_currentSurahNumber - 1].nameTransliteration;
        }
      });
    }
  }

  void _onScroll() {
    if (_ayahs.isEmpty || !_scrollCtrl.hasClients) return;
    final idx = (_scrollCtrl.offset / 120).floor().clamp(0, _ayahs.length - 1);
    final surahNum = _ayahs[idx].surah;
    if (surahNum != _currentSurahNumber) {
      setState(() {
        _currentSurahNumber = surahNum;
        _currentSurahName = kSurahList[surahNum - 1].nameTransliteration;
      });
    }
  }

  Future<void> _playAyah(Ayah ayah) async {
    final audio = ref.read(audioServiceProvider);
    audio.onAdvance = (surah, nextAyahInSurah) {
      final nextIdx = _ayahs.indexWhere(
          (a) => a.surah == surah && a.ayahNumber == nextAyahInSurah);
      if (nextIdx >= 0 && mounted) {
        _playAyah(_ayahs[nextIdx]);
      } else {
        final curIdx = _ayahs.indexWhere((a) => a.id == audio.currentPlayingAyahId);
        if (curIdx >= 0 && curIdx < _ayahs.length - 1 && mounted) {
          _playAyah(_ayahs[curIdx + 1]);
        }
      }
    };

    await audio.playAyah(
      globalAyahNumber: ayah.id,
      surah: ayah.surah,
      ayahInSurah: ayah.ayahNumber,
      totalAyahsInSurah: _ayahs.where((a) => a.surah == ayah.surah).length,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final urduFontSize = ref.watch(urduFontSizeProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Juz ${widget.juzNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _juzName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (_currentSurahName.isNotEmpty)
              Text(
                _currentSurahName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              _kJuzInfo[widget.juzNumber - 1]['arabic']!,
              style: const TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<PlayerState>(
              stream: audio.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final isBuffering =
                    playerState?.processingState == ProcessingState.buffering ||
                    playerState?.processingState == ProcessingState.loading;

                final double bottomPadding = (audio.currentPlayingAyahId != null ? 260.0 : 110.0) +
                    MediaQuery.paddingOf(context).bottom;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding),
                  itemCount: _buildItems().length,
                  itemBuilder: (ctx, i) {
                    final item = _buildItems()[i];
                    if (item is int) {
                      final sNum = item;
                      return _SurahHeader(
                        surahNumber: sNum,
                        translationName: _activeTranslationEdition?.name ?? 'Translation',
                        tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                        bismillahTranslationText: _translations[1],
                        showTranslation: _showTranslation,
                        onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
                        onToggleTafseer: () {
                          final surahAyahs = _ayahs.where((a) => a.surah == sNum).toList();
                          final ayahToOpen = surahAyahs.isNotEmpty
                              ? surahAyahs.first
                              : Ayah(
                                  id: 1,
                                  surah: sNum,
                                  ayahNumber: 1,
                                  arabicText: sNum == 9
                                      ? 'سُورَةُ التَّوْبَة'
                                      : 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                                  juz: widget.juzNumber,
                                  hizb: 1,
                                  ruku: 1,
                                  manzil: 1,
                                  page: 1,
                                  isSajda: false,
                                );
                          showAyahTafseerModal(
                            context: context,
                            ref: ref,
                            ayah: ayahToOpen,
                            activeTafseerEdition: _activeTafseerEdition ??
                                const Edition(
                                  id: 103,
                                  type: 'tafseer',
                                  language: 'ur',
                                  name: 'Tafseer Ibn e Kaseer',
                                  apiKey: 'tafseer-ibn-e-kaseer-urdu',
                                  isBundled: true,
                                  isDownloaded: true,
                                ),
                            onEditionChanged: (newEd) {
                              setState(() => _activeTafseerEdition = newEd);
                              _loadJuzAyahs();
                            },
                          );
                        },
                      );
                    }
                    final ayah = item as Ayah;
                    if (ayah.surah == 1 && ayah.ayahNumber == 1) {
                      return const SizedBox.shrink();
                    }
                    final isCurrentAyahPlaying = audio.currentPlayingAyahId == ayah.id;
                    final isPlayingNow = isCurrentAyahPlaying && audio.isPlaying;
                    final isBufferingNow = isCurrentAyahPlaying && isBuffering;
                    final activeWordAsync = ref.watch(activeWordIdProvider);
                    final activeWordId = activeWordAsync.value ?? audio.currentActiveWordId;
                    final isBookmarkedNow = _bookmarkedAyahs.contains('${ayah.surah}:${ayah.ayahNumber}');

                    return UnifiedAyahCard(
                      ayah: ayah,
                      translationText: _translations[ayah.id],
                      tafseerText: _tafseers[ayah.id],
                      translationName: _activeTranslationEdition?.name ?? 'Translation',
                      tafseerName: _activeTafseerEdition?.name ?? 'Tafseer',
                      arabicFontSize: arabicFontSize,
                      urduFontSize: urduFontSize,
                      isPlaying: isPlayingNow,
                      isBuffering: isBufferingNow,
                      isBookmarked: isBookmarkedNow,
                      activeWordId: activeWordId,
                      onOpenTafseer: () {
                        showAyahTafseerModal(
                          context: context,
                          ref: ref,
                          ayah: ayah,
                          activeTafseerEdition: _activeTafseerEdition ??
                              const Edition(
                                id: 103,
                                type: 'tafseer',
                                language: 'ur',
                                name: 'Tafseer Ibn e Kaseer',
                                apiKey: 'tafseer-ibn-e-kaseer-urdu',
                                isBundled: true,
                                isDownloaded: true,
                              ),
                          initialTafseerText: _tafseers[ayah.id],
                          onEditionChanged: (newEd) {
                            setState(() => _activeTafseerEdition = newEd);
                            _loadJuzAyahs();
                          },
                        );
                      },
                      onSelectTranslation: () => _showEditionSelector('translation'),
                      onPlayTap: () => _playAyah(ayah),
                      onShareTap: () {
                        final trText = _translations[ayah.id] ?? '';
                        final surahInfo = kSurahList[ayah.surah - 1];
                        AyahShareDialog.show(
                          context,
                          surahName: surahInfo.nameTransliteration,
                          ayahNumber: ayah.ayahNumber,
                          arabicText: cleanAyahText(ayah),
                          translationText: trText,
                        );
                      },
                      onMutashabihatTap: () => _showMutashabihatBottomSheet(ayah),
                      onCopyTap: () {
                        final trText = _translations[ayah.id] ?? '';
                        final surahInfo = kSurahList[ayah.surah - 1];
                        final full = 'Surah ${surahInfo.nameTransliteration} [${ayah.surah}:${ayah.ayahNumber}]\n\n'
                            '${cleanAyahText(ayah)}\n\n'
                            '$trText\n\n— Al Quran App';
                        Clipboard.setData(ClipboardData(text: full));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verse copied to clipboard!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                        );
                      },
                      onBookmarkTap: () async {
                        final repo = ref.read(quranRepositoryProvider);
                        final messenger = ScaffoldMessenger.of(context);
                        final key = '${ayah.surah}:${ayah.ayahNumber}';
                        final isCurrentlyBookmarked = _bookmarkedAyahs.contains(key);
                        if (isCurrentlyBookmarked) {
                          await repo.removeBookmark(ayah.surah, ayah.ayahNumber);
                          if (mounted) {
                            setState(() => _bookmarkedAyahs.remove(key));
                          }
                        } else {
                          await repo.addBookmark(ayah.surah, ayah.ayahNumber);
                          if (mounted) {
                            setState(() => _bookmarkedAyahs.add(key));
                          }
                        }
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(isCurrentlyBookmarked ? 'Bookmark removed' : 'Bookmarked!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    );
                  },
                );
              },
            ),
      bottomSheet: (audio.currentPlayingAyahId != null && _ayahs.isNotEmpty)
          ? Container(
              color: Colors.transparent,
              child: AudioControlBar(
                surahNumber: _currentSurahNumber,
                surahName: _juzName,
                currentAyahNumber: _ayahs
                    .firstWhere((a) => a.id == audio.currentPlayingAyahId,
                        orElse: () => _ayahs.first)
                    .ayahNumber,
                totalAyahs: _ayahs.length,
                onNextAyah: () {
                  final curIdx = _ayahs
                      .indexWhere((a) => a.id == audio.currentPlayingAyahId);
                  if (curIdx >= 0 && curIdx < _ayahs.length - 1) {
                    _playAyah(_ayahs[curIdx + 1]);
                  }
                },
                onPrevAyah: () {
                  final curIdx = _ayahs
                      .indexWhere((a) => a.id == audio.currentPlayingAyahId);
                  if (curIdx > 0) {
                    _playAyah(_ayahs[curIdx - 1]);
                  }
                },
                onClose: () => setState(() {}),
              ),
            )
          : null,
    );
  }

  /// Builds mixed list of [int] (surah numbers for headers) and [Ayah] items
  List<dynamic> _buildItems() {
    final items = <dynamic>[];
    int? lastSurah;
    for (final ayah in _ayahs) {
      if (ayah.surah != lastSurah) {
        items.add(ayah.surah);
        lastSurah = ayah.surah;
      }
      items.add(ayah);
    }
    return items;
  }
}

// ── Premium Surah Header Banner inside Juz ──────────────────────────────────
class _SurahHeader extends StatelessWidget {
  final int surahNumber;
  final String translationName;
  final String tafseerName;
  final String? bismillahTranslationText;
  final bool showTranslation;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleTafseer;

  const _SurahHeader({
    required this.surahNumber,
    required this.translationName,
    required this.tafseerName,
    this.bismillahTranslationText,
    required this.showTranslation,
    required this.onToggleTranslation,
    required this.onToggleTafseer,
  });

  @override
  Widget build(BuildContext context) {
    final surahInfo = kSurahList[surahNumber - 1];
    final isMeccan = surahInfo.revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A60), // Midnight Sapphire
            Color(0xFF0F2038), // Deep Royal Navy Shadow
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Top Gilded Surah Ribbon Row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left — Revelation badge in ornate gold medallion pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8D4913),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        isMeccan ? 'Meccan' : 'Medinan',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8D4913),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Center — Arabic Surah Name & Transliteration
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arabic Surah Title with subtle gold glow
                      Text(
                        'سُورَةُ ${surahInfo.nameArabic}',
                        style: const TextStyle(
                          fontFamily: 'Scheherazade New',
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                          shadows: [
                            Shadow(
                              color: Color(0xFFF59E0B),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surahInfo.nameTransliteration} • ${surahInfo.nameTranslation}',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFEF3C7),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right — Verses Count & Rukus Count in ornate gold medallion pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${surahInfo.ayahCount} Verses',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8D4913),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '${surahInfo.rukuCount} Rukus',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8D4913),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Bismillah Section (Omitted for Surah 9 At-Tawbah) ───────────
          if (surahNumber != 9) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.0),
                            const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.6),
                            const Color(0xFFF59E0B).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'Scheherazade New',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFEF3C7),
                height: 1.3,
                shadows: [
                  Shadow(
                    color: Color(0xFFF59E0B),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            if (showTranslation && (bismillahTranslationText?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  bismillahTranslationText!,
                  style: const TextStyle(
                    fontFamily: 'Noto Nastaliq Urdu',
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
