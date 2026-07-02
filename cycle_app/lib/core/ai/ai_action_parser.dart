/// Lightweight intent-parser that scans an AI reply for action tags so the
/// chat UI can offer the user one-tap "log this" buttons.
///
/// We avoid full Gemini Function Calling for now (it requires upgrading the
/// `firebase_ai` package and re-wiring streaming), and instead instruct the
/// model — via [AiPromptStyle.actionTagsRule] — to embed lightweight tags
/// like `[[log_mood:happy]]` or `[[log_symptom:cramps]]` at the END of its
/// reply when relevant. The parser strips them from the visible text and
/// returns structured [AiSuggestedAction]s for the UI to render.
library;

enum AiActionType {
  logMood,
  logSymptom,
  logWater,
  logPain,
  openLog,
  openInsights,
}

class AiSuggestedAction {
  const AiSuggestedAction({
    required this.type,
    required this.value,
    this.label,
  });

  final AiActionType type;
  final String value;
  final String? label;

  @override
  String toString() => '${type.name}:$value';
}

class AiActionParseResult {
  const AiActionParseResult({
    required this.cleanText,
    required this.actions,
  });

  final String cleanText;
  final List<AiSuggestedAction> actions;
}

class AiActionParser {
  AiActionParser._();

  // Matches [[key:value]] or [[key:value|label]]
  static final _tagRegex = RegExp(r'\[\[([a-z_]+):([^\]\|]+)(?:\|([^\]]+))?\]\]');

  /// Extracts all `[[key:value]]` tags from [reply], strips them from the
  /// text, and returns up to 3 unique [AiSuggestedAction]s ready for the UI.
  static AiActionParseResult parse(String reply) {
    final matches = _tagRegex.allMatches(reply).toList();
    if (matches.isEmpty) {
      return AiActionParseResult(cleanText: reply.trim(), actions: const []);
    }

    final actions = <AiSuggestedAction>[];
    final seen = <String>{};
    for (final m in matches) {
      final key = m.group(1)!;
      final value = m.group(2)!.trim();
      final label = m.group(3)?.trim();
      final type = _mapKey(key);
      if (type == null) continue;
      final id = '${type.name}:$value';
      if (seen.contains(id)) continue;
      seen.add(id);
      actions.add(AiSuggestedAction(type: type, value: value, label: label));
      if (actions.length >= 3) break;
    }

    final cleaned = reply.replaceAll(_tagRegex, '').trim();
    return AiActionParseResult(cleanText: cleaned, actions: actions);
  }

  static AiActionType? _mapKey(String key) => switch (key) {
        'log_mood' => AiActionType.logMood,
        'log_symptom' => AiActionType.logSymptom,
        'log_water' => AiActionType.logWater,
        'log_pain' => AiActionType.logPain,
        'open_log' => AiActionType.openLog,
        'open_insights' => AiActionType.openInsights,
        _ => null,
      };
}
