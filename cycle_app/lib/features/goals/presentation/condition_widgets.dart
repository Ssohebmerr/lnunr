import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/condition_log_store.dart';

/// A single trackable item: a stable [key] (language-independent slug) plus a
/// already-localized [label] for display.
class ConditionItem {
  const ConditionItem({required this.key, required this.label});
  final String key;
  final String label;

  /// Build from a bilingual pair — key comes from the English text so it stays
  /// stable across languages and copy edits.
  factory ConditionItem.fromEn(String en, String label) =>
      ConditionItem(key: ConditionLogStore.slug(en), label: label);
}

/// Interactive symptom chips. Tapping one logs/unlogs that symptom for today
/// in [ConditionLogStore] and shows a light confirmation. Replaces the old
/// static `AppStatChip` list that looked tappable but did nothing.
class ConditionTrackChips extends StatefulWidget {
  const ConditionTrackChips({super.key, required this.items});

  final List<ConditionItem> items;

  @override
  State<ConditionTrackChips> createState() => _ConditionTrackChipsState();
}

class _ConditionTrackChipsState extends State<ConditionTrackChips> {
  final DateTime _today = DateTime.now();
  Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ConditionLogStore.symptomsOn(_today);
    if (mounted) setState(() => _selected = s);
  }

  Future<void> _toggle(ConditionItem item) async {
    final wasSelected = _selected.contains(item.key);
    setState(() {
      if (wasSelected) {
        _selected.remove(item.key);
      } else {
        _selected.add(item.key);
      }
    });
    await ConditionLogStore.toggleSymptom(_today, item.key);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = wasSelected
        ? l10n.conditionRemovedNamed(item.label)
        : l10n.conditionLoggedNamed(item.label);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1100),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.items
          .map((item) => _TrackChip(
                label: item.label,
                selected: _selected.contains(item.key),
                onTap: () => _toggle(item),
              ))
          .toList(),
    );
  }
}

class _TrackChip extends StatelessWidget {
  const _TrackChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.9)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline,
                size: 16,
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A daily ritual checklist. Each tile can be ticked off; completion is saved
/// per day and a small progress bar shows "x of y done today".
class ConditionRitualChecklist extends StatefulWidget {
  const ConditionRitualChecklist({super.key, required this.items});

  final List<ConditionItem> items;

  @override
  State<ConditionRitualChecklist> createState() =>
      _ConditionRitualChecklistState();
}

class _ConditionRitualChecklistState extends State<ConditionRitualChecklist> {
  final DateTime _today = DateTime.now();
  Set<String> _done = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ConditionLogStore.ritualsOn(_today);
    if (mounted) setState(() => _done = s);
  }

  Future<void> _toggle(ConditionItem item) async {
    setState(() {
      if (_done.contains(item.key)) {
        _done.remove(item.key);
      } else {
        _done.add(item.key);
      }
    });
    await ConditionLogStore.toggleRitual(_today, item.key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = widget.items.length;
    final done = widget.items.where((i) => _done.contains(i.key)).length;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_outlined, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.conditionRitualsDoneToday(done, total),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          ...widget.items.map(
            (item) => _RitualTile(
              label: item.label,
              done: _done.contains(item.key),
              onTap: () => _toggle(item),
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualTile extends StatelessWidget {
  const _RitualTile({
    required this.label,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done
                      ? color
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: done
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact −/value/+ counter card backed by a [ConditionLogStore] metric
/// (e.g. the menopause daily hot-flash count).
class ConditionStepperCard extends StatefulWidget {
  const ConditionStepperCard({
    super.key,
    required this.metricName,
    required this.icon,
    required this.label,
    this.hint,
    this.accent,
    this.maxValue = 99,
  });

  final String metricName;
  final IconData icon;
  final String label;
  final String? hint;
  final Color? accent;
  final int maxValue;

  @override
  State<ConditionStepperCard> createState() => _ConditionStepperCardState();
}

class _ConditionStepperCardState extends State<ConditionStepperCard> {
  final DateTime _today = DateTime.now();
  int _value = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ConditionLogStore.metric(widget.metricName, _today);
    if (mounted) setState(() => _value = v);
  }

  Future<void> _set(int v) async {
    final clamped = v.clamp(0, widget.maxValue);
    setState(() => _value = clamped);
    await ConditionLogStore.setMetric(widget.metricName, _today, clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.accent ?? theme.colorScheme.primary;
    return AppGlassCard(
      blur: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(widget.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.hint!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: _value > 0 ? () => _set(_value - 1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$_value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: _value < widget.maxValue ? () => _set(_value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: enabled ? 0.6 : 0.25,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// A 1–5 mood check-in row of faces. Controlled via [initialValue]; taps
/// persist to the mood metric and report the new value through [onChanged].
class MoodCheckInRow extends StatefulWidget {
  const MoodCheckInRow({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final int initialValue; // 0 = not set, else 1..5
  final ValueChanged<int> onChanged;

  @override
  State<MoodCheckInRow> createState() => _MoodCheckInRowState();
}

class _MoodCheckInRowState extends State<MoodCheckInRow> {
  final DateTime _today = DateTime.now();
  late int _value = widget.initialValue;

  @override
  void didUpdateWidget(covariant MoodCheckInRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _value == 0) {
      _value = widget.initialValue;
    }
  }

  static const _faces = ['😢', '😟', '😐', '🙂', '😄'];

  Future<void> _select(int v) async {
    setState(() => _value = v);
    await ConditionLogStore.setMetric(ConditionLogStore.metricMood, _today, v);
    widget.onChanged(v);
  }

  String _semantic(AppLocalizations l10n, int v) => switch (v) {
        1 => l10n.moodVeryLow,
        2 => l10n.moodLow,
        3 => l10n.moodOkay,
        4 => l10n.moodGood,
        _ => l10n.moodGreat,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final v = i + 1;
        final selected = _value == v;
        return Expanded(
          child: Semantics(
            label: _semantic(l10n, v),
            selected: selected,
            button: true,
            child: GestureDetector(
              onTap: () => _select(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.16)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.9)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _faces[i],
                    style: TextStyle(fontSize: selected ? 26 : 22),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
