class ModerationResult {
  const ModerationResult({
    required this.approved,
    this.reason,
    this.pendingReview = false,
  });

  final bool approved;
  final String? reason;

  /// Local filter passed but cloud AI was unavailable — content awaits review.
  final bool pendingReview;
}

class ModerationRejectedException implements Exception {
  const ModerationRejectedException(this.reason);
  final String reason;
}

/// Thrown when an under-18 user tries to join, post, or comment.
/// Minors get a read-only community experience for their safety.
class MinorRestrictedException implements Exception {
  const MinorRestrictedException();
}

/// Thrown when a user is banned from community participation by an admin.
class CommunityBannedException implements Exception {
  const CommunityBannedException();
}

/// Thrown when a community has reached its member limit.
class CommunityFullException implements Exception {
  const CommunityFullException();
}

/// Thrown when a non-premium user attempts to attach media to a post.
class MediaRequiresPremiumException implements Exception {
  const MediaRequiresPremiumException();
}
