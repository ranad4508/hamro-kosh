/// Shared spacing, radius, and breakpoint constants used across the app so
/// layouts stay visually consistent without magic numbers in widgets.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Breakpoints used by [AdaptiveScaffold] to switch between a bottom
/// navigation bar (phones) and a navigation rail (tablets/desktop/foldables).
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 1024;
}
