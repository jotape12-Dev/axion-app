import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/core/widgets/axion_button.dart';
import 'package:axion/core/services/edge_function_service.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  final String interviewId;

  const CompletionScreen({super.key, required this.interviewId});

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  bool _isGenerating = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _hasError = false;
    });

    try {
      final session = ref.read(activeInterviewProvider).session;
      if (session == null) {
        throw Exception('Sessão não encontrada');
      }

      final edgeFunctions = ref.read(edgeFunctionServiceProvider);

      final questionsPayload = session.questions
          .map((q) => {
                'question': q.question,
                'answer': q.userAnswerTranscript ?? '',
                'score': q.score,
                'evaluation': q.evaluation?.label,
              })
          .toList();

      final reportData = await edgeFunctions.generateReport(
        interviewId: session.id,
        questions: questionsPayload,
        area: session.area.name,
        level: session.level.name,
      );

      final reportedSession = session.copyWith(
        overallScore: (reportData['overall_score'] as num?)?.toInt(),
        technicalScore: (reportData['technical_score'] as num?)?.toInt(),
        clarityScore: (reportData['clarity_score'] as num?)?.toInt(),
        fluencyScore: (reportData['fluency_score'] as num?)?.toInt(),
        actionPlan: reportData['action_plan'] != null
            ? ActionPlan.fromJson(
                Map<String, dynamic>.from(reportData['action_plan'] as Map))
            : null,
      );

      // Save to Supabase and update local history
      await ref
          .read(interviewHistoryProvider.notifier)
          .addAndSave(reportedSession);

      // Store completed session for report screen
      ref.read(completedInterviewProvider.notifier).state = reportedSession;

      if (mounted) {
        setState(() => _isGenerating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        showTopGlow: true,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGenerating) ...[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 56,
                        color: AppColors.success,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 32),
                    const Text(
                      'Entrevista Concluída!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 12),
                    Text(
                      'Seu relatório está sendo gerado...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 32),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    )
                        .animate(delay: 700.ms)
                        .fadeIn(duration: 300.ms),
                  ] else if (_hasError) ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Erro ao gerar relatório',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? 'Ocorreu um erro inesperado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AxionButton(
                      label: 'Tentar novamente',
                      icon: Icons.refresh_rounded,
                      onPressed: _generateReport,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Voltar ao início'),
                    ),
                  ] else ...[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assessment_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 400.ms,
                        ),
                    const SizedBox(height: 32),
                    const Text(
                      'Relatório pronto!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AxionGlowButton(
                      label: 'Ver Relatório',
                      onPressed: () =>
                          context.go('/report/${widget.interviewId}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
