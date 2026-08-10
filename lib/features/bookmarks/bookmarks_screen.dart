// lib/features/bookmarks/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bookmark.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bk = await ref.read(quranRepositoryProvider).getAllBookmarks();
    if (mounted) setState(() { _bookmarks = bk; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text('No bookmarks yet',
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap the bookmark icon on any ayah to save it.',
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (ctx, i) {
                    final bk = _bookmarks[i];
                    final surah = kSurahList[bk.surah - 1];
                    return Dismissible(
                      key: Key('bk-${bk.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, color: AppTheme.error),
                      ),
                      onDismissed: (_) async {
                        await ref.read(quranRepositoryProvider)
                            .removeBookmark(bk.surah, bk.ayah);
                        setState(() => _bookmarks.removeAt(i));
                      },
                      child: GestureDetector(
                        onTap: () => context.goNamed('verse-by-verse',
                            pathParameters: {'surahNumber': bk.surah.toString()},
                            queryParameters: {'ayah': bk.ayah.toString()}),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bookmark, color: AppTheme.primary, size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${surah.nameTransliteration} : ${bk.ayah}',
                                        style: GoogleFonts.inter(
                                            fontSize: 15, fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary)),
                                    if (bk.label != null)
                                      Text(bk.label!,
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
