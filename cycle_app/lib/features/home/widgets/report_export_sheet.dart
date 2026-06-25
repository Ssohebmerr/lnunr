import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle_report_file_exporter.dart';

/// Bottom sheet to pick a report file format before sharing.
class ReportExportSheet extends StatelessWidget {
  const ReportExportSheet({super.key});

  static Future<CycleReportExportFormat?> show(BuildContext context) {
    return showModalBottomSheet<CycleReportExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ReportExportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.doctorReportExportTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AuraColors.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.doctorReportExportSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _ExportTile(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.doctorReportExportPdf,
              subtitle: l10n.doctorReportExportPdfHint,
              onTap: () => Navigator.pop(context, CycleReportExportFormat.pdf),
            ),
            _ExportTile(
              icon: Icons.description_outlined,
              title: l10n.doctorReportExportTxt,
              subtitle: l10n.doctorReportExportTxtHint,
              onTap: () => Navigator.pop(context, CycleReportExportFormat.txt),
            ),
            _ExportTile(
              icon: Icons.table_chart_outlined,
              title: l10n.doctorReportExportCsv,
              subtitle: l10n.doctorReportExportCsvHint,
              onTap: () => Navigator.pop(context, CycleReportExportFormat.csv),
            ),
            _ExportTile(
              icon: Icons.data_object_outlined,
              title: l10n.doctorReportExportJson,
              subtitle: l10n.doctorReportExportJsonHint,
              onTap: () => Navigator.pop(context, CycleReportExportFormat.json),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AuraColors.blush.withValues(alpha: 0.35),
        foregroundColor: AuraColors.plum,
        child: Icon(icon, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
