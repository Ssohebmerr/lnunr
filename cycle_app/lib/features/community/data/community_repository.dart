import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../../core/ai/firebase_ai_service.dart';
import '../../../core/ai/direct_gemini_service.dart';
import '../../../core/config/app_secrets.dart';
import '../../../core/storage/user_prefs.dart';
import 'community_catalog_repository.dart';
import 'community_icon_registry.dart';
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
import 'moderation_result.dart';


class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseAiService? firebaseAi,
    DirectGeminiService? directGemini,
    CommunityCatalogRepository? catalog,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firebaseAi = firebaseAi ?? FirebaseAiService(),
        _directGemini = directGemini ?? DirectGeminiService(),
        _catalog = catalog ?? CommunityCatalogRepository();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseAiService _firebaseAi;
  final DirectGeminiService _directGemini;
  final CommunityCatalogRepository _catalog;

  static final _baseUrl = AppSecrets.cloudFunctionsUrl;

  String? get currentUid => _auth.currentUser?.uid;

  /// Throws [MinorRestrictedException] when the current profile is under 18.
  /// Uses [resolveProfile] so that missing birth year is auto-filled.
  Future<void> _ensureAdult(String uid) async {
    final profile = await resolveProfile(uid);
    if (profile.isMinor) throw const MinorRestrictedException();
  }

  Future<void> _ensureCanParticipate(String uid) async {
    await _ensureAdult(uid);
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.data()?['communityBanned'] == true) {
      throw const CommunityBannedException();
    }
  }

  Community _mergeSeed(Community seed, CommunityCatalogEntry? entry) {
    if (entry == null) return seed;
    return seed.copyWith(
      nameEn: entry.nameEn,
      nameAr: entry.nameAr,
      descriptionEn: entry.descriptionEn,
      descriptionAr: entry.descriptionAr,
      rulesEn: entry.rulesEn,
      rulesAr: entry.rulesAr,
      topic: entry.topic,
      icon: entry.iconName != null
          ? communityIconFromName(entry.iconName!)
          : null,
      maxMembers: entry.maxMembers,
    );
  }

  Future<List<Community>> _resolvedCommunities({
    String languageCode = 'en',
    UserGoalTypes? goal,
    List<String> joinedIds = const [],
    CommunitySortMode mode = CommunitySortMode.defaultOrder,
  }) async {
    final catalog = await _catalog.fetchAll();
    final results = <Community>[];
    for (final seed in CommunitySeed.defaults) {
      final entry = catalog[seed.id];
      if (entry != null && !entry.enabled) continue;
      results.add(_mergeSeed(seed, entry));
    }
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
    if (seed == null) return null;
    return _mergeSeed(seed, entry);
  }

  CollectionReference<Map<String, dynamic>> _membersRef(String communityId) =>
      _firestore.collection('communities').doc(communityId).collection('members');

  CollectionReference<Map<String, dynamic>> _postsRef(String communityId) =>
      _firestore.collection('communities').doc(communityId).collection('posts');

  CollectionReference<Map<String, dynamic>> _commentsRef(
    String communityId,
    String postId,
  ) =>
      _postsRef(communityId).doc(postId).collection('comments');

  Future<CommunityProfile> getProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return CommunityProfile.fromMap(doc.data());
    } catch (e, st) {
      debugPrint('CommunityRepository.getProfile failed: $e\n$st');
      rethrow;
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

  /// Auto-completes community profile from available data sources so the
  /// user is never blocked by a manual setup step.
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

    // --- Auto-resolve alias from every available source ---
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
                    : (authName.isNotEmpty
                        ? authName
                        : emailPrefix)),
          );
    if (alias.length < 2) alias = 'User_${uid.substring(0, 4)}';

    // --- Auto-set birth year to a default adult year if missing ---
    final birthYear = profile.birthYear ?? (DateTime.now().year - 25);

    final complete = CommunityProfile(
      alias: alias,
      birthYear: birthYear,
      goal: profile.goal ?? await UserPrefs.getProfileGoal(),
      setupComplete: true,
      avatarIndex: profile.avatarIndex,
      photoUrl: profile.photoUrl,
    );
    try {
      await saveProfile(uid, complete);
    } catch (e, st) {
      debugPrint('CommunityRepository.resolveProfile save failed: $e\n$st');
    }
    return complete;
  }

  Future<void> saveProfile(String uid, CommunityProfile profile) async {
    await _firestore.collection('users').doc(uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
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
            final countSnap = await _membersRef(community.id)
                .count()
                .get()
                .timeout(const Duration(seconds: 3));
            return community.copyWith(memberCount: countSnap.count ?? 0);
          } catch (e) {
            debugPrint(
              'member count skipped for ${community.id}: $e',
            );
            return community;
          }
        }),
      );
    } catch (e, st) {
      debugPrint(
        'CommunityRepository.fetchCommunitiesWithCounts failed: $e\n$st',
      );
      try {
        return await _resolvedCommunities(languageCode: languageCode, goal: goal);
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
      final countSnap = await _membersRef(communityId)
          .count()
          .get()
          .timeout(const Duration(seconds: 5));
      return countSnap.count ?? 0;
    } catch (e) {
      debugPrint('fetchMemberCount failed for $communityId: $e');
      return 0;
    }
  }

  Stream<List<CommunityMembership>> watchJoinedMemberships(String uid) =>
      _firestore
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
          return CommunityMembership(
            communityId: doc.id,
            joinedAt: date,
          );
        }).toList();
        memberships.sort((a, b) {
          final aTime = a.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return memberships;
      });

  Stream<List<String>> watchJoinedCommunityIds(String uid) =>
      watchJoinedMemberships(uid)
          .map((m) => m.map((e) => e.communityId).toList());

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
    });
    batch.set(
      _firestore.collection('users').doc(uid).collection('communityMemberships').doc(communityId),
      {'joinedAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> leaveCommunity(String uid, String communityId) async {
    final batch = _firestore.batch();
    batch.delete(_membersRef(communityId).doc(uid));
    batch.delete(
      _firestore.collection('users').doc(uid).collection('communityMemberships').doc(communityId),
    );
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _likesRef(
    String communityId,
    String postId,
  ) =>
      _postsRef(communityId).doc(postId).collection('likes');

  /// Merged feed from all joined communities.
  /// Maximum number of communities to subscribe to simultaneously.
  static const _maxConcurrentCommunities = 12;

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
        watchPosts(communityId).listen(
          (posts) {
            cache.removeWhere((k, _) => k.startsWith('$communityId|'));
            for (final p in posts) {
              cache['$communityId|${p.id}'] = p;
            }
            publish();
          },
          onError: (e, st) {
            debugPrint('CommunityRepository.watchJoinedFeed stream error: $e\n$st');
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
  ) =>
      _postsRef(communityId).doc(postId).collection('pollVotes');

  /// Live poll results: vote count per option index + the viewer's own vote.
  Stream<PollResults> watchPollResults(
    String communityId,
    String postId,
    String? viewerUid,
  ) =>
      _pollVotesRef(communityId, postId).snapshots().map((snap) {
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
      _likesRef(communityId, postId)
          .snapshots()
          .map((s) => s.docs.length);

  Stream<bool> watchUserLiked(
    String communityId,
    String postId,
    String uid,
  ) =>
      _likesRef(communityId, postId)
          .doc(uid)
          .snapshots()
          .map((s) => s.exists);

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
  ) =>
      _likesRef(communityId, postId).snapshots().map((s) {
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
  }) async {
    final ref = _likesRef(communityId, postId).doc(uid);
    final snap = await ref.get();
    final current = snap.exists
        ? ((snap.data()?['reaction'] as String?) ?? 'heart')
        : null;
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
  ) =>
      _commentsRef(communityId, postId).doc(commentId).collection('likes');

  Stream<({int count, bool liked})> watchCommentLikes(
    String communityId,
    String postId,
    String commentId,
    String? viewerUid,
  ) =>
      _commentLikesRef(communityId, postId, commentId).snapshots().map(
            (s) => (
              count: s.docs.length,
              liked: viewerUid != null &&
                  s.docs.any((d) => d.id == viewerUid),
            ),
          );

  Future<void> toggleCommentLike({
    required String communityId,
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final ref = _commentLikesRef(communityId, postId, commentId).doc(uid);
    final snap = await ref.get();
    if (snap.exists) {
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
    final snap = await _postsRef(communityId)
        .where('authorUid', isEqualTo: authorUid)
        .limit(limit)
        .get();
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

  Stream<Set<String>> watchBlockedUids(String uid) => _blockedRef(uid)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  Stream<List<BlockedUser>> watchBlockedUsers(String uid) => _blockedRef(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => BlockedUser.fromDoc(d.id, d.data()))
            .toList(),
      );

  Stream<List<CommunityPost>> watchPosts(String communityId) {
    final viewerUid = _auth.currentUser?.uid;
    return _postsRef(communityId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => CommunityPost.fromMap(d.id, d.data()))
              .where((p) => p.isVisibleTo(viewerUid))
              .toList(),
        );
  }

  /// Fetch a single page of posts for infinite scroll.
  /// Pass [lastDocument] from the previous page to get the next batch.
  static const int postsPerPage = 20;

  Future<List<CommunityPost>> fetchPostsPage(
    String communityId, {
    DocumentSnapshot? lastDocument,
  }) async {
    final viewerUid = _auth.currentUser?.uid;
    var query = _postsRef(communityId)
        .orderBy('createdAt', descending: true)
        .limit(postsPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => CommunityPost.fromMap(d.id, d.data()))
        .where((p) => p.isVisibleTo(viewerUid))
        .toList();
  }

  /// Returns the last DocumentSnapshot from the most recent page fetch,
  /// used as cursor for the next page.
  Future<DocumentSnapshot?> fetchPostsPageRaw(
    String communityId, {
    DocumentSnapshot? lastDocument,
  }) async {
    var query = _postsRef(communityId)
        .orderBy('createdAt', descending: true)
        .limit(postsPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snap = await query.get();
    return snap.docs.isNotEmpty ? snap.docs.last : null;
  }

  CommunityPost? _postFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    String? viewerUid,
  }) {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final post = CommunityPost.fromMap(snap.id, data);
    if (!post.isVisibleTo(viewerUid)) return null;
    return post;
  }

  Stream<CommunityPost?> watchPost(String communityId, String postId) {
    final viewerUid = _auth.currentUser?.uid;
    return _postsRef(communityId)
        .doc(postId)
        .snapshots()
        .map((snap) => _postFromSnapshot(snap, viewerUid: viewerUid));
  }

  Future<CommunityPost?> getPost(String communityId, String postId) async {
    final snap = await _postsRef(communityId).doc(postId).get();
    return _postFromSnapshot(snap, viewerUid: _auth.currentUser?.uid);
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
    final local = _fallbackModeration(text);
    if (!local.approved) return local;

    // 1. Try Direct Gemini API (Google AI Studio key — free)
    final direct = await _directGemini.moderateContent(text: text);
    if (direct != null) {
      if (direct.approved) return direct;
      if (_isModerationUnavailable(direct.reason)) {
        return const ModerationResult(approved: false, pendingReview: true, reason: 'Content pending AI review.');
      }
      return direct;
    }

    // 2. Try Firebase AI Logic (direct, secure, no server)
    final firebaseAi = await _firebaseAi.moderateContent(text: text);
    if (firebaseAi != null) {
      if (firebaseAi.approved) return firebaseAi;
      if (_isModerationUnavailable(firebaseAi.reason)) {
        return const ModerationResult(approved: false, pendingReview: true, reason: 'Content pending AI review.');
      }
      return firebaseAi;
    }

    // 3. Try Cloud Function (Firebase server — GEMINI_API_KEY in Firebase Secrets)
    final cloud = await _moderateViaCloud(text);
    if (cloud != null) {
      if (cloud.approved) return cloud;
      if (_isModerationUnavailable(cloud.reason)) {
        return const ModerationResult(approved: false, pendingReview: true, reason: 'Content pending AI review.');
      }
      return cloud;
    }

    // All AI services unavailable — block until reviewed.
    return const ModerationResult(approved: false, pendingReview: true, reason: 'Content pending AI review.');
  }

  /// Local safety net used when both cloud and local Gemini are unavailable.
  /// Focuses on protecting users (especially minors) from contact harvesting,
  /// external links, and harmful content.
  // ---------------------------------------------------------------------------
  // Rate limiting & duplicate detection
  // ---------------------------------------------------------------------------

  static const _rateLimitCollection = 'communityRateLimits';
  static const _hashCollection = 'communityContentHashes';

  String _hashContent(String text) {
    final bytes = utf8.encode(text.trim().toLowerCase());
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  Future<void> _storeContentHash(String uid, String hash) async {
    try {
      await _firestore.collection(_hashCollection).doc('${uid}_$hash').set({
        'uid': uid,
        'hash': hash,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _checkDuplicate(String uid, String text) async {
    final hash = _hashContent(text);
    try {
      final doc = await _firestore.collection(_hashCollection).doc('${uid}_$hash').get();
      if (doc.exists) {
        final data = doc.data();
        final createdAt = (data?['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && DateTime.now().difference(createdAt).inMinutes < 5) {
          throw const ModerationRejectedException(
            'You recently posted similar content. Please wait before posting again.',
          );
        }
      }
    } on ModerationRejectedException {
      rethrow;
    } catch (_) {}
  }

  Future<void> _enforceRateLimit(
    String uid,
    String type, {
    int maxPerHour = 10,
  }) async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final snap = await _firestore
          .collection(_rateLimitCollection)
          .doc(uid)
          .collection('actions')
          .where('type', isEqualTo: type)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .count()
          .get();

      if (snap.count != null && snap.count! >= maxPerHour) {
        throw ModerationRejectedException(
          'Too many ${type}s. Please wait before posting again.',
        );
      }

      // Record this action
      await _firestore
          .collection(_rateLimitCollection)
          .doc(uid)
          .collection('actions')
          .add({
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ModerationRejectedException {
      rethrow;
    } catch (_) {}
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
      return const ModerationResult(approved: false, reason: 'Post is too short.');
    }
    return const ModerationResult(approved: true);
  }

  Future<ModerationResult?> _moderateViaCloud(String text) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/moderate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );
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

  Stream<bool> watchPostSaved(
    String uid,
    String communityId,
    String postId,
  ) =>
      _savedPostsRef(uid)
          .doc(savedPostDocId(communityId, postId))
          .snapshots()
          .map((s) => s.exists);

  Future<bool> toggleSavePost(String uid, CommunityPost post) async {
    final id = savedPostDocId(post.communityId, post.id);
    final ref = _savedPostsRef(uid).doc(id);
    final snap = await ref.get();
    if (snap.exists) {
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
  }) =>
      _savedPostsRef(uid)
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
            debugPrint('CommunityRepository.watchSavedPosts item failed: $e\n$st');
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
    if (snap.data()?['authorUid'] != uid) {
      throw StateError('Not your post');
    }
    await ref.delete();
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
      final updates = <String, dynamic>{
        'commentCount': count < 0 ? 0 : count,
      };
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
    if (!snap.exists || snap.data()?['authorUid'] != uid) {
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
    if (!snap.exists || snap.data()?['authorUid'] != uid) return;
    await postRef.update({'bestAnswerCommentId': FieldValue.delete()});
  }

  /// Returns `true` when the post is queued for human review.
  Future<bool> createPost({
    required String communityId,
    required String uid,
    required String alias,
    required String text,
    PostType postType = PostType.support,
    String? communityName,
    int authorAvatarIndex = 0,
    String? mediaUrl,
    String? mediaType,
    bool isAnonymous = false,
    List<String>? pollOptions,
  }) async {
    await _ensureCanParticipate(uid);
    // Media uploads require a Premium subscription.
    if ((mediaUrl != null || mediaType != null) && !await UserPrefs.isPremium()) {
      throw const MediaRequiresPremiumException();
    }
    final member = await isMember(uid, communityId);
    if (!member) throw StateError('Join the community first');

    // Rate limiting: max 10 posts per hour
    await _enforceRateLimit(uid, 'post', maxPerHour: 10);

    // Duplicate detection: same text within 5 minutes
    await _checkDuplicate(uid, text);

    final moderation = await moderateText(text);
    if (!moderation.approved) {
      throw ModerationRejectedException(moderation.reason ?? 'Content rejected');
    }

    // Firestore rules only allow clients to set pending_review; the Cloud
    // Function (or admin) promotes to approved after AI review.
    final displayAlias = isAnonymous ? 'Anonymous' : alias;
    final contentHash = _hashContent(text);
    final authorIsPremium =
        !isAnonymous && await UserPrefs.isPremium();

    await _postsRef(communityId).add({
      ...CommunityPost(
        id: '',
        communityId: communityId,
        authorUid: uid,
        authorAlias: displayAlias,
        text: text.trim(),
        createdAt: DateTime.now(),
        postType: postType,
        communityName: communityName,
        authorAvatarIndex: isAnonymous ? 0 : authorAvatarIndex,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        isAnonymous: isAnonymous,
        authorIsPremium: authorIsPremium,
        pollOptions: postType == PostType.poll ? pollOptions : null,
      ).toMap(),
      'moderationStatus': 'pending_review',
      'contentHash': contentHash,
    });

    // Store hash for duplicate detection
    await _storeContentHash(uid, contentHash);

    return moderation.pendingReview;
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
    if (!snap.exists || snap.data()?['authorUid'] != uid) {
      throw StateError('Not your post');
    }

    final moderation = await moderateText(text);
    if (!moderation.approved) {
      throw ModerationRejectedException(moderation.reason ?? 'Content rejected');
    }

    await ref.update({
      'text': text.trim(),
      'postType': postType.value,
      'editedAt': FieldValue.serverTimestamp(),
      if (moderation.pendingReview) 'moderationStatus': 'pending_review',
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

  Stream<int> watchUnreadInboxCount(String uid) => _inboxRef(uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

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
    required String alias,
    required String text,
    int authorAvatarIndex = 0,
    String? parentCommentId,
  }) async {
    await _ensureCanParticipate(uid);
    final member = await isMember(uid, communityId);
    if (!member) throw StateError('Join the community first');

    await _enforceRateLimit(uid, 'comment', maxPerHour: 20);
    await _checkDuplicate(uid, text);

    final moderation = await moderateText(text);
    if (!moderation.approved) {
      throw ModerationRejectedException(moderation.reason ?? 'Content rejected');
    }

    final postRef = _postsRef(communityId).doc(postId);
    final authorIsPremium = await UserPrefs.isPremium();
    await _firestore.runTransaction((tx) async {
      tx.set(_commentsRef(communityId, postId).doc(), {
        'authorUid': uid,
        'authorAlias': alias,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'authorAvatarIndex': authorAvatarIndex,
        'authorIsPremium': authorIsPremium,
        'parentCommentId': parentCommentId,
        'moderationStatus': 'pending_review',
      });
      final snap = await tx.get(postRef);
      final count = (snap.data()?['commentCount'] as int? ?? 0) + 1;
      tx.update(postRef, {'commentCount': count});
    });
    return moderation.pendingReview;
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
    final moderation = await moderateText(text);
    if (!moderation.approved) {
      throw ModerationRejectedException(moderation.reason ?? 'Content rejected');
    }
    await ref.update({
      'text': text.trim(),
      'editedAt': FieldValue.serverTimestamp(),
      if (moderation.pendingReview) 'moderationStatus': 'pending_review',
    });
  }
}

