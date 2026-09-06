import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push-notification scaffolding for SRS §28/§29 (contribution, loan, fund
/// usage, and reminder emails/notifications). This wires up permission
/// requests and token retrieval; the actual per-event message handling
/// (routing a tapped notification to the right screen, persisting it into
/// the in-app notification center) is business logic for a later feature
/// pass, marked with TODOs below rather than stubbed out silently.
class NotificationService {
  NotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // TODO(hamro-kosh): persist this token against the signed-in member's
    // Firestore document so admins can target push notifications.
    await _messaging.getToken();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // TODO(hamro-kosh): surface an in-app banner/snackbar and add the
    // message to the notification center (SRS §45).
    debugPrint('Foreground message received: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // TODO(hamro-kosh): deep-link into the relevant screen (loan, fund,
    // announcement) using go_router based on message.data.
    debugPrint('Notification tapped: ${message.messageId}');
  }
}
