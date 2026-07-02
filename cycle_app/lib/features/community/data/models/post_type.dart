enum PostType {
  support('support'),
  question('question'),
  tip('tip'),
  vent('vent'),
  milestone('milestone'),
  poll('poll');

  const PostType(this.value);
  final String value;

  static PostType fromValue(String? raw) {
    return PostType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => PostType.support,
    );
  }
}
