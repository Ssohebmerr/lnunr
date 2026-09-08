import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/app_notifications.dart';
import '../../../core/notifications/notification_prefs.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';

/// Quick reminders toggles — opened from the account hub menu.
class AccountRemindersSheet extends StatefulWidget {
  const AccountRemindersSheet({super.key});

  @override
  State<AccountRemindersSheet> createState() => _AccountRemindersSheetState();
}

class _AccountRemindersSheetState extends State<AccountRemindersSheet> {
  bool _notifications = true;
  bool _periodReminder = true;
  bool _dailyReminder = true;
  bool _ovulationReminder = true;
  bool _latePeriodReminder = true;
  bool _smartPhaseReminder = true;
  bool _temperatureReminder = false;
  bool _loading = true;
  bool _osNotificationsEnabled = true;
  bool _exactAlarmsEnabled = true;
  int _pendingCount = 0;
  DateTime? _nextReminderAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final osEnabled = await NotificationService.areNotificationsEnabled();
    final exactOk = await AppNotifications.canScheduleExactNotifications();
    final pending = await NotificationService.pendingReminderCount();
    final nextAt = await NotificationService.nextScheduledReminderAt();
    if (mounted) {
      setState(() {
        _notifications = prefs.getBool('notifications_enabled') ?? true;
        _periodReminder = prefs.getBool('period_reminder_enabled') ?? true;
        _dailyReminder = prefs.getBool('daily_log_reminder_enabled') ?? true;
        _ovulationReminder = prefs.getBool('ovulation_reminder_enabled') ?? true;
        _latePeriodReminder =
            prefs.getBool(NotificationPrefs.latePeriodKey) ?? true;
        _smartPhaseReminder =
            prefs.getBool(NotificationPrefs.smartPhaseKey) ?? true;
        _temperatureReminder =
            prefs.getBool(NotificationPrefs.temperatureKey) ?? false;
        _osNotificationsEnabled = osEnabled;
        _exactAlarmsEnabled = exactOk;
        _pendingCount = pending;
        _nextReminderAt = nextAt;
        _loading = false;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await NotificationService.scheduleFromPrefs();
    await _load();
  }

  Future<void> _sendTest() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await NotificationService.sendTestNotification();
    if (!mounted) return;

    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.testNotificationBlocked)),
      );
      await _load();
      return;
    }

    final exactOk = await AppNotifications.canScheduleExactNotifications();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          exactOk ? l10n.testNotificationSent : l10n.notifTestExactAlarmsHint,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accountMenuReminders, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (!_osNotificationsEnabled)
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.notifOsDisabledBanner,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () async {
                          await NotificationService.requestPermission();
                          await _load();
                        },
                        child: Text(l10n.notifRequestPermission),
                      ),
                    ],
                  ),
                ),
              ),
            if (_osNotificationsEnabled && !_exactAlarmsEnabled) ...[
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.notifExactAlarmsHint,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await AppNotifications.requestExactAlarmsPermission();
                          await _load();
                        },
                        child: Text(l10n.notifEnableExactAlarms),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _pendingCount > 0
                  ? l10n.notifScheduledCount(_pendingCount)
                  : l10n.notifNoScheduled,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (_nextReminderAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.notifNextReminder(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).add_jm().format(_nextReminderAt!.toLocal()),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.notificationsEnable),
              value: _notifications,
              onChanged: (v) async {
                setState(() => _notifications = v);
                if (v) await NotificationService.requestPermission();
                await _savePref('notifications_enabled', v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.periodReminder),
              value: _periodReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _periodReminder = v);
                      await _savePref('period_reminder_enabled', v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dailyLogReminder),
              value: _dailyReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _dailyReminder = v);
                      await _savePref('daily_log_reminder_enabled', v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.ovulationReminder),
              value: _ovulationReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _ovulationReminder = v);
                      await _savePref('ovulation_reminder_enabled', v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.latePeriodReminder),
              subtitle: Text(
                l10n.latePeriodReminderSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              value: _latePeriodReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _latePeriodReminder = v);
                      await _savePref(NotificationPrefs.latePeriodKey, v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.bbtReminderEnabled),
              subtitle: Text(
                l10n.bbtReminderSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              value: _temperatureReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _temperatureReminder = v);
                      await _savePref(NotificationPrefs.temperatureKey, v);
                    }
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.smartPhaseReminder),
              subtitle: Text(
                l10n.smartPhaseReminderSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              value: _smartPhaseReminder,
              onChanged: _notifications
                  ? (v) async {
                      setState(() => _smartPhaseReminder = v);
                      await _savePref(NotificationPrefs.smartPhaseKey, v);
                    }
                  : null,
            ),
            Text(
              l10n.notificationsWellnessNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _sendTest,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.sendTestNotification),
            ),
          ],
        ],
      ),
    );
  }
}
