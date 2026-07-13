import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/sanitary_products/sanitary_products_entry.dart';
import 'package:cycle_aura/menstrudel/models/sanitary_products/sanitary_products_enum.dart';
import 'package:cycle_aura/core/theme/app_design_tokens.dart';
import 'package:cycle_aura/core/widgets/app_surface.dart';

class SanitaryProductsLogCard extends StatelessWidget {
  const SanitaryProductsLogCard({
    super.key,
    required this.entry,
    required this.l10n,
    required this.logDate,
    required this.onTap,
  });

  final SanitaryProductsEntry entry;
  final AppLocalizations l10n;
  final String logDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = entry.type.getColorScheme(colorScheme);

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.28),
                    accent.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                entry.type.getIcon(),
                color: accent,
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
                        logDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
