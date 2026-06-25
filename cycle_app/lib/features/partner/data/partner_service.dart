import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_context_engine.dart';

/// What the owner allows her partner to see.
class PartnerShareFlags {
  const PartnerShareFlags({
    this.phase = true,
    this.nextPeriod = true,
    this.pain = false,
  });

  final bool phase;
  final bool nextPeriod;
  final bool pain;

  PartnerShareFlags copyWith({bool? phase, bool? nextPeriod, bool? pain}) =>
      PartnerShareFlags(
        phase: phase ?? this.phase,
        nextPeriod: nextPeriod ?? this.nextPeriod,
        pain: pain ?? this.pain,
      );

  Map<String, dynamic> toMap() => {
        'phase': phase,
        'nextPeriod': nextPeriod,
        'pain': pain,
      };

  factory PartnerShareFlags.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PartnerShareFlags();
    return PartnerShareFlags(
      phase: data['phase'] as bool? ?? true,
      nextPeriod: data['nextPeriod'] as bool? ?? true,
      pain: data['pain'] as bool? ?? false,
    );
  }
}

/// The owner's partner link document.
class PartnerLink {
  const PartnerLink({
    required this.inviteCode,
    this.partnerUid,
    this.share = const PartnerShareFlags(),
  });

  final String inviteCode;
  final String? partnerUid;
  final PartnerShareFlags share;

  bool get isLinked => partnerUid != null;

  factory PartnerLink.fromMap(Map<String, dynamic> data) => PartnerLink(
        inviteCode: data['inviteCode'] as String? ?? '',
        partnerUid: data['partnerUid'] as String?,
        share: PartnerShareFlags.fromMap(
          (data['share'] as Map?)?.cast<String, dynamic>(),
        ),
      );
}

/// The filtered status the partner is allowed to see.
class PartnerStatus {
  const PartnerStatus({
    this.phase,
    this.cycleDay,
    this.daysUntilNextPeriod,
    this.isPeriodActive,
    this.averagePainLevel,
    this.updatedAt,
  });

  final String? phase;
  final int? cycleDay;
  final int? daysUntilNextPeriod;
  final bool? isPeriodActive;
  final double? averagePainLevel;
  final DateTime? updatedAt;

  factory PartnerStatus.fromMap(Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    return PartnerStatus(
      phase: data['phase'] as String?,
      cycleDay: data['cycleDay'] as int?,
      daysUntilNextPeriod: data['daysUntilNextPeriod'] as int?,
      isPeriodActive: data['isPeriodActive'] as bool?,
      averagePainLevel: (data['averagePainLevel'] as num?)?.toDouble(),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Partner mode: the owner shares a limited, consent-driven view of her
/// cycle with one trusted partner via a one-time invite code.
///
/// Firestore layout:
/// - `partnerLinks/{ownerUid}`  — invite code, linked partner, share flags.
/// - `partnerCodes/{code}`      — code -> owner lookup (random, unguessable).
/// - `partnerStatus/{ownerUid}` — filtered snapshot the partner may read.
class PartnerService {
  PartnerService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _prefsOwnerKey = 'partner_owner_uid';
  // No O/0/I/1 to avoid confusion when sharing the code verbally.
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String? get _uid => _auth.currentUser?.uid;

  // ---------------------------------------------------------------- owner

  Stream<PartnerLink?> watchLink() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('partnerLinks').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : PartnerLink.fromMap(data);
    });
  }

  /// Creates the link document (with a fresh invite code) when missing.
  Future<PartnerLink> ensureLink() async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final ref = _db.collection('partnerLinks').doc(uid);
    final doc = await ref.get();
    final data = doc.data();
    if (data != null && (data['inviteCode'] as String?)?.isNotEmpty == true) {
      return PartnerLink.fromMap(data);
    }

