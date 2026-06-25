import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/home_shell_actions.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/aura_scaffold.dart';

enum PremiumUpsellFeature { cloud, aiChat, aiAdvanced, communityMedia }

Future<void> showPremiumUpsellDialog(
  BuildContext context, {
  PremiumUpsellFeature feature = PremiumUpsellFeature.aiAdvanced,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final message = switch (feature) {
    PremiumUpsellFeature.cloud => l10n.premiumRequiredCloud,
    PremiumUpsellFeature.aiChat => l10n.premiumAiLimitReached,
    PremiumUpsellFeature.aiAdvanced => l10n.premiumRequiredAi,
    PremiumUpsellFeature.communityMedia => l10n.communityMediaPremiumGate,
  };

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => AppMeshBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AuraDecorations.premiumGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.softRose(opacity: 0.3),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.premiumUpsellTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.premiumSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppGlassCard(
              onTap: () {
                Navigator.pop(ctx);
                HomeShellActions.switchTab?.call(3);
              },
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.premiumUpsellSubscribe,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.premiumUpsellNotNow,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
