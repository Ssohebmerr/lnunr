import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/cloud_functions_client.dart';

/// Deletes optional cloud data when the user revokes consent (GDPR).
class ConsentDataService {
  ConsentDataService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static final _functions = CloudFunctionsClient.instance;

  Future<void> purgeCloudBackups() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);
    final backups = await userRef.collection('backups').get();
    for (final doc in backups.docs) {
      await doc.reference.delete();
    }
    await userRef.set({
      'lastSyncAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Revokes AI consent server-side. This removes nested chat messages,
  /// long-term memory, and the separate AI usage metadata collection.
  Future<void> purgeAiData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final response = await _functions.post('/purgeAiData', body: const {});
    if (response.statusCode == 200) return;

    String message = 'Failed to purge AI data';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {
      // Use the safe generic message when a proxy returns non-JSON.
    }
    throw StateError(message);
  }

  Future<void> purgeCommunityPresence() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);

    final memberships = await userRef.collection('communityMemberships').get();
    for (final membership in memberships.docs) {
      await _firestore
          .collection('communities')
          .doc(membership.id)
          .collection('members')
          .doc(uid)
          .delete()
          .catchError((_) {});
      await membership.reference.delete();
    }

    await userRef.set({
      'communityAlias': FieldValue.delete(),
      'communityGoal': FieldValue.delete(),
      'communitySetupComplete': false,
      'communityAvatarIndex': FieldValue.delete(),
      'communityPhotoUrl': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
