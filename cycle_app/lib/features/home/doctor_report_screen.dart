import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_insights_service.dart';
import '../../../core/ai/doctor_report_analyzer.dart';
import '../../../core/ai/models/doctor_report_enrichment.dart';
import '../../../core/ai/models/health_snapshot.dart';
import '../../../core/privacy/privacy_constants.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import 'cycle_report_exporter.dart';
import 'cycle_report_file_exporter.dart';
import 'data/doctor_report_patient.dart';
import 'widgets/cycle_health_report_document.dart';
import 'widgets/doctor_report_patient_sheet.dart';
import 'widgets/report_export_sheet.dart';

/// Structured monthly cycle report with QR — similar to professional health apps.
class DoctorReportScreen extends StatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  final _bridge = CycleBridgeService();

  CycleReportData? _report;
  CycleDashboardData? _dashboard;
  HealthSnapshot? _snapshot;
  DoctorReportMetrics? _metrics;
  PatientInfo _patient = const PatientInfo();
  String? _reportId;
  DoctorReportEnrichment? _enrichment;
  String? _plainText;
  bool _loading = true;
  bool _failed = false;
  bool _limitedData = false;
  bool _refining = false;
  late DateTime _exportedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    if (MenstrualCycleWidget.instance == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }

    _exportedAt = DateTime.now();
    final engine = context.read<AiContextEngine>();
    final dashboard = await _bridge.tryLoadDashboard();
    final loadedReport = await _bridge.tryLoadStructuredReport();
    final patient = await DoctorReportPatientStore.load();
    HealthSnapshot snapshot = const HealthSnapshot();
    try {
      snapshot = await engine.buildSnapshot();
    } catch (_) {}

    if (!mounted) return;

    final report = loadedReport ??
        const CycleReportData(
          keyMatrix: {},
          predictionMatrix: {},
          cycles: [],
          symptomPatterns: [],
        );

    final metrics = DoctorReportAnalyzer.analyze(
      report: report,
      snapshot: snapshot.isEmpty ? null : snapshot,
      patientAge: patient.age,
    );

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFmt = DateFormat.yMMMMd(locale.toString());
    final exportedLabel = dateFmt.format(_exportedAt);
    final reportId = 'LN-${DateFormat('yyyyMMdd-HHmm').format(_exportedAt)}';

    final isLimited = (report.cycles.isEmpty &&
            report.keyMatrix.isEmpty &&
            report.symptomPatterns.isEmpty &&
            dashboard == null) ||
        report.cycles.length < 2 ||
        (dashboard?.totalCycles ?? 0) < 2;

    final plain = CycleReportExporter.toPlainText(
      l10n: l10n,
      report: report,
      dashboard: dashboard,
      exportedDate: exportedLabel,
      metrics: metrics,
      patient: patient,
      limitedDataNote: isLimited ? l10n.doctorReportLimitedData : null,
    );

    setState(() {
      _dashboard = dashboard;
      _report = report;
      _snapshot = snapshot.isEmpty ? null : snapshot;
      _metrics = metrics;
      _patient = patient;
      _reportId = reportId;
      _enrichment = null;
      _plainText = plain;
      _loading = false;
      _failed = false;
      _limitedData = isLimited;
      _refining = true;
    });

    await _enrichReport(
      limitedData: isLimited,
      languageCode: locale.languageCode,
      exportedLabel: exportedLabel,
      report: report,
      dashboard: dashboard,
      metrics: metrics,
    );
  }

  Future<void> _enrichReport({
    required bool limitedData,
    required String languageCode,
    required String exportedLabel,
    required CycleReportData report,
    required CycleDashboardData? dashboard,
    required DoctorReportMetrics metrics,
  }) async {
    final service = context.read<AiInsightsService>();
    final enrichment = await service.enrichDoctorReport(
      languageCode: languageCode,
      limitedData: limitedData,
      clinicalMetrics: metrics.toContextMap(),
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final plain = CycleReportExporter.toPlainText(
      l10n: l10n,
      report: report,
      dashboard: dashboard,
      exportedDate: exportedLabel,
      enrichment: enrichment,
      metrics: metrics,
      patient: _patient,
      limitedDataNote:
          limitedData && (enrichment?.dataQualityNote == null)
              ? l10n.doctorReportLimitedData
              : null,
    );

    setState(() {
      _enrichment = enrichment;
      _plainText = plain;
      _refining = false;
    });
  }

  String _qrPayload() {
    // QR opens the Lune web/app landing page for the physician.
    return PrivacyConstants.privacyPolicyUrl
        .replaceAll('/privacy-policy.html', '');
  }

  Future<void> _exportReport() async {
    if (_report == null || _plainText == null) return;

    final format = await ReportExportSheet.show(context);
    if (format == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFmt = DateFormat.yMMMMd(locale.toString());
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.doctorReportExporting)),
    );

    try {
      final file = await CycleReportFileExporter.export(
        format: format,
        l10n: l10n,
        report: _report!,
        dashboard: _dashboard,
        exportedAt: _exportedAt,
        snapshot: _snapshot,
        metrics: _metrics,
        patient: _patient,
        enrichment: _enrichment,
        reportId: _reportId,
        exportedDateLabel: dateFmt.format(_exportedAt),
        rtl: locale.languageCode == 'ar',
        plainText: _plainText,
      );

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: l10n.doctorReportTitle,
        ),
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorReportExportShared)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorReportExportFailed)),
      );
    }
  }

  Future<void> _editPatient() async {
    final updated = await DoctorReportPatientSheet.show(context, _patient);
    if (updated == null || !mounted) return;

    setState(() => _patient = updated);

    // Regenerate the plain-text export so copy/share reflect the new header.
    if (_report != null) {
      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context);
      final exportedLabel = DateFormat.yMMMMd(locale.toString()).format(_exportedAt);
      final plain = CycleReportExporter.toPlainText(
        l10n: l10n,
        report: _report!,
        dashboard: _dashboard,
        exportedDate: exportedLabel,
        enrichment: _enrichment,
        metrics: _metrics,
        patient: updated,
        limitedDataNote:
            _limitedData && (_enrichment?.dataQualityNote == null)
                ? l10n.doctorReportLimitedData
                : null,
      );
      if (mounted) setState(() => _plainText = plain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFD4D4D4),
      appBar: AppBar(
        backgroundColor: AuraColors.blush.withValues(alpha: 0.95),
        foregroundColor: AuraColors.plum,
        elevation: 0,
        title: Text(l10n.doctorReportTitle),
        actions: [
          if (!_loading && !_failed)
            IconButton(
              tooltip: l10n.doctorReportEditPatient,
              icon: const Icon(Icons.badge_outlined),
              onPressed: _editPatient,
            ),
          if (_plainText != null && !_refining) ...[
            IconButton(
              tooltip: l10n.doctorReportDownload,
              icon: const Icon(Icons.download_outlined),
              onPressed: _exportReport,
            ),
            IconButton(
              tooltip: l10n.doctorReportCopy,
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: _plainText!));
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.doctorReportCopied)),
                );
              },
            ),
            IconButton(
              tooltip: l10n.doctorReportShare,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: _plainText!,
                  subject: l10n.doctorReportTitle,
                ),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.doctorReportGenerating),
                ],
              ),
            )
          : _failed
              ? _EmptyReportState(onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    CycleHealthReportDocument(
                      report: _report!,
                      dashboard: _dashboard,
                      qrPayload: _qrPayload(),
                      exportedAt: _exportedAt,
                      metrics: _metrics,
                      patient: _patient,
                      snapshot: _snapshot,
                      reportId: _reportId,
                      enrichment: _enrichment,
                      refining: _refining,
                      limitedData: _limitedData,
                      limitedDataNote: l10n.doctorReportLimitedData,
                    ),
                  ],
                ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              l10n.doctorReportFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.doctorReportRetry),
            ),
          ],
        ),
      ),
    );
  }
}
