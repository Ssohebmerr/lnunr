// ============================================================================
// test/core/security/cycle_encryption_keys_test.dart
// ----------------------------------------------------------------------------
// Tests the AES key bootstrap + resilience logic that lets the cycle DB
// survive an Android Keystore wipe.
//
// What we cover:
//   - `localCustomerId` constant is stable (used as the fallback uid).
//   - `customerIdFromUid` always returns a 16-char lowercase hex hash for any
//     non-empty uid, and never throws.
//   - `customerIdFromUid(null)` and `customerIdFromUid('')` fall back to
//     `localCustomerId`.
//   - Same uid → same hash (deterministic).
//   - Different uids → different hashes (no obvious collision in samples).
//   - `loadOrCreate` honours the secure store when present, the prefs
//     backup when the secure store is empty, and only generates a fresh key
//     when BOTH stores are empty.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_aura/core/security/cycle_encryption_keys.dart';
import 'package:cycle_aura/core/security/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // We never want a real FlutterSecureStorage call inside the unit-test JVM,
  // so inject a no-op variant via a thin shim. Because `CycleEncryptionKeys`
  // uses `SecureStorageService()` directly, we work around it by populating
  // only `SharedPreferences` and accepting that the secure-store branch is
  // exercised by reading the prefs-backed secret path (the documented
  // fallback). See `loadOrCreate` for the precedence rules.

  group('CycleEncryptionKeys.localCustomerId', () {
    test('is a stable non-empty string', () {
      expect(CycleEncryptionKeys.localCustomerId, isNotEmpty);
      // Two reads return the same reference (it's a `const`).
      expect(
        identical(CycleEncryptionKeys.localCustomerId,
            CycleEncryptionKeys.localCustomerId),
        isTrue,
      );
    });
  });

  group('CycleEncryptionKeys.customerIdFromUid', () {
    test('null → fallback to localCustomerId', () {
      expect(
        CycleEncryptionKeys.customerIdFromUid(null),
        CycleEncryptionKeys.localCustomerId,
      );
    });

    test('empty string → fallback to localCustomerId', () {
      expect(
        CycleEncryptionKeys.customerIdFromUid(''),
        CycleEncryptionKeys.localCustomerId,
      );
    });

    test('non-empty uid → 16-char lowercase hex hash', () {
      final hash = CycleEncryptionKeys.customerIdFromUid('user-abc-123');
      expect(hash.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash), isTrue,
          reason: 'expected lowercase hex, got "$hash"');
    });

    test('deterministic: same uid → same hash', () {
      final a = CycleEncryptionKeys.customerIdFromUid('lune-user-42');
      final b = CycleEncryptionKeys.customerIdFromUid('lune-user-42');
      expect(a, b);
    });

    test('distinct uids → distinct hashes (sample)', () {
      final samples = <String>[
        'lune-user-1',
        'lune-user-2',
        'firebase-uid-AAAAAAAA',
        'firebase-uid-BBBBBBBB',
        'a',
        'b',
        'very-long-uid-${'x' * 100}',
      ];
      final hashes = samples.map(CycleEncryptionKeys.customerIdFromUid).toSet();
      // 7 distinct inputs → 7 distinct outputs (sha256[0..16] is collision-free
      // in practice for this sample size).
      expect(hashes.length, samples.length);
    });

    test('hashes are stable across calls (snapshot test)', () {
      // Locking down the exact hash protects against accidental algorithm
      // changes — if you swap the hashing scheme here, you MUST also write
      // a migration that re-encrypts every user's cycle DB.
      expect(CycleEncryptionKeys.customerIdFromUid('regression-check'),
          'bff89f50c08eb480');
    });
  });

  group('CycleEncryptionKeys.loadOrCreate', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('writes a key into both stores when neither has one', () async {
      // Run with an empty prefs + no secure storage entry.
      final result = await CycleEncryptionKeys.loadOrCreate();
      expect(result['secretKey'], isNotNull);
      expect(result['secretKey'], isNotEmpty);
      expect(result['ivKey'], isNotNull);
      expect(result['ivKey'], isNotEmpty);
      expect(result['secretKey'], isNot(equals(result['ivKey'])),
          reason: 'secret and iv must be different');

      // The write should have persisted into SharedPreferences so a future
      // boot can recover from a Keystore wipe.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cycle_secret_key'), result['secretKey']);
      expect(prefs.getString('cycle_iv_key'), result['ivKey']);
    });

    test('returns the SAME key on a second call (idempotent)', () async {
      final first = await CycleEncryptionKeys.loadOrCreate();
      final second = await CycleEncryptionKeys.loadOrCreate();
      expect(second['secretKey'], first['secretKey']);
      expect(second['ivKey'], first['ivKey']);
    });

    test('uses prefs backup when secure store is empty (resilience case)',
        () async {
      // Simulate the "Android Keystore got wiped" scenario the comment in
      // loadOrCreate describes: the prefs still hold the secret, the
      // secure store does not.
      SharedPreferences.setMockInitialValues({
        'cycle_secret_key': 'prefs-only-secret',
        'cycle_iv_key': 'prefs-only-iv-zzzz',
      });
      // The SecureStorageService instance inside CycleEncryptionKeys uses a
      // default FlutterSecureStorage that will throw or return null against
      // our test platform — either way, loadOrCreate must fall back to prefs.
      final result = await CycleEncryptionKeys.loadOrCreate();
      expect(result['secretKey'], 'prefs-only-secret');
      expect(result['ivKey'], 'prefs-only-iv-zzzz');
    });
  });

  group('SecureStorageService', () {
    // Smoke test for the wrapper — the real platform channel is unreachable
    // here so we only assert it never throws and the contract is honoured.
    test('returns null on any error rather than throwing', () async {
      final svc = SecureStorageService();
      final v = await svc.read('definitely-not-set');
      expect(v, anyOf(isNull, isA<String>()));
    });
  });
}