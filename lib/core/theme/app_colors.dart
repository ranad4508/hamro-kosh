import 'package:flutter/material.dart';

/// The "Nocturne" design system's token colors (`design_spec.md` §1), as a
/// [ThemeExtension] so every screen resolves colors through
/// [Theme.of(context)] and adapts correctly to light/dark — both OS-level
/// (`ThemeMode.system`) and the in-app toggle (`ThemeModeController`) —
/// instead of a fixed set of static constants that could never change at
/// runtime. The design itself was drawn dark-only; [light] is this app's
/// own extrapolation of the same token roles onto a light ground, keeping
/// every semantic role (accent, surface, tag colors, etc.) the same so
/// widgets that reference e.g. `colors.accentDark1` as "a tag's background"
/// don't need theme-specific branches — only the token's value changes.
///
/// Access via `context.colors` ([AppColorsX]).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceFooter,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.accent,
    required this.accentLight,
    required this.accentLightest,
    required this.accentPaleBg,
    required this.accentFaintBg,
    required this.accentDark1,
    required this.accentDark2,
    required this.accentDark3,
    required this.accentDark4,
    required this.accent2,
    required this.accent2Dark,
    required this.neutralTagBg,
    required this.neutralTagFg,
    required this.warning,
    required this.warningSurface,
  });

  // Surfaces, darkest to lightest (in dark mode) / lightest to darkest
  // (in light mode) — think "page bg, card, sunken input, footer bar".
  final Color bg;
  final Color surface;
  final Color surfaceSunken;
  final Color surfaceFooter;
  final Color divider;

  // Text, most to least prominent.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;

  // Accent (purple/lavender) ramp.
  final Color accent;
  final Color accentLight;
  final Color accentLightest;
  final Color accentPaleBg;
  final Color accentFaintBg;
  final Color accentDark1;
  final Color accentDark2;
  final Color accentDark3;
  final Color accentDark4;

  // Secondary accent (muted lavender-grey).
  final Color accent2;
  final Color accent2Dark;

  // Neutral tag/pill tokens (`.tag-neutral`).
  final Color neutralTagBg;
  final Color neutralTagFg;

  // Warning / overdue / penalty (warm terracotta).
  final Color warning;
  final Color warningSurface;

  /// A subtle ring/hairline color, derived from [textPrimary] so it always
  /// reads correctly against this palette's own surfaces without a
  /// separate light/dark value to keep in sync.
  Color get neutralRing => textPrimary.withValues(alpha: 0.16);
  Color get hairline => textPrimary.withValues(alpha: 0.09);
  Color get rowDivider => textPrimary.withValues(alpha: 0.07);
  Color get rowDividerStrong => textPrimary.withValues(alpha: 0.12);

  static const dark = AppColors(
    bg: Color(0xFF161826),
    surface: Color(0xFF232532),
    surfaceSunken: Color(0xFF1E2030),
    surfaceFooter: Color(0xFF1B1D2A),
    divider: Color(0xFF292B31),
    textPrimary: Color(0xFFE9E9ED),
    textSecondary: Color(0xFFB2B6CA),
    textTertiary: Color(0xFF9397AB),
    textQuaternary: Color(0xFF75798C),
    accent: Color(0xFF9184D9),
    accentLight: Color(0xFFB5ABFC),
    accentLightest: Color(0xFFD2CEFD),
    accentPaleBg: Color(0xFFE7E5FE),
    accentFaintBg: Color(0xFFF5F4FF),
    accentDark1: Color(0xFF423A6A),
    accentDark2: Color(0xFF2B2741),
    accentDark3: Color(0xFF5D5294),
    accentDark4: Color(0xFF796CBF),
    accent2: Color(0xFFA7A1DB),
    accent2Dark: Color(0xFF423E5D),
    neutralTagBg: Color(0xFF3F424D),
    neutralTagFg: Color(0xFFF3F5FE),
    warning: Color(0xFFD2A08A),
    warningSurface: Color(0xFF332B2B),
  );

  /// This app's light extrapolation of the same roles — same relationships
  /// (e.g. `accentDark1`/`accentFaintBg` are always "a solid tag's bg/fg
  /// pair"), different concrete values so contrast stays correct on a
  /// light ground.
  static const light = AppColors(
    bg: Color(0xFFF7F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFEEF5),
    surfaceFooter: Color(0xFFFFFFFF),
    divider: Color(0xFFE2E1EA),
    textPrimary: Color(0xFF1C1B22),
    textSecondary: Color(0xFF4B4A57),
    textTertiary: Color(0xFF6F6E7C),
    textQuaternary: Color(0xFF8E8D9C),
    accent: Color(0xFF6C5DD6),
    accentLight: Color(0xFF5A4BC4),
    accentLightest: Color(0xFF4A3A9E),
    accentPaleBg: Color(0xFFEDE9FB),
    accentFaintBg: Color(0xFF3D2F8C),
    accentDark1: Color(0xFFE4DFFA),
    accentDark2: Color(0xFFEAE6FA),
    accentDark3: Color(0xFF8879D1),
    accentDark4: Color(0xFF9F93DE),
    accent2: Color(0xFF5F52A8),
    accent2Dark: Color(0xFFE6E3F5),
    neutralTagBg: Color(0xFFECECF0),
    neutralTagFg: Color(0xFF33343D),
    warning: Color(0xFFA6572E),
    warningSurface: Color(0xFFF7E8DE),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSunken,
    Color? surfaceFooter,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? accent,
    Color? accentLight,
    Color? accentLightest,
    Color? accentPaleBg,
    Color? accentFaintBg,
    Color? accentDark1,
    Color? accentDark2,
    Color? accentDark3,
    Color? accentDark4,
    Color? accent2,
    Color? accent2Dark,
    Color? neutralTagBg,
    Color? neutralTagFg,
    Color? warning,
    Color? warningSurface,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceFooter: surfaceFooter ?? this.surfaceFooter,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      accentLightest: accentLightest ?? this.accentLightest,
      accentPaleBg: accentPaleBg ?? this.accentPaleBg,
      accentFaintBg: accentFaintBg ?? this.accentFaintBg,
      accentDark1: accentDark1 ?? this.accentDark1,
      accentDark2: accentDark2 ?? this.accentDark2,
      accentDark3: accentDark3 ?? this.accentDark3,
      accentDark4: accentDark4 ?? this.accentDark4,
      accent2: accent2 ?? this.accent2,
      accent2Dark: accent2Dark ?? this.accent2Dark,
      neutralTagBg: neutralTagBg ?? this.neutralTagBg,
      neutralTagFg: neutralTagFg ?? this.neutralTagFg,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      surfaceFooter: l(surfaceFooter, other.surfaceFooter),
      divider: l(divider, other.divider),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textQuaternary: l(textQuaternary, other.textQuaternary),
      accent: l(accent, other.accent),
      accentLight: l(accentLight, other.accentLight),
      accentLightest: l(accentLightest, other.accentLightest),
      accentPaleBg: l(accentPaleBg, other.accentPaleBg),
      accentFaintBg: l(accentFaintBg, other.accentFaintBg),
      accentDark1: l(accentDark1, other.accentDark1),
      accentDark2: l(accentDark2, other.accentDark2),
      accentDark3: l(accentDark3, other.accentDark3),
      accentDark4: l(accentDark4, other.accentDark4),
      accent2: l(accent2, other.accent2),
      accent2Dark: l(accent2Dark, other.accent2Dark),
      neutralTagBg: l(neutralTagBg, other.neutralTagBg),
      neutralTagFg: l(neutralTagFg, other.neutralTagFg),
      warning: l(warning, other.warning),
      warningSurface: l(warningSurface, other.warningSurface),
    );
  }
}

/// Convenience accessor: `context.colors.accent`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
