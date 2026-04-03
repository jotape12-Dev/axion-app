import 'dart:math';
import 'package:flutter/material.dart';
import 'package:axion/core/theme/app_theme.dart';

/// Custom waveform widget that animates vertical bars based on amplitude values
/// from the record package's amplitude stream. No external audio_waveforms dependency.
class WaveformWidget extends StatefulWidget {
  final Stream<double>? amplitudeStream;
  final bool isActive;
  final Color? color;
  final int barCount;
  final double barWidth;
  final double maxHeight;
  final double minHeight;

  const WaveformWidget({
    super.key,
    this.amplitudeStream,
    this.isActive = false,
    this.color,
    this.barCount = 16,
    this.barWidth = 4,
    this.maxHeight = 40,
    this.minHeight = 4,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late List<double> _barHeights;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.filled(widget.barCount, widget.minHeight);
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _idleController.addListener(_onIdleTick);

    widget.amplitudeStream?.listen(_onAmplitude);
  }

  void _onIdleTick() {
    if (!widget.isActive) return;
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        final phase = (i / _barHeights.length) * pi * 2;
        final wave = sin(_idleController.value * pi * 2 + phase);
        _barHeights[i] =
            widget.minHeight + (widget.maxHeight * 0.3) * ((wave + 1) / 2);
      }
    });
  }

  void _onAmplitude(double amplitude) {
    if (!mounted) return;
    // Amplitude from record is in dB (negative), normalize to 0..1
    final normalized = ((amplitude + 60) / 60).clamp(0.0, 1.0);

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        final variation = 0.5 + _random.nextDouble() * 0.5;
        _barHeights[i] = widget.minHeight +
            (widget.maxHeight - widget.minHeight) * normalized * variation;
      }
    });
  }

  @override
  void dispose() {
    _idleController.removeListener(_onIdleTick);
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;

    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              width: widget.barWidth,
              height: widget.isActive
                  ? _barHeights[index]
                  : widget.minHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
                color: widget.isActive
                    ? color
                    : color.withValues(alpha: 0.3),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
