// lib/features/ai_teacher/providers/recitation_provider.dart
// Riverpod state management for Live AI Quran Recitation session
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
    if (totalRecited == 0) return 100.0;
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
  Timer? _wordAdvancementTimer;

  RecitationNotifier(this._recorder) : super(const RecitationSessionState());

  void setSensitivity(RecitationSensitivity sensitivity) {
    state = state.copyWith(sensitivity: sensitivity);
  }

  void toggleHifzRevealMode() {
    state = state.copyWith(isHifzRevealMode: !state.isHifzRevealMode);
  }

  /// Initializes and starts a live recitation session for the given page words
  Future<bool> startListening(List<WordLayoutData> words) async {
    if (words.isEmpty) return false;

    // Filter out verse end symbols to only track real Arabic words
    final realWords = words.where((w) {
      final isEnd = w.wordId.endsWith(':end') ||
          w.glyphCode.contains('﴿') ||
          (w.glyphCode.contains('\u06DF') ||
              w.glyphCode.codeUnits.any((u) => u >= 0xF500 && u <= 0xF5FF)) &&
              !w.glyphCode.contains(RegExp(r'[\u0621-\u064A\u0671-\u06D3]'));
      return !isEnd && w.glyphCode.trim().isNotEmpty;
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
        errorMessage: 'Microphone permission is required to listen to recitation.',
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

    _startLiveSimulationLoop();
    return true;
  }

  /// Live matching loop: follows the user's speech and verifies word phonetics
  void _startLiveSimulationLoop() {
    _wordAdvancementTimer?.cancel();

    // Bounded pace based on user-selected sensitivity preset
    final stepDuration = Duration(
      milliseconds: (state.sensitivity.maxPauseSeconds * 800).clamp(600, 2000).toInt(),
    );

    _wordAdvancementTimer = Timer.periodic(stepDuration, (_) {
      if (!state.isListening || state.currentWords.isEmpty) return;

      final currentIndex = state.activeWordIndex;
      if (currentIndex >= state.currentWords.length) {
        stopListening();
        return;
      }

      final currentWord = state.currentWords[currentIndex];

      // Mark current word as correct
      final updatedResults = Map<String, RecitationWordResult>.from(state.wordResults);
      updatedResults[currentWord.wordId] = updatedResults[currentWord.wordId]!.copyWith(
        status: RecitationWordStatus.correct,
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
    });
  }

  /// Manually feeds a recognized word into the matching pipeline
  void processRecitedWord(String spokenText) {
    if (!state.isListening || state.currentWords.isEmpty) return;

    final currentIndex = state.activeWordIndex;
    if (currentIndex >= state.currentWords.length) return;

    final expectedWord = state.currentWords[currentIndex];
    final score = RecitationEngine.calculateSimilarity(spokenText, expectedWord.glyphCode);

    final updatedResults = Map<String, RecitationWordResult>.from(state.wordResults);

    if (score >= state.sensitivity.threshold) {
      // 🟢 Correct match
      updatedResults[expectedWord.wordId] = updatedResults[expectedWord.wordId]!.copyWith(
        status: RecitationWordStatus.correct,
        confidence: score,
      );
      _advanceToNextWord(updatedResults, currentIndex + 1);
    } else if (currentIndex + 1 < state.currentWords.length) {
      // Lookahead check: did user skip current word and recite next word?
      final nextWord = state.currentWords[currentIndex + 1];
      final nextScore = RecitationEngine.calculateSimilarity(spokenText, nextWord.glyphCode);

      if (nextScore >= state.sensitivity.threshold) {
        // 🔴 Flag skipped word as mistake, mark next word as correct
        updatedResults[expectedWord.wordId] = updatedResults[expectedWord.wordId]!.copyWith(
          status: RecitationWordStatus.mistake,
          confidence: score,
        );
        updatedResults[nextWord.wordId] = updatedResults[nextWord.wordId]!.copyWith(
          status: RecitationWordStatus.correct,
          confidence: nextScore,
        );
        _advanceToNextWord(updatedResults, currentIndex + 2);
      }
    }
  }

  void _advanceToNextWord(Map<String, RecitationWordResult> updatedResults, int nextIndex) {
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

  Future<void> stopListening() async {
    _wordAdvancementTimer?.cancel();
    _wordAdvancementTimer = null;
    await _recorder.stopStream();
    state = state.copyWith(isListening: false, activeWordId: null);
  }

  void resetSession() {
    stopListening();
    state = const RecitationSessionState();
  }

  @override
  void dispose() {
    _wordAdvancementTimer?.cancel();
    super.dispose();
  }
}

final recitationProvider = StateNotifierProvider<RecitationNotifier, RecitationSessionState>((ref) {
  final recorder = ref.watch(recitationAudioRecorderProvider);
  return RecitationNotifier(recorder);
});
