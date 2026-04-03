class AppConstants {
  // Supabase Tables
  static const String usersTable = 'users';
  static const String interviewsTable = 'interviews';
  static const String interviewQuestionsTable = 'interview_questions';
  static const String actionPlansTable = 'action_plans';

  // Edge Function Endpoints
  static const String generateQuestionsEndpoint = 'generate-questions';
  static const String evaluateAnswerEndpoint = 'evaluate-answer';
  static const String generateReportEndpoint = 'generate-report';
  static const String transcribeEndpoint = 'transcribe';
  static const String ttsEndpoint = 'tts';

  // Interview Config
  static const int minQuestions = 6;
  static const int maxQuestions = 8;
  static const int countdownSeconds = 3;

  // Score Weights
  static const double technicalWeight = 0.50;
  static const double clarityWeight = 0.30;
  static const double fluencyWeight = 0.20;

  AppConstants._();
}

enum InterviewArea {
  mobileDev('Mobile', 'Flutter, React Native, Swift, Kotlin', '📱'),
  webFrontend('Web Frontend', 'React, Vue, Angular, Next.js', '🌐'),
  webBackend('Web Backend', 'Node.js, Python/Django, Java/Spring, Go', '⚙️'),
  databases('Banco de Dados & Dados', 'SQL, NoSQL, Data Engineering', '🗄️'),
  devopsCloud('DevOps & Cloud', 'AWS, GCP, Docker, Kubernetes', '☁️'),
  qaTesting('QA & Testes', 'Automação, Performance, Segurança', '🧪'),
  security('Segurança da Informação', 'AppSec, Infra, Compliance', '🔒'),
  architecture('Arquitetura de Software', 'Design Patterns, Microservices, DDD', '🏗️');

  final String label;
  final String description;
  final String emoji;

  const InterviewArea(this.label, this.description, this.emoji);
}

enum SeniorityLevel {
  junior('Júnior', '0-2 anos de experiência'),
  mid('Pleno', '2-5 anos de experiência'),
  senior('Sênior / Staff', '5+ anos de experiência');

  final String label;
  final String description;

  const SeniorityLevel(this.label, this.description);
}

enum InterviewStatus {
  inProgress('in_progress'),
  completed('completed'),
  endedEarly('ended_early');

  final String value;

  const InterviewStatus(this.value);

  static InterviewStatus fromString(String value) {
    return InterviewStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InterviewStatus.inProgress,
    );
  }
}

enum QuestionEvaluation {
  good('Boa', '🟢'),
  partial('Parcial', '🟡'),
  insufficient('Insuficiente', '🔴');

  final String label;
  final String emoji;

  const QuestionEvaluation(this.label, this.emoji);

  static QuestionEvaluation fromString(String value) {
    return QuestionEvaluation.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => QuestionEvaluation.partial,
    );
  }
}

enum InterviewPhase {
  idle,
  aiSpeaking,
  userSpeaking,
  processing,
  finished,
}
