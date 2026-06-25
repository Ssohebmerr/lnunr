import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';

/// Plain-text export for copy/share from structured cycle report data.
class CycleReportExporter {
  CycleReportExporter._();

  static String toPlainText({
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required String exportedDate,
  }) {
    final buf = StringBuffer();
    final km = report.keyMatrix;
    final pm = report.predictionMatrix;
    final dash = dashboard;

    buf.writeln(l10n.healthReportTitle);
    buf.writeln(l10n.healthReportCreatedBy);
    buf.writeln(l10n.healthReportExportedOn(exportedDate));
    buf.writeln();

    buf.writeln(l10n.healthReportCyclePeriodLength);
    _line(buf, l10n.reportAvgCycle, _days(km['avg_cycle_length'] ?? dash?.avgCycleLength));
    _line(buf, l10n.reportAvgPeriod, _days(km['avg_period_duration'] ?? dash?.avgPeriodDuration));
    _line(buf, l10n.healthReportPrevCycleLength, _days(km['prev_cycle_length']));
    _line(buf, l10n.healthReportPrevPeriodDuration, _days(km['prev_period_duration']));
    _line(
      buf,
      l10n.healthReportCycleRegularityScore,
      _score(km['cycle_regularity_score'] ?? dash?.cycleRegularity,
          km['cycle_regularity_score_status'] ?? dash?.cycleRegularityStatus),
    );
    _line(
      buf,
      l10n.healthReportPeriodRegularityScore,
      _score(km['period_regularity_score'] ?? dash?.periodRegularity,
          km['period_regularity_score_status'] ?? dash?.periodRegularityStatus),
    );
    buf.writeln();

    buf.writeln(l10n.healthReportPredictions);
    _line(buf, l10n.healthReportNextPeriodDay, _t(pm['next_period_day'] ?? dash?.nextPeriod));
    _line(buf, l10n.healthReportNextOvulationDay, _t(pm['next_ovulation_day'] ?? dash?.ovulation));
    buf.writeln();

    if (report.cycles.isNotEmpty) {
      buf.writeln(l10n.healthReportCycleHistorySummary);
      for (final c in report.cycles.take(8)) {
        final len = c.cycleLength ?? 0;
        final start = c.periodStartDate ?? c.cycleStartDate ?? '—';
        buf.writeln('• ${l10n.healthReportDaysCycle(len)} — $start');
      }
      buf.writeln();
    }

    if (report.symptomPatterns.isNotEmpty) {
      buf.writeln(l10n.healthReportSymptomPatternsSummary);
      for (final p in report.symptomPatterns.take(12)) {
        final name = p.name?.trim();
        if (name == null || name.isEmpty) continue;
        buf.writeln('• $name — ${l10n.reportPercentOfCycles(p.percentageOfCycles ?? 0)}');
      }
    }

    return buf.toString().trim();
  }

  /// CSV export of cycle data for spreadsheet import.
  static String toCsv({
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required String exportedDate,
  }) {
    final buf = StringBuffer();
    final km = report.keyMatrix;
    final pm = report.predictionMatrix;
    final dash = dashboard;

    // Header
    buf.writeln('Metric,Value');
    buf.writeln('"${l10n.healthReportExportedOn(exportedDate)}",""');
    buf.writeln('"${l10n.reportAvgCycle}","${_days(km['avg_cycle_length'] ?? dash?.avgCycleLength)}"');
    buf.writeln('"${l10n.reportAvgPeriod}","${_days(km['avg_period_duration'] ?? dash?.avgPeriodDuration)}"');
    buf.writeln('"${l10n.healthReportPrevCycleLength}","${_days(km['prev_cycle_length'])}"');
    buf.writeln('"${l10n.healthReportPrevPeriodDuration}","${_days(km['prev_period_duration'])}"');
    buf.writeln('"${l10n.healthReportNextPeriodDay}","${_t(pm['next_period_day'] ?? dash?.nextPeriod)}"');
    buf.writeln('"${l10n.healthReportNextOvulationDay}","${_t(pm['next_ovulation_day'] ?? dash?.ovulation)}"');
    buf.writeln();

    // Cycle history
    if (report.cycles.isNotEmpty) {
      buf.writeln('Cycle Start,Cycle Length (days)');
      for (final c in report.cycles.take(12)) {
        final len = c.cycleLength ?? 0;
        final start = c.periodStartDate ?? c.cycleStartDate ?? '';
        buf.writeln('"$start","$len"');
      }
      buf.writeln();
    }

    // Symptom patterns
    if (report.symptomPatterns.isNotEmpty) {
      buf.writeln('Symptom,% of Cycles');
      for (final p in report.symptomPatterns.take(20)) {
        final name = p.name?.trim();
        if (name == null || name.isEmpty) continue;
        buf.writeln('"$name","${p.percentageOfCycles ?? 0}%"');
      }
    }

    return buf.toString().trim();
  }

  static void _line(StringBuffer buf, String label, String value) {
    buf.writeln('• $label: $value');
  }

  static String _t(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  static String _days(dynamic v) {
    if (v == null) return '—';
    final n = v is num ? v.round() : int.tryParse(v.toString());
    return n == null ? '—' : '$n';
  }

  static String _score(dynamic score, dynamic status) {
    final s = score is double
        ? score.toStringAsFixed(1)
        : score?.toString() ?? '—';
    final st = status?.toString().trim();
    if (st == null || st.isEmpty) return s;
    return '$s ($st)';
  }
}
