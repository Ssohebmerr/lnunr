import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  // Web uses Firebase Hosting config; appId is optional for Auth + Firestore.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7eZd1_CoG4ynhNc7AwCs1zR0G1sJpIEo',
    appId: '1:113050193026:android:731eb6c6712ba42d10789b',
    messagingSenderId: '113050193026',
    projectId: 'lune-7d956',
    authDomain: 'lune-7d956.firebaseapp.com',
    storageBucket: 'lune-7d956.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3T_iSeJg0mU6aGMmcDpnO4clstnH8Q1g',
    appId: '1:113050193026:android:81eb438e56b544c710789b',
    messagingSenderId: '113050193026',
    projectId: 'lune-7d956',
    storageBucket: 'lune-7d956.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3T_iSeJg0mU6aGMmcDpnO4clstnH8Q1g',
    appId: '1:113050193026:android:731eb6c6712ba42d10789b',
    messagingSenderId: '113050193026',
    projectId: 'lune-7d956',
    storageBucket: 'lune-7d956.firebasestorage.app',
    iosBundleId: 'com.lune.app',
  );
}
