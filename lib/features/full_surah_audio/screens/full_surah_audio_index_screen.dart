// lib/features/full_surah_audio/screens/full_surah_audio_index_screen.dart
// Online Full-Surah Audio list browser with reciter selector & offline download management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/full_surah_reciter.dart';
import '../../../data/models/surah_info.dart';
import '../../../data/repositories/full_surah_reciter_repository.dart';
import '../../../services/full_surah_audio_service.dart';
import '../../quran/simple_quran_index_screen.dart' show IslamicStarBadge;

class FullSurahAudioIndexScreen extends ConsumerStatefulWidget {
  const FullSurahAudioIndexScreen({super.key});

  @override
  ConsumerState<FullSurahAudioIndexScreen> createState() =>
      _FullSurahAudioIndexScreenState();
}

class _FullSurahAudioIndexScreenState
    extends ConsumerState<FullSurahAudioIndexScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filteredSurahs {
    if (_query.isEmpty) return kSurahList;
    final q = _query;
    return kSurahList.where((s) {
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.number.toString() == q;
    }).toList();
  }

  void _openReciterPicker(FullSurahAudioService audioService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReciterPickerModal(
        selectedReciter: audioService.currentReciter,
        onSelected: (reciter) {
          audioService.setReciter(reciter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(fullSurahAudioServiceProvider);
    final isAudioActive = audioService.currentSurahNumber != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A60), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Full Surah Audio',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F2038),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.download_for_offline_rounded,
                  color: Color(0xFF1E3A60),
                  size: 24,
                ),
                if (audioService.downloadedSurahs.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${audioService.downloadedSurahs.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F2038),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Downloaded Surahs',
            onPressed: () => context.push('/home/full-surah-audio/downloads'),
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF1E3A60), size: 22),
            tooltip: 'Change Reciter',
            onPressed: () => _openReciterPicker(audioService),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 6, 16, isAudioActive ? 110 : 32),
            children: [
              // ── 1. Active Reciter Hero Card ──
              _buildReciterHeroCard(audioService),

              const SizedBox(height: 14),

              // ── 2. Search Box ──
              _buildSearchBox(),

              const SizedBox(height: 16),

              // ── 3. Surah List Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All 114 Surahs',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F2038),
                    ),
                  ),
                  Text(
                    '${_filteredSurahs.length} Available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A60),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── 4. 114 Surah Cards ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSurahs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final surah = _filteredSurahs[idx];
                  return _buildSurahRow(surah, audioService);
                },
              ),
            ],
          ),

          // ── Sticky Floating Mini Player Bar ──
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

  Widget _buildReciterHeroCard(FullSurahAudioService audioService) {
    final reciter = audioService.currentReciter;
    final reciterArabic = reciter.arabicName;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A60), Color(0xFF0F2038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A60).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openReciterPicker(audioService),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reciter.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        reciterArabic,
                        style: GoogleFonts.amiri(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD54F),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          hintText: 'Search 114 Surahs by name or number...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A60), size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSurahRow(SurahInfo s, FullSurahAudioService audioService) {
    final isPlayingThis = audioService.currentSurahNumber == s.number;
    final isDownloaded = audioService.downloadedSurahs.contains(s.number);
    final reciter = audioService.currentReciter;

    return Container(
      decoration: BoxDecoration(
        color: isPlayingThis ? const Color(0xFFFAF2E6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (isPlayingThis && audioService.isPlaying) {
              context.push('/home/full-surah-audio/player?surah=${s.number}');
            } else {
              audioService.playSurah(
                surahNumber: s.number,
                reciter: reciter,
              );
              context.push('/home/full-surah-audio/player?surah=${s.number}');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                IslamicStarBadge(
                  number: s.number,
                  size: 38,
                  borderColor: isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFF1E3A60),
                  fillColor: isPlayingThis ? const Color(0xFFFEF3C7) : const Color(0xFFEEF4FC),
                  textColor: isPlayingThis ? const Color(0xFFB45309) : const Color(0xFF1E3A60),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surah ${s.nameTransliteration}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F2038),
                        ),
                      ),
                      Text(
                        '${s.nameTranslation} • ${s.ayahCount} Verses • ${s.revelationType}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  s.nameArabic,
                  style: GoogleFonts.amiri(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),

                // Download Button
                StreamBuilder<Map<int, double>>(
                  stream: audioService.downloadProgressStream,
                  builder: (ctx, snap) {
                    final progress = snap.data?[s.number];
                    if (progress != null) {
                      return Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A60)),
                        ),
                      );
                    }

                    if (isDownloaded) {
                      return IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A60), size: 22),
                        tooltip: 'Downloaded (Tap to delete)',
                        onPressed: () {
                          audioService.deleteDownloadedSurah(s.number, reciter.id);
                        },
                      );
                    }

                    return IconButton(
                      icon: const Icon(Icons.arrow_circle_down_rounded, color: Color(0xFF64748B), size: 22),
                      tooltip: 'Download for Offline',
                      onPressed: () {
                        audioService.downloadSurah(s.number, reciter);
                      },
                    );
                  },
                ),

                // Play Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isPlayingThis ? const Color(0xFFF59E0B) : const Color(0xFF1E3A60),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: StreamBuilder<PlayerState>(
                      stream: audioService.playerStateStream,
                      builder: (ctx, snap) {
                        final isPlaying = snap.data?.playing ?? false;
                        final isProcessing = snap.data?.processingState == ProcessingState.loading ||
                            snap.data?.processingState == ProcessingState.buffering;

                        if (isPlayingThis && isProcessing) {
                          return const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          );
                        }

                        return Icon(
                          (isPlayingThis && isPlaying) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        );
                      },
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

  Widget _buildMiniPlayerBar(FullSurahAudioService audioService) {
    final surahNum = audioService.currentSurahNumber ?? 1;
    final sInfo = kSurahList.firstWhere((s) => s.number == surahNum, orElse: () => kSurahList.first);
    final reciterName = audioService.currentReciter.name;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A60), Color(0xFF0F2038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A60).withValues(alpha: 0.35),
            blurRadius: 14,
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
                  size: 34,
                  borderColor: const Color(0xFFF59E0B),
                  fillColor: const Color(0xFFFEF3C7),
                  textColor: const Color(0xFFB45309),
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
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 24),
                  onPressed: () => audioService.prevSurah(),
                ),
                StreamBuilder<PlayerState>(
                  stream: audioService.playerStateStream,
                  builder: (ctx, snap) {
                    final isPlaying = snap.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 32,
                      ),
                      onPressed: () => audioService.togglePlay(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                  onPressed: () => audioService.nextSurah(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reciter Picker Modal (Lists all 172 reciters) ────────────────────────────
class _ReciterPickerModal extends ConsumerStatefulWidget {
  final FullSurahReciter? selectedReciter;
  final ValueChanged<FullSurahReciter> onSelected;

  const _ReciterPickerModal({
    required this.selectedReciter,
    required this.onSelected,
  });

  @override
  ConsumerState<_ReciterPickerModal> createState() => _ReciterPickerModalState();
}

class _ReciterPickerModalState extends ConsumerState<_ReciterPickerModal> {
  final TextEditingController _filterCtrl = TextEditingController();
  List<FullSurahReciter> _all = [];
  List<FullSurahReciter> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReciters();
    _filterCtrl.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReciters() async {
    final repo = ref.read(fullSurahReciterRepositoryProvider);
    _all = await repo.getAllReciters();
    _filtered = _all;
    if (mounted) setState(() => _loading = false);
  }

  void _onFilterChanged() {
    final q = _filterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
    } else {
      setState(() {
        _filtered = _all.where((r) {
          return r.name.toLowerCase().contains(q) ||
              r.arabicName.contains(q) ||
              r.folderSlug.toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E1D2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Reciter (${_all.length} Available)',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F2038),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _filterCtrl,
                decoration: InputDecoration(
                  hintText: 'Search reciters by name (e.g. Sudais, Alafasy)...',
                  hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A60), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A60)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (ctx, idx) {
                      final r = _filtered[idx];
                      final isSelected = widget.selectedReciter?.id == r.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF1E3A60) : const Color(0xFFEEF4FC),
                          child: Icon(
                            Icons.person_rounded,
                            color: isSelected ? Colors.white : const Color(0xFF1E3A60),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          r.name,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF1E3A60) : const Color(0xFF0F2038),
                          ),
                        ),
                        subtitle: Text(
                          r.arabicName,
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A60), size: 22)
                            : null,
                        onTap: () {
                          widget.onSelected(r);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