    final code = _randomCode();
    await _db.collection('partnerCodes').doc(code).set({'ownerUid': uid});
    await ref.set({
      'inviteCode': code,
      'partnerUid': null,
      'share': const PartnerShareFlags().toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return PartnerLink(inviteCode: code);
  }

  Future<PartnerLink> regenerateCode() async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final ref = _db.collection('partnerLinks').doc(uid);
    final doc = await ref.get();
    final old = doc.data()?['inviteCode'] as String?;
    if (old != null && old.isNotEmpty) {
      await _db.collection('partnerCodes').doc(old).delete();
    }

    final code = _randomCode();
    await _db.collection('partnerCodes').doc(code).set({'ownerUid': uid});
    await ref.set({
      'inviteCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updated = await ref.get();
    return PartnerLink.fromMap(updated.data()!);
  }

  Future<void> setShareFlags(PartnerShareFlags flags) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('partnerLinks').doc(uid).set({
      'share': flags.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Owner removes the linked partner and wipes the shared status.
  Future<void> unlinkPartner() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('partnerLinks').doc(uid).set({
      'partnerUid': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _db.collection('partnerStatus').doc(uid).delete();
  }

  /// Publishes the filtered status for the linked partner. No-op when
  /// signed out, unlinked, or when sharing is fully disabled.
  Future<bool> publishStatus(AiContextEngine engine) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _db.collection('partnerLinks').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    final link = PartnerLink.fromMap(data);
    if (!link.isLinked) return false;

    final snapshot = await engine.buildSnapshot();
    final share = link.share;

    int? daysUntil;
    final next = DateTime.tryParse(snapshot.nextPeriodDate ?? '');
    if (next != null) {
      daysUntil = next.difference(DateTime.now()).inDays;
      if (daysUntil < 0) daysUntil = 0;
    }

    await _db.collection('partnerStatus').doc(uid).set({
      'partnerUid': link.partnerUid,
      if (share.phase) 'phase': snapshot.currentPhase,
      if (share.phase) 'cycleDay': snapshot.currentCycleDay,
      if (share.phase) 'isPeriodActive': snapshot.isPeriodActive,
      if (share.nextPeriod && daysUntil != null)
        'daysUntilNextPeriod': daysUntil,
      if (share.pain && snapshot.averagePainLevel != null)
        'averagePainLevel': snapshot.averagePainLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  // -------------------------------------------------------------- partner

  /// Joins with the owner's invite code. Returns the owner uid.
  Future<String> joinWithCode(String rawCode) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final code = rawCode.trim().toUpperCase();
    final lookup = await _db.collection('partnerCodes').doc(code).get();
    final ownerUid = lookup.data()?['ownerUid'] as String?;
    if (ownerUid == null || ownerUid == uid) {
      throw const PartnerCodeInvalidException();
    }

    await _db.collection('partnerLinks').doc(ownerUid).update({
      'partnerUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOwnerKey, ownerUid);
    return ownerUid;
  }

  Future<String?> linkedOwnerUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsOwnerKey);
  }

  Stream<PartnerStatus?> watchPartnerStatus(String ownerUid) {
    return _db.collection('partnerStatus').doc(ownerUid).snapshots().map(
      (doc) {
        final data = doc.data();
        return data == null ? null : PartnerStatus.fromMap(data);
      },
    );
  }

  /// Partner leaves: detaches from the owner's link and clears local state.
  Future<void> leave() async {
    final uid = _uid;
    final prefs = await SharedPreferences.getInstance();
    final ownerUid = prefs.getString(_prefsOwnerKey);
    if (uid != null && ownerUid != null) {
      try {
        await _db.collection('partnerLinks').doc(ownerUid).update({
          'partnerUid': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Owner may have already unlinked or regenerated; local cleanup only.
      }
    }
    await prefs.remove(_prefsOwnerKey);
  }

  String _randomCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => _alphabet[rng.nextInt(_alphabet.length)])
        .join();
  }
}

class PartnerCodeInvalidException implements Exception {
  const PartnerCodeInvalidException();
}
