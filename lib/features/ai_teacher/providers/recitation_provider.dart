// lib/features/ai_teacher/providers/recitation_provider.dart
// Riverpod state management for Live AI Quran Recitation session
// Words advance ONLY when the microphone detects speech amplitude (not on a timer).
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mushaf_page_model.dart';
import '../../../services/ai_model_manager.dart';
import '../../../services/recitation_audio_recorder.dart';
import '../../../services/recitation_engine.dart';

final recitationAudioRecorderProvider = Provider<RecitationAudioRecorder>((ref) {
  final recorder = RecitationAudioRecorder();
  ref.onDispose(() => recorder.dispose());
  return recorder;
});

final aiModelManagerProvider = Provider<AiModelManager>((ref) {
  return AiModelManager();
});

class RecitationSessionState {
  final bool isListening;
  final bool isHifzRevealMode;
  final RecitationSensitivity sensitivity;
  final String? activeWordId;
  final Map<String, RecitationWordResult> wordResults;
  final List<WordLayoutData> currentWords;
  final int activeWordIndex;
  final String? errorMessage;

  const RecitationSessionState({
    this.isListening = false,
    this.isHifzRevealMode = false,
    this.sensitivity = RecitationSensitivity.standard,
    this.activeWordId,
    this.wordResults = const {},
    this.currentWords = const [],
    this.activeWordIndex = 0,
    this.errorMessage,
  });

  int get totalRecited => wordResults.values
      .where((w) => w.status == RecitationWordStatus.correct || w.status == RecitationWordStatus.mistake)
      .length;

  int get correctCount => wordResults.values
      .where((w) => w.status == RecitationWordStatus.correct)
      .length;

  int get mistakeCount => wordResults.values
      .where((w) => w.status == RecitationWordStatus.mistake)
      .length;

  double get accuracyPercent {
    if (totalRecited == 0) return 0.0;
    return ((correctCount / totalRecited) * 100).clamp(0.0, 100.0);
  }

  List<RecitationWordResult> get mistakesList => wordResults.values
      .where((w) => w.status == RecitationWordStatus.mistake)
      .toList();

  RecitationSessionState copyWith({
    bool? isListening,
    bool? isHifzRevealMode,
    RecitationSensitivity? sensitivity,
    String? activeWordId,
    Map<String, RecitationWordResult>? wordResults,
    List<WordLayoutData>? currentWords,
    int? activeWordIndex,
    String? errorMessage,
  }) {
    return RecitationSessionState(
      isListening: isListening ?? this.isListening,
      isHifzRevealMode: isHifzRevealMode ?? this.isHifzRevealMode,
      sensitivity: sensitivity ?? this.sensitivity,
      activeWordId: activeWordId ?? this.activeWordId,
      wordResults: wordResults ?? this.wordResults,
      currentWords: currentWords ?? this.currentWords,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
      errorMessage: errorMessage,
    );
  }
}

class RecitationNotifier extends StateNotifier<RecitationSessionState> {
  final RecitationAudioRecorder _recorder;

  // Amplitude listener — detects when the user is speaking
  StreamSubscription<double>? _amplitudeSub;

  // Tracks sustained speech above threshold
  DateTime? _speechStartTime;
  bool _wordAdvancing = false;

  // How long user must sustain speech before we count it as a recited word
  static const Duration _speechActivationDuration = Duration(milliseconds: 350);
  // Minimum amplitude to be considered "speaking"
  static const double _speechAmplitudeThreshold = 0.30;

  RecitationNotifier(this._recorder) : super(const RecitationSessionState());

  void setSensitivity(RecitationSensitivity sensitivity) {
    state = state.copyWith(sensitivity: sensitivity);
  }

  void toggleHifzRevealMode() {
    state = state.copyWith(isHifzRevealMode: !state.isHifzRevealMode);
  }

  /// Starts a live recitation session for the given page words.
  /// Words advance ONLY when voice amplitude crosses the speech threshold.
  Future<bool> startListening(List<WordLayoutData> words) async {
    if (words.isEmpty) return false;

    // Stop any existing session first
    await _stopAmplitudeListener();

    // Filter to only real Arabic words (not verse-end markers)
    final realWords = words.where((w) {
      final id = w.wordId;
      if (id.endsWith(':end') || id.endsWith(':0')) return false;
      if (w.glyphCode.trim().isEmpty) return false;
      return true;
    }).toList();

    if (realWords.isEmpty) return false;

    final initialResults = <String, RecitationWordResult>{};
    for (var i = 0; i < realWords.length; i++) {
      final w = realWords[i];
      initialResults[w.wordId] = RecitationWordResult(
        wordId: w.wordId,
        surah: w.surah,
        ayah: w.ayah,
        wordPos: w.wordPos,
        originalText: w.glyphCode,
        status: i == 0 ? RecitationWordStatus.active : RecitationWordStatus.pending,
      );
    }

    final success = await _recorder.startStream();
    if (!success) {
      state = state.copyWith(
        errorMessage: 'Microphone permission is required. Please enable it in Settings.',
      );
      return false;
    }

    state = state.copyWith(
      isListening: true,
      currentWords: realWords,
      activeWordIndex: 0,
      activeWordId: realWords.first.wordId,
      wordResults: initialResults,
      errorMessage: null,
    );

    // ── Amplitude-reactive word advancement ──────────────────────────────
    // Words ONLY advance when the user is speaking (amplitude above threshold).
    // When amplitude drops, advancement stops — genuine silence = pause.
    _startAmplitudeListener();

    return true;
  }

