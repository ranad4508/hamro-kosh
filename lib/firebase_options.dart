// File generated in the shape produced by the FlutterFire CLI.
//
// ⚠️ PLACEHOLDER — these values are not a real Firebase project. Run:
//     dart pub global activate flutterfire_cli
//     flutterfire configure
// from the project root to overwrite this file with your real project's
// options (it also wires the native Android/iOS config automatically).
// See README.md → "Connect Firebase" for the full walkthrough.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and iOS '
          'in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSCHOpTi0PaovLfWuRky80kK9r6QDZZ3g',
    appId: '1:658475363771:android:a4ce60231f4093f94ea89e',
    messagingSenderId: '658475363771',
    projectId: 'hamro-kosh-main',
    storageBucket: 'hamro-kosh-main.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAo670IEgkUHZomdE0CHbYIH_1jfCrlmwI',
    appId: '1:658475363771:ios:135d55da017fc3554ea89e',
    messagingSenderId: '658475363771',
    projectId: 'hamro-kosh-main',
    storageBucket: 'hamro-kosh-main.firebasestorage.app',
    iosBundleId: 'com.hamrokosh.hamroKosh',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAH9cnatSljkplsghmKW0LBcF17YvPL9yY',
    appId: '1:658475363771:web:7d2aea26a3932ba94ea89e',
    messagingSenderId: '658475363771',
    projectId: 'hamro-kosh-main',
    authDomain: 'hamro-kosh-main.firebaseapp.com',
    storageBucket: 'hamro-kosh-main.firebasestorage.app',
  );
}
