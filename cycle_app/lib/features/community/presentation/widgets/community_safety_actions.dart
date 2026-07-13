import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Stable codes stored in Firestore `communityReports.reason`.
enum CommunityReportReason {
  harassment('harassment'),
  hateSpeech('hate_speech'),
  spam('spam'),
  inappropriate('inappropriate'),
  misinformation('misinformation'),
  selfHarm('self_harm'),
  other('other');

  const CommunityReportReason(this.code);
  final String code;

  String label(AppLocalizations l10n) => switch (this) {
    CommunityReportReason.harassment => l10n.communityReportReasonHarassment,
    CommunityReportReason.hateSpeech => l10n.communityReportReasonHate,
    CommunityReportReason.spam => l10n.communityReportReasonSpam,
    CommunityReportReason.inappropriate =>
      l10n.communityReportReasonInappropriate,
    CommunityReportReason.misinformation =>
      l10n.communityReportReasonMisinformation,
    CommunityReportReason.selfHarm => l10n.communityReportReasonSelfHarm,
    CommunityReportReason.other => l10n.communityReportReasonOther,
  };
}

/// Bottom sheet for choosing a report reason. Returns `null` if dismissed.
Future<CommunityReportReason?> showReportReasonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<CommunityReportReason>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.communityReportTitle,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          ...CommunityReportReason.values.map(
            (reason) => ListTile(
              title: Text(reason.label(l10n)),
              onTap: () => Navigator.of(ctx).pop(reason),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Confirmation dialog before blocking. Returns `true` if confirmed.
Future<bool> confirmBlockUser(
  BuildContext context, {
  required String authorAlias,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.communityBlockConfirmTitle),
      content: Text(l10n.communityBlockConfirmMessage(authorAlias)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.communityBlockCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.communityBlockConfirmAction),
        ),
      ],
    ),
  );
  return result ?? false;
}
