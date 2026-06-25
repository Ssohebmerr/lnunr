import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/media_upload_service.dart';
import 'community_constants.dart';
import 'models/community_story.dart';

class CommunityStoryRepository {
  CommunityStoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _mediaUpload = MediaUploadService();

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> _ensureStoryAllowed(String uid, String communityId) async {
    // Check adult status
    final userDoc = await _firestore.collection('users').doc(uid).get()
        .timeout(const Duration(seconds: 8));
    final birthYear = userDoc.data()?['communityBirthYear'] as int?;
    if (birthYear == null || !isCommunityAdultBirthYear(birthYear)) {
      throw Exception('Adults only');
    }
    // Check membership
    final memberDoc = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(uid)
        .get();
    if (!memberDoc.exists) {
      throw Exception('Join the community first');
    }
  }

  CollectionReference<Map<String, dynamic>> _storiesRef(String communityId) =>
      _firestore
          .collection('communities')
          .doc(communityId)
          .collection('stories');

  /// Watch active (non-expired) stories for a community.
  Stream<List<CommunityStory>> watchCommunityStories(String communityId) {
    final now = Timestamp.fromDate(DateTime.now());
    return _storiesRef(communityId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CommunityStory.fromMap(d.id, d.data()))
              .where((s) => !s.isExpired)
              .toList(),
        );
  }

  /// Watch stories from all communities the user has joined.
  Stream<List<CommunityStory>> watchJoinedStories(List<String> joinedIds) {
    if (joinedIds.isEmpty) return Stream.value(const []);
    final now = Timestamp.fromDate(DateTime.now());

    // Query each community separately to avoid collection-group index issues.
    final streams = joinedIds.map((cid) {
      return _storiesRef(cid)
          .where('expiresAt', isGreaterThan: now)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) {
                  try {
                    return CommunityStory.fromMap(d.id, d.data());
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<CommunityStory>()
                .where((s) => !s.isExpired)
                .toList(),
          );
    }).toList();

    // Merge all community story streams into one.
    return Stream<List<CommunityStory>>.multi((controller) {
      final allStories = <String, List<CommunityStory>>{};
      final subs = <StreamSubscription>[];

      for (var i = 0; i < streams.length; i++) {
        final cid = joinedIds[i];
        final sub = streams[i].listen(
          (stories) {
            allStories[cid] = stories;
            final merged = allStories.values.expand((s) => s).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            controller.add(merged);
          },
          onError: (Object e, StackTrace st) {
            debugPrint('watchJoinedStories($cid): $e');
            // Don't fail the whole stream — just skip this community.
          },
        );
        subs.add(sub);
      }

      controller.onCancel = () {
        for (final s in subs) {
          s.cancel();
        }
      };
    });
  }

  /// Create a new story from a picked image file.
  Future<void> createStory({
    required String communityId,
    required String uid,
    required String alias,
    required XFile file,
    int authorAvatarIndex = 0,
    String? textOverlay,
    String? backgroundColor,
  }) async {
    await _ensureStoryAllowed(uid, communityId);

    final mediaUrl = await _mediaUpload.uploadCommunityPostMedia(
      uid: uid,
      communityId: communityId,
      file: file,
      isVideo: false,
    );

    await _storiesRef(communityId).add({
      'communityId': communityId,
      'authorUid': uid,
      'authorAlias': alias,
      'mediaUrl': mediaUrl,
      'mediaType': 'image',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
      'authorAvatarIndex': authorAvatarIndex,
      if (textOverlay != null) 'textOverlay': textOverlay,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      'viewCount': 0,
    });
  }

  /// Create a text-only story (colored background + text).
  Future<void> createTextStory({
    required String communityId,
    required String uid,
    required String alias,
    required String text,
    required String backgroundColor,
    int authorAvatarIndex = 0,
  }) async {
    await _ensureStoryAllowed(uid, communityId);

    await _storiesRef(communityId).add({
      'communityId': communityId,
      'authorUid': uid,
      'authorAlias': alias,
      'mediaUrl': '',
      'mediaType': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
      'authorAvatarIndex': authorAvatarIndex,
      'textOverlay': text,
      'backgroundColor': backgroundColor,
      'viewCount': 0,
    });
  }

  /// Mark a story as viewed by the current user.
  Future<void> markViewed(String communityId, String storyId) async {
    final uid = currentUid;
    if (uid == null) return;

    final ref = _storiesRef(communityId).doc(storyId);
    try {
      await ref.update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('markViewed error: $e');
    }
  }

  /// Delete own story.
  Future<void> deleteStory(String communityId, String storyId) async {
    final uid = currentUid;
    if (uid == null) return;

    final ref = _storiesRef(communityId).doc(storyId);
    final snap = await ref.get();
    if (snap.data()?['authorUid'] != uid) return;

    await ref.delete();
  }

  /// Clean up expired stories.
  Future<void> cleanupExpired(String communityId) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snap = await _storiesRef(communityId)
        .where('expiresAt', isLessThan: now)
        .limit(50)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class MediaRequiresPremiumException implements Exception {
  const MediaRequiresPremiumException();
  @override
  String toString() => 'Media stories require Premium';
}
