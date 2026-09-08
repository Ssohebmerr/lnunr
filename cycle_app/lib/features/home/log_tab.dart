import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_log_period_view.dart';
import 'package:menstrual_cycle_widget/ui/model/display_symptoms_data.dart';

import '../../../core/ai/models/ai_insight.dart';
import '../../../core/ai/widgets/ai_insight_card.dart';
import '../../../core/app_home_refresh.dart';
import '../../../core/cycle/luteal_calibration.dart';
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

  /// Whether the user has saved a log while this tab has been open. The AI
  /// reflection needs something to reflect on before it is worth showing.
  bool _savedThisSession = false;
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

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, _navBarClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shown only after a save: while the form is being filled in, the
          // AI has nothing to reflect on and the card would just eat the
          // vertical space the log entry needs.
          if (_savedThisSession) ...[
            const AiInsightCard(
              type: AiInsightType.logReflection,
              margin: EdgeInsets.zero,
              blur: false,
              compact: true,
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: isDark
                    ? AuraColors.darkCard.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.32),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: MenstrualLogPeriodView(
            key: _refreshKey,
            embeddedInTab: true,
            symptomsLogDate: DateTime.now(),
            themeColor: theme.colorScheme.primary,
            displaySymptomsData: DisplaySymptomsData(),
            onDiscardChanges: () {
              if (context.mounted) {
                DailyLogFeedback.showDiscarded(context, l10n);
              }
            },
            onAutoSaved: () {
              // Temperature is logged in this form, so ovulation detection has
              // to see it on the next read rather than a stale cached scan.
              LutealCalibration.sharedBbtService.invalidate();
              // Sync home / AI context WITHOUT a global refresh — a refresh
              // recreates this very log widget mid-edit and the entry being
              // typed appears to vanish (the "won't save" bug).
              sync.onCycleDataChanged(notifyHomeRefresh: false);
            },
            onSuccess: (_) async {
              LutealCalibration.sharedBbtService.invalidate();
              await NotificationService.scheduleFromPrefs();
              // Silent sync so the form is not rebuilt out from under the user.
              await sync.onCycleDataChanged(notifyHomeRefresh: false);
              if (!context.mounted) return;

              final messenger =
                  widget.homeMessenger ?? ScaffoldMessenger.of(context);
              if (widget.popOnSave && Navigator.of(context).canPop()) {
                DailyLogFeedback.showSavedOn(messenger, context, l10n);
                Navigator.of(context).pop();
                // This tab is gone now, so a refresh updates home safely.
                HomeRefreshScope.refresh();
              } else {
                DailyLogFeedback.showSaved(context, l10n);
                if (mounted && !_savedThisSession) {
                  setState(() => _savedThisSession = true);
                }
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
          ),
        ],
      ),
    );
  }
}
