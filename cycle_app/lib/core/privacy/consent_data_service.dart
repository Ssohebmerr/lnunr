import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Deletes optional cloud data when the user revokes consent (GDPR).
class ConsentDataService {
  ConsentDataService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  Future<void> purgeAiChats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);
    final chats = await userRef.collection('chats').get();
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('messages').get();
      for (final message in messages.docs) {
        await message.reference.delete();
      }
      await chat.reference.delete();
    }
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
