import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../data/cycle_sync_service.dart';

/// Edit cycle config — changes propagate to Home, AI, notifications, and widget.
class CycleSettingsSheet extends StatefulWidget {
  const CycleSettingsSheet({super.key});

  @override
  State<CycleSettingsSheet> createState() => _CycleSettingsSheetState();
}

class _CycleSettingsSheetState extends State<CycleSettingsSheet> {
  final _sync = CycleSyncService();
  late int _cycleLength;
  late int _periodDuration;
  late DateTime _lastPeriod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final api = MenstrualCycleWidget.instance;
    _cycleLength = api?.getCycleLength() ?? 28;
    _periodDuration = api?.getPeriodDuration() ?? 5;
    _lastPeriod = DateTime.now().subtract(const Duration(days: 14));
    _loadLastPeriod();
  }

  Future<void> _loadLastPeriod() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;
    try {
      final summary = await api.getMenstrualCycleSummary();
      final last = summary['lastPeriodDate']?.toString();
      if (last != null && last.isNotEmpty) {
        setState(() => _lastPeriod = DateTime.parse(last));
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastPeriod = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final lang = context.read<LocaleController>().locale.languageCode;
      final ok = await _sync.updateCycleConfig(
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        lastPeriodDate: _lastPeriod,
        languageCode: lang,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } catch (e) {
      debugPrint('Cycle settings save failed: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.onboardingPartialSave)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.cycleSettingsTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.cycleSettingsSubtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _RowStepper(
            label: l10n.cycleLength,
            value: _cycleLength,
            onChanged: (v) => setState(() => _cycleLength = v),
          ),
          _RowStepper(
            label: l10n.periodDuration,
            value: _periodDuration,
            onChanged: (v) => setState(() => _periodDuration = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.lastPeriodDate),
            subtitle: Text(
              '${_lastPeriod.year}-${_lastPeriod.month.toString().padLeft(2, '0')}-${_lastPeriod.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.cycleSettingsSave),
          ),
        ],
      ),
    );
  }
}

class _RowStepper extends StatelessWidget {
  const _RowStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$value'),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
