import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/services/edge_function_service.dart';
import 'package:axion/core/services/audio_service.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/interview/data/interview_repository.dart';

// ─── Interview Setup State ─────────────────────────────────

class InterviewSetupState {
  final InterviewArea? selectedArea;
  final SeniorityLevel? selectedLevel;
  final String jobDescription;
  final bool isValid;

  const InterviewSetupState({
    this.selectedArea,
    this.selectedLevel,
    this.jobDescription = '',
  }) : isValid = selectedArea != null && selectedLevel != null;

  InterviewSetupState copyWith({
    InterviewArea? selectedArea,
    SeniorityLevel? selectedLevel,
    String? jobDescription,
  }) {
    return InterviewSetupState(
      selectedArea: selectedArea ?? this.selectedArea,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      jobDescription: jobDescription ?? this.jobDescription,
    );
  }
}

class InterviewSetupNotifier extends StateNotifier<InterviewSetupState> {
  InterviewSetupNotifier() : super(const InterviewSetupState());

  void selectArea(InterviewArea area) {
    state = state.copyWith(selectedArea: area);
  }

  void selectLevel(SeniorityLevel level) {
    state = state.copyWith(selectedLevel: level);
  }

  void setJobDescription(String description) {
    state = state.copyWith(jobDescription: description);
  }

  void reset() {
    state = const InterviewSetupState();
  }
}

final interviewSetupProvider =
    StateNotifierProvider<InterviewSetupNotifier, InterviewSetupState>(
  (ref) => InterviewSetupNotifier(),
);

// ─── Active Interview Session State ─────────────────────────

class ActiveInterviewState {
  final InterviewSession? session;
  final int currentQuestionIndex;
  final int totalQuestions;
  final InterviewPhase phase;
  final String currentSubtitle;
  final List<String> questions;
  final Duration elapsed;
  final bool isActive;
  final String? userTranscript;

  const ActiveInterviewState({
    this.session,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 0,
    this.phase = InterviewPhase.idle,
    this.currentSubtitle = '',
    this.questions = const [],
    this.elapsed = Duration.zero,
    this.isActive = false,
    this.userTranscript,
  });

  ActiveInterviewState copyWith({
    InterviewSession? session,
    int? currentQuestionIndex,
    int? totalQuestions,
    InterviewPhase? phase,
    String? currentSubtitle,
    List<String>? questions,
    Duration? elapsed,
    bool? isActive,
    String? userTranscript,
  }) {
    return ActiveInterviewState(
      session: session ?? this.session,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      phase: phase ?? this.phase,
      currentSubtitle: currentSubtitle ?? this.currentSubtitle,
      questions: questions ?? this.questions,
      elapsed: elapsed ?? this.elapsed,
      isActive: isActive ?? this.isActive,
      userTranscript: userTranscript ?? this.userTranscript,
    );
  }

