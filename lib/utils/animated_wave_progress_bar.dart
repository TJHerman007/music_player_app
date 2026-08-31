import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated 3-layer wave progress bar for a music player.
///
/// Features:
/// - Three independently animated wave layers.
/// - Waves are visible only in the played portion.
/// - Tap or drag to seek.
/// - Glowing circular seek handle.
/// - Animation automatically pauses when [isPlaying] is false.
/// - Designed to work with any audio player package through [onSeek].
class AnimatedWaveProgressBar extends StatefulWidget {
  const AnimatedWaveProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onSeek,
    this.height = 56,
    this.waveHeight = 10,
    this.trackHeight = 8,
    this.handleRadius = 18,
    this.waveColor = const Color(0xFF86BEEA),
    this.waveHighlightColor = const Color(0xFFB7D8F5),
    this.trackColor = const Color(0xFF304A60),
    this.handleColor = const Color(0xFFCFE6FF),
    this.showHandle = true,
  });

  /// Current playback position.
  final Duration position;

  /// Total track duration.
  final Duration duration;

  /// Whether the audio is currently playing.
  ///
  /// The wave animation runs while true and pauses while false.
  final bool isPlaying;

  /// Called whenever the user taps/drags to a new position.
  final ValueChanged<Duration> onSeek;

  /// Total height reserved for the progress bar.
  final double height;

  /// Base wave amplitude.
  final double waveHeight;

  /// Height of the background progress track.
  final double trackHeight;

  /// Radius of the circular seek handle.
  final double handleRadius;

  final Color waveColor;
  final Color waveHighlightColor;
  final Color trackColor;
  final Color handleColor;

  /// Set false if you want to hide the circular handle.
  final bool showHandle;

  @override
  State<AnimatedWaveProgressBar> createState() =>
      _AnimatedWaveProgressBarState();
}

class _AnimatedWaveProgressBarState
    extends State<AnimatedWaveProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPlaying != widget.isPlaying) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.isPlaying) {
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _progress {
    final durationMs = widget.duration.inMilliseconds;

    if (durationMs <= 0) {
      return 0.0;
    }

    return (widget.position.inMilliseconds / durationMs)
        .clamp(0.0, 1.0);
  }

  void _seekFromLocalPosition(
    Offset localPosition,
    double width,
  ) {
    final durationMs = widget.duration.inMilliseconds;

    if (durationMs <= 0 || width <= 0) {
      return;
    }

    final progress =
        (localPosition.dx / width).clamp(0.0, 1.0);

    final newPosition = Duration(
      milliseconds: (durationMs * progress).round(),
    );

    widget.onSeek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _seekFromLocalPosition(
              details.localPosition,
              width,
            );
          },
          onHorizontalDragStart: (details) {
            _seekFromLocalPosition(
              details.localPosition,
              width,
            );
          },
          onHorizontalDragUpdate: (details) {
            _seekFromLocalPosition(
              details.localPosition,
              width,
            );
          },
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(width, widget.height),
                  painter: _WaveProgressPainter(
                    progress: _progress,
                    animationValue:
                        _animationController.value,
                    waveHeight: widget.waveHeight,
                    trackHeight: widget.trackHeight,
                    handleRadius: widget.handleRadius,
                    waveColor: widget.waveColor,
                    waveHighlightColor:
                        widget.waveHighlightColor,
                    trackColor: widget.trackColor,
                    handleColor: widget.handleColor,
                    showHandle: widget.showHandle,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WaveProgressPainter extends CustomPainter {
  _WaveProgressPainter({
    required this.progress,
    required this.animationValue,
    required this.waveHeight,
    required this.trackHeight,
    required this.handleRadius,
    required this.waveColor,
    required this.waveHighlightColor,
    required this.trackColor,
    required this.handleColor,
    required this.showHandle,
  });

  final double progress;
  final double animationValue;
  final double waveHeight;
  final double trackHeight;
  final double handleRadius;

  final Color waveColor;
  final Color waveHighlightColor;
  final Color trackColor;
  final Color handleColor;
  final bool showHandle;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final playedWidth =
        (size.width * progress).clamp(0.0, size.width);

    // ------------------------------------------------------------
    // Background track
    // ------------------------------------------------------------

    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        0,
        centerY - trackHeight / 2,
        size.width,
        trackHeight,
      ),
      Radius.circular(trackHeight),
    );

    canvas.drawRRect(
      backgroundRect,
      backgroundPaint,
    );

    // ------------------------------------------------------------
    // Played section + 3 animated wave layers
    // ------------------------------------------------------------

    if (playedWidth > 0) {
      canvas.save();

      canvas.clipRect(
        Rect.fromLTWH(
          0,
          0,
          playedWidth,
          size.height,
        ),
      );

      // Back wave
      _drawWave(
        canvas,
        size,
        centerY,
        layer: 0,
        amplitude: waveHeight,
        frequency: 0.010,
        speed: 0.85,
        opacity: 0.72,
      );

      // Middle wave
      _drawWave(
        canvas,
        size,
        centerY,
        layer: 1,
        amplitude: waveHeight * 0.82,
        frequency: 0.013,
        speed: 0.62,
        opacity: 0.84,
      );

      // Front wave
      _drawWave(
        canvas,
        size,
        centerY,
        layer: 2,
        amplitude: waveHeight * 0.62,
        frequency: 0.016,
        speed: 1.15,
        opacity: 1.0,
      );

      canvas.restore();
    }

    // ------------------------------------------------------------
    // Seek handle
    // ------------------------------------------------------------

    if (showHandle) {
      _drawHandle(
        canvas,
        Offset(playedWidth, centerY),
      );
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double centerY, {
    required int layer,
    required double amplitude,
    required double frequency,
    required double speed,
    required double opacity,
  }) {
    final path = Path();

    final phase =
        animationValue * math.pi * 2 * speed;

    final layerPhase = layer * 1.35;

    path.moveTo(0, centerY);

    for (double x = 0; x <= size.width; x += 2.5) {
      final wave1 = math.sin(
            x * frequency +
                phase +
                layerPhase,
          ) *
          amplitude;

      final wave2 = math.sin(
            x * frequency * 0.48 +
                phase * 0.72 +
                layerPhase * 1.7,
          ) *
          amplitude *
          0.42;

      final wave3 = math.sin(
            x * frequency * 1.8 -
                phase * 0.38 +
                layer,
          ) *
          amplitude *
          0.14;

      final y =
          centerY +
          wave1 +
          wave2 +
          wave3;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, centerY);
    path.lineTo(0, centerY);
    path.close();

    final paint = Paint()
      ..color = (layer == 2
              ? waveHighlightColor
              : waveColor)
          .withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawHandle(
    Canvas canvas,
    Offset position,
  ) {
    // Soft outer glow.
    final glowPaint = Paint()
      ..color = handleColor.withOpacity(0.42)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawCircle(
      position,
      handleRadius + 2,
      glowPaint,
    );

    // Main handle.
    final handlePaint = Paint()
      ..color = handleColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      position,
      handleRadius,
      handlePaint,
    );

    // Small upper-left highlight.
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        position.dx - handleRadius * 0.28,
        position.dy - handleRadius * 0.30,
      ),
      handleRadius * 0.20,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WaveProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.waveHeight != waveHeight ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.handleRadius != handleRadius ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.waveHighlightColor !=
            waveHighlightColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.showHandle != showHandle;
  }
}
