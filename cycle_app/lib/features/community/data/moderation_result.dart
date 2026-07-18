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

/// The image scanner was unavailable, so unchecked media was not published.
class MediaReviewUnavailableException implements Exception {
  const MediaReviewUnavailableException();
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

/// A media entitlement error returned by a deployed community endpoint.
class MediaRequiresPremiumException implements Exception {
  const MediaRequiresPremiumException();
}
