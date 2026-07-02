import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight DAU heartbeat: updates `users/{uid}.lastActiveAt` at most
/// once per hour to power the admin DAU chart and inactive-user segments.
class ActivePingService {
  static const _prefsKey = 'last_active_ping_ms';
  static const Duration _throttle = Duration(hours: 1);

  /// Call on app start / resume. Non-blocking, never throws.
  static Future<void> pingIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_prefsKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _throttle.inMilliseconds) return;

      // Best-effort write — ignore failures (offline, permission, etc.)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await prefs.setInt(_prefsKey, now);
    } catch (_) {
      // silent — DAU is opportunistic
    }
  }
}
