import 'package:flutter/material.dart';

/// A light adjustment over Material 3's default type scale — slightly
/// tighter headline weights suit a data-dense financial dashboard better
/// than the stock scale, while staying on the platform default font
/// (Roboto/San Francisco) to avoid an external font-fetch dependency.
TextTheme buildAppTextTheme(TextTheme base) {
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}