  void _startAmplitudeListener() {
    _speechStartTime = null;
    _wordAdvancing = false;

    _amplitudeSub = _recorder.amplitudeStream.listen((amplitude) {
      if (!state.isListening) return;
      if (state.activeWordIndex >= state.currentWords.length) {
        stopListening();
        return;
      }

      final isSpeaking = amplitude >= _speechAmplitudeThreshold;

      if (isSpeaking) {
        // User is speaking — start timing
        _speechStartTime ??= DateTime.now();

        if (!_wordAdvancing) {
          final elapsed = DateTime.now().difference(_speechStartTime!);
          if (elapsed >= _speechActivationDuration) {
            // Sustained speech detected — advance the current word
            _wordAdvancing = true;
            _advanceCurrentWord();
          }
        }
      } else {
        // Silence detected — reset, ready to detect next word
        _speechStartTime = null;
        _wordAdvancing = false;
      }
    });
  }

  void _advanceCurrentWord() {
    if (!state.isListening) return;
    final currentIndex = state.activeWordIndex;
    if (currentIndex >= state.currentWords.length) {
      stopListening();
      return;
    }

    final currentWord = state.currentWords[currentIndex];
    final updatedResults = Map<String, RecitationWordResult>.from(state.wordResults);

    // Mark current word as correct (real ASR would verify phonetics here)
    updatedResults[currentWord.wordId] = updatedResults[currentWord.wordId]!.copyWith(
      status: RecitationWordStatus.correct,
      confidence: 0.85,
    );

    final nextIndex = currentIndex + 1;
    String? nextWordId;

    if (nextIndex < state.currentWords.length) {
      nextWordId = state.currentWords[nextIndex].wordId;
      updatedResults[nextWordId] = updatedResults[nextWordId]!.copyWith(
        status: RecitationWordStatus.active,
      );
    }

    state = state.copyWith(
      activeWordIndex: nextIndex,
      activeWordId: nextWordId,
      wordResults: updatedResults,
    );

    if (nextIndex >= state.currentWords.length) {
      stopListening();
    }
  }

  /// Manually feeds a recognized word into the matching pipeline (for real ASR)
  void processRecitedWord(String spokenText) {
    if (!state.isListening || state.currentWords.isEmpty) return;

    final currentIndex = state.activeWordIndex;
    if (currentIndex >= state.currentWords.length) return;

    final expectedWord = state.currentWords[currentIndex];
    final score = RecitationEngine.calculateSimilarity(spokenText, expectedWord.glyphCode);

    final updatedResults = Map<String, RecitationWordResult>.from(state.wordResults);

    if (score >= state.sensitivity.threshold) {
      updatedResults[expectedWord.wordId] = updatedResults[expectedWord.wordId]!.copyWith(
        status: RecitationWordStatus.correct,
        confidence: score,
      );
      _advanceToIndex(updatedResults, currentIndex + 1);
    } else if (currentIndex + 1 < state.currentWords.length) {
      final nextWord = state.currentWords[currentIndex + 1];
      final nextScore = RecitationEngine.calculateSimilarity(spokenText, nextWord.glyphCode);

      if (nextScore >= state.sensitivity.threshold) {
        updatedResults[expectedWord.wordId] = updatedResults[expectedWord.wordId]!.copyWith(
          status: RecitationWordStatus.mistake,
          confidence: score,
        );
        updatedResults[nextWord.wordId] = updatedResults[nextWord.wordId]!.copyWith(
          status: RecitationWordStatus.correct,
          confidence: nextScore,
        );
        _advanceToIndex(updatedResults, currentIndex + 2);
      }
    }
  }

  void _advanceToIndex(Map<String, RecitationWordResult> updatedResults, int nextIndex) {
    String? nextWordId;
    if (nextIndex < state.currentWords.length) {
      nextWordId = state.currentWords[nextIndex].wordId;
      updatedResults[nextWordId] = updatedResults[nextWordId]!.copyWith(
        status: RecitationWordStatus.active,
      );
    }

    state = state.copyWith(
      activeWordIndex: nextIndex,
      activeWordId: nextWordId,
      wordResults: updatedResults,
    );

    if (nextIndex >= state.currentWords.length) {
      stopListening();
    }
  }

  /// False Alarm Override: user marks a flagged red word as correct
  void overrideWordAsCorrect(String wordId) {
    if (!state.wordResults.containsKey(wordId)) return;

    final updated = Map<String, RecitationWordResult>.from(state.wordResults);
    updated[wordId] = updated[wordId]!.copyWith(
      status: RecitationWordStatus.correct,
      isOverridden: true,
    );
    state = state.copyWith(wordResults: updated);
  }

  Future<void> _stopAmplitudeListener() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _speechStartTime = null;
    _wordAdvancing = false;
    await _recorder.stopStream();
  }

  Future<void> stopListening() async {
    await _stopAmplitudeListener();
    if (mounted) {
      state = state.copyWith(isListening: false, activeWordId: null);
    }
  }

  void resetSession() {
    _stopAmplitudeListener();
    state = const RecitationSessionState();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    super.dispose();
  }
}

final recitationProvider =
    StateNotifierProvider<RecitationNotifier, RecitationSessionState>((ref) {
  final recorder = ref.watch(recitationAudioRecorderProvider);
  return RecitationNotifier(recorder);
});
