/// A user's membership in a community (from Firestore `communityMemberships`).
class CommunityMembership {
  const CommunityMembership({
    required this.communityId,
    this.joinedAt,
  });

  final String communityId;
  final DateTime? joinedAt;
}
