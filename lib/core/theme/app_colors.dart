import 'package:flutter/material.dart';

/// Brand seed colors sampled from the reference Hamro Kosh dashboard design
/// (dark navy/indigo surfaces, purple/lavender accents — SRS §5).
/// [ColorScheme.fromSeed] derives the full Material 3 palette from these for
/// both light and dark mode.
abstract final class AppColors {
  static const Color seedPrimary = Color(0xFF9184D9);
  static const Color seedSecondary = Color(0xFF5D5294);

  static const Color lightSurfaceTint = Color(0xFFFAF9FF);
  static const Color darkSurfaceTint = Color(0xFF161826);
}
