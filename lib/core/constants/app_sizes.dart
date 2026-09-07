/// Shared spacing, radius, and breakpoint constants used across the app so
/// layouts stay visually consistent without magic numbers in widgets.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Radius scale matching the Nocturne design's actual scale
/// (`design_spec.md` §1.4): 4px for tiny chips, 8-9px as the dominant card/
/// button/input radius, 10-12px for emphasized cards, 14px for hero cards.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double pill = 999;
}

/// Breakpoints used by [AdaptiveScaffold] to switch between a bottom
/// navigation bar (phones) and a navigation rail (tablets/desktop/foldables).
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 1024;
}
