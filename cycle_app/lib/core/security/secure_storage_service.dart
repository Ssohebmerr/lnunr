import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive values in Android Keystore / iOS Keychain (Google Play best practice).
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // resetOnError clears a corrupted keystore entry instead of
              // throwing forever (a known Android crash-loop after OS updates
              // or backup restores).
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Returns null on any platform error so callers never crash on a flaky
  /// keystore read.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
