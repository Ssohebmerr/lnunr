import '../community_constants.dart';

class CommunityProfile {
  const CommunityProfile({
    required this.alias,
    this.goal,
    this.birthYear,
    this.setupComplete = false,
    this.avatarIndex = 0,
    this.photoUrl,
  });

  final String alias;
  final String? goal;
  final int? birthYear;
  final bool setupComplete;
  final int avatarIndex;
  final String? photoUrl;

  factory CommunityProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CommunityProfile(alias: '');
    return CommunityProfile(
      alias: data['communityAlias'] as String? ?? '',
      goal: data['communityGoal'] as String?,
      birthYear: data['communityBirthYear'] as int?,
      setupComplete: data['communitySetupComplete'] as bool? ?? false,
      avatarIndex: data['communityAvatarIndex'] as int? ?? 0,
      photoUrl: data['communityPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'communityAlias': alias,
        if (goal != null) 'communityGoal': goal,
        if (birthYear != null) 'communityBirthYear': birthYear,
        'communitySetupComplete': setupComplete,
        'communityAvatarIndex': avatarIndex,
        if (photoUrl != null) 'communityPhotoUrl': photoUrl,
      };

  bool get isReady {
    final year = birthYear;
    return setupComplete &&
        alias.trim().length >= 2 &&
        year != null &&
        isCommunityAdultBirthYear(year);
  }

  /// Alias already set (e.g. from app profile) — only birth year is missing.
  bool get needsBirthYearOnly =>
      alias.trim().length >= 2 && birthYear == null;

  /// Under-18 users get a read-only, protected community experience.
  bool get isMinor {
    final year = birthYear;
    if (year == null) return true;
    return DateTime.now().year - year < 18;
  }
}
