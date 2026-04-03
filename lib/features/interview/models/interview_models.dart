import 'package:uuid/uuid.dart';
import 'package:axion/core/constants/app_constants.dart';

const _uuid = Uuid();

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final InterviewArea? preferredArea;
  final SeniorityLevel? seniorityLevel;
  final String? photoUrl;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredArea,
    this.seniorityLevel,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      preferredArea: json['preferred_area'] != null
          ? InterviewArea.values.firstWhere(
              (e) => e.name == json['preferred_area'],
              orElse: () => InterviewArea.mobileDev,
            )
          : null,
      seniorityLevel: json['seniority_level'] != null
          ? SeniorityLevel.values.firstWhere(
              (e) => e.name == json['seniority_level'],
              orElse: () => SeniorityLevel.junior,
            )
          : null,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'preferred_area': preferredArea?.name,
        'seniority_level': seniorityLevel?.name,
        'onboarding_completed': onboardingCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    InterviewArea? preferredArea,
    SeniorityLevel? seniorityLevel,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredArea: preferredArea ?? this.preferredArea,
      seniorityLevel: seniorityLevel ?? this.seniorityLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get firstName =>
      displayName?.split(' ').first ?? email.split('@').first;
}

class InterviewSession {
  final String id;
  final String userId;
  final InterviewArea area;
  final SeniorityLevel level;
  final String? jobDescription;
  final InterviewStatus status;
  final int? overallScore;
  final int? technicalScore;
  final int? clarityScore;
  final int? fluencyScore;
  final DateTime createdAt;
  final bool endedEarly;
  final List<InterviewQuestion> questions;
  final ActionPlan? actionPlan;

  const InterviewSession({
    required this.id,
    required this.userId,
    required this.area,
    required this.level,
    this.jobDescription,
    this.status = InterviewStatus.inProgress,
    this.overallScore,
    this.technicalScore,
    this.clarityScore,
    this.fluencyScore,
    required this.createdAt,
    this.endedEarly = false,
    this.questions = const [],
    this.actionPlan,
  });

  factory InterviewSession.create({
    required String userId,
    required InterviewArea area,
    required SeniorityLevel level,
    String? jobDescription,
  }) {
    return InterviewSession(
      id: _uuid.v4(),
      userId: userId,
      area: area,
      level: level,
      jobDescription: jobDescription,
      createdAt: DateTime.now(),
    );
  }

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    // Support nested Supabase joins: interview_questions(*), action_plans(*)
    final questionsJson = json['interview_questions'] as List<dynamic>?;
    final actionPlansJson = json['action_plans'] as List<dynamic>?;

    return InterviewSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      area: InterviewArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => InterviewArea.mobileDev,
      ),
      level: SeniorityLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => SeniorityLevel.junior,
      ),
      jobDescription: json['job_description'] as String?,
      status: InterviewStatus.fromString(json['status'] as String),
      overallScore: json['overall_score'] as int?,
      technicalScore: json['technical_score'] as int?,
      clarityScore: json['clarity_score'] as int?,
      fluencyScore: json['fluency_score'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      endedEarly: json['ended_early'] as bool? ?? false,
      questions: questionsJson
              ?.map((q) =>
                  InterviewQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
      actionPlan: actionPlansJson != null && actionPlansJson.isNotEmpty
          ? ActionPlan.fromJson(
              actionPlansJson.first as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'area': area.name,
        'level': level.name,
        'job_description': jobDescription,
        'status': status.value,
        'overall_score': overallScore,
        'technical_score': technicalScore,
        'clarity_score': clarityScore,
        'fluency_score': fluencyScore,
        'created_at': createdAt.toIso8601String(),
        'ended_early': endedEarly,
      };

  InterviewSession copyWith({
    InterviewStatus? status,
    int? overallScore,
    int? technicalScore,
    int? clarityScore,
    int? fluencyScore,
    bool? endedEarly,
    List<InterviewQuestion>? questions,
    ActionPlan? actionPlan,
  }) {
    return InterviewSession(
      id: id,
      userId: userId,
      area: area,
      level: level,
      jobDescription: jobDescription,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      technicalScore: technicalScore ?? this.technicalScore,
      clarityScore: clarityScore ?? this.clarityScore,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      createdAt: createdAt,
      endedEarly: endedEarly ?? this.endedEarly,
      questions: questions ?? this.questions,
      actionPlan: actionPlan ?? this.actionPlan,
    );
  }
}

class InterviewQuestion {
  final String id;
  final String interviewId;
  final int questionOrder;
  final String question;
  final String? userAnswerTranscript;
  final int? score;
  final String? idealAnswer;
  final QuestionEvaluation? evaluation;
  final DateTime createdAt;

  const InterviewQuestion({
    required this.id,
    required this.interviewId,
    required this.questionOrder,
    required this.question,
    this.userAnswerTranscript,
    this.score,
    this.idealAnswer,
    this.evaluation,
    required this.createdAt,
  });

  factory InterviewQuestion.create({
    required String interviewId,
    required int questionOrder,
    required String question,
  }) {
    return InterviewQuestion(
      id: _uuid.v4(),
      interviewId: interviewId,
      questionOrder: questionOrder,
      question: question,
      createdAt: DateTime.now(),
    );
  }

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] as String,
      interviewId: json['interview_id'] as String,
      questionOrder: json['question_order'] as int,
      question: json['question'] as String,
      userAnswerTranscript: json['user_answer_transcript'] as String?,
      score: json['score'] as int?,
      idealAnswer: json['ideal_answer'] as String?,
      evaluation: json['evaluation'] != null
          ? QuestionEvaluation.fromString(json['evaluation'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'interview_id': interviewId,
        'question_order': questionOrder,
        'question': question,
        'user_answer_transcript': userAnswerTranscript,
        'score': score,
        'ideal_answer': idealAnswer,
        'evaluation': evaluation?.label,
        'created_at': createdAt.toIso8601String(),
      };

  InterviewQuestion copyWith({
    String? userAnswerTranscript,
    int? score,
    String? idealAnswer,
    QuestionEvaluation? evaluation,
  }) {
    return InterviewQuestion(
      id: id,
      interviewId: interviewId,
      questionOrder: questionOrder,
      question: question,
      userAnswerTranscript:
          userAnswerTranscript ?? this.userAnswerTranscript,
      score: score ?? this.score,
      idealAnswer: idealAnswer ?? this.idealAnswer,
      evaluation: evaluation ?? this.evaluation,
      createdAt: createdAt,
    );
  }
}

class ActionPlan {
  final String id;
  final String interviewId;
  final List<String> criticalPoints;
  final List<String> reviewPoints;
  final List<String> strengths;
  final DateTime createdAt;

  const ActionPlan({
    required this.id,
    required this.interviewId,
    required this.criticalPoints,
    required this.reviewPoints,
    required this.strengths,
    required this.createdAt,
  });

  factory ActionPlan.fromJson(Map<String, dynamic> json) {
    return ActionPlan(
      id: json['id'] as String,
      interviewId: json['interview_id'] as String,
      criticalPoints: (json['critical_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reviewPoints: (json['review_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'interview_id': interviewId,
        'critical_points': criticalPoints,
        'review_points': reviewPoints,
        'strengths': strengths,
        'created_at': createdAt.toIso8601String(),
      };
}
