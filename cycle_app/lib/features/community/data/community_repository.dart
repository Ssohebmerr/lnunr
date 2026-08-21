import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../../core/age/age_gate.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/security/community_text_sanitize.dart';
import '../../../core/ai/firebase_ai_service.dart';
import '../../../core/ai/direct_gemini_service.dart';
import '../../../core/firebase/cloud_functions_client.dart';
import '../../../core/storage/user_prefs.dart';
import 'community_catalog_repository.dart';
import 'community_list_resolver.dart';
import 'community_seed.dart';
import 'community_sort.dart';
import 'models/community.dart';
import 'models/community_comment.dart';
import 'models/community_membership.dart';
import 'models/community_post.dart';
import 'models/community_profile.dart';
import 'models/post_reactions.dart';
import 'models/post_type.dart';
import 'models/community_inbox_item.dart';
import 'models/blocked_user.dart';
import 'models/followed_user.dart';
import 'moderation_result.dart';

class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseAiService? firebaseAi,
    DirectGeminiService? directGemini,
    CommunityCatalogRepository? catalog,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firebaseAi = firebaseAi ?? FirebaseAiService(),
       _directGemini = directGemini ?? DirectGeminiService(),
       _catalog = catalog ?? CommunityCatalogRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseAiService _firebaseAi;
  final DirectGeminiService _directGemini;
  final CommunityCatalogRepository _catalog;

  final CloudFunctionsClient _functions = CloudFunctionsClient.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Throws [MinorRestrictedException] when the user cannot access community UGC.
  Future<void> _ensureAdult(String uid) async {
    if (await blocksCommunityByAgeGate()) {
      throw const MinorRestrictedException();
    }
    final profile = await fetchProfile(uid);
    if (!profile.isReady || profile.isMinor) {
      throw const MinorRestrictedException();
    }
  }

  Future<void> _ensureCanParticipate(String uid) async {
    await _ensureAdult(uid);
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.data()?['communityBanned'] == true) {
      throw const CommunityBannedException();
    }
  }

  Community _mergeSeed(Community seed, CommunityCatalogEntry? entry) =>
      CommunityListResolver.mergeSeed(seed, entry);

  Future<List<Community>> _resolvedCommunities({
    String languageCode = 'en',
    UserGoalTypes? goal,
    List<String> joinedIds = const [],
    CommunitySortMode mode = CommunitySortMode.defaultOrder,
  }) async {
    final catalog = await _catalog.fetchAll();
    final results = CommunityListResolver.activeOnly(catalog: catalog);
    return sortCommunities(
      communities: results,
      catalog: catalog,
      languageCode: languageCode,
      goal: goal,
      joinedIds: joinedIds,
      mode: mode,
    );
  }

  Future<Map<String, CommunityCatalogEntry>> fetchCommunityCatalog() =>
      _catalog.fetchAll();

  Future<Community?> resolveCommunity(String id) async {
    final catalog = await _catalog.fetchAll();
    final entry = catalog[id];
    if (entry != null && !entry.enabled) return null;
    final seed = CommunitySeed.byId(id);
    if (seed != null) return _mergeSeed(seed, entry);
    if (entry == null) return null;
    return CommunityListResolver.fromCatalogOnly(entry);
  }

  CollectionReference<Map<String, dynamic>> _membersRef(String communityId) =>
      _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members');

  CollectionReference<Map<String, dynamic>> _postsRef(String communityId) =>
      _firestore.collection('communities').doc(communityId).collection('posts');

  CollectionReference<Map<String, dynamic>> _commentsRef(
    String communityId,
    String postId,
  ) => _postsRef(communityId).doc(postId).collection('comments');

  DocumentReference<Map<String, dynamic>> _privateAuthPostRef(
    String communityId,
    String postId,
  ) => _firestore
      .collection('communityPrivateAuth')
      .doc(communityId)
      .collection('posts')
      .doc(postId);

  Future<bool> _userOwnsPost(
    Map<String, dynamic>? data,
    String communityId,
    String postId,
    String uid,
  ) async {
    if (data == null) return false;
    final authorUid = data['authorUid'] as String?;
    if (authorUid != null && authorUid == uid) return true;
    if (data['isAnonymous'] == true) {
      final snap = await _privateAuthPostRef(communityId, postId).get();
      return snap.data()?['authorUid'] == uid;
    }
    return false;
  }

  Future<bool> _postVisibleToViewer(
    CommunityPost post,
    String? viewerUid,
  ) async {
    if (!post.isPendingReview || !post.isAnonymous) {
      return post.isVisibleTo(viewerUid);
    }
    final owned =
        viewerUid != null &&
        await _userOwnsPost(
          {'isAnonymous': true},
          post.communityId,
          post.id,
          viewerUid,
        );
    return post.isVisibleTo(viewerUid, ownedByViewer: owned);
  }

  Future<List<CommunityPost>> _filterVisiblePosts(
    Iterable<CommunityPost> posts,
    String? viewerUid,
  ) async {
    final out = <CommunityPost>[];
    for (final post in posts) {
      if (await _postVisibleToViewer(post, viewerUid)) out.add(post);
    }
    return out;
  }

  Future<CommunityProfile> getProfile(String uid) async {
    final profile = await fetchProfile(uid);
    if (profile.alias.isEmpty &&
        profile.birthYear == null &&
        !profile.setupComplete) {
      throw StateError('Community profile not found for $uid');
    }
    return profile;
  }

  /// Read-only community profile from Firestore (no auto-fill or writes).
  Future<CommunityProfile> fetchProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return CommunityProfile.fromMap(doc.data());
    } catch (e, st) {
      debugPrint('CommunityRepository.fetchProfile failed: $e\n$st');
      return const CommunityProfile(alias: '');
    }
  }

  String _normalizedAlias(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .replaceAll('@', '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Returns the stored profile, or an in-memory draft with a suggested alias.
  /// Never writes [communityBirthYear] — the user must confirm via setup sheet.
  Future<CommunityProfile> resolveProfile(String uid) async {
    CommunityProfile profile;
    Map<String, dynamic>? userData;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      userData = doc.data();
      profile = CommunityProfile.fromMap(userData);
    } catch (e, st) {
      debugPrint('CommunityRepository.resolveProfile read failed: $e\n$st');
      profile = const CommunityProfile(alias: '');
    }

    if (profile.isReady) return profile;

    final localName = (await UserPrefs.getProfileName())?.trim() ?? '';
    final remoteName = (userData?['name'] as String?)?.trim() ?? '';
    final authName = _auth.currentUser?.displayName?.trim() ?? '';
    final email = _auth.currentUser?.email ?? '';
    final emailPrefix = email.contains('@') ? email.split('@').first : '';

    String alias = profile.alias.trim().length >= 2
        ? profile.alias.trim()
        : _normalizedAlias(
            localName.isNotEmpty
                ? localName
                : (remoteName.isNotEmpty
                      ? remoteName
                      : (authName.isNotEmpty ? authName : emailPrefix)),
          );
    if (alias.length < 2) alias = 'User_${uid.substring(0, 4)}';

    return CommunityProfile(
      alias: alias,
      birthYear: profile.birthYear,
      goal: profile.goal ?? await UserPrefs.getProfileGoal(),
      setupComplete: profile.setupComplete && profile.birthYear != null,
      avatarIndex: profile.avatarIndex,
      photoUrl: profile.photoUrl,
    );
  }

  Future<void> saveProfile(String uid, CommunityProfile profile) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(profile.toMap(), SetOptions(merge: true));
    // Recompute server-side AI age group from write-once birth year.
    if (profile.birthYear != null) {
      await ConsentManager.syncAiEligibility();
    }
  }

  /// [fetchCounts] — skip remote member counts when the user cannot read
  /// `communities/*/members` yet (no adult profile). Avoids slow sequential
  /// Firestore calls that used to time out the whole tab (cloud-off screen).
  Future<List<Community>> fetchCommunitiesWithCounts({
    bool fetchCounts = true,
    String languageCode = 'en',
    UserGoalTypes? goal,
    List<String> joinedIds = const [],
  }) async {
    try {
      final communities = await _resolvedCommunities(
        languageCode: languageCode,
        goal: goal,
        joinedIds: joinedIds,
      );
      if (!fetchCounts) return communities;

      return Future.wait(
        communities.map((community) async {
          try {
            final countSnap = await _membersRef(
              community.id,
            ).count().get().timeout(const Duration(seconds: 3));
            return community.copyWith(memberCount: countSnap.count ?? 0);
          } catch (e) {
            debugPrint('member count skipped for ${community.id}: $e');
            return community;
          }
        }),
      );
    } catch (e, st) {
      debugPrint(
        'CommunityRepository.fetchCommunitiesWithCounts failed: $e\n$st',
      );
      try {
        return await _resolvedCommunities(
          languageCode: languageCode,
          goal: goal,
        );
      } catch (_) {
        return CommunitySeed.defaults;
      }
    }
  }

  Future<bool> isMember(String uid, String communityId) async {
    final doc = await _membersRef(communityId).doc(uid).get();
    return doc.exists;
  }

  Future<int> fetchMemberCount(String communityId) async {
    try {
      final countSnap = await _membersRef(
        communityId,
      ).count().get().timeout(const Duration(seconds: 5));
      return countSnap.count ?? 0;
    } catch (e) {
      debugPrint('fetchMemberCount failed for $communityId: $e');
      return 0;
    }
  }

  Stream<List<CommunityMembership>> watchJoinedMemberships(
    String uid,
  ) => _firestore
      .collection('users')
      .doc(uid)
      .collection('communityMemberships')
      .snapshots()
      .map((snapshot) {
        final memberships = snapshot.docs.map((doc) {
          final joinedAt = doc.data()['joinedAt'];
          DateTime? date;
          if (joinedAt is Timestamp) {
            date = joinedAt.toDate();
          }
          return CommunityMembership(communityId: doc.id, joinedAt: date);
        }).toList();
        memberships.sort((a, b) {
          final aTime = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return memberships;
      });

  Stream<List<String>> watchJoinedCommunityIds(String uid) =>
      watchJoinedMemberships(
        uid,
      ).map((m) => m.map((e) => e.communityId).toList());

  Future<void> joinCommunity({
    required String uid,
    required String communityId,
    required String alias,
  }) async {
    await _ensureCanParticipate(uid);
    final community = await resolveCommunity(communityId);
    if (community == null) throw StateError('Unknown community');

    final countSnap = await _membersRef(communityId).count().get();
    if ((countSnap.count ?? 0) >= community.maxMembers) {
      throw const CommunityFullException();
    }

    final batch = _firestore.batch();
    batch.set(_membersRef(communityId).doc(uid), {
      'alias': alias,
      'joinedAt': FieldValue.serverTimestamp(),
      // Auditable proof that this membership was created through the
      // guidelines acceptance flow required for user-generated content.
      'guidelinesVersion': 1,
      'guidelinesAcceptedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('communityMemberships')
          .doc(communityId),
      {'joinedAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> leaveCommunity(String uid, String communityId) async {
    final batch = _firestore.batch();
    batch.delete(_membersRef(communityId).doc(uid));
    batch.delete(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('communityMemberships')
          .doc(communityId),
    );
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _likesRef(
    String communityId,
    String postId,
  ) => _postsRef(communityId).doc(postId).collection('likes');

  /// Merged feed from all joined communities.
  /// Maximum number of communities to subscribe to simultaneously.
  static const _maxConcurrentCommunities = 12;

  /// The home feed only needs a recent slice from each joined community.
  /// Community detail screens still keep their full 50-post live window.
  /// This caps a 12-community feed at 144 live documents instead of 600,
  /// which materially reduces first-paint time and Firestore listener work.
  static const _feedPostsPerCommunity = 12;

  Stream<List<CommunityPost>> watchJoinedFeed(List<String> joinedIds) {
    if (joinedIds.isEmpty) return Stream.value(const []);

    final controller = StreamController<List<CommunityPost>>.broadcast();
    final cache = <String, CommunityPost>{};
    final subs = <StreamSubscription<List<CommunityPost>>>[];

    void publish() {
      final list = cache.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(list.take(50).toList());
    }

    // Limit concurrent subscriptions to avoid excessive Firestore listeners.
    final limitedIds = joinedIds.take(_maxConcurrentCommunities).toList();

    for (final communityId in limitedIds) {
      subs.add(
        watchPosts(communityId, limit: _feedPostsPerCommunity).listen(
          (posts) {
            cache.removeWhere((k, _) => k.startsWith('$communityId|'));
            for (final p in posts) {
              cache['$communityId|${p.id}'] = p;
            }
            publish();
          },
          onError: (e, st) {
            debugPrint(
              'CommunityRepository.watchJoinedFeed stream error: $e\n$st',
            );
            publish();
          },
        ),
      );
    }

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  // ---------------------------------------------------------------------
  // Polls
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _pollVotesRef(
    String communityId,
    String postId,
  ) => _postsRef(communityId).doc(postId).collection('pollVotes');

  /// Live poll results: vote count per option index + the viewer's own vote.
  Stream<PollResults> watchPollResults(
    String communityId,
    String postId,
    String? viewerUid,
  ) => _pollVotesRef(communityId, postId).snapshots().map((snap) {
    final counts = <int, int>{};
    int? myVote;
    for (final doc in snap.docs) {
      final option = doc.data()['option'] as int? ?? -1;
      if (option < 0) continue;
      counts[option] = (counts[option] ?? 0) + 1;
      if (doc.id == viewerUid) myVote = option;
    }
    return PollResults(
      counts: counts,
      totalVotes: snap.docs.length,
      myVote: myVote,
    );
  });

  /// Casts (or changes) the member's vote — one doc per uid so re-voting
  /// simply overwrites the previous choice.
  Future<void> votePoll({
    required String communityId,
    required String postId,
    required String uid,
    required int optionIndex,
  }) async {
    await _pollVotesRef(communityId, postId).doc(uid).set({
      'option': optionIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchLikeCount(String communityId, String postId) =>
      _likesRef(communityId, postId).snapshots().map((s) => s.docs.length);

  Stream<bool> watchUserLiked(String communityId, String postId, String uid) =>
      _likesRef(communityId, postId).doc(uid).snapshots().map((s) => s.exists);

  Future<void> toggleLike({
    required String communityId,
    required String postId,
    required String uid,
  }) async {
    final ref = _likesRef(communityId, postId).doc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // ---------------------------------------------------------------------
  // Reactions (stored on the like docs — legacy docs count as 'heart')
  // ---------------------------------------------------------------------

  static const postReactionKinds = ['heart', 'hug', 'celebrate', 'strong'];

  /// One listener per card: total, per-reaction breakdown, and my reaction.
  /// Replaces the old watchLikeCount + watchUserLiked pair.
  Stream<PostReactions> watchPostReactions(
    String communityId,
    String postId,
    String? viewerUid,
  ) => _likesRef(communityId, postId).snapshots().map((s) {
    final counts = <String, int>{};
    String? mine;
    for (final doc in s.docs) {
      final reaction = (doc.data()['reaction'] as String?) ?? 'heart';
      counts[reaction] = (counts[reaction] ?? 0) + 1;
      if (doc.id == viewerUid) mine = reaction;
    }
    return PostReactions(
      total: s.docs.length,
      counts: counts,
      myReaction: mine,
    );
  });

  /// Tapping the same reaction removes it; anything else sets/overwrites it.
  Future<void> setPostReaction({
    required String communityId,
    required String postId,
    required String uid,
    required String reaction,
    required String? currentReaction,
    required bool currentReactionLoaded,
  }) async {
    final ref = _likesRef(communityId, postId).doc(uid);
    final String? current;
    if (currentReactionLoaded) {
      current = currentReaction;
    } else {
      final snap = await ref.get();
      current = snap.exists
          ? ((snap.data()?['reaction'] as String?) ?? 'heart')
          : null;
    }
    if (current == reaction) {
      await ref.delete();
      return;
    }
    await ref.set({
      'reaction': reaction,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Comment likes
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _commentLikesRef(
    String communityId,
    String postId,
    String commentId,
  ) => _commentsRef(communityId, postId).doc(commentId).collection('likes');

  Stream<({int count, bool liked})> watchCommentLikes(
    String communityId,
    String postId,
    String commentId,
    String? viewerUid,
  ) => _commentLikesRef(communityId, postId, commentId).snapshots().map(
    (s) => (
      count: s.docs.length,
      liked: viewerUid != null && s.docs.any((d) => d.id == viewerUid),
    ),
  );

  /// Like totals for a batch of comments (aggregate count queries), used by
  /// the "most liked" comment sort.
  Future<Map<String, int>> fetchCommentLikeCounts(
    String communityId,
    String postId,
    List<String> commentIds,
  ) async {
    final entries = await Future.wait(
      commentIds.map((id) async {
        final agg = await _commentLikesRef(
          communityId,
          postId,
          id,
        ).count().get();
        return MapEntry(id, agg.count ?? 0);
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<void> toggleCommentLike({
    required String communityId,
    required String postId,
    required String commentId,
    required String uid,
    bool? currentlyLiked,
  }) async {
    final ref = _commentLikesRef(communityId, postId, commentId).doc(uid);
    final liked = currentlyLiked ?? (await ref.get()).exists;
    if (liked) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  /// Recent public (non-anonymous) posts by one member in a community, for
  /// the member profile sheet. Sorted client-side so the single-field
  /// `authorUid` filter needs no composite index.
  Future<List<CommunityPost>> fetchMemberPosts(
    String communityId,
    String authorUid, {
    int limit = 30,
  }) async {
    final snap = await _postsRef(
      communityId,
    ).where('authorUid', isEqualTo: authorUid).limit(limit).get();
    final viewerUid = _auth.currentUser?.uid;
    return snap.docs
        .map((d) => CommunityPost.fromMap(d.id, d.data()))
        .where((p) => !p.isAnonymous && p.isVisibleTo(viewerUid))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> reportPost({
    required String communityId,
    required String postId,
    required String reporterUid,
    required String reason,
    required String authorUid,
    required String authorAlias,
    String? commentId,
  }) async {
    await _firestore.collection('communityReports').add({
      'communityId': communityId,
      'postId': postId,
      'commentId': commentId,
      'reporterUid': reporterUid,
      'authorUid': authorUid,
      'authorAlias': authorAlias,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Blocking
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('blockedUsers');

  Future<void> blockUser({
    required String uid,
    required String blockedUid,
    String? authorAlias,
  }) async {
    if (uid == blockedUid) return;
    await _blockedRef(uid).doc(blockedUid).set({
      'createdAt': FieldValue.serverTimestamp(),
      if (authorAlias != null && authorAlias.isNotEmpty)
        'authorAlias': authorAlias,
    });
  }

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) async {
    await _blockedRef(uid).doc(blockedUid).delete();
  }

  Stream<Set<String>> watchBlockedUids(String uid) =>
      _blockedRef(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Stream<List<BlockedUser>> watchBlockedUsers(String uid) => _blockedRef(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => BlockedUser.fromDoc(d.id, d.data())).toList(),
      );

  // ── Following ────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _followingRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('following');

  Future<void> followUser({
    required String uid,
    required String followedUid,
    String? alias,
    int avatarIndex = 0,
  }) async {
    if (uid == followedUid) return;
    await _followingRef(uid).doc(followedUid).set({
      'createdAt': FieldValue.serverTimestamp(),
      'avatarIndex': avatarIndex,
      if (alias != null && alias.isNotEmpty) 'alias': alias,
    });
  }

  Future<void> unfollowUser({
    required String uid,
    required String followedUid,
  }) async {
    await _followingRef(uid).doc(followedUid).delete();
  }

  Stream<bool> watchIsFollowing(String uid, String otherUid) =>
      _followingRef(uid).doc(otherUid).snapshots().map((d) => d.exists);

  Stream<Set<String>> watchFollowingUids(String uid) => _followingRef(
    uid,
  ).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Stream<List<FollowedUser>> watchFollowing(String uid) => _followingRef(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => FollowedUser.fromDoc(d.id, d.data())).toList(),
      );

  /// Ids of posts the user has commented on, for the "my comments" feed
  /// filter. Collection-group query constrained to the user's own comments
  /// (rules require the authorUid filter); post id = comment's grandparent.
  Stream<Set<String>> watchMyCommentedPostIds(String uid) => _firestore
      .collectionGroup('comments')
      .where('authorUid', isEqualTo: uid)
      .limit(500)
      .snapshots()
      .map(
        (s) => {
          for (final d in s.docs)
            if (d.reference.parent.parent != null)
              d.reference.parent.parent!.id,
        },
      );

  Stream<List<CommunityPost>> watchPosts(String communityId, {int limit = 50}) {
    final viewerUid = _auth.currentUser?.uid;
    return _postsRef(communityId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((s) async {
          final posts = s.docs
              .map((d) => CommunityPost.fromMap(d.id, d.data()))
              .toList();
          return _filterVisiblePosts(posts, viewerUid);
        });
  }

  /// Fetch a single page of posts for infinite scroll.
  /// Pass [lastDocument] from the previous page to get the next batch.
  static const int postsPerPage = 20;

  Future<List<CommunityPost>> fetchPostsPage(
    String communityId, {
    DocumentSnapshot? lastDocument,
  }) async {
    final viewerUid = _auth.currentUser?.uid;
    var query = _postsRef(
      communityId,
    ).orderBy('createdAt', descending: true).limit(postsPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snap = await query.get();
    final posts = snap.docs
        .map((d) => CommunityPost.fromMap(d.id, d.data()))
        .toList();
    return _filterVisiblePosts(posts, viewerUid);
  }

  /// Returns the last DocumentSnapshot from the most recent page fetch,
  /// used as cursor for the next page.
  Future<DocumentSnapshot?> fetchPostsPageRaw(
    String communityId, {
    DocumentSnapshot? lastDocument,
  }) async {
    var query = _postsRef(
      communityId,
    ).orderBy('createdAt', descending: true).limit(postsPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snap = await query.get();
    return snap.docs.isNotEmpty ? snap.docs.last : null;
  }

  Future<CommunityPost?> _postFromSnapshotAsync(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    String? viewerUid,
  }) async {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final post = CommunityPost.fromMap(snap.id, data);
    if (!await _postVisibleToViewer(post, viewerUid)) return null;
    return post;
  }

  Stream<CommunityPost?> watchPost(String communityId, String postId) {
    final viewerUid = _auth.currentUser?.uid;
    return _postsRef(communityId)
        .doc(postId)
        .snapshots()
        .asyncMap((snap) => _postFromSnapshotAsync(snap, viewerUid: viewerUid));
  }

  Future<CommunityPost?> getPost(String communityId, String postId) async {
    final snap = await _postsRef(communityId).doc(postId).get();
    return _postFromSnapshotAsync(snap, viewerUid: _auth.currentUser?.uid);
  }

  Stream<List<CommunityComment>> watchComments(
    String communityId,
    String postId,
  ) {
    final viewerUid = _auth.currentUser?.uid;
    return _commentsRef(communityId, postId)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => CommunityComment.fromMap(d.id, d.data()))
              .where((c) => c.isVisibleTo(viewerUid))
              .toList(),
        );
  }

  bool _isModerationUnavailable(String? reason) {
    if (reason == null) return true;
    final lower = reason.toLowerCase();
    return lower.contains('unavailable') ||
        lower.contains('try again later') ||
        lower.contains('غير متاح');
  }

  Future<ModerationResult> moderateText(String text) async {
    final clean = text.length <= CommunityTextSanitize.maxCommentLength
        ? CommunityTextSanitize.comment(text)
        : CommunityTextSanitize.post(text);
    final local = _fallbackModeration(clean);
    if (!local.approved) return local;

    if (kDebugMode) {
      // 1. Try Direct Gemini API (Google AI Studio key — free)
      final direct = await _directGemini.moderateContent(text: clean);
      if (direct != null) {
        if (direct.approved) return direct;
        if (_isModerationUnavailable(direct.reason)) {
          return const ModerationResult(
            approved: false,
            pendingReview: true,
            reason: 'Content pending AI review.',
          );
        }
        return direct;
      }

      // 2. Try Firebase AI Logic (direct, secure, no server)
      final firebaseAi = await _firebaseAi.moderateContent(text: clean);
      if (firebaseAi != null) {
        if (firebaseAi.approved) return firebaseAi;
        if (_isModerationUnavailable(firebaseAi.reason)) {
          return const ModerationResult(
            approved: false,
            pendingReview: true,
            reason: 'Content pending AI review.',
          );
        }
        return firebaseAi;
      }
    }

    // Release: Cloud Function only (keys in Firebase Secrets).
    final cloud = await _moderateViaCloud(clean);
    if (cloud != null) {
      if (cloud.approved) return cloud;
      if (_isModerationUnavailable(cloud.reason)) {
        return const ModerationResult(
          approved: false,
          pendingReview: true,
          reason: 'Content pending AI review.',
        );
      }
      return cloud;
    }

    // All AI services unavailable — block until reviewed.
    return const ModerationResult(
      approved: false,
      pendingReview: true,
      reason: 'Content pending AI review.',
    );
  }

  /// Local safety net used when both cloud and local Gemini are unavailable.
  /// Focuses on protecting users (especially minors) from contact harvesting,
  /// external links, and harmful content.
  /// Sends the final community write through the trusted Cloud Function.
  /// The client keeps local validation for fast feedback, but it cannot bypass
  /// quotas, duplicate detection, identity fields, or the media paywall.
  Future<Map<String, dynamic>> _submitCommunity(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final response = await _functions.post(
      '/submitCommunity',
      body: {'action': action, ...payload},
      timeout: const Duration(seconds: 32),
    );

    Map<String, dynamic> body = const {};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (response.statusCode == 200) return body;

    final code = body['error'] as String? ?? '';
    final message = body['message'] as String? ?? 'Could not publish now.';
    if (code == 'community_minor') throw const MinorRestrictedException();
    if (code == 'community_banned') throw const CommunityBannedException();
    if (code == 'media_premium_required') {
      throw const MediaRequiresPremiumException();
    }
    if (code == 'media_review_unavailable') {
      throw const MediaReviewUnavailableException();
    }
    if (code == 'rate_limited' || code == 'duplicate_content') {
      throw ModerationRejectedException(message);
    }
    if (code == 'content_rejected') {
      throw ModerationRejectedException(message);
    }
    throw StateError(message);
  }

  // ---------------------------------------------------------------------------
  // Moderation
  // ---------------------------------------------------------------------------

  ModerationResult _fallbackModeration(String text) {
    final lower = text.toLowerCase();

    const blocked = [
      // Self-harm / dangerous
      'kill yourself', 'suicide', 'انتحار', 'اقتلي نفسك',
      // Commerce / spam
      'buy pills', 'للبيع', 'اشتري من',
      // External contact / social handles (grooming vector)
      'whatsapp', 'whats app', 'واتساب', 'واتس اب',
      'telegram', 'تيليجرام', 'تلغرام', 'تلجرام',
      'snapchat', 'سناب',
      'instagram', 'انستا', 'إنستا', 'انستغرام',
      'tiktok', 'تيك توك',
      'discord', 'ديسكورد',
      // Links
      'http://', 'https://', 'www.', '.com/', 'bit.ly',
    ];
    for (final word in blocked) {
      if (lower.contains(word)) {
        return const ModerationResult(
          approved: false,
          reason: 'Content may be unsafe, promotional, or shares contact info.',
        );
      }
    }

    // Phone numbers — match real phone shapes only. The old "7+ consecutive
    // digits" rule caught innocent year lists like "2024 و 2025 و 2026"
    // (concatenated to 12 digits), so we now require a phone-like prefix:
    //   • +<10+ digits>   — international
    //   • 0[5-7]\d{8}     — local mobile (GCC-style)
    //   • \d{3}-\d{3}-\d{4} — US-style dashed
    final phonePattern = RegExp(
      r'\+\d{10,}'
      r'|(?<!\d)0[5-7]\d{8}'
      r'|\b\d{3}[- ]\d{3}[- ]\d{4}\b',
    );
    if (phonePattern.hasMatch(text)) {
      return const ModerationResult(
        approved: false,
        reason: 'Sharing phone numbers is not allowed.',
      );
    }

    // Email addresses — require a TLD with at least 2 chars so we don't
    // false-positive on stray "@" in conversational text.
    if (RegExp(r'[\w.+-]+@[\w-]+\.[A-Za-z]{2,}').hasMatch(text)) {
      return const ModerationResult(
        approved: false,
        reason: 'Sharing email addresses is not allowed.',
      );
    }

    if (text.trim().length < 3) {
      return const ModerationResult(
        approved: false,
        reason: 'Post is too short.',
      );
    }
    return const ModerationResult(approved: true);
  }

  Future<ModerationResult?> _moderateViaCloud(String text) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _functions.post('/moderate', body: {'text': text});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ModerationResult(
          approved: data['approved'] as bool? ?? false,
          reason: data['reason'] as String?,
        );
      }
    } catch (e, st) {
      debugPrint('CommunityRepository._moderateViaCloud failed: $e\n$st');
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _savedPostsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedPosts');

  static String savedPostDocId(String communityId, String postId) =>
      '${communityId}_$postId';

  Stream<bool> watchPostSaved(String uid, String communityId, String postId) =>
      _savedPostsRef(uid)
          .doc(savedPostDocId(communityId, postId))
          .snapshots()
          .map((s) => s.exists);

  /// One listener for the whole feed instead of one saved-doc listener per
  /// visible post card.
  Stream<Set<String>> watchSavedPostIds(String uid) => _savedPostsRef(
    uid,
  ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  Future<bool> toggleSavePost(
    String uid,
    CommunityPost post, {
    bool? currentlySaved,
  }) async {
    final id = savedPostDocId(post.communityId, post.id);
    final ref = _savedPostsRef(uid).doc(id);
    final saved = currentlySaved ?? (await ref.get()).exists;
    if (saved) {
      await ref.delete();
      return false;
    }
    await ref.set({
      'communityId': post.communityId,
      'postId': post.id,
      'savedAt': FieldValue.serverTimestamp(),
      if (post.communityName != null) 'communityName': post.communityName,
      // For anonymous posts we deliberately drop the real `authorUid` from
      // the saved doc — otherwise the saved-posts collection would quietly
      // re-identify the author, defeating the anonymity promise to the user.
      'authorAlias': post.authorAlias,
      'textPreview': post.text.length > 120
          ? '${post.text.substring(0, 120)}…'
          : post.text,
      'postType': post.postType.value,
      'authorAvatarIndex': post.authorAvatarIndex,
      if (!post.isAnonymous) 'authorUid': post.authorUid,
    });
    return true;
  }

  Stream<List<CommunityPost>> watchSavedPosts(
    String uid, {
    Set<String> blockedUids = const {},
  }) => _savedPostsRef(uid)
      .orderBy('savedAt', descending: true)
      .limit(50)
      .snapshots()
      .asyncMap((snap) async {
        if (snap.docs.isEmpty) return const <CommunityPost>[];

        // Parallel fetch all saved post references instead of sequential N+1.
        final futures = snap.docs.map((doc) async {
          final data = doc.data();
          final communityId = data['communityId'] as String?;
          final postId = data['postId'] as String?;
          if (communityId == null || postId == null) return null;
          try {
            final postDoc = await _postsRef(communityId).doc(postId).get();
            if (!postDoc.exists) return null;
            final postData = postDoc.data();
            if (postData == null) return null;
            // Use the full viewer-aware check so posts from authors the user
            // has blocked don't resurface through the saved tab.
            final post = CommunityPost.fromMap(postId, postData);
            if (!post.isVisibleToViewer(uid, blockedUids: blockedUids)) {
              return null;
            }
            return post;
          } catch (e, st) {
            debugPrint(
              'CommunityRepository.watchSavedPosts item failed: $e\n$st',
            );
            return null;
          }
        });

        final results = await Future.wait(futures);
        return results.whereType<CommunityPost>().toList();
      });

  Future<void> deletePost({
    required String communityId,
    required String postId,
    required String uid,
  }) async {
    final ref = _postsRef(communityId).doc(postId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (!await _userOwnsPost(snap.data(), communityId, postId, uid)) {
      throw StateError('Not your post');
    }
    await ref.delete();
    if (snap.data()?['isAnonymous'] == true) {
      await _privateAuthPostRef(communityId, postId).delete();
    }
  }

  Future<void> deleteComment({
    required String communityId,
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final commentRef = _commentsRef(communityId, postId).doc(commentId);
    final postRef = _postsRef(communityId).doc(postId);
    await _firestore.runTransaction((tx) async {
      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) return;
      if (commentSnap.data()?['authorUid'] != uid) {
        throw StateError('Not your comment');
      }
      tx.delete(commentRef);
      final postSnap = await tx.get(postRef);
      final data = postSnap.data();
      if (data == null) return;
      final count = (data['commentCount'] as int? ?? 1) - 1;
      final updates = <String, dynamic>{'commentCount': count < 0 ? 0 : count};
      if (data['bestAnswerCommentId'] == commentId) {
        updates['bestAnswerCommentId'] = FieldValue.delete();
      }
      tx.update(postRef, updates);
    });
  }

  Future<void> setBestAnswer({
    required String communityId,
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final postRef = _postsRef(communityId).doc(postId);
    final snap = await postRef.get();
    if (!snap.exists ||
        !await _userOwnsPost(snap.data(), communityId, postId, uid)) {
      throw StateError('Only the post author can mark a best answer');
    }
    await postRef.update({'bestAnswerCommentId': commentId});
  }

  Future<void> clearBestAnswer({
    required String communityId,
    required String postId,
    required String uid,
  }) async {
    final postRef = _postsRef(communityId).doc(postId);
    final snap = await postRef.get();
    if (!snap.exists ||
        !await _userOwnsPost(snap.data(), communityId, postId, uid)) {
      return;
    }
    await postRef.update({'bestAnswerCommentId': FieldValue.delete()});
  }

  /// Returns `true` when the post is queued for human review.
  Future<bool> createPost({
    required String communityId,
    required String uid,
    required String text,
    PostType postType = PostType.support,
    String? communityName,
    int authorAvatarIndex = 0,
    String? mediaUrl,
    String? mediaType,
    bool isAnonymous = false,
    List<String>? pollOptions,
    String? coverStyle,
  }) async {
    if (_auth.currentUser?.uid != uid) throw StateError('Not signed in');
    final clean = CommunityTextSanitize.post(text);
    // Keep instant client-side safety feedback, while the trusted submission
    // endpoint performs the only network/AI moderation pass. Previously the
    // client repeated profile, membership and AI calls that the endpoint
    // already performs, adding several serial round trips to every post.
    final localModeration = _fallbackModeration(clean);
    if (!localModeration.approved) {
      throw ModerationRejectedException(
        localModeration.reason ?? 'Content rejected',
      );
    }

    final result = await _submitCommunity('post', {
      'communityId': communityId,
      'text': clean,
      'postType': postType.value,
      'communityName': ?communityName,
      'authorAvatarIndex': authorAvatarIndex,
      'mediaUrl': ?mediaUrl,
      'mediaType': ?mediaType,
      'isAnonymous': isAnonymous,
      'coverStyle': ?coverStyle,
      if (postType == PostType.poll && pollOptions != null)
        'pollOptions': pollOptions,
    });
    return result['pendingReview'] as bool? ?? false;
  }

  Future<void> updatePost({
    required String communityId,
    required String postId,
    required String uid,
    required String text,
    PostType postType = PostType.support,
  }) async {
    await _ensureCanParticipate(uid);
    final ref = _postsRef(communityId).doc(postId);
    final snap = await ref.get();
    if (!snap.exists ||
        !await _userOwnsPost(snap.data(), communityId, postId, uid)) {
      throw StateError('Not your post');
    }

    final clean = CommunityTextSanitize.post(text);
    final moderation = await moderateText(clean);
    if (!moderation.approved && !moderation.pendingReview) {
      throw ModerationRejectedException(
        moderation.reason ?? 'Content rejected',
      );
    }

    await ref.update({
      'text': clean,
      'postType': postType.value,
      'editedAt': FieldValue.serverTimestamp(),
      // Always re-queue for server moderation after edits. Client moderation
      // alone must not keep edited text visible as previously approved.
      'moderationStatus': 'pending_review',
    });
  }

  CollectionReference<Map<String, dynamic>> _inboxRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('communityInbox');

  Stream<List<CommunityInboxItem>> watchInbox(String uid) => _inboxRef(uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => CommunityInboxItem.fromDoc(d.id, d.data()))
            .toList(),
      );

  Stream<int> watchUnreadInboxCount(String uid) => _inboxRef(
    uid,
  ).where('read', isEqualTo: false).snapshots().map((s) => s.docs.length);

  Future<void> markInboxItemRead(String uid, String inboxId) async {
    await _inboxRef(uid).doc(inboxId).update({'read': true});
  }

  Future<void> markAllInboxRead(String uid) async {
    final snap = await _inboxRef(uid).where('read', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Returns `true` when the comment is queued for human review.
  Future<bool> createComment({
    required String communityId,
    required String postId,
    required String uid,
    required String text,
    int authorAvatarIndex = 0,
    String? parentCommentId,
    List<String> mentions = const [],
  }) async {
    if (_auth.currentUser?.uid != uid) throw StateError('Not signed in');

    final clean = CommunityTextSanitize.comment(text);
    // The server repeats all authoritative participation and AI checks. Only
    // run the synchronous safety net here so the comment takes one network
    // trip instead of several sequential ones.
    final localModeration = _fallbackModeration(clean);
    if (!localModeration.approved) {
      throw ModerationRejectedException(
        localModeration.reason ?? 'Content rejected',
      );
    }

    final result = await _submitCommunity('comment', {
      'communityId': communityId,
      'postId': postId,
      'text': clean,
      'authorAvatarIndex': authorAvatarIndex,
      'parentCommentId': ?parentCommentId,
      if (mentions.isNotEmpty) 'mentions': mentions.take(5).toList(),
    });
    return result['pendingReview'] as bool? ?? false;
  }

  Future<void> updateComment({
    required String communityId,
    required String postId,
    required String commentId,
    required String uid,
    required String text,
  }) async {
    await _ensureCanParticipate(uid);
    final ref = _commentsRef(communityId, postId).doc(commentId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['authorUid'] != uid) {
      throw StateError('Not your comment');
    }
    final clean = CommunityTextSanitize.comment(text);
    final moderation = await moderateText(clean);
    if (!moderation.approved && !moderation.pendingReview) {
      throw ModerationRejectedException(
        moderation.reason ?? 'Content rejected',
      );
    }
    await ref.update({
      'text': clean,
      'editedAt': FieldValue.serverTimestamp(),
      // Always re-queue for server moderation after edits.
      'moderationStatus': 'pending_review',
    });
  }
}
