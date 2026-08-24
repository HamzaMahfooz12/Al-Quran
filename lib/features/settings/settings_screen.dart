// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/edition.dart';
import '../../data/models/reciter.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/reciter_repository.dart';
import '../../services/audio_cache_service.dart';
import '../../services/settings_service.dart';
import '../../services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<Edition> _translations = [];
  List<Edition> _tafseers = [];
  List<Reciter> _reciters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(quranRepositoryProvider);
    final reciterRepo = ref.read(reciterRepositoryProvider);
    final t = await repo.getAvailableEditions(type: 'translation');
    final tf = await repo.getAvailableEditions(type: 'tafseer');
    final r = await reciterRepo.getReciters();
    if (mounted) {
      setState(() {
        _translations = t;
        _tafseers = tf;
        _reciters = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);

    final currentTranslation = _translations
        .where((e) => e.id == settings.selectedTranslationId)
        .firstOrNull;
    final currentTafseer = _tafseers
        .where((e) => e.id == settings.selectedTafseerEditionId)
        .firstOrNull;
    final currentReciter = _reciters
        .where((r) => r.id == settings.selectedReciterId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          // ── Reading & Display ──────────────────────────────────────────
          _sectionHeader('Reading & Display'),

          // Arabic Font Size
          Consumer(
            builder: (context, ref, child) {
              final fontSize = ref.watch(arabicFontSizeProvider);
              return _settingsTile(
                icon: Icons.text_fields,
                title: 'Arabic Font Size',
                subtitle: '${fontSize.toInt()}px',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        ref.read(arabicFontSizeProvider.notifier).updateSize(fontSize - 2);
                      },
                    ),
                    Text(fontSize.toInt().toString(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        ref.read(arabicFontSizeProvider.notifier).updateSize(fontSize + 2);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Auto-Scroll Speed
          _settingsTile(
            icon: Icons.speed,
            title: 'Auto-Scroll Speed',
            subtitle: '${settings.autoScrollSpeed}x',
            trailing: DropdownButton<int>(
              value: settings.autoScrollSpeed,
              underline: const SizedBox(),
              items: [1, 2, 3]
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('${s}x')))
                  .toList(),
              onChanged: (v) {
                if (v != null) settings.setAutoScrollSpeed(v);
                setState(() {});
              },
            ),
          ),

          // ── Content & Recitation (Dropdown Pickers) ────────────────────
          _sectionHeader('Content & Recitation'),

          // Default Translation Selector
          _selectorTile(
            icon: Icons.translate,
            title: 'Default Translation',
            selectedName: currentTranslation?.name ?? 'Fateh Muhammad Jalandhry',
            selectedBadge: currentTranslation?.language.toUpperCase() ?? 'UR',
            onTap: () => _openEditionPicker(
              title: 'Select Default Translation',
              items: _translations,
              selectedId: settings.selectedTranslationId,
              onSelected: (id) {
                settings.setSelectedTranslationId(id);
                setState(() {});
              },
            ),
          ),

          // Default Tafseer Selector
          _selectorTile(
            icon: Icons.menu_book,
            title: 'Default Tafseer',
            selectedName: currentTafseer?.name ?? 'Tafseer Ibn Kathir',
            selectedBadge: currentTafseer?.language.toUpperCase() ?? 'EN',
            onTap: () => _openEditionPicker(
              title: 'Select Default Tafseer',
              items: _tafseers,
              selectedId: settings.selectedTafseerEditionId,
              onSelected: (id) {
                settings.setSelectedTafseerEditionId(id);
                setState(() {});
              },
            ),
          ),

          // Default Reciter Selector
          _selectorTile(
            icon: Icons.record_voice_over,
            title: 'Default Reciter',
            selectedName: currentReciter?.name ?? 'Mishary Rashid Alafasy',
            selectedBadge: currentReciter?.style ?? 'Hafs',
            onTap: () => _openReciterPicker(
              selectedId: settings.selectedReciterId,
              onSelected: (id) {
                settings.setSelectedReciterId(id);
                setState(() {});
              },
            ),
          ),

          // ── Languages Multi-Select ──────────────────────────────────────
          _sectionHeader('Preferred Languages'),
          _buildLanguageChips(settings),

          // ── Prayer Times & Fiqh ─────────────────────────────────────────
          _sectionHeader('Prayer Times & Fiqh'),
          Consumer(
            builder: (context, ref, child) {
              final selectedFiqh = ref.watch(selectedFiqhProvider);
              final isHanafi = selectedFiqh == 'hanafi';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8ECE9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Juristic Method (Fiqh / فقہ)',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Determines Asr prayer calculation method',
                                style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Choice Card 1: Hanafi
                    InkWell(
                      onTap: () => ref.read(selectedFiqhProvider.notifier).setFiqh('hanafi'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isHanafi ? AppTheme.primarySurface : const Color(0xFFFBFDFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHanafi ? AppTheme.primary : const Color(0xFFE2E8E4),
                            width: isHanafi ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHanafi ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isHanafi ? AppTheme.primary : AppTheme.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hanafi',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isHanafi ? AppTheme.primary : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Text(
                                        'حَنَفِي',
                                        style: TextStyle(
                                          fontFamily: 'Scheherazade New',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Later Asr time (Shadow factor = 2x)',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Choice Card 2: Shafi'i / Standard
                    InkWell(
                      onTap: () => ref.read(selectedFiqhProvider.notifier).setFiqh('standard'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: !isHanafi ? AppTheme.primarySurface : const Color(0xFFFBFDFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isHanafi ? AppTheme.primary : const Color(0xFFE2E8E4),
                            width: !isHanafi ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !isHanafi ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: !isHanafi ? AppTheme.primary : AppTheme.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Shafi\'i / Hanbali / Maliki',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: !isHanafi ? AppTheme.primary : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Text(
                                        'شَافِعِي • جُمْهُور',
                                        style: TextStyle(
                                          fontFamily: 'Scheherazade New',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Standard earlier Asr time (Shadow factor = 1x)',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Storage & Audio Cache ───────────────────────────────────────
          _sectionHeader('Storage & Audio Cache'),
          const _AudioCacheTile(),

          const SizedBox(height: 16),

          // ── App Update ──────────────────────────────────────────────────
          _sectionHeader('App Update'),
          _UpdateCheckTile(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLanguageChips(SettingsService settings) {
    const langs = {
      'ur': 'Urdu', 'en': 'English', 'ar': 'Arabic',
      'fr': 'French', 'de': 'German', 'tr': 'Turkish',
      'id': 'Indonesian', 'ms': 'Malay', 'bn': 'Bengali', 'fa': 'Persian',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: langs.entries.map((e) {
          final isSelected = settings.selectedLanguages.contains(e.key);
          return FilterChip(
            selected: isSelected,
            label: Text(e.value),
            selectedColor: AppTheme.primarySurface,
            checkmarkColor: AppTheme.primary,
            labelStyle: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
            ),
            onSelected: (selected) {
              final updated = List<String>.from(settings.selectedLanguages);
              if (selected) {
                updated.add(e.key);
              } else if (updated.length > 1) {
                updated.remove(e.key);
              }
              settings.setSelectedLanguages(updated);
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _selectorTile({
    required IconData icon,
    required String title,
    required String selectedName,
    required String selectedBadge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECE9)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selectedBadge.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedBadge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditionPicker({
    required String title,
    required List<Edition> items,
    required int? selectedId,
    required void Function(int id) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableEditionBottomSheet(
        title: title,
        items: items,
        selectedId: selectedId,
        onSelected: onSelected,
      ),
    );
  }

  void _openReciterPicker({
    required String selectedId,
    required void Function(String id) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableReciterBottomSheet(
        items: _reciters,
        selectedId: selectedId,
        onSelected: onSelected,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppTheme.primary, letterSpacing: 1.0)),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── Searchable Edition Picker Bottom Sheet ────────────────────────────────────
class _SearchableEditionBottomSheet extends StatefulWidget {
  final String title;
  final List<Edition> items;
  final int? selectedId;
  final void Function(int id) onSelected;

  const _SearchableEditionBottomSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_SearchableEditionBottomSheet> createState() => _SearchableEditionBottomSheetState();
}

class _SearchableEditionBottomSheetState extends State<_SearchableEditionBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.language.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or language...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, idx) {
                final item = filtered[idx];
                final isSelected = item.id == widget.selectedId;

                return ListTile(
                  title: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    item.language.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                      : null,
                  onTap: () {
                    widget.onSelected(item.id);
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

// ── Searchable Reciter Picker Bottom Sheet ────────────────────────────────────
class _SearchableReciterBottomSheet extends StatefulWidget {
  final List<Reciter> items;
  final String selectedId;
  final void Function(String id) onSelected;

  const _SearchableReciterBottomSheet({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_SearchableReciterBottomSheet> createState() => _SearchableReciterBottomSheetState();
}

class _SearchableReciterBottomSheetState extends State<_SearchableReciterBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((r) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return r.name.toLowerCase().contains(q) ||
          (r.style?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                const SizedBox(height: 12),
                Text(
                  'Select Reciter',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search reciter name or style...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reciters List
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, idx) {
                final r = filtered[idx];
                final isSelected = r.id == widget.selectedId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppTheme.primary : AppTheme.primarySurface,
                    child: Icon(
                      Icons.person,
                      color: isSelected ? Colors.white : AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    r.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    r.style ?? 'Hafs',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                      : null,
                  onTap: () {
                    widget.onSelected(r.id);
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

// ── Self-contained OTA Update Check Tile ──────────────────────────────────────
class _UpdateCheckTile extends StatefulWidget {
  @override
  State<_UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends State<_UpdateCheckTile> {
  bool _checking = false;
  bool _downloading = false;
  double _downloadProgress = 0;
  String _statusMessage = '';
  AppUpdateInfo? _updateInfo;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _currentVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checking = true;
      _statusMessage = '';
      _updateInfo = null;
    });

    final result = await UpdateService.checkForUpdate();

    if (mounted) {
      setState(() {
        _checking = false;
        _updateInfo = result;
        if (result.isUpdateAvailable) {
          _statusMessage = 'Update available: v${result.latestVersion}';
        } else {
          _statusMessage = 'You are on the latest version!';
        }
      });
    }
  }

  Future<void> _downloadUpdate() async {
    if (_updateInfo == null || _updateInfo!.downloadUrl.isEmpty) return;

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _statusMessage = 'Downloading update...';
    });

    await UpdateService.downloadAndInstall(
      _updateInfo!.downloadUrl,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _statusMessage = error;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _downloading = false;
            _statusMessage = 'Download complete! Installing...';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current version display
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text('Current Version: $_currentVersion',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 14),

          // Check for Updates button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_checking || _downloading) ? null : _checkForUpdate,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh, size: 20),
              label: Text(_checking ? 'Checking...' : 'Check for Updates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Status message
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: (_updateInfo?.isUpdateAvailable ?? false)
                    ? AppTheme.primary
                    : AppTheme.textMuted,
              ),
            ),
          ],

          // Changelog
          if (_updateInfo != null &&
              _updateInfo!.isUpdateAvailable &&
              _updateInfo!.changelog.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("What's New:",
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Text(_updateInfo!.changelog,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ],

          // Download progress bar
          if (_downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 8,
                backgroundColor: AppTheme.primarySurface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary),
            ),
          ],

          // Download & Install button
          if (_updateInfo != null &&
              _updateInfo!.isUpdateAvailable &&
              !_downloading) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadUpdate,
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download & Install Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioCacheTile extends StatefulWidget {
  const _AudioCacheTile();

  @override
  State<_AudioCacheTile> createState() => _AudioCacheTileState();
}

class _AudioCacheTileState extends State<_AudioCacheTile> {
  final AudioCacheService _cacheService = AudioCacheService();
  int _cacheSizeBytes = 0;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await _cacheService.getCacheSizeBytes();
    if (mounted) {
      setState(() => _cacheSizeBytes = size);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Audio Cache?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will delete all temporarily cached recitation audio files (${_cacheService.formatBytes(_cacheSizeBytes)}) from your device. You can stream or download them again anytime.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: Text('Clear Cache', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _clearing = true);
      await _cacheService.clearAllCache();
      await _loadCacheSize();
      if (mounted) {
        setState(() => _clearing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio cache cleared successfully.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeStr = _cacheService.formatBytes(_cacheSizeBytes);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storage_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recitation Audio Storage',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Cached Audio: $sizeStr',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: (_clearing || _cacheSizeBytes == 0) ? null : _clearCache,
                icon: _clearing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFD32F2F)),
                label: Text(
                  'Clear Cache',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _cacheSizeBytes == 0 ? AppTheme.textMuted : const Color(0xFFD32F2F),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _cacheSizeBytes == 0 ? const Color(0xFFE0E0E0) : const Color(0xFFFFCDD2),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
