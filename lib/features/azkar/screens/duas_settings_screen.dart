// lib/features/azkar/screens/duas_settings_screen.dart
// Luxury Alabaster & Warm Gold Duas Settings Screen
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuasSettingsScreen extends StatefulWidget {
  const DuasSettingsScreen({super.key});

  @override
  State<DuasSettingsScreen> createState() => _DuasSettingsScreenState();
}

class _DuasSettingsScreenState extends State<DuasSettingsScreen> {
  String _selectedLang = 'ur'; // Default to Urdu
  List<Map<String, dynamic>> _customDuas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('azkar_display_language') ?? 'ur';
    final customRaw = prefs.getString('azkar_custom_duas_list');
    List<Map<String, dynamic>> customList = [];
    if (customRaw != null) {
      try {
        final decoded = jsonDecode(customRaw) as List;
        customList = decoded.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _selectedLang = savedLang;
        _customDuas = customList;
        _loading = false;
      });
    }
  }

  Future<void> _setLanguage(String lang) async {
    HapticFeedback.selectionClick();
    setState(() => _selectedLang = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_display_language', lang);
  }

  Future<void> _deleteCustomDua(int index) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _customDuas.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_custom_duas_list', jsonEncode(_customDuas));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Custom Dua removed',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF354033),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAddDuaModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDuaModal(
        onDuaAdded: (newDua) async {
          setState(() {
            _customDuas.add(newDua);
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('azkar_custom_duas_list', jsonEncode(_customDuas));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFC5A059), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'New Dua successfully added!',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF354033),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: InkWell(
            onTap: () => context.pop(true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECE4D8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1B1C1E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF354033),
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          'Duas Settings',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF354033),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 32 + bottomPad),
              children: [
                // ── 1. Translation Language Selector ──
                _buildSectionHeader(
                  'Translation Language',
                  'Select default language for Duas & Supplications',
                ),
                const SizedBox(height: 10),
                _buildLanguageCard(),

                const SizedBox(height: 24),

                // ── 2. Add New Dua to Category Action Card ──
                _buildSectionHeader(
                  'Custom Supplications',
                  'Add personal or specific Duas under any category',
                ),
                const SizedBox(height: 10),
                _buildAddDuaActionCard(),

                if (_customDuas.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCustomDuasList(),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFC59A27),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF354033),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard() {
    final languages = [
      {'code': 'ur', 'name': 'اردو (Urdu)', 'sub': 'Default pre-selected translation (ترجمہ اردو)'},
      {'code': 'en', 'name': 'English', 'sub': 'English authentic Sahih translation'},
      {'code': 'all', 'name': 'All Languages (سب زبانیں)', 'sub': 'Display Arabic, Urdu & English simultaneously'},
      {'code': 'transliteration', 'name': 'Transliteration Only', 'sub': 'Roman phonetic English reading'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE4D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B1C1E),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: languages.asMap().entries.map((entry) {
          final idx = entry.key;
          final lang = entry.value;
          final isSelected = _selectedLang == lang['code'];
          final isLast = idx == languages.length - 1;

          return Column(
            children: [
              Material(
                color: isSelected ? const Color(0xFFFAF5E8) : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                child: InkWell(
                  onTap: () => _setLanguage(lang['code']!),
                  borderRadius: BorderRadius.vertical(
                    top: idx == 0 ? const Radius.circular(18) : Radius.zero,
                    bottom: isLast ? const Radius.circular(18) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Radio button in warm gold
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFC5A059) : const Color(0xFFD1D5DB),
                              width: isSelected ? 6.5 : 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    lang['name']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF7C633E) : const Color(0xFF354033),
                                    ),
                                  ),
                                  if (lang['code'] == 'ur') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F4EC),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFE8DFD0)),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF7C633E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang['sub']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFECE4D8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddDuaActionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFBF7), Color(0xFFF5ECE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC59A27).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B1C1E),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _openAddDuaModal,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Warm Ivory frame with Gold Plus icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5EB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC59A27).withValues(alpha: 0.50),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10B8860B),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, color: Color(0xFFC59A27), size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Dua to Category',
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354033),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add custom Arabic, Urdu & English supplications',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF7C7365),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E1D2)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFC59A27),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDuasList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE4D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B1C1E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _customDuas.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFECE4D8)),
        itemBuilder: (ctx, idx) {
          final dua = _customDuas[idx];
          final title = dua['title'] as String? ?? 'Custom Dua';
          final category = dua['category'] as String? ?? 'General';
          final arabic = dua['arabic'] as String? ?? '';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E1D2)),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFFC59A27), size: 18),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF354033),
              ),
            ),
            subtitle: Text(
              '$category • $arabic',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                color: Color(0xFF7C7365),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: 'Delete custom dua',
              onPressed: () => _deleteCustomDua(idx),
            ),
          );
        },
      ),
    );
  }
}

