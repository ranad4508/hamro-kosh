import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/firestore_offline_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/shared_preferences_provider.dart';
import 'firebase_options.dart';

/// App entry point, separated from `main.dart` so startup sequencing
/// (Firebase, offline persistence, push notifications, preferences) lives
/// in one readable place instead of a bloated `main()`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    configureFirestoreOfflinePersistence();
    await NotificationService(
      FirebaseMessaging.instance,
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    ).initialize();
  } catch (error, stackTrace) {
    // Expected until `flutterfire configure` has been run with a real
    // project — the app still starts so the rest of the UI (theming,
    // navigation scaffold) remains usable/demoable without Firebase.
    debugPrint('Firebase initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const HamroKoshApp(),
    ),
  );
}
