import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_log_period_view.dart';
import 'package:menstrual_cycle_widget/ui/model/display_symptoms_data.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_sync_service.dart';
import 'widgets/daily_log_feedback.dart';

/// Daily symptom / period logging — opened from the + FAB or embedded in a tab.
class LogTab extends StatefulWidget {
  const LogTab({
    super.key,
    this.popOnSave = false,
    this.homeMessenger,
  });

  /// When true, closes the log screen after a successful save.
  final bool popOnSave;

  /// Parent [ScaffoldMessenger] so the save toast survives [Navigator.pop].
  final ScaffoldMessengerState? homeMessenger;

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> {
  Key _refreshKey = UniqueKey();
  static const _navBarClearance = 88.0;

  @override
  void initState() {
    super.initState();
    HomeRefreshScope.notifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) {
      setState(() {
        _refreshKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sync = CycleSyncService();

    if (MenstrualCycleWidget.instance == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_calendar_outlined,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(l10n.onboardingCycleSubtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, _navBarClearance),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: theme.brightness == Brightness.dark
              ? AuraColors.darkCard.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.72),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: MenstrualLogPeriodView(
            key: _refreshKey,
            embeddedInTab: true,
            themeColor: theme.colorScheme.primary,
            displaySymptomsData: DisplaySymptomsData(),
            onDiscardChanges: () {
              if (context.mounted) {
                DailyLogFeedback.showDiscarded(context, l10n);
              }
            },
            onSuccess: (_) async {
              await NotificationService.scheduleFromPrefs();
              await sync.onCycleDataChanged();
              HomeRefreshScope.refresh();
              if (!context.mounted) return;

              final messenger = widget.homeMessenger ?? ScaffoldMessenger.of(context);
              if (widget.popOnSave && Navigator.of(context).canPop()) {
                DailyLogFeedback.showSavedOn(messenger, context, l10n);
                Navigator.of(context).pop();
              } else {
                DailyLogFeedback.showSaved(context, l10n);
              }
            },
            onError: (_) {
              if (context.mounted) {
                DailyLogFeedback.showError(context, l10n);
              }
            },
          ),
        ),
      ),
    );
  }
}
