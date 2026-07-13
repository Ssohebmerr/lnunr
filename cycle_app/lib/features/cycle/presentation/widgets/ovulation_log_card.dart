import 'package:flutter/material.dart';

import '../../../../core/app_home_refresh.dart';
import '../../../../core/cycle/ovulation_log_service.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/cycle_sync_service.dart';

/// Quick ovulation / LH logging on the home screen.
class OvulationLogCard extends StatefulWidget {
  const OvulationLogCard({super.key});

  @override
  State<OvulationLogCard> createState() => _OvulationLogCardState();
}

class _OvulationLogCardState extends State<OvulationLogCard> {
  final _service = OvulationLogService();
  bool _loggedToday = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final today = await _service.hasLogOn(DateTime.now());
    if (mounted) {
      setState(() {
        _loggedToday = today;
        _loading = false;
      });
    }
  }

  Future<void> _log(OvulationLogType type, {DateTime? date}) async {
    if (date == null) {
      await _service.logToday(type);
    } else {
      await _service.logDate(date, type);
    }
    await CycleSyncService().onCycleDataChanged();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.ovulationLogSaved)),
    );
    await _refresh();
  }

  Future<void> _pickDate(OvulationLogType type) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (picked != null) await _log(type, date: picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bubble_chart_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.ovulationLogTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_loggedToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    l10n.ovulationLogSaved,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _log(OvulationLogType.ovulation),
                icon: const Icon(Icons.egg_outlined, size: 18),
                label: Text(l10n.ovulationLogToday),
              ),
              OutlinedButton.icon(
                onPressed: () => _log(OvulationLogType.lhPositive),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: Text(l10n.ovulationLogLhPositive),
              ),
              TextButton(
                onPressed: () => _pickDate(OvulationLogType.ovulation),
                child: Text(l10n.ovulationLogPickDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact ovulation actions for the daily log tab.
class OvulationLogBar extends StatelessWidget {
  const OvulationLogBar({super.key});

  Future<void> _log(BuildContext context, OvulationLogType type) async {
    await OvulationLogService().logToday(type);
    await CycleSyncService().onCycleDataChanged();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.ovulationLogSaved)),
    );
    HomeRefreshScope.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AuraDecorations.softCard(
        theme.brightness == Brightness.dark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ovulationLogTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _log(context, OvulationLogType.ovulation),
                  icon: const Icon(Icons.egg_outlined, size: 18),
                  label: Text(l10n.ovulationLogToday),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _log(context, OvulationLogType.lhPositive),
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: Text(l10n.ovulationLogLhPositive),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
