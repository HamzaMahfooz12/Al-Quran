// lib/features/azkar/screens/duas_settings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
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
    setState(() => _selectedLang = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_display_language', lang);
  }

  Future<void> _deleteCustomDua(int index) async {
    setState(() {
      _customDuas.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_custom_duas_list', jsonEncode(_customDuas));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom Dua removed'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAddDuaModal() {
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
              const SnackBar(
                content: Text('New Dua successfully added!'),
                backgroundColor: Color(0xFF1E3A60),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
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
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A60), size: 20),
          onPressed: () => context.pop(true),
        ),
        title: Text(
          'Duas Settings',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A60)))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + bottomPad),
              children: [
                // ── 1. Translation Language Selector ──
                _buildSectionHeader('Translation Language', 'Select default language for Duas & Supplications'),
                const SizedBox(height: 10),
                _buildLanguageCard(),

                const SizedBox(height: 24),

                // ── 2. Add New Dua to Category Action Card ──
                _buildSectionHeader('Custom Supplications', 'Add personal or specific Duas under any category'),
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
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B2A1E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
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
        border: Border.all(color: const Color(0xFFE8E1D2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: languages.map((lang) {
          final isSelected = _selectedLang == lang['code'];
          final isLast = languages.indexOf(lang) == languages.length - 1;

          return Column(
            children: [
              Material(
                color: isSelected ? const Color(0xFFEEF4FC) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _setLanguage(lang['code']!),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1E3A60) : const Color(0xFFD1D5DB),
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
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF1E3A60) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (lang['code'] == 'ur') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang['sub']!,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6B7280),
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
              if (!isLast) const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFF3F4F6)),
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
          colors: [Color(0xFF0F2038), Color(0xFF1E3A60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2038).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add custom Arabic, Urdu & English supplications',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
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
        border: Border.all(color: const Color(0xFFE8E1D2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _customDuas.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
        itemBuilder: (ctx, idx) {
          final dua = _customDuas[idx];
          final title = dua['title'] as String? ?? 'Custom Dua';
          final category = dua['category'] as String? ?? 'General';
          final arabic = dua['arabic'] as String? ?? '';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF4FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A60), size: 18),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            subtitle: Text(
              '$category • $arabic',
              style: GoogleFonts.amiri(fontSize: 13, color: const Color(0xFF6B7280)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
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
                    color: const Color(0xFF1B2A1E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  // Category Dropdown
                  Text('Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E1D2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E3A60)),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A))),
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
                  Text('Dua Title / Name *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                    decoration: _inputDeco('e.g. Dua for Entering Home'),
                  ),

                  const SizedBox(height: 12),

                  // Arabic Text
                  Text('Arabic Text (عربی متن) *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _arabicCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter Arabic text' : null,
                    style: GoogleFonts.amiri(fontSize: 17, height: 1.4),
                    decoration: _inputDeco('بِسْمِ اللَّهِ وَلَجْنَا...'),
                  ),

                  const SizedBox(height: 12),

                  // Urdu Translation
                  Text('Urdu Translation (اردو ترجمہ)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _urduCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: GoogleFonts.notoNastaliqUrdu(fontSize: 13, height: 1.6),
                    decoration: _inputDeco('اللہ کے نام کے ساتھ ہم داخل ہوئے...'),
                  ),

                  const SizedBox(height: 12),

                  // English Translation
                  Text('English Translation', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _englishCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('In the name of Allah we enter...'),
                  ),

                  const SizedBox(height: 12),

                  // Transliteration
                  Text('Transliteration (Pronunciation)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
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
                            Text('Reference / Hadith', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
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
                          Text('Count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5E50))),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8E1D2)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    if (_repetitionCount > 1) {
                                      setState(() => _repetitionCount--);
                                    }
                                  },
                                ),
                                Text(
                                  '$_repetitionCount',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => setState(() => _repetitionCount++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
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
      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A60), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
