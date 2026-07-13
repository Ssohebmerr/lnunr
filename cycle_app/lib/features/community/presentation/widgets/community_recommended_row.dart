import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/community.dart';
import 'community_ui.dart';

/// Horizontal row of recommended community "discover cards" for the Discover
/// tab. The rail intentionally previews only a few groups while the complete
/// catalog remains visible in the lists below.
class CommunityRecommendedRow extends StatelessWidget {
  const CommunityRecommendedRow({
    super.key,
    required this.communities,
    required this.languageCode,
    required this.joinedIds,
    required this.onOpen,
  });

  final List<Community> communities;
  final String languageCode;
  final List<String> joinedIds;
  final void Function(Community community, bool isJoined) onOpen;

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.communityRecommendedTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: communities.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = communities[index];
              final joined = joinedIds.contains(c.id);
              return _DiscoverCard(
                community: c,
                languageCode: languageCode,
                isJoined: joined,
                onTap: () => onOpen(c, joined),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Compact horizontal card used in the Recommended rail. A quiet surface and
/// clear hierarchy make it scannable without competing with the full list.
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.community,
    required this.languageCode,
    required this.isJoined,
    required this.onTap,
  });

  final Community community;
  final String languageCode;
  final bool isJoined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = community.nameForLocale(languageCode);
    final description = community.descriptionForLocale(languageCode);
    final gradient = CommunityTopicPalette.gradient(community.topic);
    final accent = CommunityTopicPalette.iconColor(community.topic);
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 230,
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
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(community.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 12,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(community.memberCount),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isJoined)
                            Expanded(
                              child: Text(
                                l10n.communityJoinedBadge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                l10n.communityJoin,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000).round()}k';
  }
}
