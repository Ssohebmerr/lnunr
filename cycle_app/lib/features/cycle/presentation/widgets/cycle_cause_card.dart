import 'package:flutter/material.dart';

import '../../../../core/cycle/cycle_annotation_service.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/cycle_sync_service.dart';

/// Asks what made a cycle unusual, so the predictor can learn from the user
/// instead of guessing.
///
/// The outlier filter is statistical: it sees that a cycle sits far from the
/// median, never *why*. That matters most for moderate disruptions — a cycle
/// six days long than usual survives the filter and quietly drags the average,
/// while the user knew all along it was the month she had flu.
///
/// Cycles set aside here leave the date estimate but are still reviewed for
/// clinical patterns, so no amount of explaining can hide a real signal.
class CycleCauseCard extends StatefulWidget {
  const CycleCauseCard({
    super.key,
    required this.cycleStart,
    this.margin,
    this.onSaved,
  });

  /// First day of the cycle being explained.
  final DateTime cycleStart;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onSaved;

  @override
  State<CycleCauseCard> createState() => _CycleCauseCardState();
}

class _CycleCauseCardState extends State<CycleCauseCard> {
  final _service = CycleAnnotationService();
  Set<CycleCause> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CycleCauseCard old) {
    super.didUpdateWidget(old);
    if (old.cycleStart != widget.cycleStart) _load();
  }

  Future<void> _load() async {
    final causes = await _service.causesFor(widget.cycleStart);
    if (!mounted) return;
    setState(() {
      _selected = {...causes};
      _loading = false;
    });
  }

  Future<void> _save(Set<CycleCause> causes) async {
    setState(() {
      _selected = causes;
      _saving = true;
    });

    await _service.setCauses(widget.cycleStart, causes);
    // The prediction baseline just changed — recompute rather than waiting for
    // the next natural refresh.
    await CycleSyncService().onCycleDataChanged();

    if (!mounted) return;
    setState(() => _saving = false);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          causes.isEmpty ? l10n.cycleCauseCleared : l10n.cycleCauseSaved,
        ),
      ),
    );
    widget.onSaved?.call();
  }

  String _label(CycleCause c, AppLocalizations l10n) => switch (c) {
    CycleCause.illness => l10n.cycleCauseIllness,
    CycleCause.travel => l10n.cycleCauseTravel,
    CycleCause.stress => l10n.cycleCauseStress,
    CycleCause.weightChange => l10n.cycleCauseWeight,
    CycleCause.medication => l10n.cycleCauseMedication,
    CycleCause.poorSleep => l10n.cycleCauseSleep,
    CycleCause.intenseExercise => l10n.cycleCauseExercise,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                  child: const Icon(
                    Icons.auto_fix_high_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.cycleCauseTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cycleCauseIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cause in CycleCause.values)
                  FilterChip(
                    label: Text(_label(cause, l10n)),
                    selected: _selected.contains(cause),
                    onSelected: _saving
                        ? null
                        : (on) {
                            final next = {..._selected};
                            on ? next.add(cause) : next.remove(cause);
                            _save(next);
                          },
                  ),
                // An explicit "nothing unusual" is what lets someone undo a
                // mistaken tap without hunting for which chip to clear.
                if (_selected.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: Text(l10n.cycleCauseNothing),
                    onPressed: _saving ? null : () => _save({}),
                  ),
              ],
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.cycleCauseStillCounted,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
