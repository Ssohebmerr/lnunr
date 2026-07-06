import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_cycle_widget/ui/model/symptoms_patterns.dart';
import 'package:menstrual_cycle_widget/utils/model/periods_date_range.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/ai/doctor_report_analyzer.dart';
import '../../../core/ai/models/doctor_report_enrichment.dart';
import '../../../core/ai/models/health_snapshot.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../data/doctor_report_flag_text.dart';
import '../data/doctor_report_patient.dart';

/// Era-style printable cycle health report (stats, history dots, symptoms, QR).
class CycleHealthReportDocument extends StatelessWidget {
  const CycleHealthReportDocument({
    super.key,
    required this.report,
    required this.dashboard,
    required this.qrPayload,
    required this.exportedAt,
    this.metrics,
    this.patient,
    this.snapshot,
    this.reportId,
    this.enrichment,
    this.refining = false,
    this.limitedData = false,
    this.limitedDataNote,
  });

  final CycleReportData report;
  final CycleDashboardData? dashboard;
  final String qrPayload;
  final DateTime exportedAt;
  final DoctorReportMetrics? metrics;
  final PatientInfo? patient;
  final HealthSnapshot? snapshot;
  final String? reportId;
  final DoctorReportEnrichment? enrichment;
  final bool refining;
  final bool limitedData;
  final String? limitedDataNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final ar = locale.languageCode == 'ar';
    final dateFmt = DateFormat.yMMMMd(locale.toString());

    final km = report.keyMatrix;
    final pm = report.predictionMatrix;
    final dash = dashboard;
    final enrich = enrichment;
    final m = metrics;
    final pt = patient;
    final snap = snapshot;
    final vitalsRows = _vitalsRows(l10n, snap);

