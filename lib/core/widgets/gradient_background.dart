import 'package:flutter/material.dart';
import 'package:axion/core/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showTopGlow;

  const GradientBackground({
    super.key,
    required this.child,
    this.showTopGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        children: [
          if (showTopGlow)
            Positioned(
              top: -100,
              left: 0,
              right: 0,
              child: ExcludeSemantics(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.15),
                        AppColors.accent.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
