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
  static final _tagRegex =
      RegExp(r'\[\[([a-z_]+):([^\]\|]+)(?:\|([^\]]+))?\]\]');

  // Matches bare navigation tags like [[open_log]] or [[open_insights]]
  static final _bareTagRegex = RegExp(r'\[\[(open_log|open_insights)\]\]');

  static final _truncatedSuffix = RegExp(
    r'(\n\s*)?(\.\.\.\s*)?\[response truncated\]\s*$',
    multiLine: true,
    caseSensitive: false,
  );

  static final _stoppedSuffix = RegExp(
    r'\n?\s*\[response stopped:[^\]]+\]\s*$',
    multiLine: true,
    caseSensitive: false,
  );

  /// Meta strings the model or gateway may leak anywhere in the reply.
  static final _truncatedAnywhere = RegExp(
    r'\[response truncated\]',
    caseSensitive: false,
  );

  static final _stoppedAnywhere = RegExp(
    r'\[response stopped:[^\]]+\]',
    caseSensitive: false,
  );

  /// Any remaining `[[...]]` block (known or unknown action tags).
  static final _anyDoubleBracket = RegExp(r'\[\[[^\]]*\]\]?');

  /// Lone `[open_log]`-style tags without double brackets.
  static final _loneBracketTag = RegExp(
    r'\[(?:open_log|open_insights|response[^\]]*)\]',
    caseSensitive: false,
  );

  static final _incompleteTagSuffix = RegExp(r'\[\[[^\]]*$');

  static final _zeroWidth = RegExp(r'[\u200B-\u200D\uFEFF]');

  /// Strips action tags, internal meta messages, and incomplete trailing tags
  /// so AI replies never leak English system strings to the UI.
  static String sanitizeForDisplay(String reply) {
    if (reply.isEmpty) return reply;

    var text = reply.replaceAll(_zeroWidth, '');
    text = _stripMetaMessages(text);
    text = text.replaceAll(_truncatedAnywhere, '');
    text = text.replaceAll(_stoppedAnywhere, '');
    text = text.replaceAll(_tagRegex, '');
    text = text.replaceAll(_bareTagRegex, '');
    text = text.replaceAll(_anyDoubleBracket, '');
    text = text.replaceAll(_loneBracketTag, '');
    text = text.replaceAll(_incompleteTagSuffix, '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return text.trim();
  }

  /// Extracts all action tags from [reply], strips them (and any internal
  /// meta suffixes) from the text, and returns up to 3 unique actions.
  static AiActionParseResult parse(String reply) {
    final actions = _extractActions(reply);
    final cleaned = sanitizeForDisplay(reply);
    return AiActionParseResult(cleanText: cleaned, actions: actions);
  }

  static List<AiSuggestedAction> _extractActions(String reply) {
    final pending = <({int start, String key, String value, String? label})>[];

    for (final m in _tagRegex.allMatches(reply)) {
      pending.add((
        start: m.start,
        key: m.group(1)!,
        value: m.group(2)!.trim(),
        label: m.group(3)?.trim(),
      ));
    }
    for (final m in _bareTagRegex.allMatches(reply)) {
      pending.add((
        start: m.start,
        key: m.group(1)!,
        value: '',
        label: null,
      ));
    }
    pending.sort((a, b) => a.start.compareTo(b.start));

    final actions = <AiSuggestedAction>[];
    final seen = <String>{};
    for (final item in pending) {
      _addAction(
        actions,
        seen,
        key: item.key,
        value: item.value,
        label: item.label,
      );
    }
    return actions;
  }

  static void _addAction(
    List<AiSuggestedAction> actions,
    Set<String> seen, {
    required String key,
    required String value,
    String? label,
  }) {
    if (actions.length >= 3) return;
    final type = _mapKey(key);
    if (type == null) return;
    final id = '${type.name}:$value';
    if (seen.contains(id)) return;
    seen.add(id);
    actions.add(AiSuggestedAction(type: type, value: value, label: label));
  }

  static String _stripMetaMessages(String text) {
    var t = text;
    while (_truncatedSuffix.hasMatch(t)) {
      t = t.replaceFirst(_truncatedSuffix, '');
    }
    while (_stoppedSuffix.hasMatch(t)) {
      t = t.replaceFirst(_stoppedSuffix, '');
    }
    return t;
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
