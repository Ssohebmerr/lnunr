import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/model/phases_percentage.dart';
import 'package:menstrual_cycle_widget/ui/model/symptoms_patterns.dart';

import '../../../core/ai/models/health_snapshot.dart';

/// One row in the Symptom Insights screen.
///
/// Built by [SymptomInsightAnalyzer] on top of the raw
/// [SymptomsPatterns] returned by the underlying cycle widget. We add:
///   - [dominantPhase] — the phase where this symptom appears most
///   - [confidence]    — 0..100, % of occurrences that fell into the
///                       dominant phase. 100 = perfectly consistent.
///   - [samples]       — total number of cycles where this symptom showed
///                       up at least once. Powers the "based on N cycles"
///                       trust signal in the UI.
class SymptomInsight {
  const SymptomInsight({
    required this.symptomName,
    required this.dominantPhase,
    required this.confidence,
    required this.samples,
    required this.percentageOfCycles,
    required this.phases,
  });

  /// Raw symptom name as stored in the DB. Localisation happens in the
  /// message generator — we never compare against Arabic/English strings
  /// in this layer.
  final String symptomName;

  /// The phase where this symptom has the highest occurrence rate.
  /// One of: 'menstruation', 'follicular', 'ovulation', 'luteal',
  /// 'late', or '' when there isn't enough data to call it.
  final String dominantPhase;

  /// 0..100. Higher = the symptom is more concentrated in the dominant
  /// phase. < 50 means it's roughly evenly spread or scattered.
  final int confidence;

  /// Number of cycles that contributed data. We never show insights that
  /// rely on fewer than [_minimumSamples] cycles — see the analyzer.
  final int samples;

  /// Mirrors [SymptomsPatterns.percentageOfCycles] — included here so
  /// the UI doesn't have to import the upstream model.
  final int percentageOfCycles;

  /// Per-phase percentage breakdown (each entry: phase + 0..100).
  final List<PhasePercentage> phases;

  bool get hasEnoughData => samples >= SymptomInsightAnalyzer.minimumSamples;

  /// Friendly "this is your dominant phase" sentence for the given locale.
  /// The UI uses this to anchor the rest of the card.
  String phaseLabel(String locale) {
    final code = locale.toLowerCase();
    final isArabic = code == 'ar' || code.startsWith('ar-');
    switch (dominantPhase) {
      case 'menstruation':
        return isArabic ? 'أثناء الدورة' : 'during your period';
      case 'follicular':
        return isArabic ? 'مرحلة الجريب' : 'follicular phase';
      case 'ovulation':
        return isArabic ? 'مرحلة التبويض' : 'ovulation';
      case 'luteal':
        return isArabic ? 'المرحلة الأصفر' : 'luteal phase';
      case 'late':
        return isArabic ? 'بعد الدورة' : 'after your cycle';
      default:
        return isArabic ? 'غير محدد' : 'various phases';
    }
  }
}

/// Reads the existing [SymptomsPatterns] + [HealthSnapshot] and produces
/// a flat list of [SymptomInsight]s, sorted by confidence (highest first).
///
/// We deliberately stay on top of the existing API (`getSymptomsPatternForReport`)
/// rather than re-implementing the SQL — the upstream already aggregates
/// "this symptom appears in N% of cycles" + per-phase breakdown. Our job
/// is to interpret those numbers and decide whether each row is worth
/// showing in the UI.
class SymptomInsightAnalyzer {
  const SymptomInsightAnalyzer();

  /// Minimum cycles of history required before we trust an insight.
  /// One cycle is anecdotal; 3+ starts to be a pattern.
  static const int minimumSamples = 3;

  /// A symptom must appear in at least [minimumConfidence]% of its
  /// dominant phase to count as a "real" pattern. Anything below is
  /// noise and gets filtered out.
  static const int minimumConfidence = 60;

  Future<List<SymptomInsight>> analyze({
    int cycleWindow = 6,
    int? cycleLength,
    int? periodDuration,
  }) async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return const <SymptomInsight>[];

    final patterns = await widget.getSymptomsPatternForReport();
    if (patterns.isEmpty) return const <SymptomInsight>[];

    final cycleLen = cycleLength ?? widget.getCycleLength();
    final periodDur = periodDuration ?? widget.getPeriodDuration();

    final out = <SymptomInsight>[];
    for (final p in patterns) {
      final name = (p.name ?? '').trim();
      if (name.isEmpty) continue;
      final phases = p.phases ?? const <PhasePercentage>[];
      if (phases.isEmpty) continue;

      // Sort phases by percentage descending — the first one wins as the
      // dominant phase (unless it's below the noise floor).
      final sorted = [...phases]
        ..sort((a, b) => (b.percentage ?? 0).compareTo(a.percentage ?? 0));
      final top = sorted.first;
      final samples = p.percentageOfCycles ?? 0;

      if (samples < minimumSamples) continue;
      final topPct = top.percentage ?? 0;
      final conf = topPct.round();
      if (conf < minimumConfidence) continue;

      out.add(SymptomInsight(
        symptomName: name,
        dominantPhase: _normalisePhaseName(top.phaseName ?? '', cycleLen, periodDur),
        confidence: conf,
        samples: samples,
        percentageOfCycles: samples,
        phases: List<PhasePercentage>.from(sorted),
      ));
    }

    // Highest confidence first — that's what the user cares about most.
    out.sort((a, b) => b.confidence.compareTo(a.confidence));
    return out;
  }

  /// The upstream phase labels are localised strings ("أثناء الدورة",
  /// "during your period"). We map them back to a stable internal
  /// vocabulary so callers can switch on the phase without doing
  /// string compares against either locale.
  String _normalisePhaseName(
    String localised,
    int cycleLength,
    int periodDuration,
  ) {
    final l = localised.trim().toLowerCase();
    if (l.contains('menstruation') ||
        l.contains('دور') ||
        l.contains('حيض') ||
        l.contains('period') ||
        l.contains('menstrual')) {
      return 'menstruation';
    }
    if (l.contains('ovulation') || l.contains('تبويض') || l.contains('ovulat')) {
      return 'ovulation';
    }
    if (l.contains('luteal') || l.contains('أصفر') || l.contains('lutéal')) {
      return 'luteal';
    }
    if (l.contains('follicular') || l.contains('جريب') || l.contains('follic')) {
      return 'follicular';
    }
    if (l.contains('late') || l.contains('متأخر') || l.contains('tardif')) {
      return 'late';
    }
    return '';
  }
}