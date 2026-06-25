import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/sync/data/cloud_sync_service.dart';
import 'premium_status_notifier.dart';

/// Syncs `users/{uid}.isPremium` from Firestore into local prefs app-wide.
class PremiumSyncListener extends StatefulWidget {
  const PremiumSyncListener({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumSyncListener> createState() => _PremiumSyncListenerState();
}

class _PremiumSyncListenerState extends State<PremiumSyncListener>
    with WidgetsBindingObserver {
  final _sync = CloudSyncService();
  StreamSubscription<bool>? _premiumSub;
  StreamSubscription<User?>? _authSub;
  String? _uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(PremiumStatusNotifier.instance.loadFromPrefs());
    _bind(FirebaseAuth.instance.currentUser?.uid);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _bind(user?.uid);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _uid != null) {
      unawaited(_sync.fetchPremiumStatus(_uid!).then(
        PremiumStatusNotifier.instance.applyRemote,
      ));
    }
  }

  void _bind(String? uid) {
    if (_uid == uid) return;
    _premiumSub?.cancel();
    _uid = uid;
    if (uid == null) {
      unawaited(PremiumStatusNotifier.instance.applyRemote(false));
      return;
    }
    unawaited(_sync.fetchPremiumStatus(uid).then(
      PremiumStatusNotifier.instance.applyRemote,
      onError: (e) => debugPrint('PremiumSyncListener fetch: $e'),
    ));
    _premiumSub = _sync.watchPremiumStatus(uid).listen(
      (isPremium) => PremiumStatusNotifier.instance.applyRemote(isPremium),
      onError: (e, st) {
        debugPrint('PremiumSyncListener stream: $e\n$st');
        // Retry once on stream error
        Future.delayed(const Duration(seconds: 3), () {
          if (_uid == uid) {
            unawaited(_sync.fetchPremiumStatus(uid).then(
              PremiumStatusNotifier.instance.applyRemote,
              onError: (_) {},
            ));
          }
        });
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _premiumSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
