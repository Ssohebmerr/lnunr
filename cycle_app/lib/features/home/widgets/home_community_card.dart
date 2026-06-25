import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../community/presentation/community_tab.dart';
import '../sub_feature_page.dart';

/// Quick entry to communities from the home screen.
class HomeCommunityCard extends StatelessWidget {
  const HomeCommunityCard({super.key});

  void _open(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubFeaturePage(
          title: l10n.navCommunity,
          child: CommunityTab(key: ValueKey(uid ?? 'guest')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppGlassCard(
      blur: false,
      onTap: () => _open(context),
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AuraColors.darkRose.withValues(alpha: 0.5),
                        AuraColors.lavender.withValues(alpha: 0.35),
                      ]
                    : AuraColors.gradientRoseLavender,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.softRose(opacity: 0.2),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityHomeCardTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.communityHomeCardSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
