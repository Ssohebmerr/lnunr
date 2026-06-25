import 'package:flutter/material.dart';

import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';

/// Prominent entry to Lune AI on the home screen.
class HomeAiEntryCard extends StatefulWidget {
  const HomeAiEntryCard({super.key});

  @override
  State<HomeAiEntryCard> createState() => _HomeAiEntryCardState();
}

class _HomeAiEntryCardState extends State<HomeAiEntryCard> {
  bool _premium = false;
  int _freeRemaining = 5;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final premium = await PremiumGate.hasPremium();
    final remaining = await PremiumGate.remainingFreeAiMessages();
    if (mounted) {
      setState(() {
        _premium = premium;
        _freeRemaining = remaining;
        _loading = false;
      });
    }
  }

  void _open() {
    HomeShellActions.openAiChat?.call();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      blur: false,
      onTap: _open,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.softRose(opacity: 0.22),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.homeAiCardTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'AI',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _loading
                      ? l10n.homeAiCardTap
                      : _premium
                          ? l10n.homeAiCardSubtitlePremium
                          : l10n.homeAiCardSubtitleFree(_freeRemaining),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chat_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }
}
