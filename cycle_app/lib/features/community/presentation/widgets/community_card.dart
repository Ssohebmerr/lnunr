import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/community.dart';
import 'community_ui.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.community,
    required this.languageCode,
    required this.isJoined,
    required this.onTap,
    this.isJoinable = true,
  });

  final Community community;
  final String languageCode;
  final bool isJoined;
  final VoidCallback onTap;
  final bool isJoinable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = community.nameForLocale(languageCode);
    final description = community.descriptionForLocale(languageCode);
    final iconColor = CommunityTopicPalette.iconColor(community.topic);
    final memberCountLabel = _formatMemberCount(community.memberCount);

    return Semantics(
      button: true,
      label: name,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: isDark
              ? AuraColors.darkCard.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : theme.colorScheme.outline.withValues(alpha: 0.07),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.18 : 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(community.icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (!isJoinable)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.communityClosedBadge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else if (isJoined)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.communityJoinedBadge,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(
                                  alpha: isDark ? 0.18 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    size: 12,
                                    color: iconColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    memberCountLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: iconColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                _topicLabel(community.topic, context),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Friendly count label: 1.2k for 1200+, 12.5k for 12500+, otherwise the
  /// raw number. We deliberately hide the `maxMembers` ratio so groups feel
  /// open and welcoming rather than "almost full".
  String _formatMemberCount(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) {
      final v = (n / 1000).toStringAsFixed(1);
      return '${v}k';
    }
    return '${(n / 1000).round()}k';
  }

  String _topicLabel(String topic, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (topic) {
      case 'conception':
        return l10n.communityCatConception;
      case 'contraception':
        return l10n.communityCatContraception;
      case 'condition':
        return l10n.communityCatCondition;
      case 'support':
        return l10n.communityCatSupport;
      case 'culture':
        return l10n.communityCatCulture;
      case 'age':
        return l10n.communityCatAge;
      default:
        return l10n.communityCatGeneral;
    }
  }
}
