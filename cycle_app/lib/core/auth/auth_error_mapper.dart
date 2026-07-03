import '../../l10n/app_localizations.dart';

/// Maps Firebase Auth errors to user-friendly localized messages.
class AuthErrorMapper {
  static String message(Object error, AppLocalizations l10n) {
    final text = error.toString().toLowerCase();
    if (text.contains('wrong-password') ||
        text.contains('invalid-credential') ||
        text.contains('invalid_login_credentials')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (text.contains('user-not-found')) {
      return l10n.authErrorUserNotFound;
    }
    if (text.contains('email-already-in-use')) {
      return l10n.authErrorEmailInUse;
    }
    if (text.contains('weak-password')) {
      return l10n.authErrorWeakPassword;
    }
    if (text.contains('too-many-requests')) {
      return l10n.authErrorTooManyRequests;
    }
    if (text.contains('network-request-failed') ||
        text.contains('network error')) {
      return l10n.authErrorNetwork;
    }
    if (text.contains('cancelled') || text.contains('canceled')) {
      return l10n.authErrorCancelled;
    }
    if (text.contains('apiexception: 10') ||
        text.contains('developer_error') ||
        text.contains('sign_in_failed')) {
      return l10n.authErrorGoogleConfig;
    }
    return l10n.errorGeneric;
  }
}
