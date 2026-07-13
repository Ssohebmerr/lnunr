import 'package:firebase_auth/firebase_auth.dart';
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
                    _FollowButton(
                      authorUid: authorUid,
                      alias: alias,
                      avatarIndex: avatarIndex,
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

/// Follow / following toggle for the member profile header. Hidden when
/// viewing your own profile or signed out.
class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.authorUid,
    required this.alias,
    required this.avatarIndex,
  });

  final String authorUid;
  final String alias;
  final int avatarIndex;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == authorUid) return const SizedBox.shrink();

    final repo = context.read<CommunityRepository>();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<bool>(
      stream: repo.watchIsFollowing(uid, authorUid),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final following = snap.data!;

        if (following) {
          return OutlinedButton.icon(
            onPressed: () => repo.unfollowUser(uid: uid, followedUid: authorUid),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(l10n.communityFollowingBtn),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          );
        }

        return FilledButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await repo.followUser(
              uid: uid,
              followedUid: authorUid,
              alias: alias,
              avatarIndex: avatarIndex,
            );
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.communityFollowedToast(alias))),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
          label: Text(l10n.communityFollow),
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        );
      },
    );
  }
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
        color: theme.brightness == Brightness.dark
            ? AuraColors.darkCard.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                size: 12,
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
