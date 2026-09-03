import 'dart:math' as math;

import 'package:flutter/material.dart';

/// TIUS animated 3-layer wave progress bar.
///
/// Visual design:
/// - Three animated wave layers.
/// - Bright pink played region.
/// - Soft pink/purple layered waves.
/// - Dark/light adaptive unplayed track.
/// - Glowing white/pink seek handle.
/// - Tap anywhere to seek.
/// - Drag horizontally to seek.
/// - Animation runs only while playing.
/// - Pausing preserves the current wave phase.
class AnimatedWaveProgressBar extends StatefulWidget {
  const AnimatedWaveProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onSeek,

    this.height = 52,
    this.waveHeight = 10,
    this.trackHeight = 10,
    this.handleRadius = 9,

    this.waveColor = const Color(0xFFFF2A8B),
    this.waveHighlightColor = const Color(0xFFFF72B5),
    this.waveSecondaryColor = const Color(0xFFE83291),

    this.trackColor = const Color(0xFFE8DDE7),
    this.handleColor = Colors.white,
    this.handleCenterColor = const Color(0xFFFF2A8B),

    this.showHandle = true,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration> onSeek;

  final double height;
  final double waveHeight;
  final double trackHeight;
  final double handleRadius;

  final Color waveColor;
  final Color waveHighlightColor;
  final Color waveSecondaryColor;

  final Color trackColor;
  final Color handleColor;
  final Color handleCenterColor;

  final bool showHandle;

  @override
  State<AnimatedWaveProgressBar> createState() =>
      _AnimatedWaveProgressBarState();
}

