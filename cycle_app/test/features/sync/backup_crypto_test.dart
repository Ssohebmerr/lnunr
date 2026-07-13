import 'package:cycle_aura/features/sync/data/backup_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupCrypto payload crypto', () {
    final sample = <String, dynamic>{
      'allTableData': {
        'symptoms_logs': [
          {'logDate': '2026-07-13', 'cycleDay': '4'},
        ],
        'periods_logs': ['2026-07-10', '2026-07-11'],
      },
      'cycleLength': 28,
      'periodDuration': 5,
      'backupDate': '2026-07-13',
    };

    test('round-trips a backup map', () {
      final key = BackupCrypto.generateKey();
      final payload = BackupCrypto.encryptPayload(key, sample);

      expect(payload['payload'], isA<String>());
      expect(payload['iv'], isA<String>());
      // Ciphertext must not leak the plaintext.
      expect(payload['payload'], isNot(contains('periods_logs')));

      final decrypted = BackupCrypto.decryptPayload(key, payload);
      expect(decrypted, sample);
    });

    test('every encryption uses a fresh IV', () {
      final key = BackupCrypto.generateKey();
      final a = BackupCrypto.encryptPayload(key, sample);
      final b = BackupCrypto.encryptPayload(key, sample);
      expect(a['iv'], isNot(b['iv']));
      expect(a['payload'], isNot(b['payload']));
    });

    test('wrong key fails instead of returning garbage', () {
      final payload = BackupCrypto.encryptPayload(
        BackupCrypto.generateKey(),
        sample,
      );
      expect(
        () => BackupCrypto.decryptPayload(BackupCrypto.generateKey(), payload),
        throwsA(anything),
      );
    });

    test('missing fields are rejected', () {
      final key = BackupCrypto.generateKey();
      expect(
        () => BackupCrypto.decryptPayload(key, {'payload': 'abc'}),
        throwsFormatException,
      );
      expect(
        () => BackupCrypto.decryptPayload(key, {'iv': 'abc'}),
        throwsFormatException,
      );
    });

    test('generateKey produces distinct 32-byte base64 keys', () {
      final a = BackupCrypto.generateKey();
      final b = BackupCrypto.generateKey();
      expect(a, isNot(b));
      // 32 bytes → 44 base64 chars with padding.
      expect(a.length, 44);
    });
  });
}
