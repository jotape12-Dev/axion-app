import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/interview/data/interview_repository.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';
import 'package:axion/features/profile/providers/profile_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  InterviewArea? _filterArea;
  bool? _filterEndedEarly;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      await ref
          .read(interviewHistoryProvider.notifier)
          .loadHistory(profile.id);
    }
  }

  Future<void> _openReport(InterviewSession session) async {
    final repo = ref.read(interviewRepositoryProvider);
    final full = await repo.getSessionWithDetails(session.id);
    if (!mounted) return;
    ref.read(completedInterviewProvider.notifier).state = full ?? session;
    context.push('/report/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(interviewHistoryProvider);

    final filtered = history.where((s) {
      if (_filterArea != null && s.area != _filterArea) return false;
      if (_filterEndedEarly != null && s.endedEarly != _filterEndedEarly) {
        return false;
      }
      return true;
    }).toList();

    final completedSessions =
        history.where((s) => s.overallScore != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        automaticallyImplyLeading: true,
      ),
      body: GradientBackground(
        child: history.isEmpty
            ? _buildEmpty()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (completedSessions.length >= 2) ...[
                      const Text(
                        'Evolução do Score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ScoreChart(sessions: completedSessions)
                          .animate()
                          .fadeIn(duration: 600.ms),
                      const SizedBox(height: 24),
                    ],

                    // Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            isSelected: _filterArea == null &&
                                _filterEndedEarly == null,
                            onTap: () => setState(() {
                              _filterArea = null;
                              _filterEndedEarly = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completas',
                            isSelected: _filterEndedEarly == false,
                            onTap: () => setState(() {
                              _filterEndedEarly =
                                  _filterEndedEarly == false ? null : false;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Encerradas',
                            isSelected: _filterEndedEarly == true,
                            onTap: () => setState(() {
                              _filterEndedEarly =
                                  _filterEndedEarly == true ? null : true;
                            }),
                          ),
                          const SizedBox(width: 8),
                          ...InterviewArea.values.map(
                            (area) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: '${area.emoji} ${area.label}',
                                isSelected: _filterArea == area,
                                onTap: () => setState(() {
                                  _filterArea =
                                      _filterArea == area ? null : area;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Nenhuma sessão encontrada com os filtros selecionados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryCard(
                                session: entry.value,
                                onTap: () => _openReport(entry.value),
                              )
                                  .animate(
                                    delay: Duration(
                                        milliseconds: entry.key * 80),
                                  )
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: 0.05, end: 0),
                            ),
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma entrevista registrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas sessões aparecerão aqui',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  final List<InterviewSession> sessions;
  const _ScoreChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final reversed = sessions.reversed.toList();
    final spots = reversed.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value.overallScore ?? 0).toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  '#${value.toInt() + 1}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accent,
                  strokeWidth: 2,
                  strokeColor: AppColors.background,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.0),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final InterviewSession session;
  final VoidCallback onTap;

  const _HistoryCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${session.createdAt.day.toString().padLeft(2, '0')}/${session.createdAt.month.toString().padLeft(2, '0')}/${session.createdAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(session.area.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.area.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.level.label} • $dateStr',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (session.endedEarly)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Encerrada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              )
            else if (session.overallScore != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _scoreColor(session.overallScore!)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${session.overallScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor(session.overallScore!),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
