import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the Nocturne design's type scale on Inter (Latin) — Devanagari
/// text uses [notoSansDevanagari] directly rather than the ambient
/// [TextTheme], since Nepali strings render in a different family from the
/// English string sitting right next to them (`design_spec.md` §1.3's
/// always-both-languages pattern) rather than switching the whole theme's
/// font per locale.
///
/// Turn 4's accessibility correction is treated as canon over the smaller
/// sizes literally drawn in turns 1-3 (`design_spec.md` §1.3): 13-15px body
/// text, larger headline sizes for hero numerals.
///
/// Takes the resolved [AppColors] palette (light or dark) rather than
/// reading static colors, since this is built once per [AppTheme.light]/
/// [AppTheme.dark] call.
TextTheme buildAppTextTheme(AppColors colors) {
  final base = GoogleFonts.interTextTheme();
  return base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02,
          fontSize: 34,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02,
          fontSize: 28,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 22,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 19,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 15.5,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 15),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 13,
          color: colors.textTertiary,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: base.labelMedium?.copyWith(fontSize: 12),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 9.5,
          letterSpacing: 1.1,
          color: colors.accent,
        ),
      )
      .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);
}

/// The Devanagari counterpart to [buildAppTextTheme] — used explicitly via
/// [BilingualText] rather than through the ambient [TextTheme], since a
/// Nepali line always sits directly beside/beneath an English one in a
/// different, smaller, dimmer style rather than replacing it.
TextStyle notoSansDevanagari({
  double fontSize = 12.5,
  FontWeight fontWeight = FontWeight.w400,
  // Fallback only — callers should pass `context.colors.textTertiary` (or
  // similar) explicitly so this adapts to the active theme.
  Color color = const Color(0xFF9397AB),
  double? height,
}) {
  return GoogleFonts.notoSansDevanagari(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

/// The uppercase, letter-spaced "kicker"/eyebrow label style (`.k` in the
/// source stylesheet) used above section headings and hero card titles.
TextStyle kickerTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall!;
}
