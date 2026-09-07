import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Nocturne design's primary call-to-action (`.btn-primary`): accent
/// text and 1px accent border on a transparent fill — the design reserves
/// solid fills for tags/chips, not buttons — with a built-in loading state
/// so every async action (sign in, submit request, save) shows the same
/// spinner-in-button pattern instead of each screen reinventing it.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// The design's `.btn-block` — full width. Defaults to true since nearly
  /// every primary action in the design sits in a sticky full-width footer.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accent,
        disabledForegroundColor: colors.accent.withValues(alpha: 0.45),
        side: BorderSide(color: colors.accent),
        minimumSize: const Size.fromHeight(48),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.accent,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// The design's `.btn-secondary`: a neutral divider-colored outline, used
/// for the less-prominent half of a two-button pair ("Reject" next to
/// "Approve", "Not now" next to "Accept and receive").
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.neutralRing),
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// The design's `.btn-ghost`: accent-colored text with no border, used for
/// quiet inline actions ("Copy", "See all", "Clear").
class AppGhostButton extends StatelessWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(foregroundColor: context.colors.accent);
    if (icon == null) {
      return TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
