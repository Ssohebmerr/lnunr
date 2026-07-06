/// Aggregated live reactions on a post (stored on the like docs).
class PostReactions {
  const PostReactions({
    this.total = 0,
    this.counts = const {},
    this.myReaction,
  });

  final int total;

  /// Reaction kind (`heart`/`hug`/`celebrate`/`strong`) → count.
  final Map<String, int> counts;

  /// The viewer's reaction kind, or null if they haven't reacted.
  final String? myReaction;

  bool get hasReacted => myReaction != null;

  int countFor(String kind) => counts[kind] ?? 0;
}
