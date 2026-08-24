// lib/features/ai_teacher/widgets/model_download_dialog.dart
// On-demand AI model download modal with real-time download progress
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/recitation_provider.dart';

class ModelDownloadDialog extends ConsumerStatefulWidget {
  final VoidCallback onDownloadComplete;

  const ModelDownloadDialog({
    super.key,
    required this.onDownloadComplete,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onDownloadComplete}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ModelDownloadDialog(onDownloadComplete: onDownloadComplete),
    );
  }

  @override
  ConsumerState<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends ConsumerState<ModelDownloadDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  String _statusText = 'Ready to download (~35 MB)';
  String _speedText = '';

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _statusText = 'Connecting to high-speed CDN...';
    });

    final manager = ref.read(aiModelManagerProvider);

    final sub = manager.progressStream.listen((data) {
      if (mounted) {
        setState(() {
          _progress = data.progress;
          final mbReceived = (data.receivedBytes / 1048576).toStringAsFixed(1);
          final mbTotal = (data.totalBytes / 1048576).toStringAsFixed(1);
          _statusText = 'Downloading: $mbReceived MB / $mbTotal MB (${(data.progress * 100).toInt()}%)';
          _speedText = data.speedString;
        });
      }
    });

    final success = await manager.downloadModel();
    await sub.cancel();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onDownloadComplete();
    } else {
      setState(() {
        _downloading = false;
        _statusText = 'Download failed. Please check internet and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Color(0xFF2E7D32), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live AI Quran Teacher',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'On-Demand AI Model Download',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Benefits checklist
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECE9)),
              ),
              child: Column(
                children: [
                  _benefitRow(Icons.check_circle_outline_rounded, 'Real-time Green / Red word verification'),
                  const SizedBox(height: 6),
                  _benefitRow(Icons.offline_bolt_outlined, '100% Offline after one-time download'),
                  const SizedBox(height: 6),
                  _benefitRow(Icons.security_outlined, 'Voice stays completely private on your device'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            if (_downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusText,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ),
                  if (_speedText.isNotEmpty)
                    Text(
                      _speedText,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                    ),
                ],
              ),
            ] else ...[
              Text(
                'Download size: ~35 MB. Kept on your device for instant offline recitation listening.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                if (!_downloading)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                    ),
                  ),
                if (!_downloading) const SizedBox(width: 10),
                Expanded(
                  flex: _downloading ? 1 : 2,
                  child: ElevatedButton.icon(
                    onPressed: _downloading ? null : _startDownload,
                    icon: _downloading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(_downloading ? 'Downloading...' : 'Download Model (~35 MB)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
