// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/edition.dart';
import '../../data/models/reciter.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/reciter_repository.dart';
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
    if (mounted) setState(() { _translations = t; _tafseers = tf; _reciters = r; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Reading ────────────────────────────────────────────────────
          _sectionHeader('Reading'),
          // ── Font Size ──────────────────────────────────────────────────
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

          // ── Languages ──────────────────────────────────────────────────
          _sectionHeader('Languages'),
          ..._buildLanguageTiles(settings),

          // ── Translation ────────────────────────────────────────────────
          _sectionHeader('Default Translation'),
          ..._translations.map((e) => _radioTile(
                title: e.name,
                subtitle: e.language.toUpperCase(),
                selected: settings.selectedTranslationId == e.id,
                onTap: () {
                  settings.setSelectedTranslationId(e.id);
                  setState(() {});
                },
              )),

          // ── Tafseer ────────────────────────────────────────────────────
          _sectionHeader('Default Tafseer'),
          ..._tafseers.map((e) => _radioTile(
                title: e.name,
                subtitle: e.language.toUpperCase(),
                selected: settings.selectedTafseerEditionId == e.id,
                onTap: () {
                  settings.setSelectedTafseerEditionId(e.id);
                  setState(() {});
                },
              )),

          // ── Reciter ────────────────────────────────────────────────────
          _sectionHeader('Default Reciter'),
          ..._reciters.map((r) => _radioTile(
                title: r.name,
                subtitle: r.style ?? '',
                selected: settings.selectedReciterId == r.id,
                onTap: () {
                  settings.setSelectedReciterId(r.id);
                  setState(() {});
                },
              )),

          const SizedBox(height: 32),

          // ── App Update ──────────────────────────────────────────────────
          _sectionHeader('App Update'),
          _UpdateCheckTile(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildLanguageTiles(SettingsService settings) {
    const langs = {
      'ur': 'Urdu', 'en': 'English', 'ar': 'Arabic',
      'fr': 'French', 'de': 'German', 'tr': 'Turkish',
      'id': 'Indonesian', 'ms': 'Malay', 'bn': 'Bengali', 'fa': 'Persian',
    };
    return langs.entries.map((e) {
      final selected = settings.selectedLanguages.contains(e.key);
      return CheckboxListTile(
        value: selected,
        title: Text(e.value, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
        activeColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        onChanged: (v) {
          final langs = List<String>.from(settings.selectedLanguages);
          if (v == true) { langs.add(e.key); }
          else if (langs.length > 1) { langs.remove(e.key); }
          settings.setSelectedLanguages(langs);
          setState(() {});
        },
      );
    }).toList();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
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
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
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

  Widget _radioTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySurface : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.primary : AppTheme.textMuted),
          ],
        ),
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

