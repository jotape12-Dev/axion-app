import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';
import 'package:axion/features/profile/providers/profile_providers.dart';

class PreInterviewScreen extends ConsumerStatefulWidget {
  const PreInterviewScreen({super.key});

  @override
  ConsumerState<PreInterviewScreen> createState() =>
      _PreInterviewScreenState();
}

class _PreInterviewScreenState extends ConsumerState<PreInterviewScreen> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _checkingPermissions = true;
  bool _countdownStarted = false;
  int _countdown = 3;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!mounted) return;

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _micGranted = micStatus.isGranted;
      _checkingPermissions = false;
      _permissionDenied = !_cameraGranted || !_micGranted;
    });

    if (_cameraGranted && _micGranted) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() => _countdownStarted = true);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _startInterview();
      }
    });
  }

  void _startInterview() {
    final setup = ref.read(interviewSetupProvider);
    if (setup.selectedArea == null || setup.selectedLevel == null) return;

    final userId = ref.read(userProfileProvider)?.id ?? '';

    final session = InterviewSession.create(
      userId: userId,
      area: setup.selectedArea!,
      level: setup.selectedLevel!,
      jobDescription: setup.jobDescription.isEmpty
          ? null
          : setup.jobDescription,
    );

    ref.read(activeInterviewProvider.notifier).startInterview(session);
    context.go('/interview');
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
              child: _permissionDenied
                  ? _buildPermissionDenied()
                  : _buildChecklist(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.videocam_off_rounded,
              size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 24),
        const Text(
          'Permissões Necessárias',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A câmera e o microfone são obrigatórios para simular '
          'o ambiente real de uma entrevista técnica.\n\n'
          'Ative as permissões nas configurações do dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => openAppSettings(),
          child: const Text('Abrir Configurações'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Voltar'),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Preparando...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 40),
        _CheckItem(
          label: 'Câmera ativa',
          isChecked: _cameraGranted,
          delay: 0,
        ),
        const SizedBox(height: 16),
        _CheckItem(
          label: 'Microfone ativo',
          isChecked: _micGranted,
          delay: 300,
        ),
        const SizedBox(height: 16),
        _CheckItem(
          label: 'Não saia do app — a entrevista será\nencerrada automaticamente',
          isChecked: _cameraGranted && _micGranted,
          isWarning: true,
          delay: 600,
        ),
        const SizedBox(height: 48),
        if (_countdownStarted) ...[
          Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          )
              .animate(
                onComplete: (_) {},
              )
              .scale(
                begin: const Offset(1.5, 1.5),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
              ),
          const SizedBox(height: 8),
          Text(
            'A entrevista vai começar...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ] else if (_checkingPermissions) ...[
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool isChecked;
  final bool isWarning;
  final int delay;

  const _CheckItem({
    required this.label,
    required this.isChecked,
    this.isWarning = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isChecked
                ? (isWarning
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15))
                : AppColors.surfaceLight,
          ),
          child: Icon(
            isChecked
                ? (isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.check_rounded)
                : Icons.hourglass_empty_rounded,
            size: 18,
            color: isChecked
                ? (isWarning ? AppColors.warning : AppColors.success)
                : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isChecked
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
              fontWeight:
                  isChecked ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.1, end: 0);
  }
}
