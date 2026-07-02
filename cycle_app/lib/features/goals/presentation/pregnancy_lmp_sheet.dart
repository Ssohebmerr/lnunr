import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_sync_service.dart';

/// Confirm or update LMP when switching to pregnancy mode.
class PregnancyLmpSheet extends StatefulWidget {
  const PregnancyLmpSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PregnancyLmpSheet(
        initialDate:
            initialDate ?? DateTime.now().subtract(const Duration(days: 14)),
      ),
    );
  }

  @override
  State<PregnancyLmpSheet> createState() => _PregnancyLmpSheetState();
}

class _PregnancyLmpSheetState extends State<PregnancyLmpSheet> {
  late DateTime _lmp;
  bool _saving = false;
  final _sync = CycleSyncService();

  @override
  void initState() {
    super.initState();
    _lmp = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lmp = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final lang = context.read<LocaleController>().locale.languageCode;
    final api = MenstrualCycleWidget.instance;
    try {
      final ok = await _sync.updateCycleConfig(
        cycleLength: api?.getCycleLength() ?? 28,
        periodDuration: api?.getPeriodDuration() ?? 5,
        lastPeriodDate: _lmp,
        languageCode: lang,
      );
      if (mounted && ok) Navigator.of(context).pop(_lmp);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formatted =
        '${_lmp.year}-${_lmp.month.toString().padLeft(2, '0')}-${_lmp.day.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.onboardingPregnancyDataTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.onboardingPregnancyDataSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppGlassCard(
              onTap: _pickDate,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.onboardingPregnancyLmp),
                subtitle: Text(formatted),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.pregnancyWeightSave),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads the current LMP from cycle summary when available.
Future<DateTime> loadCurrentLmp() async {
  final fallback = DateTime.now().subtract(const Duration(days: 14));
  final api = MenstrualCycleWidget.instance;
  if (api == null) return fallback;
  try {
    final summary = await api.getMenstrualCycleSummary();
    final last = summary['lastPeriodDate']?.toString();
    if (last != null && last.isNotEmpty) {
      return DateTime.parse(last);
    }
  } catch (_) {}
  return fallback;
}
