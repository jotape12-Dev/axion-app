import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/core/widgets/axion_button.dart';
import 'package:axion/features/profile/providers/profile_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step state
  String _name = '';
  InterviewArea? _selectedArea;
  SeniorityLevel? _selectedLevel;

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    if (_name.length >= 2 && _selectedArea != null && _selectedLevel != null) {
      ref.read(userProfileProvider.notifier).completeOnboarding(
            displayName: _name,
            area: _selectedArea!,
            level: _selectedLevel!,
          );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accent : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildNameStep(),
                    _buildAreaStep(),
                    _buildLevelStep(),
                  ],
                ),
              ),

              // Bottom Bar
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: const Text('Voltar'),
                      ),
                    const Spacer(),
                    if (_currentStep < 2)
                      AxionButton(
                        label: 'Continuar',
                        onPressed: _isNextEnabled ? _nextPage : null,
                      )
                    else
                      AxionButton(
                        label: 'Começar',
                        onPressed: _isNextEnabled ? _completeOnboarding : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isNextEnabled {
    if (_currentStep == 0) return _name.length >= 2;
    if (_currentStep == 1) return _selectedArea != null;
    if (_currentStep == 2) return _selectedLevel != null;
    return false;
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Como podemos te chamar?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Use seu nome ou um apelido profissional.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Seu nome completo ou apelido',
            ),
            style: const TextStyle(fontSize: 18),
            onChanged: (v) => setState(() => _name = v),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildAreaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Qual é a sua área?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Isso personaliza suas entrevistas.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: InterviewArea.values.length,
            itemBuilder: (context, index) {
              final area = InterviewArea.values[index];
              final isSelected = _selectedArea == area;
              return _AreaOptionTile(
                area: area,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedArea = area),
              );
            },
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildLevelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Qual é o seu nível?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dessa forma geramos perguntas adequadas à sua experiência.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ...SeniorityLevel.values.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LevelOptionTile(
                level: level,
                isSelected: _selectedLevel == level,
                onTap: () => setState(() => _selectedLevel = level),
              ),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }
}

class _AreaOptionTile extends StatelessWidget {
  final InterviewArea area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaOptionTile({
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
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(area.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              area.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelOptionTile extends StatelessWidget {
  final SeniorityLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelOptionTile({
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
          color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent)
            else
              const Icon(Icons.circle_outlined, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
