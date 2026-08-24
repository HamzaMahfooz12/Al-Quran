// lib/services/recitation_audio_recorder.dart
// Stub audio recorder for the AI Quran Teacher UI demo.
// The 'record' package has a known build incompatibility in version 5.2.x
// (record_linux 0.7.2 does not implement startStream from record_platform_interface 1.6.0).
// This stub provides a working microphone visualizer via simulated amplitude
// so all UI flows work correctly until the AI model integration phase.
import 'dart:async';
import 'dart:math';

class RecitationAudioRecorder {
  final _random = Random();
  Timer? _amplitudeTimer;

  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  // Stub pcmStream (no-op)
  Stream<List<int>> get pcmStream => const Stream.empty();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async => true;

  Future<bool> startStream() async {
    if (_isRecording) return true;

    _isRecording = true;

    // Simulate realistic speech amplitude pulses for the visualizer
    double _phase = 0.0;
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 80), (_) {
      _phase += 0.3;
      final base = sin(_phase) * 0.35 + 0.45;
      final noise = (_random.nextDouble() - 0.5) * 0.25;
      final amplitude = (base + noise).clamp(0.0, 1.0);
      _amplitudeController.add(amplitude);
    });

    return true;
  }

  Future<void> stopStream() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _isRecording = false;
    _amplitudeController.add(0.0);
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController.close();
  }
}
