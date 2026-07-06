import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/premium/premium_badge.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_post.dart';
import 'community_time.dart';

/// Mini member profile: avatar, alias, and their recent public posts in the
/// community. Opened by tapping an author's avatar/name on a post. Anonymous
/// posts never reach this sheet (callers must check `post.isAnonymous`).
Future<void> showMemberProfileSheet(
  BuildContext context, {
  required String communityId,
  required String authorUid,
  required String alias,
  required int avatarIndex,
  bool isPremium = false,
}) {
  final repo = context.read<CommunityRepository>();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final l10n = AppLocalizations.of(ctx)!;
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.7;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    AppAvatar(
                      radius: 28,
                      avatarIndex: avatarIndex,
                      uidSeed: authorUid,
                      isPremium: isPremium,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  alias,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPremium) const PremiumNameBadge(),
                            ],
                          ),
                          Text(
                            l10n.communityMemberProfile,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
              Flexible(
                child: FutureBuilder<List<CommunityPost>>(
                  future: repo.fetchMemberPosts(communityId, authorUid),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final posts = snap.data ?? const <CommunityPost>[];
                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(36),
                        child: Center(
                          child: Text(
                            l10n.communityNoRecentPosts,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      children: [
                        Text(
                          l10n.communityRecentPosts,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final post in posts)
                          _MemberPostPreview(post: post),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MemberPostPreview extends StatelessWidget {
  const _MemberPostPreview({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                communityRelativeTime(context, post.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