// ── Add Dua Modal Form ──────────────────────────────────────────────────────
class _AddDuaModal extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onDuaAdded;
  const _AddDuaModal({required this.onDuaAdded});

  @override
  State<_AddDuaModal> createState() => _AddDuaModalState();
}

class _AddDuaModalState extends State<_AddDuaModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _arabicCtrl = TextEditingController();
  final _urduCtrl = TextEditingController();
  final _englishCtrl = TextEditingController();
  final _transliterationCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  int _repetitionCount = 1;
  String _selectedCategory = 'Morning & Evening (صبح و شام)';

  final List<String> _categories = [
    'Morning & Evening (صبح و شام)',
    'After Salah (نماز کے بعد)',
    'Sleep & Night (سوتے وقت)',
    'Travel & Journey (سفر کی دعائیں)',
    'Food & Drink (کھانے پینے کی دعائیں)',
    'Protection & Ruqyah (حفاظت و استعاذہ)',
    'Forgiveness & Repentance (توبہ و استغفار)',
    'Quranic Rabbana (قرآنی دعائیں)',
    'Daily Life & General (روزمرہ کی دعائیں)',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _arabicCtrl.dispose();
    _urduCtrl.dispose();
    _englishCtrl.dispose();
    _transliterationCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newDua = {
        'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
        'category': _selectedCategory,
        'title': _titleCtrl.text.trim(),
        'arabic': _arabicCtrl.text.trim(),
        'urduTranslation': _urduCtrl.text.trim(),
        'englishTranslation': _englishCtrl.text.trim(),
        'transliteration': _transliterationCtrl.text.trim(),
        'reference': _referenceCtrl.text.trim().isNotEmpty ? _referenceCtrl.text.trim() : 'Custom Addition',
        'count': _repetitionCount,
      };

      widget.onDuaAdded(newDua);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFFC5A059), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar & Title
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Supplication',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF354033),
                  ),
                ),
                IconButton(
                  icon: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F4EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  // Category Dropdown
                  Text(
                    'Category',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECE4D8)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFC5A059)),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF354033)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dua Title
                  Text(
                    'Dua Title / Name *',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                    decoration: _inputDeco('e.g. Dua for Entering Home'),
                  ),

                  const SizedBox(height: 12),

                  // Arabic Text
                  Text(
                    'Arabic Text (عربی متن) *',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _arabicCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter Arabic text' : null,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 1.4, color: Color(0xFF354033)),
                    decoration: _inputDeco('بِسْمِ اللَّهِ وَلَجْنَا...'),
                  ),

                  const SizedBox(height: 12),

                  // Urdu Translation
                  Text(
                    'Urdu Translation (اردو ترجمہ)',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _urduCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: GoogleFonts.notoNastaliqUrdu(fontSize: 13, height: 1.6, color: const Color(0xFF354033)),
                    decoration: _inputDeco('اللہ کے نام کے ساتھ ہم داخل ہوئے...'),
                  ),

                  const SizedBox(height: 12),

                  // English Translation
                  Text(
                    'English Translation',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _englishCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('In the name of Allah we enter...'),
                  ),

                  const SizedBox(height: 12),

                  // Transliteration
                  Text(
                    'Transliteration (Pronunciation)',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _transliterationCtrl,
                    decoration: _inputDeco('Bismillahi walajna...'),
                  ),

                  const SizedBox(height: 12),

                  // Reference & Repetitions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference / Hadith',
                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _referenceCtrl,
                              decoration: _inputDeco('e.g. Abu Dawud 5096'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Count',
                            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFECE4D8)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16, color: Color(0xFFC5A059)),
                                  onPressed: () {
                                    if (_repetitionCount > 1) {
                                      setState(() => _repetitionCount--);
                                    }
                                  },
                                ),
                                Text(
                                  '$_repetitionCount',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF354033)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16, color: Color(0xFFC5A059)),
                                  onPressed: () => setState(() => _repetitionCount++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Save Button in Royal Gold
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A059),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        shadowColor: const Color(0x38B8860B),
                      ),
                      child: Text(
                        'Save Supplication',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFFAF7F2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECE4D8))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECE4D8))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
