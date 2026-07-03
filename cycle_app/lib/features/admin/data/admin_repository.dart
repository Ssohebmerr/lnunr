import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/cms/app_settings.dart';
import '../../../core/config/app_secrets.dart';
import '../../community/data/models/community_profile.dart';

class AdminAiReport {
  const AdminAiReport({
    required this.id,
    required this.uid,
    required this.email,
    required this.reason,
    required this.response,
    required this.status,
    required this.createdAt,
  });

  factory AdminAiReport.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['timestamp'];
    return AdminAiReport(
      id: id,
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      response: data['response'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String uid;
  final String email;
  final String reason;
  final String response;
  final String status;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.communityId,
    required this.postId,
    required this.reporterUid,
    required this.authorUid,
    required this.authorAlias,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.commentId,
  });

  factory AdminReport.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return AdminReport(
      id: id,
      communityId: data['communityId'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      reporterUid: data['reporterUid'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorAlias: data['authorAlias'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      commentId: data['commentId'] as String?,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String communityId;
  final String postId;
  final String reporterUid;
  final String authorUid;
  final String authorAlias;
  final String reason;
  final String status;
  final String? commentId;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
}

class AdminPendingPost {
  const AdminPendingPost({
    required this.communityId,
    required this.postId,
    required this.authorAlias,
    required this.text,
    required this.createdAt,
  });

  factory AdminPendingPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final segments = doc.reference.path.split('/');
    final communityId = segments.length >= 2 ? segments[1] : '';
    final ts = data['createdAt'];
    return AdminPendingPost(
      communityId: communityId,
      postId: doc.id,
      authorAlias: data['authorAlias'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String communityId;
  final String postId;
  final String authorAlias;
  final String text;
  final DateTime createdAt;
}

class AdminPendingComment {
  const AdminPendingComment({
    required this.communityId,
    required this.postId,
    required this.commentId,
    required this.authorAlias,
    required this.text,
    required this.createdAt,
  });

  factory AdminPendingComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final segments = doc.reference.path.split('/');
    final communityId = segments.length >= 2 ? segments[1] : '';
    final postId = segments.length >= 4 ? segments[3] : '';
    final ts = data['createdAt'];
    return AdminPendingComment(
      communityId: communityId,
      postId: postId,
      commentId: doc.id,
      authorAlias: data['authorAlias'] as String? ?? 'User',
      text: data['text'] as String? ?? '',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String communityId;
  final String postId;
  final String commentId;
  final String authorAlias;
  final String text;
  final DateTime createdAt;
}

class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.action,
    required this.details,
    required this.adminUid,
    required this.createdAt,
    this.adminEmail,
  });

  factory AdminActivity.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['timestamp'];
    return AdminActivity(
      id: id,
      action: data['action'] as String? ?? '',
      details: data['details'] as String? ?? '',
      adminUid: data['adminUid'] as String? ?? '',
      adminEmail: data['adminEmail'] as String?,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String action;
  final String details;
  final String adminUid;
  final String? adminEmail;
  final DateTime createdAt;
}

class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    required this.isBanned,
    required this.isPremium,
  });
  final String uid;
  final String email;
  final bool isBanned;
  final bool isPremium;
}

class AdminRepository {
  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(true);
      if (token.claims?['admin'] == true) return true;
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Stream<List<AdminReport>> watchReports() => _firestore
      .collection('communityReports')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => AdminReport.fromDoc(d.id, d.data())).toList());

