import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/community.dart';
import 'community_ui.dart';

/// Horizontal row of recommended community "discover cards" for the Discover
/// tab. Uses a compact vertical layout (icon → name → member count) instead
/// of the wide [CommunityCard], so 3–4 cards fit elegantly side-by-side.
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
        const SizedBox(height: 12),
        SizedBox(
          height: 158,
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
        const SizedBox(height: 22),
      ],
    );
  }
}

/// Compact vertical card used in the Recommended horizontal scroller.
/// Larger gradient icon on top, name, and a single member-count chip below —
/// no wasted space, very scannable.
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
    final gradient = CommunityTopicPalette.gradient(community.topic);
    final accent = CommunityTopicPalette.iconColor(community.topic);
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 152,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.06 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.32),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          community.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
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
                          const Spacer(),
                          if (isJoined)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            )
                          else
                            Text(
                              l10n.communityJoin,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
