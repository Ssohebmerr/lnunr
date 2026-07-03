import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/premium/data/play_billing_service.dart';
import '../../features/sync/data/cloud_sync_service.dart';
import 'premium_status_notifier.dart';

/// App-wide Google Play Billing listener — starts once at launch so purchases
/// complete even if the user leaves the Account tab during checkout.
class PlayBillingCoordinator {
  PlayBillingCoordinator._();

  static final PlayBillingCoordinator instance = PlayBillingCoordinator._();

  final PlayBillingService billing = PlayBillingService();
  final CloudSyncService _sync = CloudSyncService();

  bool _started = false;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    await billing.startListening(onPremiumGranted: _onPremiumGranted);
  }

  Future<void> _onPremiumGranted() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final isPremium = await _sync.fetchPremiumStatus(uid);
      await PremiumStatusNotifier.instance.applyRemote(isPremium);
    } catch (e, st) {
      debugPrint('PlayBillingCoordinator premium sync failed: $e\n$st');
    }
  }

  void dispose() {
    billing.dispose();
    _started = false;
  }
}
