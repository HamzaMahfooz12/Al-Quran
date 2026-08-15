import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/bookmark.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  bool _loading = true;
  List<Bookmark> _bookmarks = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);
    final list = await repo.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _loading = false;
      });
    }
  }

  Future<void> _deleteBookmark(Bookmark b) async {
    final repo = ref.read(quranRepositoryProvider);
    await repo.removeBookmark(b.surah, b.ayah);
    _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark removed'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _bookmarks.where((b) {
      final info = kSurahList[b.surah - 1];
      final matchesSurah = info.nameTransliteration.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          info.nameArabic.contains(_searchQuery);
      final matchesLabel = b.label?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return matchesSurah || matchesLabel;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        title: Text(
          'Saved Bookmarks',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2D6A4F)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_border_rounded, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No Bookmarks Found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Tap the bookmark icon on any verse to save it.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final b = filtered[idx];
                          final info = kSurahList[b.surah - 1];
                          final dateStr = DateFormat('MMM dd, yyyy').format(b.createdAt);

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.bookmark, color: Color(0xFF2E7D32)),
                              ),
                              title: Text(
                                '${info.nameTransliteration} (${info.nameArabic}) — Verse ${b.ayah}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                b.label != null && b.label!.isNotEmpty
                                    ? 'Note: ${b.label}\nSaved on $dateStr'
                                    : 'Saved on $dateStr',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteBookmark(b),
                              ),
                              onTap: () => context.push('/home/surah/${b.surah}?scrollToAyah=${b.ayah}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
