import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

/// The app's single feedback-toast component — every success/error/warning/
/// info message in the app goes through this, so the look never drifts
/// screen to screen. Wraps `awesome_snackbar_content`, which produces the
/// exact colored-card / bubble-icon / close-button / dot-accent design the
/// product's UI reference calls for.
abstract final class AppSnackbar {
  static void showSuccess(BuildContext context, {required String title, required String message}) {
    _show(context, title: title, message: message, contentType: ContentType.success);
  }

  static void showError(BuildContext context, {required String title, required String message}) {
    _show(context, title: title, message: message, contentType: ContentType.failure);
  }

  static void showWarning(BuildContext context, {required String title, required String message}) {
    _show(context, title: title, message: message, contentType: ContentType.warning);
  }

  static void showInfo(BuildContext context, {required String title, required String message}) {
    _show(context, title: title, message: message, contentType: ContentType.help);
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
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
