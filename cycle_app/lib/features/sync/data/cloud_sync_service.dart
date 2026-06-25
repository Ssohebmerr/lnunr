import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/premium/premium_gate.dart';
import '../../../core/security/cycle_encryption_keys.dart';

class CloudSyncService {
  CloudSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<bool> syncBackup() async {
    if (!await PremiumGate.canUseCloudSync()) return false;
    final user = _auth.currentUser;
    final api = MenstrualCycleWidget.instance;
    if (user == null || api == null) return false;

    try {
      final backup = await api.getBackupOfMenstrualCycleData();
      await _firestore.collection('users').doc(user.uid).collection('backups').add({
        'data': backup,
        'syncedAt': FieldValue.serverTimestamp(),
        'version': 1,
      });
      await _firestore.collection('users').doc(user.uid).set({
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreLatest() async {
    if (!await PremiumGate.canUseCloudSync()) return false;
    final user = _auth.currentUser;
    final api = MenstrualCycleWidget.instance;
    if (user == null || api == null) return false;

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .orderBy('syncedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return false;
      final data = snap.docs.first.data()['data'];
      if (data is! Map<String, dynamic>) return false;

      return api.restoreBackupOfMenstrualCycleData(
        backupData: data,
        customerId: CycleEncryptionKeys.customerIdFromUid(user.uid),
      );
    } catch (_) {
      return false;
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