class _AnimatedWaveProgressBarState extends State<AnimatedWaveProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool _dragging = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _animationController.addStatusListener(_handleAnimationStatus);

    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncAnimation();
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!mounted) {
      return;
    }

    if (status == AnimationStatus.completed && widget.isPlaying) {
      // Start the next cycle without allowing the animation to visibly pause.
      _animationController.forward(from: 0.0);
    }
  }

  void _syncAnimation() {
    if (widget.isPlaying) {
      if (!_animationController.isAnimating) {
        _animationController.forward(from: _animationController.value);
      }
    } else {
      // Stopping preserves the current animation phase.
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_handleAnimationStatus);
    _animationController.dispose();
    super.dispose();
  }

  double get _progress {
    final durationMs = widget.duration.inMilliseconds;

    if (durationMs <= 0) {
      return 0.0;
    }

    final positionMs = widget.position.inMilliseconds;

    return (positionMs / durationMs).clamp(0.0, 1.0).toDouble();
  }

  void _seekFromDx(double dx, double width) {
    if (width <= 0) {
      return;
    }

    final durationMs = widget.duration.inMilliseconds;

    if (durationMs <= 0) {
      return;
    }

    final progress = (dx / width).clamp(0.0, 1.0).toDouble();

    final milliseconds = (durationMs * progress).round();

    widget.onSeek(Duration(milliseconds: milliseconds));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTapDown: (details) {
            _seekFromDx(details.localPosition.dx, width);
          },

          onHorizontalDragStart: (details) {
            _dragging = true;

            _seekFromDx(details.localPosition.dx, width);
          },

          onHorizontalDragUpdate: (details) {
            if (!_dragging) {
              return;
            }

            _seekFromDx(details.localPosition.dx, width);
          },

          onHorizontalDragEnd: (_) {
            _dragging = false;
          },

          onHorizontalDragCancel: () {
            _dragging = false;
          },

          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveProgressPainter(
                    progress: _progress,
                    animationValue: _animationController.value,

                    waveHeight: widget.waveHeight,
                    trackHeight: widget.trackHeight,
                    handleRadius: widget.handleRadius,

                    waveColor: widget.waveColor,
                    waveHighlightColor: widget.waveHighlightColor,
                    waveSecondaryColor: widget.waveSecondaryColor,

                    trackColor: widget.trackColor,

                    handleColor: widget.handleColor,
                    handleCenterColor: widget.handleCenterColor,

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
  const _WaveProgressPainter({
    required this.progress,
    required this.animationValue,

    required this.waveHeight,
    required this.trackHeight,
    required this.handleRadius,

    required this.waveColor,
    required this.waveHighlightColor,
    required this.waveSecondaryColor,

    required this.trackColor,

    required this.handleColor,
    required this.handleCenterColor,

    required this.showHandle,
  });

  final double progress;
  final double animationValue;

  final double waveHeight;
  final double trackHeight;
  final double handleRadius;

  final Color waveColor;
  final Color waveHighlightColor;
  final Color waveSecondaryColor;

  final Color trackColor;

  final Color handleColor;
  final Color handleCenterColor;

  final bool showHandle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final centerY = size.height / 2;

    final playedWidth = (size.width * progress)
        .clamp(0.0, size.width)
        .toDouble();

    // ------------------------------------------------------------
    // UNPLAYED TRACK
    // ------------------------------------------------------------

    final trackTop = centerY - trackHeight / 2;

    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackHeight)),
      trackPaint,
    );

    // ------------------------------------------------------------
    // PLAYED WAVE REGION
    // ------------------------------------------------------------

    if (playedWidth > 0) {
      canvas.save();

      // The played region is a rounded capsule.
      final playedRect = Rect.fromLTWH(
        0,
        centerY - waveHeight * 1.65,
        playedWidth,
        waveHeight * 3.3,
      );

      final playedRadius = Radius.circular(waveHeight * 1.65);

      canvas.clipRRect(RRect.fromRectAndRadius(playedRect, playedRadius));

      // Strong pink base.
      final basePaint = Paint()
        ..color = waveColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          0,
          centerY - waveHeight * 1.65,
          playedWidth,
          waveHeight * 3.3,
        ),
        basePaint,
      );

      // Three waves.
      //
      // Bottom = strongest.
      // Middle = softer.
      // Top = subtle/highlight.
      _drawWave(
        canvas,
        size,
        centerY,
        playedWidth,

        amplitude: waveHeight * 0.72,
        frequency: 0.014,
        speed: 1.00,
        phaseOffset: 0.0,

        color: waveColor,
        opacity: 0.95,

        verticalOffset: waveHeight * 0.55,
      );

      _drawWave(
        canvas,
        size,
        centerY,
        playedWidth,

        amplitude: waveHeight * 0.58,
        frequency: 0.011,
        speed: 0.72,
        phaseOffset: 2.0,

        color: waveSecondaryColor,
        opacity: 0.68,

        verticalOffset: -waveHeight * 0.05,
      );

      _drawWave(
        canvas,
        size,
        centerY,
        playedWidth,

        amplitude: waveHeight * 0.46,
        frequency: 0.0085,
        speed: 0.48,
        phaseOffset: 4.1,

        color: waveHighlightColor,
        opacity: 0.62,

        verticalOffset: -waveHeight * 0.58,
      );

      canvas.restore();
    }

    // ------------------------------------------------------------
    // SEEK HANDLE
    // ------------------------------------------------------------

    if (showHandle) {
      final handleX = playedWidth;

      // Outer soft glow.
      final glowPaint = Paint()
        ..color = handleCenterColor.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

      canvas.drawCircle(Offset(handleX, centerY), handleRadius + 5, glowPaint);

      // Second subtle glow ring.
      final outerGlowPaint = Paint()
        ..color = handleCenterColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(handleX, centerY),
        handleRadius + 8,
        outerGlowPaint,
      );

      // White outer handle.
      final handlePaint = Paint()
        ..color = handleColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(handleX, centerY),
        handleRadius + 2,
        handlePaint,
      );

      // Pink center.
      final centerPaint = Paint()
        ..color = handleCenterColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(handleX, centerY),
        handleRadius * 0.48,
        centerPaint,
      );

      // Tiny white center highlight.
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(handleX - handleRadius * 0.14, centerY - handleRadius * 0.14),
        handleRadius * 0.13,
        highlightPaint,
      );
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double centerY,
    double playedWidth, {
    required double amplitude,
    required double frequency,
    required double speed,
    required double phaseOffset,
    required Color color,
    required double opacity,
    required double verticalOffset,
  }) {
    if (playedWidth <= 0) {
      return;
    }

    final path = Path();

    final phase = animationValue * math.pi * 2 * speed;

    path.moveTo(0, centerY + verticalOffset);

    // Slightly finer sampling gives the wave a smoother
    // appearance on high-density displays.
    for (double x = 0; x <= playedWidth + 4; x += 2.0) {
      final wave1 = math.sin(x * frequency + phase + phaseOffset) * amplitude;

      final wave2 =
          math.sin(x * frequency * 0.47 + phase * 0.68 + phaseOffset * 1.35) *
          amplitude *
          0.30;

      final wave3 =
          math.sin(x * frequency * 1.72 - phase * 0.42 + phaseOffset * 0.5) *
          amplitude *
          0.10;

      final y = centerY + verticalOffset + wave1 + wave2 + wave3;

      path.lineTo(x, y);
    }

    // Fill the wave down to the bottom.
    path.lineTo(playedWidth, size.height);

    path.lineTo(0, size.height);

    path.close();

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.waveHeight != waveHeight ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.handleRadius != handleRadius ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.waveHighlightColor != waveHighlightColor ||
        oldDelegate.waveSecondaryColor != waveSecondaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.handleCenterColor != handleCenterColor ||
        oldDelegate.showHandle != showHandle;
  }
}
