import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/notifications/community_notification_service.dart';

/// Listens for community inbox events and surfaces local notifications.
class CommunityNotificationListener extends StatefulWidget {
  const CommunityNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  State<CommunityNotificationListener> createState() =>
      _CommunityNotificationListenerState();
}

class _CommunityNotificationListenerState
    extends State<CommunityNotificationListener> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inboxSub;
  StreamSubscription<User?>? _authSub;
  String? _uid;
  bool _skipInitialSnapshot = true;

  @override
  void initState() {
    super.initState();
    _bind(FirebaseAuth.instance.currentUser?.uid);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _bind(user?.uid);
    });
  }

  void _bind(String? uid) {
    if (_uid == uid) return;
    _inboxSub?.cancel();
    _uid = uid;
    if (uid == null) return;

    _skipInitialSnapshot = true;
    _inboxSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('communityInbox')
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen(
          (snap) async {
            if (_skipInitialSnapshot) {
              _skipInitialSnapshot = false;
              return;
            }

            for (final change in snap.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              final data = change.doc.data();
              if (data == null) continue;
              await CommunityNotificationService.showFromInbox(data);
            }
          },
          onError: (Object e, StackTrace st) {
            debugPrint('CommunityNotificationListener: $e\n$st');
          },
        );
  }

  @override
  void dispose() {
    _inboxSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
