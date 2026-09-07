import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

/// The app's single feedback-toast component — every success/error/warning/
/// info message in the app goes through this, so the look never drifts
/// screen to screen. Wraps `awesome_snackbar_content`, which produces the
/// exact colored-card / bubble-icon / close-button / dot-accent design the
/// product's UI reference calls for.
abstract final class AppSnackbar {
  // Guards against the same message flashing 2-3 times in a row — e.g. a
  // `ref.listen` error callback re-running across a couple of rebuilds, or a
  // double-tapped submit button firing the same failed request twice, each
  // independently calling `showError` with an identical title/message
  // within the same instant. A genuinely new/different message is never
  // suppressed, only an exact repeat within this short window.
  static String? _lastKey;
  static DateTime? _lastShownAt;
  static const _dedupeWindow = Duration(milliseconds: 800);

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.success,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.failure,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.warning,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.help,
    );
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final now = DateTime.now();
    final key = '$contentType|$title|$message';
    if (key == _lastKey &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupeWindow) {
      return;
    }
    _lastKey = key;
    _lastShownAt = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      // `clearSnackBars()` removes the current snackbar (and anything
      // queued behind it) instantly, with no exit animation — swapping in a
      // genuinely new message this way reads as one clean replacement
      // instead of the previous card visibly animating out while the next
      // animates in, which is what actually reads as "flashing" when two
      // calls land close together.
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 4),
          // Flutter's default floating margin (~15dp each side) leaves the
          // card looking narrow against the reference design — tighten it
          // so the card reads as wide as the screen realistically allows.
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          padding: EdgeInsets.zero,
          // SnackBar defaults to Clip.hardEdge, which clips anything a child
          // paints outside its own rounded-rect bounds — including the
          // bubble icon badge, which `awesome_snackbar_content` deliberately
          // positions with a *negative* top/left offset so it peeks out
          // above the card's corner. Without this, that badge gets sliced
          // off exactly like the "cut off icon" bug this fixes.
          clipBehavior: Clip.none,
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: contentType,
            inMaterialBanner: false,
          ),
        ),
      );
  }
}
