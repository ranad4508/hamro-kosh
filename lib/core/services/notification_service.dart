import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push-notification wiring for SRS §23/§28/§29. Requests permission,
/// keeps the signed-in member's FCM token saved on their `users` document
/// (this was the actual missing link — Cloud Functions can't push to a
/// device without one), and refreshes it if it rotates. Sending pushes
/// happens server-side (functions/index.js's `sendPush`), never from the
/// client.
class NotificationService {
  NotificationService(this._messaging, this._auth, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _saveTokenForCurrentUser();
    _auth.authStateChanges().listen((_) => _saveTokenForCurrentUser());
    _messaging.onTokenRefresh.listen((token) => _saveToken(token));

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (error) {
      // The user doc may not exist yet mid-registration; the next
      // authStateChanges/onTokenRefresh firing will retry.
      debugPrint('Could not save FCM token: $error');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // No further action needed here: the in-app notification center reads
    // live from Firestore (populated server-side by the same Cloud
    // Function that sent this push), so it updates regardless of whether
    // this specific push is shown as a system banner.
    debugPrint('Foreground message received: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // TODO(hamro-kosh): deep-link into the relevant screen (loan, fund,
    // announcement) using go_router based on message.data, once a
    // global navigator/router handle is threaded in here.
    debugPrint('Notification tapped: ${message.messageId}');
  }
}
