/// The kinds of insights the AI engine can generate. Each type has its own
/// prompt and cache slot; screens just ask for a type and render the result.
enum AiInsightType {
  /// Short daily tip (nutrition, mood, activity) tailored to the cycle phase.
  dailyTip,

  /// Emotional intelligence: interprets mood/symptom patterns for this phase.
  moodInsight,

  /// Overall cycle health read: regularity, pain trend, what to watch.
  cycleHealth,

  /// Weekly wellness summary of logs and progress.
  weeklySummary,

  /// Prenatal tip tailored to gestational week and trimester.
  prenatalTip,

  /// Conception / fertility coaching.
  conceiveTip,

  /// Avoid-pregnancy awareness and protection tips.
  avoidTip,

  /// General cycle wellness tip.
  wellnessTip,
}

class AiInsight {
  const AiInsight({
    required this.type,
    required this.text,
    required this.generatedAt,
    this.fromCache = false,
  });

  final AiInsightType type;
  final String text;
  final DateTime generatedAt;
  final bool fromCache;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory AiInsight.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    return AiInsight(
      type: AiInsightType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AiInsightType.dailyTip,
      ),
      text: json['text'] as String? ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      fromCache: fromCache,
    );
  }
}
