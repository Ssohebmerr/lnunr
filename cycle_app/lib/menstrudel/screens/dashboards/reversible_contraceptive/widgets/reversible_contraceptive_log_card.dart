import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/birth_control/reversible_contraceptives/reversible_contraceptive_log_entry.dart';
import 'package:cycle_aura/core/theme/app_design_tokens.dart';
import 'package:cycle_aura/core/widgets/app_surface.dart';

class ReversibleContraceptiveLogCard extends StatelessWidget {
  const ReversibleContraceptiveLogCard({
    super.key,
    required this.entry,
    required this.l10n,
    required this.injectionDate,
    required this.dueDateString,
    required this.isOverdue,
    required this.onTap,
  });

  final ReversibleContraceptiveLogEntry entry;
  final AppLocalizations l10n;
  final String injectionDate;
  final String dueDateString;
  final bool isOverdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color dueDateColor = isOverdue ? colorScheme.error : colorScheme.tertiary;
    final String dueLabel = isOverdue ? l10n.overdue : l10n.nextDue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppGlassCard(
        blur: false,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.22),
                    colorScheme.primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                entry.type.getIcon(),
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.type.getDisplayName(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        injectionDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: dueDateColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: dueDateColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '$dueLabel: $dueDateString',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: dueDateColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
