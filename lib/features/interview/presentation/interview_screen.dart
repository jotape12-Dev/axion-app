import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/waveform_widget.dart';
import 'package:axion/core/services/audio_service.dart';
import 'package:axion/features/interview/providers/interview_providers.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false, // avoid AVAudioSession conflict with record
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final interview = ref.read(activeInterviewProvider);
    if (!interview.isActive) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;

      ref.read(activeInterviewProvider.notifier).endEarly();

      final session =
          ref.read(activeInterviewProvider.notifier).getCompletedSession();
      if (session != null) {
        // endedEarly sessions are added locally only (no report to save)
        ref.read(interviewHistoryProvider.notifier).addAndSave(session);
      }

      if (mounted) {
        context.go('/interview-ended');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeInterviewProvider);
    final audioService = ref.watch(audioServiceProvider);
    final selectedCount = ref.watch(interviewSetupProvider).questionCount;

    // Auto-navigate on finish
    if (state.phase == InterviewPhase.finished && state.session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/completion/${state.session!.id}');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pergunta ${state.currentQuestionIndex + 1} de ${state.totalQuestions > 0 ? state.totalQuestions : selectedCount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        state.formattedTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.totalQuestions > 0
                      ? (state.currentQuestionIndex + 1) /
                          state.totalQuestions
                      : 0,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 4,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // AI Avatar
            _AiAvatar(phase: state.phase),

            const SizedBox(height: 32),

            // Phase indicator
            _PhaseIndicator(phase: state.phase),

            const SizedBox(height: 24),

            // Subtitle / AI speech text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _TypewriterSubtitle(
                key: ValueKey(state.currentSubtitle),
                text: state.currentSubtitle,
                isAnimating: state.phase == InterviewPhase.aiSpeaking,
              ),
            ),

            const Spacer(flex: 3),

            // Waveform (shown when user is speaking)
            if (state.phase == InterviewPhase.userSpeaking)
              WaveformWidget(
                isActive: true,
                amplitudeStream: audioService.amplitudeStream,
              ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Action button
            if (state.phase == InterviewPhase.userSpeaking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(activeInterviewProvider.notifier)
                        .endUserResponse(),
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: const Text('Encerrar minha resposta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

            if (state.phase == InterviewPhase.processing)
              Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analisando resposta...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Camera PiP (bottom-left)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_cameraController != null &&
                            _cameraController!.value.isInitialized)
                          CameraPreview(_cameraController!)
                        else
                          const Icon(
                            Icons.videocam_rounded,
                            color: AppColors.textTertiary,
                            size: 28,
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypewriterSubtitle extends StatefulWidget {
  final String text;
  final bool isAnimating;

  const _TypewriterSubtitle({
    super.key,
    required this.text,
    required this.isAnimating,
  });

  @override
  State<_TypewriterSubtitle> createState() => _TypewriterSubtitleState();
}

class _TypewriterSubtitleState extends State<_TypewriterSubtitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    if (widget.isAnimating && widget.text.isNotEmpty) {
      _startAnimation();
    } else {
      _controller.value = 1.0;
    }
  }

  void _startAnimation() {
    _controller.reset();
    // speech rate 0.45 ≈ 67 wpm → ~1.1 words/sec → ~5.5 chars/sec → ~180ms/char
    final wordCount = widget.text.split(' ').length;
    final durationMs = (wordCount / 3.5 * 1000).round().clamp(300, 30000);
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final chars = (_controller.value * widget.text.length).round();
        final visible = widget.text.substring(0, chars.clamp(0, widget.text.length));
        return Text(
          visible,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }
}

class _AiAvatar extends StatefulWidget {
  final InterviewPhase phase;

  const _AiAvatar({required this.phase});

  @override
  State<_AiAvatar> createState() => _AiAvatarState();
}

class _AiAvatarState extends State<_AiAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpeaking = widget.phase == InterviewPhase.aiSpeaking;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isSpeaking ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent,
                  AppColors.accentDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(
                    alpha: isSpeaking ? 0.5 : 0.25,
                  ),
                  blurRadius: isSpeaking ? 30 : 15,
                  spreadRadius: isSpeaking ? 5 : 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final InterviewPhase phase;

  const _PhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      InterviewPhase.aiSpeaking => ('Entrevistadora está falando...', AppColors.accent),
      InterviewPhase.userSpeaking => ('Sua vez de responder', AppColors.success),
      InterviewPhase.processing => ('Processando...', AppColors.warning),
      _ => ('', AppColors.textTertiary),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2000.ms, color: color.withValues(alpha: 0.1));
  }
}
