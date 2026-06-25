/// Build-time secrets passed via `--dart-define`.
///
/// Example:
///   flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
///   flutter build apk --dart-define=CLOUD_FUNCTIONS_URL=https://your-region-project.cloudfunctions.net
class AppSecrets {
  AppSecrets._();

  /// Google AI Studio key for direct Gemini access.
  /// Passed at build time: --dart-define=GEMINI_API_KEY=...
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Firebase Cloud Functions base URL.
  /// Passed at build time: --dart-define=CLOUD_FUNCTIONS_URL=...
  static const cloudFunctionsUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-lune-7d956.cloudfunctions.net',
  );
}
