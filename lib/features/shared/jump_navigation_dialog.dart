import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/surah_info.dart';
import '../../data/repositories/quran_repository.dart';

class JumpNavigationDialog extends ConsumerStatefulWidget {
  final String? mushafType;
  final Function(int pageNumber)? onJumpToPage;

  const JumpNavigationDialog({
    super.key,
    this.mushafType,
    this.onJumpToPage,
  });

  static Future<void> show(
    BuildContext context, {
    String? mushafType,
    Function(int pageNumber)? onJumpToPage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JumpNavigationDialog(
        mushafType: mushafType,
        onJumpToPage: onJumpToPage,
      ),
    );
  }

  @override
  ConsumerState<JumpNavigationDialog> createState() => _JumpNavigationDialogState();
}

class _JumpNavigationDialogState extends ConsumerState<JumpNavigationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  final TextEditingController _pageInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Page, Surah, Juz, Manzil
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pageInputCtrl.dispose();
    super.dispose();
  }

  void _executeJumpToPage(int pageNum) {
    Navigator.pop(context);
    if (widget.onJumpToPage != null) {
      widget.onJumpToPage!(pageNum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMushafMode = widget.onJumpToPage != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & title
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            isMushafMode ? 'Jump To Location (Mushaf)' : 'Jump To Location',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 10),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFF2D6A4F),
            labelColor: const Color(0xFF1B4332),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Page'),
              Tab(text: 'Surah (1-114)'),
              Tab(text: 'Juz (1-30)'),
              Tab(text: 'Manzil (1-7)'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPageJumpTab(),
                _buildSurahJumpTab(),
                _buildJuzJumpTab(),
                _buildManzilJumpTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Direct Page Number Jump Tab ──────────────────────────────────────────
  Widget _buildPageJumpTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Enter Page Number (1 - 610)',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageInputCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Page number...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2D6A4F)),
                    ),
                  ),
                  onSubmitted: (v) {
                    final p = int.tryParse(v);
                    if (p != null && p >= 1 && p <= 610) {
                      _executeJumpToPage(p);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final p = int.tryParse(_pageInputCtrl.text);
                  if (p != null && p >= 1 && p <= 610) {
                    _executeJumpToPage(p);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid page number (1-610)')),
                    );
                  }
                },
                child: Text('Jump', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 60, // Quick page shortcuts (Page 1, 10, 20... up to 600)
              itemBuilder: (ctx, i) {
                final pageNum = (i + 1) * 10;
                if (pageNum > 610) return const SizedBox.shrink();
                return InkWell(
                  onTap: () => _executeJumpToPage(pageNum),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4A843).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'P. $pageNum',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Surah Jump Tab ───────────────────────────────────────────────────────
  Widget _buildSurahJumpTab() {
    final filtered = kSurahList.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.number.toString() == q;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search Surah name or number...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF2D6A4F)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final surah = filtered[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text('${surah.number}',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))),
                ),
                title: Text(surah.nameTransliteration, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${surah.ayahCount} Verses • ${surah.revelationType}', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                trailing: Text(surah.nameArabic, style: const TextStyle(fontFamily: 'Scheherazade New', fontSize: 18, color: Color(0xFF1B4332))),
                onTap: () async {
                  if (widget.onJumpToPage != null && widget.mushafType != null) {
                    final repo = ref.read(quranRepositoryProvider);
                    final page = await repo.getSurahStartPage(surah.number, widget.mushafType!);
                    _executeJumpToPage(page);
                  } else {
                    Navigator.pop(context);
                    context.push('/home/surah/${surah.number}');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 3. Juz Jump Tab ─────────────────────────────────────────────────────────
  Widget _buildJuzJumpTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 30,
      itemBuilder: (ctx, idx) {
        final juzNum = idx + 1;
        return Card(
          elevation: 0.5,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text('$juzNum', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332))),
            ),
            title: Text('Juz $juzNum (پارہ $juzNum)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () async {
              if (widget.onJumpToPage != null && widget.mushafType != null) {
                final repo = ref.read(quranRepositoryProvider);
                final page = await repo.getJuzStartPage(juzNum, widget.mushafType!);
                _executeJumpToPage(page);
              } else {
                Navigator.pop(context);
                context.push('/home/juz/$juzNum');
              }
            },
          ),
        );
      },
    );
  }

  // ── 4. Manzil Jump Tab ──────────────────────────────────────────────────────
  Widget _buildManzilJumpTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 7,
      itemBuilder: (ctx, idx) {
        final manzilNum = idx + 1;
        return Card(
          child: ListTile(
            title: Text('Manzil $manzilNum', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Phase $manzilNum of 7', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
