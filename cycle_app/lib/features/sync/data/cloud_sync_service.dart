import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/premium/premium_gate.dart';
import '../../../core/security/cycle_encryption_keys.dart';

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
  CloudSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
      final backup = await api.getBackupOfMenstrualCycleData(
        isEncryptData: true,
      );
      final backups =
          _firestore.collection('users').doc(user.uid).collection('backups');
      await backups.add({
        'data': backup,
        'syncedAt': FieldValue.serverTimestamp(),
        'version': 1,
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
      final data = snap.docs.first.data()['data'];
      if (data is! Map<String, dynamic>) return CloudBackupResult.failed;

      final restored = await api.restoreBackupOfMenstrualCycleData(
        backupData: data,
        customerId: CycleEncryptionKeys.localCustomerId,
      );
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
