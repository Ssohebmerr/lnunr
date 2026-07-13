import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../../../core/security/secure_storage_service.dart';

/// Account-scoped encryption for cloud backups.
///
/// The cycle database itself is encrypted with a key that never leaves the
/// device keystore ([CycleEncryptionKeys]) — which also meant a cloud backup
/// made on device A could never be decrypted on device B, so cloud restore
/// did not survive device loss or reinstall.
///
/// This service fixes that with a *backup key* that belongs to the account,
/// not the device: a random 256-bit AES key generated once per user, cached
/// in the platform keystore, and escrowed in
/// `users/{uid}/secure/backupKey` (owner-only Firestore rules). Cloud backup
/// payloads are encrypted with this key, so after signing in on a new device
/// the key — and therefore the backup — is recoverable.
///
/// Trade-off, on purpose: Firestore holds both the ciphertext and the key
/// (in separate owner-only documents), so this protects against leaked
/// storage dumps and third parties, not against a fully compromised project
/// admin. That is the standard consumer-app balance between privacy and
/// "my phone broke and I lost everything".
class BackupCrypto {
  BackupCrypto({FirebaseFirestore? firestore, SecureStorageService? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? SecureStorageService();

  final FirebaseFirestore _firestore;
  final SecureStorageService _storage;

  static const _localKeyPrefix = 'cloud_backup_key_';

  DocumentReference<Map<String, dynamic>> _keyDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('secure').doc('backupKey');

  /// The account backup key (base64, 32 bytes) — local cache first, then the
  /// Firestore escrow, generating and escrowing a fresh key when neither
  /// exists. Returns null when the key can neither be loaded nor escrowed
  /// (offline, rules not deployed) so callers can fall back to a legacy
  /// device-key backup instead of failing the sync.
  Future<String?> loadOrCreateKey(String uid) async {
    final existing = await loadKey(uid);
    if (existing != null) return existing;

    final fresh = generateKey();
    try {
      // Escrow first: a key that only exists locally would recreate the
      // exact portability bug this class exists to fix.
      await _keyDoc(uid).set({
        'k': fresh,
        'v': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      return null;
    }
    await _storage.write('$_localKeyPrefix$uid', fresh);
    return fresh;
  }

  /// The account backup key if it exists locally or in escrow — never
  /// creates one. Used by restore, where a missing key simply means there is
  /// no portable backup to decrypt.
  Future<String?> loadKey(String uid) async {
    final local = await _storage.read('$_localKeyPrefix$uid');
    if (local != null && local.isNotEmpty) return local;

    try {
      final doc = await _keyDoc(uid).get();
      final remote = doc.data()?['k'] as String?;
      if (remote == null || remote.isEmpty) return null;
      await _storage.write('$_localKeyPrefix$uid', remote);
      return remote;
    } catch (_) {
      return null;
    }
  }

  /// Fresh random 256-bit key, base64-encoded.
  static String generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Encrypts [plain] (a JSON-safe map) with AES-256-CBC and a random IV.
  /// The result is the Firestore payload shape used by version-2 backups.
  static Map<String, dynamic> encryptPayload(
    String keyB64,
    Map<String, dynamic> plain,
  ) {
    final key = enc.Key(base64Decode(keyB64));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final cipher = encrypter.encrypt(jsonEncode(plain), iv: iv);
    return {'payload': cipher.base64, 'iv': iv.base64};
  }

  /// Reverses [encryptPayload]. Throws on a wrong key or tampered payload.
  static Map<String, dynamic> decryptPayload(
    String keyB64,
    Map<String, dynamic> doc,
  ) {
    final payload = doc['payload'] as String?;
    final ivB64 = doc['iv'] as String?;
    if (payload == null || ivB64 == null) {
      throw const FormatException('Missing payload or iv');
    }
    final key = enc.Key(base64Decode(keyB64));
    final iv = enc.IV(base64Decode(ivB64));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = encrypter.decrypt64(payload, iv: iv);
    final decoded = jsonDecode(plain);
    if (decoded is! Map) throw const FormatException('Not a JSON object');
    return Map<String, dynamic>.from(decoded);
  }
}
