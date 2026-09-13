import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'finance_colors.dart';

/// Builds the app's [ThemeData] for both brightnesses from the same
/// Nocturne token roles (`app_colors.dart`) — the reference design was
/// drawn dark-only, but the app itself supports light/dark/system so it
/// respects both the OS-level appearance and the in-app toggle
/// (`ThemeModeController`). Every color comes from the resolved
/// [AppColors] palette, not a Material-3 seed derivation, so both themes
/// stay internally consistent with each other and with the design tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      surface: colors.bg,
      onSurface: colors.textPrimary,
      surfaceContainerLowest: colors.bg,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surfaceSunken,
      surfaceContainerHighest: colors.surfaceSunken,
      surfaceTint: Colors.transparent,
      onSurfaceVariant: colors.textTertiary,
      outline: colors.textQuaternary,
      outlineVariant: colors.divider,
      primary: colors.accent,
      onPrimary: brightness == Brightness.dark ? colors.bg : Colors.white,
      primaryContainer: colors.accentDark1,
      onPrimaryContainer: colors.accentFaintBg,
      secondary: colors.accent2,
      onSecondary: brightness == Brightness.dark ? colors.bg : Colors.white,
      secondaryContainer: colors.accent2Dark,
      onSecondaryContainer: colors.accentFaintBg,
      tertiary: colors.accentLight,
      onTertiary: brightness == Brightness.dark ? colors.bg : Colors.white,
      error: colors.warning,
      onError: Colors.white,
      errorContainer: colors.warningSurface,
      onErrorContainer: colors.warning,
      inversePrimary: colors.accentDark1,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.bg,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      dividerColor: colors.divider,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: buildAppTextTheme(colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.neutralRing),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceFooter,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: selected ? colors.accent : colors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? colors.accent : colors.textTertiary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceFooter,
        useIndicator: true,
        indicatorColor: colors.accentDark2,
        selectedIconTheme: IconThemeData(color: colors.accent),
        unselectedIconTheme: IconThemeData(color: colors.textTertiary),
        selectedLabelTextStyle: TextStyle(color: colors.accent),
        unselectedLabelTextStyle: TextStyle(color: colors.textTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.35),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.accent),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSunken,
        labelStyle: TextStyle(color: colors.textTertiary),
        hintStyle: TextStyle(color: colors.textQuaternary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.neutralRing),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.neutralRing),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: colors.warning),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceSunken,
        selectedColor: colors.accentDark1,
        labelStyle: TextStyle(color: colors.textPrimary),
        side: BorderSide(color: colors.neutralRing),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceFooter,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceSunken,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.neutralRing,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : Colors.transparent,
        ),
        side: BorderSide(color: colors.neutralRing, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colors.textPrimary),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.surfaceSunken,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.divider,
      ),
      extensions: [
        colors,
        brightness == Brightness.dark ? FinanceColors.dark : FinanceColors.light,
      ],
    );
  }
}
