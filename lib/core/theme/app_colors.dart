import 'package:flutter/material.dart';

/// Brand seed colors sampled from the Hamro Kosh knot-and-arrow mark
/// (violet-to-indigo gradient). [ColorScheme.fromSeed] derives the full
/// Material 3 palette from these for both light and dark mode.
abstract final class AppColors {
  static const Color seedPrimary = Color(0xFF7C5CFC);
  static const Color seedSecondary = Color(0xFF3F3F5C);

  static const Color lightSurfaceTint = Color(0xFFFAF9FF);
  static const Color darkSurfaceTint = Color(0xFF171221);
}
