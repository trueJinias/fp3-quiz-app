// File generated for Firebase configuration.
// Generated from google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCD1QgtJt5tDDEg_Xz0oKFf9k_zGp8GnSM',
    appId: '1:223368078586:android:33b5795dbef99d26c71543',
    messagingSenderId: '223368078586',
    projectId: 'fp3-exam-prep',
    storageBucket: 'fp3-exam-prep.firebasestorage.app',
  );
}