  String get formattedTime {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class ActiveInterviewNotifier extends StateNotifier<ActiveInterviewState> {
  final EdgeFunctionService _edgeFunctions;
  final AudioService _audio;
  Timer? _timer;
  final List<InterviewQuestion> _answeredQuestions = [];

  ActiveInterviewNotifier({
    required EdgeFunctionService edgeFunctions,
    required AudioService audio,
  })  : _edgeFunctions = edgeFunctions,
        _audio = audio,
        super(const ActiveInterviewState());

  Future<void> startInterview(InterviewSession session) async {
    _answeredQuestions.clear();

    state = ActiveInterviewState(
      session: session,
      isActive: true,
      phase: InterviewPhase.aiSpeaking,
      currentSubtitle: 'Gerando perguntas...',
    );

    _startTimer();

    try {
      final questions = await _edgeFunctions.generateQuestions(
        area: session.area.name,
        level: session.level.name,
        jobDescription: session.jobDescription,
        count: AppConstants.maxQuestions,
      );

      final total = questions.length.clamp(
        AppConstants.minQuestions,
        AppConstants.maxQuestions,
      );

      state = state.copyWith(
        questions: questions.take(total).toList(),
        totalQuestions: total,
        currentQuestionIndex: 0,
        currentSubtitle: questions.first,
      );

      await _speakCurrentQuestion();
    } catch (e) {
      debugPrint('Error generating questions: $e');
      // Graceful degradation: end the interview
      state = state.copyWith(
        isActive: false,
        phase: InterviewPhase.idle,
        currentSubtitle: 'Erro ao gerar perguntas.',
      );
      _timer?.cancel();
    }
  }

  Future<void> _speakCurrentQuestion() async {
    if (!state.isActive) return;

    final questionText = state.questions[state.currentQuestionIndex];
    state = state.copyWith(
      phase: InterviewPhase.aiSpeaking,
      currentSubtitle: questionText,
    );

    // Use device TTS — fires onTtsComplete when done
    _audio.onTtsComplete = _onAiFinishedSpeaking;
    await _audio.speak(questionText);
  }

  void _onAiFinishedSpeaking() {
    if (!mounted || !state.isActive) return;
    state = state.copyWith(phase: InterviewPhase.userSpeaking);
    _audio.startRecording();
  }

  Future<void> endUserResponse() async {
    if (state.phase != InterviewPhase.userSpeaking) return;

    state = state.copyWith(phase: InterviewPhase.processing);

    String transcript = '';
    try {
      final audioBytes = await _audio.stopRecording();
      if (audioBytes != null && audioBytes.isNotEmpty) {
        transcript = await _edgeFunctions.transcribeAudio(audioBytes);
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
      transcript = '[transcrição indisponível]';
    }

    if (!state.isActive) return;

    // Evaluate the answer
    int? score;
    String? evaluation;
    try {
      final result = await _edgeFunctions.evaluateAnswer(
        question: state.questions[state.currentQuestionIndex],
        answer: transcript,
        area: state.session!.area.name,
        level: state.session!.level.name,
      );
      score = result['score'] as int?;
      evaluation = result['evaluation'] as String?;
    } catch (e) {
      debugPrint('Evaluation error: $e');
    }

    final question = InterviewQuestion.create(
      interviewId: state.session!.id,
      questionOrder: state.currentQuestionIndex,
      question: state.questions[state.currentQuestionIndex],
    ).copyWith(
      userAnswerTranscript: transcript,
      score: score,
      evaluation: evaluation != null
          ? QuestionEvaluation.fromString(evaluation)
          : null,
    );

    _answeredQuestions.add(question);

    state = state.copyWith(userTranscript: transcript);

    _moveToNextQuestion();
  }

  void _moveToNextQuestion() {
    final nextIndex = state.currentQuestionIndex + 1;

    if (nextIndex >= state.totalQuestions) {
      final updatedSession = state.session!.copyWith(
        questions: List.from(_answeredQuestions),
        status: InterviewStatus.completed,
      );
      state = state.copyWith(
        session: updatedSession,
        phase: InterviewPhase.finished,
        isActive: false,
      );
      _timer?.cancel();
      return;
    }

    state = state.copyWith(
      currentQuestionIndex: nextIndex,
      currentSubtitle: state.questions[nextIndex],
      userTranscript: null,
    );

    _speakCurrentQuestion();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );
      }
    });
  }

  void endEarly() {
    _audio.stopRecording();
    _audio.stopSpeaking();

    final updatedSession = state.session?.copyWith(
      questions: List.from(_answeredQuestions),
      status: InterviewStatus.endedEarly,
      endedEarly: true,
    );
    state = state.copyWith(
      session: updatedSession,
      isActive: false,
      phase: InterviewPhase.idle,
    );
    _timer?.cancel();
  }

  InterviewSession? getCompletedSession() => state.session;

  void reset() {
    _timer?.cancel();
    _answeredQuestions.clear();
    state = const ActiveInterviewState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeInterviewProvider =
    StateNotifierProvider<ActiveInterviewNotifier, ActiveInterviewState>(
  (ref) => ActiveInterviewNotifier(
    edgeFunctions: ref.watch(edgeFunctionServiceProvider),
    audio: ref.watch(audioServiceProvider),
  ),
);

// ─── Completed Interview Provider (for report) ─────────────

final completedInterviewProvider =
    StateProvider<InterviewSession?>((ref) => null);

// ─── Interview History ───────────────────────────────────────

class InterviewHistoryNotifier extends StateNotifier<List<InterviewSession>> {
  final InterviewRepository _repo;

  InterviewHistoryNotifier(this._repo) : super([]);

  Future<void> loadHistory(String userId) async {
    try {
      state = await _repo.getHistory(userId);
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> addAndSave(InterviewSession session) async {
    // Optimistically update UI
    state = [session, ...state];
    try {
      await _repo.saveSession(session);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }
}

final interviewHistoryProvider =
    StateNotifierProvider<InterviewHistoryNotifier, List<InterviewSession>>(
  (ref) => InterviewHistoryNotifier(ref.watch(interviewRepositoryProvider)),
);
