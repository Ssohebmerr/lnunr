import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/premium/premium_badge.dart';
import '../../../../core/security/community_text_sanitize.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_repository.dart';
import '../../data/community_seed.dart';
import '../../data/models/community_post.dart';
import '../../data/post_cover_styles.dart';
import '../../data/models/post_reactions.dart';
import '../../data/models/post_type.dart';
import '../community_clipboard.dart';
import '../community_share.dart';
import 'community_safety_actions.dart';
import 'community_time.dart';
import 'community_ui.dart';
import 'member_profile_sheet.dart';
import 'poll_view.dart';
import 'post_media_view.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showCommunity = false,
    this.savedOverride,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final bool showCommunity;

  /// Feed screens can provide their single saved-posts subscription here.
  /// Other screens keep the card's self-contained document listener.
  final bool? savedOverride;

  /// Resolved cover style — only for media-free text posts.
  static PostCoverStyle? _coverFor(CommunityPost post) {
    if (post.hasImage || post.hasVideo) return null;
    return PostCoverStyles.byId(post.coverStyle);
  }

  Widget _savedAction({
    required BuildContext context,
    required CommunityRepository repo,
    required String uid,
    required bool saved,
    required AppLocalizations l10n,
    bool savedLoaded = true,
  }) {
    return CommunityPostAction(
      icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      active: saved,
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final nowSaved = await repo.toggleSavePost(
          uid,
          post,
          currentlySaved: savedLoaded ? saved : null,
        );
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                nowSaved ? l10n.communityPostSaved : l10n.communityPostUnsaved,
              ),
            ),
          );
        }
      },
    );
  }

  Color _typeColor(PostType type) => switch (type) {
    PostType.support => AuraColors.rose,
    PostType.question => const Color(0xFF7B6CF6),
    PostType.tip => const Color(0xFF3D9A78),
    PostType.vent => const Color(0xFFE88B4A),
    PostType.milestone => const Color(0xFFE0B33B),
    PostType.poll => const Color(0xFF4DA3CC),
  };

  IconData _typeIcon(PostType type) => switch (type) {
    PostType.support => Icons.favorite_rounded,
    PostType.question => Icons.help_outline_rounded,
    PostType.tip => Icons.lightbulb_outline_rounded,
    PostType.vent => Icons.whatshot_rounded,
    PostType.milestone => Icons.emoji_events_rounded,
    PostType.poll => Icons.poll_rounded,
  };

  String _typeLabel(PostType type, AppLocalizations l10n) => switch (type) {
    PostType.support => l10n.postTypeSupport,
    PostType.question => l10n.postTypeQuestion,
    PostType.tip => l10n.postTypeTip,
    PostType.vent => l10n.postTypeVent,
    PostType.milestone => l10n.postTypeMilestone,
    PostType.poll => l10n.postTypePoll,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = context.read<CommunityRepository>();
    final time = communityRelativeTime(context, post.createdAt);
    final typeColor = _typeColor(post.postType);
    final languageCode = Localizations.localeOf(context).languageCode;
    final community = CommunitySeed.byId(post.communityId);
    final communityLabel =
        post.communityName ?? community?.nameForLocale(languageCode);

    return Semantics(
      button: true,
      label: '${post.authorAlias}: ${post.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: isDark
              ? AuraColors.darkCard.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.94),
          elevation: isDark ? 0 : 1,
          shadowColor: AuraColors.plum.withValues(alpha: 0.08),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : theme.colorScheme.outline.withValues(alpha: 0.07),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 2, color: typeColor.withValues(alpha: 0.7)),
                // Feed context comes first, as in a modern multi-community
                // timeline: members immediately know which group a post
                // belongs to before reading the author and content.
                if (showCommunity && communityLabel != null) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      10,
                      10,
                      9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(
                              alpha: isDark ? 0.16 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            community?.icon ?? Icons.groups_rounded,
                            size: 17,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            communityLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.62,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.07),
                  ),
                ],
                // ── Header ──
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 8, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with ring — tap opens the member profile
                      GestureDetector(
                        onTap: post.isAnonymous
                            ? null
                            : () => showMemberProfileSheet(
                                context,
                                communityId: post.communityId,
                                authorUid: post.authorUid,
                                alias: post.authorAlias,
                                avatarIndex: post.authorAvatarIndex,
                                isPremium: post.authorIsPremium,
                              ),
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: typeColor.withValues(alpha: 0.32),
                              width: 1.5,
                            ),
                          ),
                          child: post.isAnonymous
                              ? Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.55),
                                  ),
                                  child: Icon(
                                    Icons.visibility_off_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : AppAvatar(
                                  radius: 19,
                                  avatarIndex: post.authorAvatarIndex,
                                  uidSeed: post.authorUid,
                                  isPremium: post.authorIsPremium,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.authorAlias,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (post.authorIsPremium)
                                  const PremiumNameBadge(),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 0,
                              runSpacing: 2,
                              children: [
                                Text(
                                  time,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (post.isEdited)
                                  Text(
                                    ' · ${l10n.communityEdited}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (post.isPendingReview)
                                  Text(
                                    ' · ${l10n.communityPendingReview}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (uid != null && uid != post.authorUid)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                          onSelected: (action) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (action == 'copy') {
                              await copyCommunityText(context, post.text);
                            } else if (action == 'report') {
                              final reason = await showReportReasonSheet(
                                context,
                              );
                              if (reason == null || !context.mounted) {
                                return;
                              }
                              await repo.reportPost(
                                communityId: post.communityId,
                                postId: post.id,
                                reporterUid: uid,
                                reason: reason.code,
                                authorUid: post.authorUid,
                                authorAlias: post.authorAlias,
                              );
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.communityReported)),
                              );
                            } else if (action == 'block') {
                              final confirmed = await confirmBlockUser(
                                context,
                                authorAlias: post.authorAlias,
                              );
                              if (!confirmed || !context.mounted) return;
                              await repo.blockUser(
                                uid: uid,
                                blockedUid: post.authorUid,
                                authorAlias: post.authorAlias,
                              );
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.communityBlocked)),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  const Icon(Icons.copy_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.communityCopy),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  const Icon(Icons.flag_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.communityReportPost),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  const Icon(Icons.block_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.communityBlockUser),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // ── Compact metadata ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TypeBadge(
                        color: typeColor,
                        icon: _typeIcon(post.postType),
                        label: _typeLabel(post.postType, l10n),
                      ),
                      if (!showCommunity && communityLabel != null)
                        _PostMetaBadge(
                          icon: Icons.groups_rounded,
                          label: communityLabel,
                          color: theme.colorScheme.primary,
                        ),
                      if (post.postType == PostType.question &&
                          (post.hasBestAnswer || post.commentCount > 0))
                        _PostMetaBadge(
                          icon: post.hasBestAnswer
                              ? Icons.verified_rounded
                              : Icons.help_outline_rounded,
                          label: post.hasBestAnswer
                              ? l10n.communityBestAnswer
                              : l10n.communityAnswered,
                          color: theme.colorScheme.tertiary,
                        ),
                    ],
                  ),
                ),
                // ── Milestone celebration banner ──
                if (post.postType == PostType.milestone) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFE0B33B,
                        ).withValues(alpha: isDark ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: const Color(
                            0xFFE0B33B,
                          ).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFE0B33B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.postTypeMilestone,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isDark
                                    ? const Color(0xFFFFD875)
                                    : const Color(0xFF8A6510),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // ── Text (inside a designed gradient cover when one is set) ──
                if (post.text.isNotEmpty &&
                    post.text != '📷' &&
                    post.text != '🎬') ...[
                  const SizedBox(height: 10),
                  if (_coverFor(post) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _PostCoverView(
                        style: _coverFor(post)!,
                        text: CommunityTextSanitize.forDisplay(post.text),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        CommunityTextSanitize.forDisplay(post.text),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          letterSpacing: 0.05,
                          fontWeight: post.postType == PostType.milestone
                              ? FontWeight.w600
                              : null,
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                // ── Poll ──
                if (post.isPoll) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: PollView(post: post, accentColor: typeColor),
                  ),
                ],
                // ── Media follows the post text, matching familiar social
                // feed reading order. All media behavior stays unchanged.
                if (post.hasImage || post.hasVideo) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: PostMediaView(
                      mediaUrl: post.mediaUrl!,
                      mediaType: post.mediaType!,
                      compact: post.hasVideo,
                    ),
                  ),
                ],
                // ── Top-comment preview (server-denormalised) ──
                if (post.hasTopComment) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: isDark ? 0.28 : 0.45),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppAvatar(
                            radius: 11,
                            avatarIndex: post.topCommentAvatarIndex,
                            uidSeed: post.topCommentAlias ?? post.id,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${post.topCommentAlias ?? ''}  ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: CommunityTextSanitize.forDisplay(
                                      post.topCommentPreview!,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // ── Action bar ──
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: theme.colorScheme.outline.withValues(alpha: 0.09),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (uid != null) _ReactionAction(post: post, uid: uid),
                      CommunityPostAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: post.commentCount > 0
                            ? '${post.commentCount}'
                            : null,
                        onTap: onTap,
                      ),
                      if (uid != null) ...[
                        CommunityPostAction(
                          icon: Icons.ios_share_rounded,
                          onTap: () {
                            final lang = Localizations.localeOf(
                              context,
                            ).languageCode;
                            final community = CommunitySeed.byId(
                              post.communityId,
                            );
                            final name =
                                post.communityName ??
                                community?.nameForLocale(lang) ??
                                l10n.navCommunity;
                            shareCommunityPost(
                              post: post,
                              communityName: name,
                              shareLabel: l10n.communityShareVia,
                            );
                          },
                        ),
                        if (savedOverride != null)
                          _savedAction(
                            context: context,
                            repo: repo,
                            uid: uid,
                            saved: savedOverride!,
                            l10n: l10n,
                          )
                        else
                          StreamBuilder<bool>(
                            stream: repo.watchPostSaved(
                              uid,
                              post.communityId,
                              post.id,
                            ),
                            builder: (context, savedSnap) => _savedAction(
                              context: context,
                              repo: repo,
                              uid: uid,
                              saved: savedSnap.data ?? false,
                              l10n: l10n,
                              savedLoaded: savedSnap.hasData,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reaction button: tap toggles a heart, long-press opens a picker with the
/// per-reaction breakdown. One Firestore listener per card (replaces the old
/// liked + count pair).
class _ReactionAction extends StatelessWidget {
  const _ReactionAction({required this.post, required this.uid});

  final CommunityPost post;
  final String uid;

  static const _emoji = {
    'heart': '❤️',
    'hug': '🤗',
    'celebrate': '🎉',
    'strong': '💪',
  };

  String _label(String kind, AppLocalizations l10n) => switch (kind) {
    'hug' => l10n.reactionHug,
    'celebrate' => l10n.reactionCelebrate,
    'strong' => l10n.reactionStrong,
    _ => l10n.reactionHeart,
  };

  Future<void> _react(
    BuildContext context,
    CommunityRepository repo,
    String reaction,
    String? currentReaction,
    bool currentReactionLoaded,
  ) async {
    HapticFeedback.selectionClick();
    try {
      await repo.setPostReaction(
        communityId: post.communityId,
        postId: post.id,
        uid: uid,
        reaction: reaction,
        currentReaction: currentReaction,
        currentReactionLoaded: currentReactionLoaded,
      );
    } catch (e) {
      debugPrint('_ReactionAction failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  void _showPicker(
    BuildContext context,
    CommunityRepository repo,
    PostReactions reactions,
    bool reactionsLoaded,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              for (final kind in CommunityRepository.postReactionKinds)
                Expanded(
                  child: _ReactionPickerItem(
                    emoji: _emoji[kind]!,
                    label: _label(kind, l10n),
                    count: reactions.countFor(kind),
                    selected: reactions.myReaction == kind,
                    onTap: () {
                      Navigator.pop(ctx);
                      _react(
                        context,
                        repo,
                        kind,
                        reactions.myReaction,
                        reactionsLoaded,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommunityRepository>();

    return StreamBuilder<PostReactions>(
      stream: repo.watchPostReactions(post.communityId, post.id, uid),
      builder: (context, snap) {
        final reactions = snap.data ?? const PostReactions();
        final mine = reactions.myReaction;
        final theme = Theme.of(context);
        final color = mine != null
            ? AuraColors.rose
            : theme.colorScheme.onSurfaceVariant;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                _react(context, repo, mine ?? 'heart', mine, snap.hasData),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showPicker(context, repo, reactions, snap.hasData);
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: mine == null
                        ? Icon(
                            Icons.favorite_border_rounded,
                            key: const ValueKey('none'),
                            size: 18,
                            color: color,
                          )
                        : Text(
                            _emoji[mine] ?? '❤️',
                            key: ValueKey(mine),
                            style: const TextStyle(fontSize: 15),
                          ),
                  ),
                  if (reactions.total > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '${reactions.total}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: mine != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReactionPickerItem extends StatelessWidget {
  const _ReactionPickerItem({
    required this.emoji,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count > 0)
              Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostMetaBadge extends StatelessWidget {
  const _PostMetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.62,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width designed cover for text posts: gradient background, faint
/// oversized watermark icon, and the post text centered in white — the
/// magazine look without shipping or moderating any imagery.
class _PostCoverView extends StatelessWidget {
  const _PostCoverView({required this.style, required this.text});

  final PostCoverStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(gradient: style.gradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PositionedDirectional(
              end: -18,
              bottom: -22,
              child: Icon(
                style.icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 26,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
