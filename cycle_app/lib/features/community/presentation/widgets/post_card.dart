import 'dart:ui';

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
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final bool showCommunity;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withValues(alpha: isDark ? 0.05 : 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 0),
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
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    typeColor.withValues(alpha: 0.5),
                                    typeColor.withValues(alpha: 0.15),
                                  ],
                                ),
                              ),
                              child: post.isAnonymous
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.55),
                                      ),
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 18,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                  : AppAvatar(
                                      radius: 20,
                                      avatarIndex: post.authorAvatarIndex,
                                      uidSeed: post.authorUid,
                                      isPremium: post.authorIsPremium,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        post.authorAlias,
                                        style:
                                            theme.textTheme.titleSmall?.copyWith(
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
                                Row(
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
                          _TypeBadge(
                            color: typeColor,
                            icon: _typeIcon(post.postType),
                            label: _typeLabel(post.postType, l10n),
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
                                  final reason = await showReportReasonSheet(context);
                                  if (reason == null || !context.mounted) return;
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
                    // ── Community label ──
                    if (showCommunity && post.communityName != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 13,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  post.communityName!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // ── Media ──
                    if (post.hasImage || post.hasVideo) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PostMediaView(
                          mediaUrl: post.mediaUrl!,
                          mediaType: post.mediaType!,
                          compact: post.hasVideo,
                        ),
                      ),
                    ],
                    // ── Milestone celebration banner ──
                    if (post.postType == PostType.milestone) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE0B33B),
                                Color(0xFFFFC75A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE0B33B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.postTypeMilestone,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.celebration_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // ── Text ──
                    if (post.text.isNotEmpty &&
                        post.text != '📷' &&
                        post.text != '🎬') ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          CommunityTextSanitize.forDisplay(post.text),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            letterSpacing: 0.05,
                            fontWeight: post.postType == PostType.milestone
                                ? FontWeight.w600
                                : null,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    // ── Poll ──
                    if (post.isPoll) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PollView(post: post, accentColor: typeColor),
                      ),
                    ],
                    // ── Action bar ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                if (uid != null) ...[
                                  _ReactionAction(post: post, uid: uid),
                                  StreamBuilder<bool>(
                                    stream: repo.watchPostSaved(
                                      uid,
                                      post.communityId,
                                      post.id,
                                    ),
                                    builder: (context, savedSnap) {
                                      final saved = savedSnap.data ?? false;
                                      return CommunityPostAction(
                                        icon: saved
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        active: saved,
                                        onTap: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final nowSaved =
                                              await repo.toggleSavePost(
                                                  uid, post);
                                          if (context.mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  nowSaved
                                                      ? l10n.communityPostSaved
                                                      : l10n
                                                          .communityPostUnsaved,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                  CommunityPostAction(
                                    icon: Icons.ios_share_rounded,
                                    onTap: () {
                                      final lang =
                                          Localizations.localeOf(context)
                                              .languageCode;
                                      final community =
                                          CommunitySeed.byId(post.communityId);
                                      final name = post.communityName ??
                                          community?.nameForLocale(lang) ??
                                          l10n.navCommunity;
                                      shareCommunityPost(
                                        post: post,
                                        communityName: name,
                                        shareLabel: l10n.communityShareVia,
                                      );
                                    },
                                  ),
                                ],
                                CommunityPostAction(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: post.commentCount > 0
                                      ? '${post.commentCount}'
                                      : null,
                                  onTap: onTap,
                                ),
                                const Spacer(),
                                if (post.postType == PostType.question &&
                                    (post.hasBestAnswer ||
                                        post.commentCount > 0))
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.only(end: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          post.hasBestAnswer
                                              ? Icons.verified_rounded
                                              : Icons.help_outline_rounded,
                                          size: 15,
                                          color: theme.colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          post.hasBestAnswer
                                              ? l10n.communityBestAnswer
                                              : l10n.communityAnswered,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.tertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
  ) async {
    HapticFeedback.selectionClick();
    try {
      await repo.setPostReaction(
        communityId: post.communityId,
        postId: post.id,
        uid: uid,
        reaction: reaction,
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
                      _react(context, repo, kind);
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
            onTap: () => _react(context, repo, mine ?? 'heart'),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showPicker(context, repo, reactions);
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        fontWeight:
                            mine != null ? FontWeight.w700 : FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
