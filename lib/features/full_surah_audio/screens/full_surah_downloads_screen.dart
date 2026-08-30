// lib/features/full_surah_audio/screens/full_surah_downloads_screen.dart
// Dedicated offline downloads manager for Full Surah Audio

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/surah_info.dart';
import '../../../services/full_surah_audio_service.dart';
import '../../quran/simple_quran_index_screen.dart' show IslamicStarBadge;

class FullSurahDownloadsScreen extends ConsumerStatefulWidget {
  const FullSurahDownloadsScreen({super.key});

  @override
  ConsumerState<FullSurahDownloadsScreen> createState() =>
      _FullSurahDownloadsScreenState();
}

class _FullSurahDownloadsScreenState
    extends ConsumerState<FullSurahDownloadsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<DownloadedSurahInfo> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final audioService = ref.read(fullSurahAudioServiceProvider);
    final list = await audioService.getAllDownloadedSurahs();
    if (mounted) {
      setState(() {
        _downloads = list;
        _isLoading = false;
      });
    }
  }

  List<DownloadedSurahInfo> get _filteredDownloads {
    if (_query.isEmpty) return _downloads;
    final q = _query;
    return _downloads.where((d) {
      final s = kSurahList[d.surahNumber - 1];
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          d.reciter.name.toLowerCase().contains(q) ||
          d.reciter.arabicName.contains(q) ||
          d.surahNumber.toString() == q;
    }).toList();
  }

  int get _totalBytes {
    return _downloads.fold<int>(0, (sum, d) => sum + d.fileSizeBytes);
  }

  String _formatTotalBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteSingle(DownloadedSurahInfo item) async {
    final s = kSurahList[item.surahNumber - 1];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Download',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B2A1E),
          ),
        ),
        content: Text(
          'Remove Surah ${s.nameTransliteration} (${item.reciter.name}) from offline storage? (${item.formattedSize})',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5E50)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final audioService = ref.read(fullSurahAudioServiceProvider);
      await audioService.deleteDownloadedSurah(item.surahNumber, item.reciter.id);
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surah ${s.nameTransliteration} removed from downloads'),
            backgroundColor: const Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteAll() async {
    if (_downloads.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete All Downloads?',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFDC2626),
          ),
        ),
        content: Text(
          'This will remove all ${_downloads.length} downloaded Surahs (${_formatTotalBytes(_totalBytes)}) from your device storage.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5E50)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete All', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final audioService = ref.read(fullSurahAudioServiceProvider);
      await audioService.deleteAllDownloads();
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All downloaded audio files removed'),
            backgroundColor: Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playDownloadedSurah(DownloadedSurahInfo item, FullSurahAudioService audioService) {
    audioService.playSurah(
      surahNumber: item.surahNumber,
      reciter: item.reciter,
    );
    context.push('/home/full-surah-audio/player?surah=${item.surahNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(fullSurahAudioServiceProvider);
    final isAudioActive = audioService.currentSurahNumber != null;
    final filtered = _filteredDownloads;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C7A39), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Downloaded Surahs',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2A1E),
              ),
            ),
            Text(
              'التنزيلات المحفوظة',
              style: GoogleFonts.amiri(
                fontSize: 12,
                color: const Color(0xFF2C7A39),
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          if (_downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626), size: 23),
              tooltip: 'Delete All Downloads',
              onPressed: _deleteAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2C7A39), size: 22),
            tooltip: 'Refresh Downloads',
            onPressed: _loadDownloads,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C7A39)),
            )
          else if (_downloads.isEmpty)
            _buildEmptyState()
          else
            ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, isAudioActive ? 110 : 32),
              children: [
                // ── 1. Storage & Offline Banner ──
                _buildStorageBanner(),

                const SizedBox(height: 14),

                // ── 2. Search Box ──
                _buildSearchBox(),

                const SizedBox(height: 16),

                // ── 3. Section Title ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Offline Surahs (${filtered.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2A1E),
                      ),
                    ),
                    Text(
                      'Ready to Play',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C7A39),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 4. Downloaded Cards ──
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E1D2)),
                    ),
                    child: Center(
                      child: Text(
                        'No downloads match "$_query"',
                        style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13.5),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      return _buildDownloadItemCard(filtered[i], audioService);
                    },
                  ),
              ],
            ),

          // ── Bottom Floating Mini-Player Bar ──
          if (isAudioActive)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: _buildMiniPlayerBar(audioService),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C7A39), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C7A39).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4)),
                ),
                child: const Center(
                  child: Icon(Icons.offline_pin_rounded, color: Color(0xFFFFD54F), size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_downloads.length} Surahs Downloaded',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Storage Used: ${_formatTotalBytes(_totalBytes)} • 100% Offline',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA5D6A7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFFEF3C7), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Play anytime without using cellular data or WiFi.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFFFEF3C7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search downloaded surahs or reciters...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2C7A39), size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDownloadItemCard(DownloadedSurahInfo item, FullSurahAudioService audioService) {
    final s = kSurahList[item.surahNumber - 1];
    final isPlayingThis = (audioService.currentSurahNumber == item.surahNumber) &&
        (audioService.currentReciter.id == item.reciter.id);

    return Container(
      decoration: BoxDecoration(
        color: isPlayingThis ? const Color(0xFFFAF2E6) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFFE8E1D2),
          width: isPlayingThis ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _playDownloadedSurah(item, audioService),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IslamicStarBadge(
                  number: s.number,
                  size: 40,
                  borderColor: isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFF56BA64),
                  fillColor: isPlayingThis ? const Color(0xFFFEF3C7) : const Color(0xFFEAF6EC),
                  textColor: isPlayingThis ? const Color(0xFFB45309) : const Color(0xFF2C7A39),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Surah ${s.nameTransliteration}',
                              style: GoogleFonts.outfit(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B2A1E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF6EC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.formattedSize,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2C7A39),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🎙️ ${item.reciter.name}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.nameTranslation} • ${s.ayahCount} Verses',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF8D9E92),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.nameArabic,
                  style: const TextStyle(
                    fontFamily: 'Scheherazade New',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2A1E),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 10),

                // Delete Action Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 21),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSingle(item),
                ),

                // Play Button
                GestureDetector(
                  onTap: () => _playDownloadedSurah(item, audioService),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFF3FA34D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFF3FA34D))
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        (isPlayingThis && audioService.isPlaying)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2C7A39).withValues(alpha: 0.15),
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF56BA64).withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: 48,
                  color: Color(0xFF2C7A39),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Downloads Available',
              style: GoogleFonts.outfit(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2A1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t downloaded any Surahs yet.\nTap the download icon next to any Surah in the list to listen offline anytime without internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.library_music_rounded, size: 18),
              label: Text(
                'Browse All Surahs',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C7A39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerBar(FullSurahAudioService audioService) {
    final surahNum = audioService.currentSurahNumber ?? 1;
    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final reciterName = audioService.currentReciter.name;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C7A39), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            context.push('/home/full-surah-audio/player?surah=$surahNum');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IslamicStarBadge(
                  number: surahNum,
                  size: 36,
                  borderColor: const Color(0xFFFFD54F),
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  textColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Surah ${sInfo.nameTransliteration}',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        reciterName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFA5D6A7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: audioService.playerStateStream,
                  builder: (ctx, snap) {
                    final isPlaying = snap.data?.playing ?? false;
                    final isProcessing = snap.data?.processingState == ProcessingState.loading ||
                        snap.data?.processingState == ProcessingState.buffering;

                    return IconButton(
                      icon: isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                              color: const Color(0xFFFFD54F),
                              size: 34,
                            ),
                      onPressed: () => audioService.togglePlay(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
