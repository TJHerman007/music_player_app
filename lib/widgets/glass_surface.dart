import 'package:flutter/material.dart';

/// Lightweight glass surface.
///
/// Intentionally does NOT use BackdropFilter. This makes it suitable for
/// repeated widgets such as song rows, cards, buttons, and grids.
class GlassSurface extends StatelessWidget {
  const GlassSurface({required this.child, super.key});

  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(35));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark
        ? const Color.fromARGB(223, 40, 44, 49)
        : const Color(0xE6FFFDF9);

    final highlightColor = isDark
        ? const Color.fromARGB(197, 54, 59, 66)
        : const Color(0xFFFFFFFF);

    final shadowColor = isDark
        ? const Color.fromARGB(47, 3, 3, 3)
        : const Color(0x1F887E75);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: _radius,
          border: Border.all(color: highlightColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: _radius,
          child: child,
        ),
      ),
    );
  }
}

/// A stronger surface for navigation and larger panels.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({required this.child, super.key});

  final Widget child;

  static const _radius = BorderRadius.horizontal(right: Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tint = isDark ? const Color(0xFF24282D) : const Color(0xF2FFFDF9);

    final border = isDark ? const Color(0x33FFFFFF) : const Color(0xC7FFFFFF);

    final selectedOverlay = colorScheme.primary.withValues(
      alpha: isDark ? 0.22 : 0.14,
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(color: border, width: 1.0),
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 14,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ListTileTheme(
            selectedColor: colorScheme.primary,
            selectedTileColor: selectedOverlay,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Full-screen background.
///
/// Only the background itself listens to the accent color. The child is kept
/// outside the ListenableBuilder so an accent update doesn't rebuild the
/// complete application UI.
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    required this.child,
    this.accentListenable,
    this.accentProvider,
    super.key,
  });

  final Widget child;
  final Listenable? accentListenable;
  final Color? Function()? accentProvider;

  @override
  Widget build(BuildContext context) {
    final listenable = accentListenable;

    if (listenable == null) {
      return _StaticBackground(accent: accentProvider?.call(), child: child);
    }

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        return _StaticBackground(accent: accentProvider?.call(), child: child);
      },
    );
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground({required this.accent, required this.child});

  final Color? accent;
  final Widget child;

  static const _darkBaseColors = [
    Color.fromARGB(0, 37, 43, 49),
    Color.fromARGB(0, 27, 30, 34),
    Color.fromARGB(0, 21, 24, 27),
  ];

  static const _lightBaseColors = [
    Color.fromARGB(136, 255, 252, 249),
    Color.fromARGB(139, 243, 238, 232),
    Color.fromARGB(139, 232, 240, 236),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColors = isDark ? _darkBaseColors : _lightBaseColors;

    final currentAccent = accent;

    final firstColor = Color.lerp(
      baseColors[0],
      currentAccent ?? baseColors[0],
      isDark ? 0.35 : 0.22,
    )!;

    final secondColor = Color.lerp(
      baseColors[1],
      currentAccent ?? baseColors[1],
      isDark ? 0.28 : 0.16,
    )!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [firstColor, secondColor, baseColors[2]],
          stops: const [0.0, 0.58, 1.0],
        ),
      ),
      child: child,
    );
  }
}
