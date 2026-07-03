/// Role for a single conversation turn passed to a Gemini multi-turn chat.
enum AiTurnRole { user, model }

/// A single conversation turn (user or model). Used by AI services to
/// support proper multi-turn memory instead of stuffing history into the
/// user message.
class AiTurn {
  const AiTurn({required this.role, required this.text});

  final AiTurnRole role;
  final String text;

  AiTurn.user(this.text) : role = AiTurnRole.user;
  AiTurn.model(this.text) : role = AiTurnRole.model;

  @override
  String toString() => '${role.name}: $text';
}
