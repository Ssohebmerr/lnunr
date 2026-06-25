import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/doctor_report_builder.dart';
import '../../../core/ai/models/health_snapshot.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import 'cycle_report_exporter.dart';
import 'cycle_report_file_exporter.dart';
import 'widgets/cycle_health_report_document.dart';
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
  String? _plainText;
  bool _loading = true;
  bool _failed = false;
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
    final report = await _bridge.tryLoadStructuredReport();
    HealthSnapshot snapshot = const HealthSnapshot();
    try {
      snapshot = await engine.buildSnapshot();
    } catch (_) {}

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFmt = DateFormat.yMMMMd(locale.toString());
    final hasData = report != null &&
        (report.cycles.isNotEmpty ||
            report.keyMatrix.isNotEmpty ||
            dashboard != null);

    final plain = hasData
        ? CycleReportExporter.toPlainText(
            l10n: l10n,
            report: report,
            dashboard: dashboard,
            exportedDate: dateFmt.format(_exportedAt),
          )
        : null;

    setState(() {
      _dashboard = dashboard;
      _report = report;
      _snapshot = snapshot.isEmpty ? null : snapshot;
      _plainText = plain;
      _loading = false;
      _failed = !hasData;
    });
  }

  String _qrPayload() {
    final snap = _snapshot;
    final text = _plainText ?? '';
    if (snap != null && !snap.isEmpty) {
      return DoctorReportBuilder.qrPayload(snap, text);
    }
    if (text.isNotEmpty) {
      return text.length > 800 ? text.substring(0, 800) : text;
    }
    return 'Lune|cycle_report';
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
        exportedDateLabel: dateFmt.format(_exportedAt),
        rtl: locale.languageCode == 'ar',
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
          if (_plainText != null) ...[
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
