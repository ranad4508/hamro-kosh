import 'package:flutter/material.dart';

import '../models/loan_status.dart';
import '../theme/app_colors.dart';

/// A small pill badge for a loan/contribution/transaction status, styled
/// after the Nocturne design's `.tag` component family (`.tag-accent`,
/// `.tag-outline`, `.tag-neutral`) rather than a generic Material chip.
///
/// Color-coding follows the design's own convention (`design_spec.md` §2,
/// pattern 2): solid accent = good/complete/on-track, an accent outline =
/// needs attention/waiting, flat neutral grey = informational/inactive, and
/// the one warm terracotta = danger/overdue/penalty.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color? bg, Color fg, Color? border) = switch (tone) {
      StatusTone.positive => (colors.accentDark1, colors.accentFaintBg, null),
      StatusTone.info => (colors.accent2Dark, colors.accentFaintBg, null),
      StatusTone.neutral => (colors.neutralTagBg, colors.neutralTagFg, null),
      StatusTone.pending => (null, colors.accent, colors.accent),
      StatusTone.negative => (colors.warningSurface, colors.warning, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: fg, fontSize: 11.5),
      ),
    );
  }
}
