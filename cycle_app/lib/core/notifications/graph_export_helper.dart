import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';

/// Shares a graph PDF/PNG exported by menstrual_cycle_widget.
Future<void> shareGraphExport(BuildContext context, dynamic file) async {
  if (file is! File) return;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: 'Lune',
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.graphExportShared),
      ),
    );
  }
}
