import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/ai/doctor_report_analyzer.dart';
import '../../../core/ai/models/doctor_report_enrichment.dart';
import '../../../core/ai/models/health_snapshot.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import 'cycle_report_exporter.dart';
import 'data/doctor_report_flag_text.dart';
import 'data/doctor_report_patient.dart';

enum CycleReportExportFormat { pdf, txt, csv, json }

/// Writes cycle health reports to shareable files (PDF, TXT, CSV, JSON).
class CycleReportFileExporter {
  CycleReportFileExporter._();

  static Future<File> export({
    required CycleReportExportFormat format,
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required DateTime exportedAt,
    HealthSnapshot? snapshot,
    DoctorReportMetrics? metrics,
    PatientInfo? patient,
    DoctorReportEnrichment? enrichment,
    String? reportId,
    required String exportedDateLabel,
    required bool rtl,
    String? plainText,
  }) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(exportedAt);
    final baseName = 'lune_cycle_report_$stamp';

    switch (format) {
      case CycleReportExportFormat.txt:
        return _writeText(
          dir: dir,
          name: '$baseName.txt',
          l10n: l10n,
          report: report,
          dashboard: dashboard,
          exportedDateLabel: exportedDateLabel,
          plainText: plainText,
        );
      case CycleReportExportFormat.json:
        return _writeJson(
          dir: dir,
          name: '$baseName.json',
          report: report,
          dashboard: dashboard,
          exportedAt: exportedAt,
          snapshot: snapshot,
        );
      case CycleReportExportFormat.csv:
        return _writeCsv(
          dir: dir,
          name: '$baseName.csv',
          l10n: l10n,
          report: report,
          dashboard: dashboard,
          exportedDateLabel: exportedDateLabel,
        );
      case CycleReportExportFormat.pdf:
        return _writePdf(
          dir: dir,
          name: '$baseName.pdf',
          l10n: l10n,
          report: report,
          dashboard: dashboard,
          metrics: metrics,
          patient: patient,
          enrichment: enrichment,
          reportId: reportId,
          exportedDateLabel: exportedDateLabel,
          rtl: rtl,
          plainText: plainText,
        );
    }
  }

  static Future<File> _writeText({
    required Directory dir,
    required String name,
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required String exportedDateLabel,
    String? plainText,
  }) async {
    final content = plainText ??
        CycleReportExporter.toPlainText(
          l10n: l10n,
          report: report,
          dashboard: dashboard,
          exportedDate: exportedDateLabel,
        );
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  static Future<File> _writeJson({
    required Directory dir,
    required String name,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required DateTime exportedAt,
    HealthSnapshot? snapshot,
  }) async {
    final payload = <String, dynamic>{
      'app': 'Lune',
      'exportedAt': exportedAt.toIso8601String(),
      'keyMatrix': report.keyMatrix,
      'predictionMatrix': report.predictionMatrix,
      'cycles': report.cycles.map((c) => c.toJson()).toList(),
      'symptomPatterns': report.symptomPatterns.map((p) => p.toJson()).toList(),
      if (dashboard != null)
        'dashboard': {
          'avgCycleLength': dashboard.avgCycleLength,
          'avgPeriodDuration': dashboard.avgPeriodDuration,
          'cycleRegularity': dashboard.cycleRegularity,
          'cycleRegularityStatus': dashboard.cycleRegularityStatus,
          'periodRegularity': dashboard.periodRegularity,
          'periodRegularityStatus': dashboard.periodRegularityStatus,
          'nextPeriod': dashboard.nextPeriod,
          'ovulation': dashboard.ovulation,
        },
      if (snapshot != null && !snapshot.isEmpty)
        'wellnessSnapshot': snapshot.toPromptMap(),
    };

    final file = File('${dir.path}/$name');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  static Future<File> _writeCsv({
    required Directory dir,
    required String name,
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required String exportedDateLabel,
  }) async {
    final km = report.keyMatrix;
    final pm = report.predictionMatrix;
    final dash = dashboard;
    final buf = StringBuffer();

    buf.writeln('${_cell('field')},${_cell('value')}');
    buf.writeln('${_cell(l10n.healthReportTitle)},${_cell('Lune')}');
    buf.writeln(
      '${_cell(l10n.healthReportExportedOn(exportedDateLabel))},${_cell('')}',
    );
    buf.writeln(
      '${_cell(l10n.reportAvgCycle)},${_cell(_days(km['avg_cycle_length'] ?? dash?.avgCycleLength))}',
    );
    buf.writeln(
      '${_cell(l10n.reportAvgPeriod)},${_cell(_days(km['avg_period_duration'] ?? dash?.avgPeriodDuration))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportPrevCycleLength)},${_cell(_days(km['prev_cycle_length']))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportPrevPeriodDuration)},${_cell(_days(km['prev_period_duration']))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportCycleRegularityScore)},${_cell(_score(km['cycle_regularity_score'] ?? dash?.cycleRegularity, km['cycle_regularity_score_status'] ?? dash?.cycleRegularityStatus))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportPeriodRegularityScore)},${_cell(_score(km['period_regularity_score'] ?? dash?.periodRegularity, km['period_regularity_score_status'] ?? dash?.periodRegularityStatus))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportNextPeriodDay)},${_cell(_t(pm['next_period_day'] ?? dash?.nextPeriod))}',
    );
    buf.writeln(
      '${_cell(l10n.healthReportNextOvulationDay)},${_cell(_t(pm['next_ovulation_day'] ?? dash?.ovulation))}',
    );
    buf.writeln();

    buf.writeln(
      '${_cell('cycle_start')},${_cell('period_start')},${_cell('cycle_length')},${_cell('period_duration')}',
    );
    for (final c in report.cycles) {
      buf.writeln(
        '${_cell(c.cycleStartDate ?? '')},${_cell(c.periodStartDate ?? '')},${_cell('${c.cycleLength ?? ''}')},${_cell('${c.periodDuration ?? ''}')}',
      );
    }
    buf.writeln();

    buf.writeln('${_cell('symptom')},${_cell('percent_of_cycles')}');
    for (final p in report.symptomPatterns) {
      final symptom = p.name?.trim();
      if (symptom == null || symptom.isEmpty) continue;
      buf.writeln(
        '${_cell(symptom)},${_cell('${p.percentageOfCycles ?? 0}')}',
      );
    }

    final file = File('${dir.path}/$name');
    await file.writeAsString(buf.toString());
    return file;
  }

  // Clinical letterhead palette (mirrors AuraColors in the on-screen report).
  static const _accent = PdfColor.fromInt(0xFFD484A8); // roseDeep
  static const _plum = PdfColor.fromInt(0xFF5C3D52);
  static const _amber = PdfColor.fromInt(0xFFB26A00);
  static const _amberBg = PdfColor.fromInt(0xFFFFF6EC);

  /// Builds a structured, professionally laid-out clinical PDF (letterhead,
  /// patient block, sectioned tables, amber attention panels, page numbers).
  /// Falls back to the plain-text dump only when there is no structured data.
  static Future<File> _writePdf({
    required Directory dir,
    required String name,
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    DoctorReportMetrics? metrics,
    PatientInfo? patient,
    DoctorReportEnrichment? enrichment,
    String? reportId,
    required String exportedDateLabel,
    required bool rtl,
    String? plainText,
  }) async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final startAlign =
        rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final endAlign =
        rtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end;

    final km = report.keyMatrix;
    final pm = report.predictionMatrix;
    final dash = dashboard;
    final m = metrics;
    final enrich = enrichment;
    final rid = reportId;

    pw.Widget stat(String label, String? value) {
      final v = (value == null || value.trim().isEmpty) ? '—' : value.trim();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: PdfColors.grey800),
                  textDirection: direction),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 2,
              child: pw.Text(v,
                  textAlign: rtl ? pw.TextAlign.left : pw.TextAlign.right,
                  style: pw.TextStyle(font: bold, fontSize: 10),
                  textDirection: direction),
            ),
          ],
        ),
      );
    }

    pw.Widget bullet(String text, {PdfColor? color}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ',
                style: pw.TextStyle(
                    font: regular, fontSize: 10, color: color ?? _accent)),
            pw.Expanded(
              child: pw.Text(text,
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 10,
                      color: color ?? PdfColors.black,
                      lineSpacing: 1.5),
                  textDirection: direction),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionBox(String title, List<pw.Widget> rows,
        {bool attention = false}) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: attention ? const pw.EdgeInsets.all(10) : pw.EdgeInsets.zero,
        decoration: attention
            ? pw.BoxDecoration(
                color: _amberBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _amber, width: 0.5),
              )
            : null,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    font: bold,
                    fontSize: 12,
                    color: attention ? _amber : _plum),
                textDirection: direction),
            pw.SizedBox(height: 6),
            ...rows,
          ],
        ),
      );
    }

    final sections = <pw.Widget>[];

    if (patient != null && !patient.isEmpty) {
      final rows = <pw.Widget>[];
      if (patient.hasName) {
        rows.add(stat(l10n.doctorReportPatientName, patient.name));
      }
      if (patient.age != null) {
        rows.add(stat(l10n.doctorReportPatientAge, '${patient.age}'));
      }
      if (patient.hasNote) rows.add(bullet(patient.note!.trim()));
      sections.add(sectionBox(l10n.healthReportPatientSection, rows));
    }

    if (enrich?.clinicalSummary != null &&
        enrich!.clinicalSummary!.trim().isNotEmpty) {
      sections.add(sectionBox(l10n.healthReportClinicalSummary, [
        pw.Text(enrich.clinicalSummary!.trim(),
            style:
                pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 2),
            textDirection: direction),
      ]));
    }

    if (m != null && !m.isEmpty) {
      final rows = <pw.Widget>[];
      if (m.lastPeriodStart != null) {
        rows.add(stat(l10n.healthReportLastPeriod, _isoDate(m.lastPeriodStart!)));
      }
      if (m.analyzedCycleCount > 0) {
        rows.add(stat(l10n.healthReportCyclesAnalyzed, '${m.analyzedCycleCount}'));
      }
      if (m.hasRangeData) {
        rows.add(stat(l10n.healthReportCycleLengthRange,
            '${m.minCycleLength}–${m.maxCycleLength}'));
      }
      if (m.cycleVariability != null) {
        rows.add(stat(l10n.healthReportCycleVariability, '${m.cycleVariability}'));
      }
      if (m.minPeriodDuration != null &&
          m.maxPeriodDuration != null &&
          m.minPeriodDuration != m.maxPeriodDuration) {
        rows.add(stat(l10n.healthReportPeriodLengthRange,
            '${m.minPeriodDuration}–${m.maxPeriodDuration}'));
      }
      if (m.averagePainLevel != null) {
        rows.add(stat(l10n.healthReportAveragePain,
            '${m.averagePainLevel!.toStringAsFixed(1)} / 4'));
      }
      if (rows.isNotEmpty) {
        sections.add(sectionBox(l10n.healthReportMenstrualHistory, rows));
      }
    }

    sections.add(sectionBox(l10n.healthReportCyclePeriodLength, [
      stat(l10n.reportAvgCycle,
          _days(km['avg_cycle_length'] ?? dash?.avgCycleLength)),
      stat(l10n.reportAvgPeriod,
          _days(km['avg_period_duration'] ?? dash?.avgPeriodDuration)),
      stat(
        l10n.healthReportCycleRegularityScore,
        _score(km['cycle_regularity_score'] ?? dash?.cycleRegularity,
            km['cycle_regularity_score_status'] ?? dash?.cycleRegularityStatus),
      ),
      stat(
        l10n.healthReportPeriodRegularityScore,
        _score(km['period_regularity_score'] ?? dash?.periodRegularity,
            km['period_regularity_score_status'] ??
                dash?.periodRegularityStatus),
      ),
    ]));

    final np = _t(pm['next_period_day'] ?? dash?.nextPeriod);
    final no = _t(pm['next_ovulation_day'] ?? dash?.ovulation);
    if (np.isNotEmpty || no.isNotEmpty) {
      sections.add(sectionBox(l10n.healthReportPredictions, [
        stat(l10n.healthReportNextPeriodDay, np),
        stat(l10n.healthReportNextOvulationDay, no),
      ]));
    }

    if (m != null && m.flags.isNotEmpty) {
      sections.add(sectionBox(
        l10n.healthReportPatternsToDiscuss,
        [for (final f in m.flags) bullet(DoctorReportFlagText.of(l10n, f), color: _amber)],
        attention: true,
      ));
    }

    if (report.symptomPatterns.isNotEmpty) {
      final rows = <pw.Widget>[];
      for (final p in report.symptomPatterns.take(12)) {
        final nm = p.name?.trim();
        if (nm == null || nm.isEmpty) continue;
        rows.add(stat(nm, l10n.reportPercentOfCycles(p.percentageOfCycles ?? 0)));
      }
      if (rows.isNotEmpty) {
        sections.add(sectionBox(l10n.healthReportSymptomPatternsSummary, rows));
      }
    }

    if (enrich != null && enrich.patterns.isNotEmpty) {
      sections.add(sectionBox(l10n.healthReportObservedPatterns,
          [for (final i in enrich.patterns) bullet(i)]));
    }

    if (enrich != null && enrich.discussionPoints.isNotEmpty) {
      sections.add(sectionBox(l10n.healthReportDiscussionPoints,
          [for (final i in enrich.discussionPoints) bullet(i)]));
    }

    if (enrich != null && enrich.redFlags.isNotEmpty) {
      sections.add(sectionBox(
        l10n.healthReportRedFlags,
        [for (final i in enrich.redFlags) bullet(i, color: _amber)],
        attention: true,
      ));
    }

    if (report.cycles.isNotEmpty) {
      final rows = <pw.Widget>[];
      for (final c in report.cycles.take(8)) {
        final len = c.cycleLength ?? 0;
        final start = c.periodStartDate ?? c.cycleStartDate ?? '—';
        rows.add(bullet('${l10n.healthReportDaysCycle(len)} — $start'));
      }
      sections.add(sectionBox(l10n.healthReportCycleHistorySummary, rows));
    }

    final note = enrich?.dataQualityNote?.trim();
    if (note != null && note.isNotEmpty) {
      sections.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(note,
            style: pw.TextStyle(
                font: regular,
                fontSize: 9,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic),
            textDirection: direction),
      ));
    }

    // No structured data (brand-new user) → fall back to the plain-text dump.
    if (sections.isEmpty && plainText != null && plainText.trim().isNotEmpty) {
      for (final line in plainText.split('\n')) {
        sections.add(pw.Text(line,
            style: pw.TextStyle(font: regular, fontSize: 10),
            textDirection: direction));
      }
    }

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
                    pw.Text('Lune',
                        style: pw.TextStyle(
                            font: bold, fontSize: 20, color: _accent)),
                    pw.SizedBox(height: 2),
                    pw.Text(l10n.healthReportTitle,
                        style: pw.TextStyle(
                            font: regular, fontSize: 11, color: _plum),
                        textDirection: direction),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: endAlign,
                children: [
                  if (rid != null && rid.isNotEmpty)
                    pw.Text(rid,
                        style: pw.TextStyle(
                            font: regular,
                            fontSize: 9,
                            color: PdfColors.grey700)),
                  pw.SizedBox(height: 2),
                  pw.Text(l10n.healthReportExportedOn(exportedDateLabel),
                      style: pw.TextStyle(
                          font: regular, fontSize: 9, color: PdfColors.grey700),
                      textDirection: direction),
                ],
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
                  child: pw.Text(l10n.doctorReportDisclaimer,
                      style: pw.TextStyle(
                          font: regular, fontSize: 7, color: PdfColors.grey600),
                      textDirection: direction,
                      maxLines: 2),
                ),
                pw.SizedBox(width: 12),
                pw.Text('${context.pageNumber}/${context.pagesCount}',
                    style: pw.TextStyle(
                        font: regular, fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        build: (context) => sections,
      ),
    );

    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _cell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _t(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }

  static String _days(dynamic v) {
    if (v == null) return '';
    final n = v is num ? v.round() : int.tryParse(v.toString());
    return n == null ? '' : '$n';
  }

  static String _score(dynamic score, dynamic status) {
    final s = score is double
        ? score.toStringAsFixed(1)
        : score?.toString() ?? '';
    final st = status?.toString().trim();
    if (st == null || st.isEmpty) return s;
    return '$s ($st)';
  }
}
