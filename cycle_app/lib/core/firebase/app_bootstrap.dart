import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Initializes Firebase, App Check, Firestore persistence, and Crashlytics.
class AppBootstrap {
  AppBootstrap._();

  /// Debug builds use the App Check debug provider so emulators and sideloaded
  /// test APKs can still reach Firestore. RELEASE builds now default to the real
  /// attestation providers (Play Integrity / App Attest) — App Check is no
  /// longer effectively disabled in production.
  ///
  /// Pass `--dart-define=APP_CHECK_DEBUG=true` to force the debug provider in a
  /// release build (e.g. a QA/sideload build that isn't registered with Play
  /// Integrity yet).
  static const _forceDebugAppCheck = bool.fromEnvironment(
    'APP_CHECK_DEBUG',
    defaultValue: false,
  );

  static final bool _useDebugAppCheck = kDebugMode || _forceDebugAppCheck;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence so the app works without network.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    try {
      await FirebaseAppCheck.instance
          .activate(
            androidProvider: _useDebugAppCheck
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider: _useDebugAppCheck
                ? AppleProvider.debug
                : AppleProvider.appAttest,
          )
          .timeout(const Duration(seconds: 4));
    } catch (e, st) {
      // App Check can fail on sideloaded release APKs (no Play Integrity).
      // The app must still launch; Firebase calls may be limited until fixed.
      debugPrint('[AppBootstrap] App Check activate skipped: $e\n$st');
    }

    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }
}
