import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Surfaces clinically meaningful patterns found in the user's own logged
/// cycles — prolonged, short, highly variable or absent cycles.
///
/// Deliberately **not** behind the premium gate and deliberately **not** an AI
/// call. Repeated 50-day cycles are the classic marker of oligomenorrhea, and
/// a health signal drawn from the user's own data is not something to sell or
/// to make contingent on a model being reachable.
///
/// Renders nothing when there is no signal, which is the common case.
class CycleSignalsCard extends StatelessWidget {
  const CycleSignalsCard({
    super.key,
    required this.flags,
    this.onOpenDoctorReport,
    this.margin,
  });

  final Set<CyclePatternFlag> flags;
  final VoidCallback? onOpenDoctorReport;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = AuraColors.warning;

    return Padding(
      padding: margin ?? const EdgeInsets.only(top: 12),
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
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.cycleSignalsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // The reassurance comes first, on purpose: the list below reads as
            // alarming out of context, and the ordinary causes really are the
            // most likely ones.
            Text(
              l10n.cycleSignalsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),

            for (final flag in _ordered(flags))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _label(flag, l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 2),
            Text(
              l10n.cycleSignalsFooter,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onOpenDoctorReport != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onOpenDoctorReport,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: Text(l10n.cycleSignalsOpenReport),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Most clinically notable first, so the list does not read as a random set.
  List<CyclePatternFlag> _ordered(Set<CyclePatternFlag> flags) => [
    for (final f in const [
      CyclePatternFlag.absentCycles,
      CyclePatternFlag.prolongedCycles,
      CyclePatternFlag.shortCycles,
      CyclePatternFlag.highVariability,
    ])
      if (flags.contains(f)) f,
  ];

  String _label(CyclePatternFlag flag, AppLocalizations l10n) =>
      switch (flag) {
        CyclePatternFlag.prolongedCycles => l10n.cycleSignalsProlonged,
        CyclePatternFlag.shortCycles => l10n.cycleSignalsShort,
        CyclePatternFlag.highVariability => l10n.cycleSignalsVariable,
        CyclePatternFlag.absentCycles => l10n.cycleSignalsAbsent,
      };
}