  Stream<List<AdminAiReport>> watchAiReports() => _firestore
      .collection('aiReports')
      .limit(100)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => AdminAiReport.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> resolveReport(String reportId) async {
    await _firestore.collection('communityReports').doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _auth.currentUser?.uid,
    });
    await _logActivity('resolve_report', 'Report $reportId resolved');
  }

  Future<void> resolveAiReport(String reportId, {String status = 'resolved'}) async {
    await _firestore.collection('aiReports').doc(reportId).update({
      'status': status,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _auth.currentUser?.uid,
    });
    await _logActivity('resolve_ai_report', 'AI report $reportId → $status');
  }

  Future<void> hidePost(String communityId, String postId) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .update({
      'hidden': true,
      'hiddenAt': FieldValue.serverTimestamp(),
      'hiddenBy': _auth.currentUser?.uid,
    });
    await _logActivity('hide_post', 'Post $postId in $communityId hidden');
  }

  Stream<List<AdminPendingPost>> watchPendingPosts() => _firestore
      .collectionGroup('posts')
      .where('moderationStatus', isEqualTo: 'pending_review')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map(
        (s) => s.docs.map(AdminPendingPost.fromDoc).toList(),
      );

  Stream<List<AdminPendingComment>> watchPendingComments() => _firestore
      .collectionGroup('comments')
      .where('moderationStatus', isEqualTo: 'pending_review')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map(
        (s) => s.docs.map(AdminPendingComment.fromDoc).toList(),
      );

  Future<void> approveComment(
    String communityId,
    String postId,
    String commentId,
  ) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'moderationStatus': 'approved',
      'moderationReviewedAt': FieldValue.serverTimestamp(),
      'moderationReviewedBy': _auth.currentUser?.uid,
    });
    await _logActivity('approve_comment', 'Comment $commentId approved');
  }

  Future<void> rejectPendingComment(
    String communityId,
    String postId,
    String commentId,
  ) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'hidden': true,
      'moderationStatus': 'rejected',
      'hiddenAt': FieldValue.serverTimestamp(),
      'hiddenBy': _auth.currentUser?.uid,
      'moderationReviewedAt': FieldValue.serverTimestamp(),
      'moderationReviewedBy': _auth.currentUser?.uid,
    });
    await _logActivity('reject_comment', 'Comment $commentId rejected');
  }

  Future<void> approvePost(String communityId, String postId) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .update({
      'moderationStatus': 'approved',
      'moderationReviewedAt': FieldValue.serverTimestamp(),
      'moderationReviewedBy': _auth.currentUser?.uid,
    });
    await _logActivity('approve_post', 'Post $postId in $communityId approved');
  }

  Future<void> rejectPendingPost(String communityId, String postId) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId)
        .update({
      'hidden': true,
      'moderationStatus': 'rejected',
      'hiddenAt': FieldValue.serverTimestamp(),
      'hiddenBy': _auth.currentUser?.uid,
      'moderationReviewedAt': FieldValue.serverTimestamp(),
      'moderationReviewedBy': _auth.currentUser?.uid,
    });
    await _logActivity('reject_post', 'Post $postId in $communityId rejected');
  }

  Future<void> banUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'communityBanned': true,
      'communityBannedAt': FieldValue.serverTimestamp(),
      'communityBannedReason': 'Banned by admin',
    });
    await _logActivity('ban_user', 'User $uid banned');
  }

  Future<void> unbanUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'communityBanned': false,
      'communityBannedAt': FieldValue.delete(),
      'communityBannedReason': FieldValue.delete(),
    });
    await _logActivity('unban_user', 'User $uid unbanned');
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    await _firestore.collection('appSettings').doc('main').set(settings.toMap());
    await _logActivity('update_settings', 'App settings updated');
  }

  Stream<List<AdminActivity>> watchActivityLog() => _firestore
      .collection('adminActivityLog')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => AdminActivity.fromDoc(d.id, d.data())).toList());

  Future<int> approximateUserCount() async {
    try {
      final snap = await _firestore.collection('users').count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> pendingReportsCount() async {
    try {
      final snap = await _firestore
          .collection('communityReports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<AdminUser>> searchUsers(String query) async {
    try {
      final snap = await _firestore
          .collection('users')
          .limit(50)
          .get();
      final results = <AdminUser>[];
      final lower = query.toLowerCase();
      for (final doc in snap.docs) {
        final data = doc.data();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final uid = doc.id.toLowerCase();
        if (email.contains(lower) || uid.contains(lower)) {
          results.add(AdminUser(
            uid: doc.id,
            email: data['email'] as String? ?? '',
            isBanned: data['communityBanned'] == true,
            isPremium: data['isPremium'] == true,
          ));
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<CommunityProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return CommunityProfile.fromMap(doc.data());
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> sendBroadcast({
    required String title,
    required String body,
    String? audience,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'error': 'Not authenticated'};
      final token = await user.getIdToken();
      final url = Uri.parse(
        '${AppSecrets.cloudFunctionsUrl}/adminBroadcast',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'audience': ?audience,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        return {'error': data['error'] ?? 'HTTP ${response.statusCode}'};
      }
      await _logActivity(
          'broadcast', 'Broadcast "$title" — ${data['sent']} sent, ${data['failed']} failed');
      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> _logActivity(String action, String details) async {
    try {
      final admin = _auth.currentUser;
      if (admin == null) return;
      await _firestore.collection('adminActivityLog').add({
        'action': action,
        'details': details,
        'adminUid': admin.uid,
        'adminEmail': admin.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('AdminRepository._logActivity failed: $e\n$st');
    }
  }
}
