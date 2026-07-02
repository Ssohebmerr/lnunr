import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/ai/models/health_snapshot.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import 'cycle_report_exporter.dart';

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

  static Future<File> _writePdf({
    required Directory dir,
    required String name,
    required AppLocalizations l10n,
    required CycleReportData report,
    CycleDashboardData? dashboard,
    required String exportedDateLabel,
    required bool rtl,
    String? plainText,
  }) async {
    final plain = plainText ??
        CycleReportExporter.toPlainText(
          l10n: l10n,
          report: report,
          dashboard: dashboard,
          exportedDate: exportedDateLabel,
        );

    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final direction =
        rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final body = <pw.Widget>[];
    final lines = plain.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        body.add(pw.SizedBox(height: 8));
        continue;
      }

      final nextHasBullet =
          i + 1 < lines.length && lines[i + 1].trimLeft().startsWith('•');
      final isSection = !line.trimLeft().startsWith('•') &&
          (nextHasBullet || i == 0);

      body.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
            line,
            style: pw.TextStyle(
              font: isSection ? bold : regular,
              fontSize: isSection ? 13 : 11,
            ),
            textDirection: direction,
          ),
        ),
      );
    }

    body.add(pw.SizedBox(height: 16));
    body.add(
      pw.Text(
        l10n.doctorReportDisclaimer,
        style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700),
        textDirection: direction,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(40)),
        textDirection: direction,
        build: (context) => body,
      ),
    );

    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await doc.save());
    return file;
  }

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
