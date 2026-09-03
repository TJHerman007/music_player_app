import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight animated sine progress visualizer.
///
/// It intentionally uses a procedural wave instead of storing/rendering a
/// large waveform, keeping scrolling/player UI inexpensive.
class SineProgressVisualizer extends StatefulWidget {
  const SineProgressVisualizer({
    required this.progress,
    required this.accent,
    this.height = 34,
    this.active = true,
    super.key,
  });

  final double progress;
  final Color accent;
  final double height;
  final bool active;

  @override
  State<SineProgressVisualizer> createState() => _SineProgressVisualizerState();
}

class _SineProgressVisualizerState extends State<SineProgressVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return CustomPaint(
            painter: _SinePainter(
              progress: widget.progress.clamp(0.0, 1.0),
              accent: widget.accent,
              phase: widget.active ? _controller.value * math.pi * 2 : 0,
              active: widget.active,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SinePainter extends CustomPainter {
  const _SinePainter({
    required this.progress,
    required this.accent,
    required this.phase,
    required this.active,
  });

  final double progress;
  final Color accent;
  final double phase;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = size.height / 2;
    final amplitude = size.height * 0.30;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.18);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.95);

    final basePath = Path();
    final activePath = Path();

    const cycles = 7.5;
    final points = math.max(32, size.width.floor());

    for (var i = 0; i <= points; i++) {
      final x = size.width * i / points;
      final y =
          center +
          math.sin((x / size.width) * cycles * math.pi * 2 + phase) * amplitude;

      if (i == 0) {
        basePath.moveTo(x, y);
        activePath.moveTo(x, y);
      } else {
        basePath.lineTo(x, y);
        if (x <= size.width * progress) {
          activePath.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(basePath, base);

    if (progress > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
      canvas.drawPath(basePath, activePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.phase != phase ||
        oldDelegate.active != active;
  }
}
