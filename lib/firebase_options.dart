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
    apiKey: 'AIzaSyAF-ec28WuatrNbaJm1-ji9HCG5jf521D8',
    appId: '1:147153174017:android:cd6e7ac8c565e65bc98a00',
    messagingSenderId: '147153174017',
    projectId: 'hamro-kosh1',
    storageBucket: 'hamro-kosh1.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCaL7LzHIcTRo0Riu23I_48L9t7tW1MOlc',
    appId: '1:147153174017:ios:7bfd608d134d5c6ac98a00',
    messagingSenderId: '147153174017',
    projectId: 'hamro-kosh1',
    storageBucket: 'hamro-kosh1.firebasestorage.app',
    iosBundleId: 'com.hamrokosh.hamroKosh',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyArBKSqM43hZV1fcYJ30R9PJ1qqaWO-oa8',
    appId: '1:147153174017:web:90040e9b369832a0c98a00',
    messagingSenderId: '147153174017',
    projectId: 'hamro-kosh1',
    authDomain: 'hamro-kosh1.firebaseapp.com',
    storageBucket: 'hamro-kosh1.firebasestorage.app',
  );
}
