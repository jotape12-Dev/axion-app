import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/core/widgets/axion_button.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';

import 'package:axion/features/profile/providers/profile_providers.dart';

class InterviewSetupScreen extends ConsumerStatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  ConsumerState<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-select from profile on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      if (profile != null) {
        if (profile.preferredArea != null) {
          ref.read(interviewSetupProvider.notifier).selectArea(profile.preferredArea!);
        }
        if (profile.seniorityLevel != null) {
          ref.read(interviewSetupProvider.notifier).selectLevel(profile.seniorityLevel!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(interviewSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Entrevista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Area Selection
                      const Text(
                        'Área / Tecnologia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecione a área da entrevista',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: InterviewArea.values.length,
                        itemBuilder: (context, index) {
                          final area = InterviewArea.values[index];
                          final isSelected = setup.selectedArea == area;
                          return _AreaCard(
                            area: area,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(interviewSetupProvider.notifier)
                                .selectArea(area),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),

                      const SizedBox(height: 32),

                      // Seniority Level
                      const Text(
                        'Nível de Senioridade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...SeniorityLevel.values.map(
                        (level) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LevelTile(
                            level: level,
                            isSelected: setup.selectedLevel == level,
                            onTap: () => ref
                                .read(interviewSetupProvider.notifier)
                                .selectLevel(level),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Job Description (optional)
                      const Text(
                        'Descrição da Vaga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opcional — personaliza as perguntas',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Cole a descrição da vaga ou descreva o que a empresa pede. Isso personaliza as perguntas para sua oportunidade específica.',
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        onChanged: (v) => ref
                            .read(interviewSetupProvider.notifier)
                            .setJobDescription(v),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Bottom CTA
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: AxionGlowButton(
                    label: 'Iniciar Entrevista',
                    onPressed: setup.isValid
                        ? () => context.push('/pre-interview')
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final InterviewArea area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaCard({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(area.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              area.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.accent
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              area.description,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final SeniorityLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
