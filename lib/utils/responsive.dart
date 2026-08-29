import 'package:flutter/material.dart';

/// Responsive helpers for the entire app.
///
/// Usage:
///   final r = Responsive.of(context);
///
///   r.isMobile
///   r.isTablet
///   r.isDesktop
///   r.width
///   r.height
///   r.scale(24)
///   r.font(18)
///   r.horizontalPadding
///
/// The breakpoints are intentionally simple:
///   < 600   = mobile
///   < 1024  = tablet
///   >= 1024 = desktop
class Responsive {
  const Responsive._(this.context);

  final BuildContext context;

  static Responsive of(BuildContext context) {
    return Responsive._(context);
  }

  MediaQueryData get mediaQuery => MediaQuery.of(context);

  double get width => mediaQuery.size.width;
  double get height => mediaQuery.size.height;

  double get shortestSide => mediaQuery.size.shortestSide;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  bool get isLandscape => width > height;
  bool get isPortrait => height >= width;

  /// Safe-area-aware usable dimensions.
  double get safeWidth =>
      width - mediaQuery.padding.left - mediaQuery.padding.right;

  double get safeHeight =>
      height - mediaQuery.padding.top - mediaQuery.padding.bottom;

  /// Responsive horizontal page padding.
  double get horizontalPadding {
    if (isMobile) return 16;
    if (isTablet) return 28;
    return 40;
  }

  /// Responsive vertical page padding.
  double get verticalPadding {
    if (isMobile) return 16;
    if (isTablet) return 24;
    return 32;
  }

  /// Scales a design value relative to a 390px mobile design width.
  ///
  /// Clamped so large desktop screens don't make everything enormous.
  double scale(double value, {double min = 0.85, double max = 1.35}) {
    final factor = width / 390.0;
    return value * factor.clamp(min, max);
  }

  /// Font-size helper with a smaller growth range than normal spacing.
  double font(double size, {double minScale = 0.92, double maxScale = 1.18}) {
    final factor = width / 390.0;
    return size * factor.clamp(minScale, maxScale);
  }

  /// Responsive radius.
  double radius(double value) {
    return scale(value, min: 0.9, max: 1.15);
  }

  /// Responsive icon size.
  double icon(double value) {
    return scale(value, min: 0.9, max: 1.15);
  }

  /// Returns a responsive value for mobile/tablet/desktop.
  double value({required double mobile, double? tablet, double? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Useful for cards/grids.
  int gridColumns({int mobile = 2, int tablet = 4, int desktop = 6}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  /// Calculates a grid aspect ratio from the available width.
  double gridChildAspectRatio({
    double mobile = 0.78,
    double tablet = 0.82,
    double desktop = 0.86,
  }) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }
}

/// A convenient extension so you can write:
///
///   context.responsive.width
///   context.responsive.isMobile
///   context.responsive.scale(20)
extension ResponsiveBuildContext on BuildContext {
  Responsive get responsive => Responsive.of(this);
}

/// Responsive builder for widgets that need different layouts.
///
/// Example:
///
/// ResponsiveLayout(
///   mobile: MobileWidget(),
///   tablet: TabletWidget(),
///   desktop: DesktopWidget(),
/// )
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    if (r.isDesktop) {
      return desktop ?? tablet ?? mobile;
    }

    if (r.isTablet) {
      return tablet ?? mobile;
    }

    return mobile;
  }
}

/// Responsive spacing widget.
///
/// Example:
///   RSpace(24)
class RSpace extends StatelessWidget {
  const RSpace(this.size, {super.key, this.horizontal = false});

  final double size;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final value = context.responsive.scale(size);

    return SizedBox(
      width: horizontal ? value : null,
      height: horizontal ? null : value,
    );
  }
}

/// Responsive page container.
///
/// Keeps content from becoming excessively wide on large monitors.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth = 1400,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: r.horizontalPadding,
            vertical: r.verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
