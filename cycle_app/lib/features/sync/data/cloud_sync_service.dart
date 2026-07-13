import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/premium/premium_gate.dart';
import 'backup_crypto.dart';

enum CloudBackupResult {
  success,
  needsPremium,
  needsConsent,
  notSignedIn,
  cycleStoreUnavailable,
  noBackupFound,
  failed,
}

class CloudSyncService {
  CloudSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    BackupCrypto? backupCrypto,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _crypto = backupCrypto ?? BackupCrypto();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final BackupCrypto _crypto;

  Future<CloudBackupResult> syncBackup() async {
    if (!await PremiumGate.hasPremium()) {
      return CloudBackupResult.needsPremium;
    }
    if (!await PremiumGate.canUseCloudSync()) {
      return CloudBackupResult.needsConsent;
    }
    final user = _auth.currentUser;
    final api = MenstrualCycleWidget.instance;
    if (user == null) return CloudBackupResult.notSignedIn;
    if (api == null) return CloudBackupResult.cycleStoreUnavailable;

    try {
      // Version 2 (portable): export decrypted, then encrypt with the
      // account-scoped backup key so the backup survives a device change.
      // Version 1 (legacy fallback when the key can't be escrowed): payload
      // encrypted with the device keystore key — same-device restore only.
      final keyB64 = await _crypto.loadOrCreateKey(user.uid);
      final Map<String, dynamic> docData;
      if (keyB64 != null) {
        final plain = await api.getBackupOfMenstrualCycleData(
          isEncryptData: false,
        );
        docData = {
          ...BackupCrypto.encryptPayload(keyB64, plain),
          'version': 2,
        };
      } else {
        final legacy = await api.getBackupOfMenstrualCycleData(
          isEncryptData: true,
        );
        docData = {'data': legacy, 'version': 1};
      }

      final backups =
          _firestore.collection('users').doc(user.uid).collection('backups');
      await backups.add({
        ...docData,
        'syncedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(user.uid).set({
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Keep only the most recent backups so the collection can't grow forever.
      await _pruneOldBackups(backups);
      return CloudBackupResult.success;
    } catch (_) {
      return CloudBackupResult.failed;
    }
  }

  /// Deletes all but the most recent [keep] backups for a user. Best-effort:
  /// failures here never fail the sync itself.
  Future<void> _pruneOldBackups(
    CollectionReference<Map<String, dynamic>> backups, {
    int keep = 5,
  }) async {
    try {
      final all = await backups.orderBy('syncedAt', descending: true).get();
      if (all.docs.length <= keep) return;
      for (final doc in all.docs.skip(keep)) {
        await doc.reference.delete();
      }
    } catch (_) {
      // Pruning is non-critical; ignore errors.
    }
  }

  Future<CloudBackupResult> restoreLatest() async {
    if (!await PremiumGate.hasPremium()) {
      return CloudBackupResult.needsPremium;
    }
    if (!await PremiumGate.canUseCloudSync()) {
      return CloudBackupResult.needsConsent;
    }
    final user = _auth.currentUser;
    final api = MenstrualCycleWidget.instance;
    if (user == null) return CloudBackupResult.notSignedIn;
    if (api == null) return CloudBackupResult.cycleStoreUnavailable;

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .orderBy('syncedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return CloudBackupResult.noBackupFound;
      final doc = snap.docs.first.data();

      final bool restored;
      if (doc['payload'] != null) {
        // Version 2: decrypt with the account backup key (fetched from the
        // Firestore escrow when this device has never seen it), then hand
        // the plaintext to the store, which re-encrypts with THIS device's
        // key. This is the path that survives device loss/reinstall.
        final keyB64 = await _crypto.loadKey(user.uid);
        if (keyB64 == null) return CloudBackupResult.failed;
        final plain = BackupCrypto.decryptPayload(keyB64, doc);
        restored = await api.restoreBackupOfMenstrualCycleData(
          isDecryptData: false,
          backupData: plain,
          // Must be the *store* id (getCustomerId() = encrypted). Passing
          // the plaintext id used to file restored rows under a partition no
          // query reads, and poisoned the config row so data vanished on
          // relaunch.
          customerId: api.getCustomerId(),
        );
      } else {
        // Version 1 legacy: payload encrypted with the ORIGINAL device's
        // keystore key — only decryptable on that device.
        final raw = doc['data'];
        // Firestore may hand nested maps back as Map<Object?, Object?>.
        if (raw is! Map) return CloudBackupResult.failed;
        restored = await api.restoreBackupOfMenstrualCycleData(
          backupData: Map<String, dynamic>.from(raw),
          customerId: api.getCustomerId(),
        );
      }
      return restored ? CloudBackupResult.success : CloudBackupResult.failed;
    } catch (_) {
      return CloudBackupResult.failed;
    }
  }

  Stream<bool> watchPremiumStatus(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      return doc.data()?['isPremium'] as bool? ?? false;
    });
  }

  Future<bool> fetchPremiumStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['isPremium'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
