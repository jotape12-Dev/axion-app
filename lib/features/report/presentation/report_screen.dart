import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';

class ReportScreen extends ConsumerWidget {
  final String interviewId;

  const ReportScreen({super.key, required this.interviewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(completedInterviewProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relatório')),
        body: const Center(
          child: Text(
            'Relatório não encontrado',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/home'),
              ),
              title: const Text('Relatório'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Overall Score
                    _ScoreCard(
                      score: session.overallScore ?? 0,
                      area: session.area,
                      level: session.level,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Score Breakdown
                    const Text(
                      'Breakdown por Dimensão',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DimensionBar(
                      label: 'Conteúdo Técnico',
                      score: session.technicalScore ?? 0,
                      weight: '50%',
                      delay: 200,
                    ),
                    const SizedBox(height: 12),
                    _DimensionBar(
                      label: 'Clareza e Comunicação',
                      score: session.clarityScore ?? 0,
                      weight: '30%',
                      delay: 400,
                    ),
                    const SizedBox(height: 12),
                    _DimensionBar(
                      label: 'Fluência Verbal',
                      score: session.fluencyScore ?? 0,
                      weight: '20%',
                      delay: 600,
                    ),

                    const SizedBox(height: 32),

                    // Per-question analysis
                    const Text(
                      'Análise por Pergunta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...session.questions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionCard(
                              index: entry.key + 1,
                              question: entry.value,
                            ),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Action Plan
                    if (session.actionPlan != null) ...[
                      const Text(
                        'Plano de Ação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActionSection(
                        emoji: '🔴',
                        title: 'Pontos Críticos',
                        items: session.actionPlan!.criticalPoints,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      _ActionSection(
                        emoji: '🟡',
                        title: 'Pontos de Revisão',
                        items: session.actionPlan!.reviewPoints,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _ActionSection(
                        emoji: '🟢',
                        title: 'Pontos Fortes',
                        items: session.actionPlan!.strengths,
                        color: AppColors.success,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Voltar ao Início'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatefulWidget {
  final int score;
  final InterviewArea area;
  final SeniorityLevel level;

  const _ScoreCard({
    required this.score,
    required this.area,
    required this.level,
  });

  @override
  State<_ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<_ScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.score >= 75) return AppColors.success;
    if (widget.score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.cardGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Animated circular progress
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _scoreAnimation.value / 100,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _scoreAnimation.value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor,
                          ),
                        ),
                        Text(
                          'de 100',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.area.emoji} ${widget.area.label}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.level.label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  final String label;
  final int score;
  final String weight;
  final int delay;

  const _DimensionBar({
    required this.label,
    required this.score,
    required this.weight,
    required this.delay,
  });

  Color get _color {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$score/100',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'peso $weight',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final InterviewQuestion question;

  const _QuestionCard({required this.index, required this.question});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  Color get _evalColor {
    return switch (widget.question.evaluation) {
      QuestionEvaluation.good => AppColors.success,
      QuestionEvaluation.partial => AppColors.warning,
      QuestionEvaluation.insufficient => AppColors.error,
      _ => AppColors.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _evalColor.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _evalColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: _expanded ? null : 2,
                    overflow:
                        _expanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (q.evaluation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _evalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${q.evaluation!.emoji} ${q.evaluation!.label}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _evalColor,
                      ),
                    ),
                  ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 24),
              if (q.userAnswerTranscript != null) ...[
                Text(
                  'Sua resposta:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  q.userAnswerTranscript!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (q.idealAnswer != null) ...[
                Text(
                  'Resposta ideal incluiria:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  q.idealAnswer!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> items;
  final Color color;

  const _ActionSection({
    required this.emoji,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(color: color, fontSize: 14)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
