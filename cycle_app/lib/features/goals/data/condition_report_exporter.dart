import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import 'condition_catalog.dart';
import 'condition_log_store.dart';
import 'goal_mode_content.dart';

/// Builds the shareable "doctor report" PDF for the life-stage condition
/// goals (menopause / PCOS / postpartum): the daily logs captured on Home
/// (hot flashes, mood, symptoms, rituals) summarised alongside basic cycle
/// stats, in the same clinical letterhead style as the general cycle report
/// (see CycleReportFileExporter).
class ConditionReportExporter {
  ConditionReportExporter._();

  // Same palette as the general clinical report.
  static const _accent = PdfColor.fromInt(0xFFD484A8); // roseDeep
  static const _plum = PdfColor.fromInt(0xFF5C3D52);
  static const _barBg = PdfColor.fromInt(0xFFEFE6EC);

  static Future<File> exportPdf({
    required AppLocalizations l10n,
    required UserGoalTypes goal,
    required CycleDashboardData data,
    required String lang,
    required bool rtl,
    required DateTime exportedAt,
    required String exportedDateLabel,
  }) async {
    // Logged history — the whole point of the report.
    final symptoms30 = await ConditionLogStore.symptomHistory(days: 30);
    final rituals7 = await ConditionLogStore.ritualHistory(days: 7);
    final metricName = switch (goal) {
      UserGoalTypes.menopause => ConditionLogStore.metricHotFlash,
      UserGoalTypes.postpartum => ConditionLogStore.metricMood,
      _ => null,
    };
    final metric14 = metricName == null
        ? <String, int>{}
        : await ConditionLogStore.metricHistory(metricName, days: 14);

    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final startAlign = rtl
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;

    final goalTitle = switch (goal) {
      UserGoalTypes.menopause => l10n.goalMenopauseTitle,
      UserGoalTypes.pcos => l10n.goalPcosTitle,
      _ => l10n.postpartumJourneyTitle,
    };

    pw.Widget stat(String label, String? value) {
      final v = (value == null || value.trim().isEmpty) ? '—' : value.trim();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
                textDirection: direction,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                v,
                textAlign: rtl ? pw.TextAlign.left : pw.TextAlign.right,
                style: pw.TextStyle(font: bold, fontSize: 10),
                textDirection: direction,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionBox(String title, List<pw.Widget> rows) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(font: bold, fontSize: 12, color: _plum),
              textDirection: direction,
            ),
            pw.SizedBox(height: 6),
            ...rows,
          ],
        ),
      );
    }

    // ── Overview ─────────────────────────────────────────────────────────
    final sections = <pw.Widget>[
      sectionBox(l10n.conditionReportOverview, [
        stat(l10n.conditionReportGoalLabel, goalTitle),
        stat(l10n.reportAvgCycle, '${data.avgCycleLength}'),
        stat(l10n.homeRegularity, '${data.cycleRegularity.round()}%'),
        if (goal == UserGoalTypes.menopause)
          stat(l10n.menopauseDaysSincePeriodTitle, '${data.cycleDay}')
        else
          stat(l10n.reportCycleDay, '${data.cycleDay}'),
        stat(l10n.reportTotalCycles, '${data.totalCycles}'),
      ]),
    ];

    final hasLogs =
        symptoms30.isNotEmpty || rituals7.isNotEmpty || metric14.isNotEmpty;

    if (!hasLogs) {
      sections.add(
        pw.Text(
          l10n.conditionReportNoLogs,
          style: pw.TextStyle(
            font: regular,
            fontSize: 10,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
          textDirection: direction,
        ),
      );
    } else {
      // ── 14-day chart ───────────────────────────────────────────────────
      final now = DateTime.now();
      final days = List.generate(
        14,
        (i) => now.subtract(Duration(days: 13 - i)),
      );
      final values = switch (goal) {
        UserGoalTypes.pcos => days
            .map((d) =>
                symptoms30[ConditionLogStore.dayKey(d)]?.length ?? 0)
            .toList(),
        _ => days
            .map((d) => metric14[ConditionLogStore.dayKey(d)] ?? 0)
            .toList(),
      };
      final chartTitle = switch (goal) {
        UserGoalTypes.menopause => l10n.conditionTrendHotFlashes,
        UserGoalTypes.postpartum => l10n.conditionTrendMood,
        _ => l10n.conditionTrendSymptomsPerDay,
      };
      final dataMax = values.reduce((a, b) => a > b ? a : b);
      final max = goal == UserGoalTypes.postpartum
          ? 5
          : (dataMax > 0 ? dataMax : 1);
      final rangeFmt = DateFormat.MMMd(lang);
      final rangeLabel =
          '${rangeFmt.format(days.first)} – ${rangeFmt.format(days.last)}';

      sections.add(
        sectionBox('$chartTitle · $rangeLabel', [
          pw.Container(
            height: 64,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) pw.SizedBox(width: 3),
                  pw.Expanded(
                    child: pw.Container(
                      height: values[i] == 0
                          ? 2.0
                          : 6 + (values[i] / max).clamp(0.0, 1.0) * 56,
                      decoration: pw.BoxDecoration(
                        color: values[i] == 0 ? _barBg : _accent,
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '0–$max',
            style: pw.TextStyle(
              font: regular,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ]),
      );

      // ── Most frequent symptoms (30 days) ──────────────────────────────
      final labels = ConditionCatalog.symptomLabels(goal, lang);
      final counts = <String, int>{};
      for (final set in symptoms30.values) {
        for (final slug in set) {
          counts[slug] = (counts[slug] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        final top = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        sections.add(
          sectionBox('${l10n.conditionTopSymptoms} · ${l10n.conditionTrendLast30Days}', [
            for (final e in top.take(8))
              stat(
                labels[e.key] ?? e.key.replaceAll('_', ' '),
                l10n.conditionReportTimes(e.value),
              ),
          ]),
        );
      }

      // ── Consistency ────────────────────────────────────────────────────
      final loggedDays = <String>{
        ...symptoms30.keys,
        ...metric14.keys,
        ...rituals7.keys,
      }.length;
      final catalogSize = GoalModeContent.rituals(goal).length;
      final ritualsDone =
          rituals7.values.fold<int>(0, (sum, set) => sum + set.length);
      final completion = catalogSize == 0
          ? 0
          : ((ritualsDone / (catalogSize * 7)) * 100).clamp(0, 100).round();

      sections.add(
        sectionBox(l10n.conditionReportConsistency, [
          stat(l10n.conditionDaysLogged, '$loggedDays/30'),
          stat(
            '${l10n.conditionRitualCompletion} · ${l10n.conditionTrendLast7Days}',
            '$completion%',
          ),
        ]),
      );
    }

    // ── Document ─────────────────────────────────────────────────────────
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 40),
          textDirection: direction,
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _accent, width: 1.2),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: startAlign,
                  children: [
                    pw.Text(
                      'Lune',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 20,
                        color: _accent,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${l10n.conditionReportTitle} — $goalTitle',
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 11,
                        color: _plum,
                      ),
                      textDirection: direction,
                    ),
                  ],
                ),
              ),
              pw.Text(
                l10n.healthReportExportedOn(exportedDateLabel),
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
                textDirection: direction,
              ),
            ],
          ),
        ),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    l10n.doctorReportDisclaimer,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                    textDirection: direction,
                    maxLines: 2,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  '${context.pageNumber}/${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (context) => sections,
      ),
    );

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(exportedAt);
    final file = File('${dir.path}/lune_condition_report_$stamp.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
