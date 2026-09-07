import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The design's On/Off pill toggle (`design_spec.md`'s `.tag` family, as
/// seen on the admin fund-rules "What members can see" rows) — a solid
/// accent pill reading "On", a neutral outlined pill reading "Off" — used
/// instead of a native sliding [Switch], which doesn't appear anywhere in
/// the reference design.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? colors.accent.withValues(alpha: enabled ? 1 : 0.5)
              : colors.surfaceSunken,
          borderRadius: BorderRadius.circular(20),
          border: value ? null : Border.all(color: colors.neutralRing),
        ),
        child: Text(
          value ? 'On' : 'Off',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: value ? colors.bg : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Drop-in replacement for [SwitchListTile] using [AppToggle] as the
/// trailing control, so every on/off row in the app (privacy settings, app
/// lock, email preferences) shares one look.
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.contentPadding,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget title;
  final Widget? subtitle;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      onTap: () => onChanged(!value),
      title: title,
      subtitle: subtitle,
      trailing: AppToggle(value: value, onChanged: onChanged),
    );
  }
}
