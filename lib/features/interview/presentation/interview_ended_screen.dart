import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/core/widgets/axion_button.dart';

class InterviewEndedScreen extends StatelessWidget {
  const InterviewEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 56,
                    color: AppColors.error,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 32),
                const Text(
                  'Entrevista Encerrada',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                Text(
                  'Você saiu da tela durante a entrevista. '
                  'Isso seria desclassificatório em um processo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A sessão foi salva no histórico como '
                          '"Encerrada precocemente" com os dados '
                          'coletados até o momento.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 40),
                AxionButton(
                  label: 'Voltar ao Início',
                  width: double.infinity,
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home'),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
