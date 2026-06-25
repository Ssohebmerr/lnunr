import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Initializes Firebase, App Check, and Crashlytics error reporting.
class AppBootstrap {
  AppBootstrap._();

  /// Set `false` for Play Store release. `true` lets sideload/test APKs use Firestore.
  static const _useDebugAppCheck = bool.fromEnvironment(
    'APP_CHECK_DEBUG',
    defaultValue: true,
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: _useDebugAppCheck
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: _useDebugAppCheck
          ? AppleProvider.debug
          : AppleProvider.appAttest,
    );

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
