import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/cycle/bbt_tracking_status.dart';
import '../../../../core/notifications/notification_prefs.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Explains why basal body temperature is worth logging, shows how close the
/// user is to a real ovulation confirmation, and owns the morning reminder.
///
/// The prediction engine can detect ovulation from temperature, but only if
/// the readings exist — so this card carries the ask, and reports honest
/// progress instead of a generic "track more" nudge.
class BbtTrackingCard extends StatefulWidget {
  const BbtTrackingCard({super.key, this.onLogToday, this.margin});

  final VoidCallback? onLogToday;
  final EdgeInsetsGeometry? margin;

  @override
  State<BbtTrackingCard> createState() => _BbtTrackingCardState();
}

class _BbtTrackingCardState extends State<BbtTrackingCard> {
  BbtTrackingStatus _status = BbtTrackingStatus.empty;
  bool _reminderOn = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await BbtTrackingStatus.load();
    final on = await NotificationPrefs.temperatureEnabled();
    final (hour, minute) = await NotificationPrefs.temperatureTime();
    if (!mounted) return;
    setState(() {
      _status = status;
      _reminderOn = on;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _loading = false;
    });
  }

  Future<void> _setReminder(bool value) async {
    setState(() => _reminderOn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefs.temperatureKey, value);
    await NotificationService.scheduleFromPrefs();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    await NotificationPrefs.setTemperatureTime(picked.hour, picked.minute);
    await NotificationService.scheduleFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final confirmed = _status.ovulationConfirmed;

    return Padding(
      padding: widget.margin ?? const EdgeInsets.only(top: 12),
      child: AppGlassCard(
        blur: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AuraDecorations.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    confirmed
                        ? Icons.check_circle_outline
                        : Icons.device_thermostat,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.bbtCardTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Explain the value once; drop it as soon as she is tracking.
            if (!_status.hasStarted) ...[
              Text(
                l10n.bbtCardWhy,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.bbtCardHow,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            if (confirmed) ...[
              _StatusLine(
                icon: Icons.verified_outlined,
                color: AuraColors.success,
                text: l10n.bbtCardConfirmed(
                  DateFormat.MMMd(
                    lang == 'ar' ? 'ar' : 'en',
                  ).format(_status.confirmedOvulationDate!),
                  (_status.shiftCelsius ?? 0).toStringAsFixed(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.bbtCardConfirmedNote,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _status.progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _status.isReady
                    ? l10n.bbtCardReady
                    : l10n.bbtCardProgress(
                        _status.readingsThisCycle,
                        BbtTrackingStatus.minReadingsForDetection,
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            if (_status.isCalibrated) ...[
              const SizedBox(height: 6),
              _StatusLine(
                icon: Icons.tune_rounded,
                color: theme.colorScheme.primary,
                text: l10n.bbtCardCalibrated(_status.measuredLutealSignals),
              ),
            ],

            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.bbtCardReminderOn,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: _reminderOn
                  ? InkWell(
                      onTap: _pickTime,
                      child: Text(
                        l10n.bbtCardReminderTime(
                          _reminderTime.format(context),
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
              value: _reminderOn,
              onChanged: _setReminder,
            ),

            if (widget.onLogToday != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: widget.onLogToday,
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: Text(l10n.bbtCardLogNow),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
