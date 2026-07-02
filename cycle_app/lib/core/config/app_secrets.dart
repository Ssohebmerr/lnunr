/// Build-time secrets passed via `--dart-define`.
///
/// Example:
///   flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
///   flutter build apk --dart-define=CLOUD_FUNCTIONS_URL=https://your-region-project.cloudfunctions.net
class AppSecrets {
  AppSecrets._();

  /// Google AI Studio key for direct Gemini access.
  /// Passed at build time: --dart-define=GEMINI_API_KEY=...
  /// Falls back to the embedded key below.
  ///
  /// NOTE: Keep this repository private. Google automatically blocks API keys
  /// detected in public source. If this key ever returns
  /// API_KEY_SERVICE_BLOCKED, generate a new one at aistudio.google.com/apikey
  /// and replace the value below.
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6Kex3j9LyVqTEW6f6Y7KVctmxfBdAQKeATKhSXP_Dx5Vg',
  );

  /// Firebase Cloud Functions base URL.
  /// Passed at build time: --dart-define=CLOUD_FUNCTIONS_URL=...
  static const cloudFunctionsUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-lune-7d956.cloudfunctions.net',
  );
}
