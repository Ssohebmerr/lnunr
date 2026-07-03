/// Build-time configuration — no API keys in release builds.
///
/// AI keys live in Firebase Functions secrets:
///   DEEPSEEK_API_KEY (primary)
///   GEMINI_API_KEY   (fallback)
class AppSecrets {
  AppSecrets._();

  /// Firebase Cloud Functions base URL.
  static const cloudFunctionsUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-lune-7d956.cloudfunctions.net',
  );
}
