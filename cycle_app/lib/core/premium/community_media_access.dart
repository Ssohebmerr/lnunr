import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'premium_status_notifier.dart';
import '../storage/user_prefs.dart';

/// Resolves the client-side entitlement for community image uploads.
///
/// Firebase Storage and the submission Function repeat this check using
/// trusted server data. This helper only keeps the picker UX in sync with
/// those authoritative checks.
class CommunityMediaAccess {
  const CommunityMediaAccess._();

  static Future<bool> canUpload({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    if (await UserPrefs.isPremium()) return true;

    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return false;

    try {
      // A Premium grant can reach Firestore before the app-wide listener has
      // refreshed SharedPreferences. Read the authoritative server value so
      // the media picker does not incorrectly show the Premium paywall.
      final userDoc = await (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final isPremium = userDoc.data()?['isPremium'] == true;
      await PremiumStatusNotifier.instance.applyRemote(isPremium);
      return isPremium;
    } catch (_) {
      // Storage and the submission Function enforce Premium again. Fail
      // closed when the authoritative status cannot be refreshed.
      return false;
    }
  }
}