    return Container(
      color: const Color(0xFFD4D4D4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReportHeader(
                  title: l10n.healthReportTitle,
                  createdBy: l10n.healthReportCreatedBy,
                  exportedLabel: l10n.healthReportExportedOn(
                    dateFmt.format(exportedAt),
                  ),
                  qrPayload: qrPayload,
                ),
                const SizedBox(height: 14),
                _PatientHeader(
                  patient: pt,
                  metrics: m,
                  reportId: reportId,
                  goalLabel: _goalLabel(l10n, snap),
                  ar: ar,
                  l10n: l10n,
                ),
                if (refining) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.doctorReportRefining,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (enrich?.clinicalSummary != null &&
                    enrich!.clinicalSummary!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportClinicalSummary,
                    children: [
                      Text(
                        enrich.clinicalSummary!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ],
                if (m != null && !m.isEmpty) ...[
                  const SizedBox(height: 20),
                  _ReportSection(
                    title: l10n.healthReportMenstrualHistory,
                    children: _menstrualHistoryRows(l10n, m, dateFmt, ar),
                  ),
                ],
                if (m != null && m.flags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _RedFlagSection(
                    title: l10n.healthReportPatternsToDiscuss,
                    items: [
                      for (final f in m.flags) DoctorReportFlagText.of(l10n, f),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _ReportSection(
                  title: l10n.healthReportCyclePeriodLength,
                  children: [
                    _StatRow(
                      label: l10n.reportAvgCycle,
                      value: _daysLabel(
                        km['avg_cycle_length'] ?? dash?.avgCycleLength,
                        ar,
                      ),
                    ),
                    _StatRow(
                      label: l10n.reportAvgPeriod,
                      value: _daysLabel(
                        km['avg_period_duration'] ?? dash?.avgPeriodDuration,
                        ar,
                      ),
                    ),
                    _StatRow(
                      label: l10n.healthReportPrevCycleLength,
                      value: _daysLabel(km['prev_cycle_length'], ar),
                    ),
                    _StatRow(
                      label: l10n.healthReportPrevPeriodDuration,
                      value: _daysLabel(km['prev_period_duration'], ar),
                    ),
                    _StatRow(
                      label: l10n.healthReportCycleRegularityScore,
                      value: _scoreLabel(
                        km['cycle_regularity_score'] ?? dash?.cycleRegularity,
                        km['cycle_regularity_score_status'] ??
                            dash?.cycleRegularityStatus,
                      ),
                    ),
                    _StatRow(
                      label: l10n.healthReportPeriodRegularityScore,
                      value: _scoreLabel(
                        km['period_regularity_score'] ?? dash?.periodRegularity,
                        km['period_regularity_score_status'] ??
                            dash?.periodRegularityStatus,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ReportSection(
                  title: l10n.healthReportPredictions,
                  children: [
                    _StatRow(
                      label: l10n.healthReportNextPeriodDay,
                      value: _text(
                        pm['next_period_day'] ?? dash?.nextPeriod,
                      ),
                    ),
                    _StatRow(
                      label: l10n.healthReportNextOvulationDay,
                      value: _text(pm['next_ovulation_day'] ?? dash?.ovulation),
                    ),
                  ],
                ),
                if (report.cycles.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportCycleHistorySummary,
                    children: [
                      for (var i = 0; i < report.cycles.length && i < 8; i++)
                        _CycleHistoryRow(
                          cycle: report.cycles[i],
                          isCurrent: i == 0,
                          ar: ar,
                          l10n: l10n,
                        ),
                    ],
                  ),
                ],
                if (report.symptomPatterns.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportSymptomPatternsSummary,
                    children: [
                      for (final p in report.symptomPatterns.take(12))
                        _SymptomPatternRow(pattern: p),
                    ],
                  ),
                ],
                if (_hasSymptomBurden(m, snap)) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportSymptomBurden,
                    children: _symptomBurdenRows(l10n, m, snap, ar),
                  ),
                ],
                if (enrich != null && enrich.patterns.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportObservedPatterns,
                    children: [
                      for (final item in enrich.patterns)
                        _BulletRow(text: item),
                    ],
                  ),
                ],
                if (enrich != null && enrich.discussionPoints.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportDiscussionPoints,
                    children: [
                      for (final item in enrich.discussionPoints)
                        _BulletRow(text: item),
                    ],
                  ),
                ],
                if (enrich != null && enrich.redFlags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _RedFlagSection(
                    title: l10n.healthReportRedFlags,
                    items: enrich.redFlags,
                  ),
                ],
                if (vitalsRows.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReportSection(
                    title: l10n.healthReportVitalsAdherence,
                    children: vitalsRows,
                  ),
                ],
                const SizedBox(height: 20),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                const SizedBox(height: 8),
                if (enrich?.dataQualityNote != null &&
                    enrich!.dataQualityNote!.trim().isNotEmpty) ...[
                  Text(
                    enrich.dataQualityNote!.trim(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else if (limitedData && limitedDataNote != null) ...[
                  Text(
                    limitedDataNote!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  l10n.healthReportFooter,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.doctorReportDisclaimer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _goalLabel(AppLocalizations l10n, HealthSnapshot? snap) {
    if (snap != null && snap.isPregnancyMode) {
      return l10n.healthReportModePregnancy;
    }
    return l10n.healthReportModeCycle;
  }

  static List<Widget> _menstrualHistoryRows(
    AppLocalizations l10n,
    DoctorReportMetrics m,
    DateFormat dateFmt,
    bool ar,
  ) {
    final rows = <Widget>[];
    if (m.lastPeriodStart != null) {
      rows.add(_StatRow(
        label: l10n.healthReportLastPeriod,
        value: dateFmt.format(m.lastPeriodStart!),
      ));
    }
    if (m.firstCycleDate != null && m.lastCycleDate != null) {
      rows.add(_StatRow(
        label: l10n.healthReportDataPeriod,
        value: '${dateFmt.format(m.firstCycleDate!)} — '
            '${dateFmt.format(m.lastCycleDate!)}',
      ));
    }
    if (m.analyzedCycleCount > 0) {
      rows.add(_StatRow(
        label: l10n.healthReportCyclesAnalyzed,
        value: '${m.analyzedCycleCount}',
      ));
    }
    if (m.hasRangeData) {
      rows.add(_StatRow(
        label: l10n.healthReportCycleLengthRange,
        value: _rangeLabel(m.minCycleLength!, m.maxCycleLength!, ar),
      ));
    }
    if (m.cycleVariability != null) {
      rows.add(_StatRow(
        label: l10n.healthReportCycleVariability,
        value: _daysLabel(m.cycleVariability, ar),
      ));
    }
    if (m.minPeriodDuration != null &&
        m.maxPeriodDuration != null &&
        m.minPeriodDuration != m.maxPeriodDuration) {
      rows.add(_StatRow(
        label: l10n.healthReportPeriodLengthRange,
        value: _rangeLabel(m.minPeriodDuration!, m.maxPeriodDuration!, ar),
      ));
    }
    return rows;
  }

  static bool _hasSymptomBurden(DoctorReportMetrics? m, HealthSnapshot? snap) {
    return (m?.averagePainLevel != null) ||
        (snap != null && snap.wellnessLogCount > 0);
  }

  static List<Widget> _symptomBurdenRows(
    AppLocalizations l10n,
    DoctorReportMetrics? m,
    HealthSnapshot? snap,
    bool ar,
  ) {
    final rows = <Widget>[];
    final pain = m?.averagePainLevel;
    if (pain != null) {
      rows.add(_StatRow(
        label: l10n.healthReportAveragePain,
        value: '${pain.toStringAsFixed(1)} / 4',
      ));
    }
    if (snap != null && snap.wellnessLogCount > 0) {
      rows.add(_StatRow(
        label: l10n.healthReportWellnessEntries,
        value: '${snap.wellnessLogCount}',
      ));
    }
    return rows;
  }

  static List<Widget> _vitalsRows(AppLocalizations l10n, HealthSnapshot? snap) {
    if (snap == null) return const [];
    final rows = <Widget>[];
    final hub = snap.wellnessHub;

    final vitals = hub['dailyVitals'];
    if (vitals is Map) {
      final weight = vitals['latestWeight'];
      if (weight != null && weight.toString().trim().isNotEmpty) {
        rows.add(_StatRow(
          label: l10n.healthReportLatestWeight,
          value: weight.toString().trim(),
        ));
      }
      final temp = vitals['latestBodyTemperature'];
      if (temp != null && temp.toString().trim().isNotEmpty) {
        rows.add(_StatRow(
          label: l10n.healthReportLatestTemperature,
          value: temp.toString().trim(),
        ));
      }
      final water = vitals['avgWaterLast30Days'];
      if (water != null) {
        final unit = (vitals['waterUnit'] ?? '').toString().trim();
        rows.add(_StatRow(
          label: l10n.healthReportAvgWater,
          value: '$water $unit'.trim(),
        ));
      }
    }

    final pills = hub['birthControlPills'];
    if (pills is Map && pills['active'] == true) {
      final taken = pills['takenLast7Days'];
      final scheduled = pills['scheduledLast7Days'];
      if (taken != null && scheduled is num && scheduled > 0) {
        rows.add(_StatRow(
          label: l10n.healthReportPillAdherence,
          value: '$taken / $scheduled',
        ));
      }
    }

    return rows;
  }

  static String _rangeLabel(int min, int max, bool ar) =>
      ar ? '$min–$max يوم' : '$min–$max days';

  static String _text(dynamic v) {
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  static String _daysLabel(dynamic days, bool ar) {
    if (days == null) return '—';
    final n = days is num ? days.round() : int.tryParse(days.toString());
    if (n == null) return '—';
    return ar ? '$n يوم' : '$n days';
  }

  static String _scoreLabel(dynamic score, dynamic status) {
    final s = score is double
        ? score.toStringAsFixed(1)
        : score?.toString() ?? '—';
    final st = status?.toString().trim();
    if (st == null || st.isEmpty) return s;
    return '$s ($st)';
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Official-looking patient identity block at the top of the report.
class _PatientHeader extends StatelessWidget {
  const _PatientHeader({
    required this.patient,
    required this.metrics,
    required this.reportId,
    required this.goalLabel,
    required this.ar,
    required this.l10n,
  });

  final PatientInfo? patient;
  final DoctorReportMetrics? metrics;
  final String? reportId;
  final String goalLabel;
  final bool ar;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pt = patient;
    final rows = <Widget>[];

    if (pt != null && pt.hasName) {
      rows.add(_kv(theme, l10n.doctorReportPatientName, pt.name!.trim(),
          emphasize: true));
    }
    if (pt?.age != null) {
      rows.add(_kv(
        theme,
        l10n.doctorReportPatientAge,
        ar ? '${pt!.age} سنة' : '${pt!.age} yrs',
      ));
    }
    rows.add(_kv(theme, l10n.healthReportMode, goalLabel));
    if (reportId != null && reportId!.isNotEmpty) {
      rows.add(_kv(theme, l10n.healthReportReportId, reportId!));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuraColors.blush.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AuraColors.roseDeep.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: AuraColors.roseDeep),
              const SizedBox(width: 6),
              Text(
                l10n.healthReportPatientSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
          if (pt != null && pt.hasNote) ...[
            const SizedBox(height: 4),
            Text(
              l10n.doctorReportPatientNote,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pt.note!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(ThemeData theme, String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber attention panel used for both on-device clinical flags and the AI's
/// "worth mentioning" list. Never diagnostic — framed as discussion prompts.
class _RedFlagSection extends StatelessWidget {
  const _RedFlagSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  static const _accent = Color(0xFFB26A00);
  static const _accentDeep = Color(0xFF8A5200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0A34E).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _accentDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.flag_outlined, size: 13, color: _accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({
    required this.title,
    required this.createdBy,
    required this.exportedLabel,
    required this.qrPayload,
  });

  final String title;
  final String createdBy;
  final String exportedLabel;
  final String qrPayload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: QrImageView(
            data: qrPayload,
            version: QrVersions.auto,
            size: 72,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black87,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AuraColors.roseDeep,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                createdBy,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exportedLabel,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.event_note_outlined, size: 18, color: AuraColors.roseDeep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CustomPaint(
            painter: _DottedLinePainter(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
            child: const SizedBox(height: 1, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CycleHistoryRow extends StatelessWidget {
  const _CycleHistoryRow({
    required this.cycle,
    required this.isCurrent,
    required this.ar,
    required this.l10n,
  });

  final PeriodsDateRange cycle;
  final bool isCurrent;
  final bool ar;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final length = (cycle.cycleLength ?? 0).clamp(1, 35);
    final period = (cycle.periodDuration ?? 0).clamp(0, length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.healthReportDaysCycle(length),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _CycleDotsRow(cycleLength: length, periodDays: period),
          const SizedBox(height: 4),
          Text(
            _dateRange(cycle, isCurrent, ar, l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _dateRange(
    PeriodsDateRange c,
    bool current,
    bool ar,
    AppLocalizations l10n,
  ) {
    final start = _shortDate(c.periodStartDate ?? c.cycleStartDate, ar);
    if (current) {
      return '$start - ${l10n.healthReportUntilNow}';
    }
    final end = _shortDate(c.cycleEndDate ?? c.periodEndDate, ar);
    if (start.isEmpty && end.isEmpty) return '—';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  String _shortDate(String? raw, bool ar) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    if (ar) {
      const months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      final m = months[parsed.month - 1];
      return '$m ${parsed.day.toString().padLeft(2, '0')}';
    }
    return DateFormat('MMM dd').format(parsed);
  }
}

class _CycleDotsRow extends StatelessWidget {
  const _CycleDotsRow({
    required this.cycleLength,
    required this.periodDays,
  });

  final int cycleLength;
  final int periodDays;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(cycleLength, (i) {
          final isPeriod = i < periodDays;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPeriod ? AuraColors.roseDeep : Colors.black87,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SymptomPatternRow extends StatelessWidget {
  const _SymptomPatternRow({required this.pattern});

  final SymptomsPatterns pattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final name = pattern.name?.trim();
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final pct = (pattern.percentageOfCycles ?? 0).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: theme.textTheme.bodySmall),
              ),
              Text(
                l10n.reportPercentOfCycles(pct),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AuraColors.blush.withValues(alpha: 0.5),
              color: AuraColors.roseDeep,
            ),
          ),
        ],
      ),
    );
  }
}
