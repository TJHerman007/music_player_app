import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.64);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.82);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : const Color(0xFF9AAFC0).withValues(alpha: 0.28);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: highlightColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? const Color(0x55303B3D) : const Color(0x66F7FAF7);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.78);
    final selectedOverlay = Theme.of(context).colorScheme.primary
        .withValues(alpha: isDark ? 0.22 : 0.14);

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.1),
                blurRadius: 10,
                offset: const Offset(8, 0),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTileTheme(
              selectedColor: Theme.of(context).colorScheme.primary,
              selectedTileColor: selectedOverlay,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF122C35), Color(0xFF17152A), Color(0xFF121212)]
              : const [Color(0xFFF4F8FF), Color(0xFFE7F5F0), Color(0xFFFFEEE7)],
        ),
      ),
      child: child,
    );
  }
}
