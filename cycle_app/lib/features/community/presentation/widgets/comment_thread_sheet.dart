import 'package:flutter/material.dart';

import '../../../../core/premium/premium_badge.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/community_comment.dart';
import '../community_feed_utils.dart';
import 'comment_like_button.dart';
import 'community_time.dart';

typedef CommentActionCallback = void Function(CommunityComment comment);

Future<void> showCommentThreadSheet({
  required BuildContext context,
  required CommunityComment root,
  required List<CommunityComment> allComments,
  required String? bestAnswerId,
  required CommentActionCallback onCommentTap,
  CommentActionCallback? onReply,
  String? communityId,
  String? postId,
}) {
  final l10n = AppLocalizations.of(context)!;
  final replies = collectThreadReplies(root.id, allComments);

  String? aliasOf(String? commentId) {
    if (commentId == null) return null;
    for (final c in allComments) {
      if (c.id == commentId) return c.authorAlias;
    }
    return null;
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.75;

      return Material(
        color: isDark ? AuraColors.darkBg : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.communityThreadTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        l10n.communityViewReplies(replies.length),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
              // Comments list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    _ThreadCommentTile(
                      comment: root,
                      isBest: bestAnswerId == root.id,
                      isRoot: true,
                      communityId: communityId,
                      postId: postId,
                      onTap: () => onCommentTap(root),
                      onReply: onReply == null
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              onReply(root);
                            },
                    ),
                    if (replies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 28,
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.communityNoReplies,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...replies.asMap().entries.map(
                        (entry) => _ThreadCommentTile(
                          comment: entry.value,
                          isBest: bestAnswerId == entry.value.id,
                          isLast: entry.key == replies.length - 1,
                          communityId: communityId,
                          postId: postId,
                          replyingToAlias:
                              entry.value.parentCommentId == root.id
                              ? null
                              : aliasOf(entry.value.parentCommentId),
                          onTap: () => onCommentTap(entry.value),
                          onReply: onReply == null
                              ? null
                              : () {
                                  Navigator.of(ctx).pop();
                                  onReply(entry.value);
                                },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ThreadCommentTile extends StatelessWidget {
  const _ThreadCommentTile({
    required this.comment,
    required this.onTap,
    this.onReply,
    this.replyingToAlias,
    this.isBest = false,
    this.isRoot = false,
    this.isLast = false,
    this.communityId,
    this.postId,
  });

  final CommunityComment comment;
  final VoidCallback onTap;
  final VoidCallback? onReply;
  final String? replyingToAlias;
  final bool isBest;
  final bool isRoot;
  final bool isLast;
  final String? communityId;
  final String? postId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bestColor = theme.colorScheme.tertiary;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Threading line
            if (!isRoot) ...[
              Column(
                children: [
                  Container(
                    width: 3,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isBest
                          ? bestColor
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Material(
                color: isRoot
                    ? (isDark
                          ? AuraColors.darkCard.withValues(alpha: 0.82)
                          : Colors.white.withValues(alpha: 0.84))
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: isRoot
                      ? BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.07,
                          ),
                        )
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: EdgeInsets.all(isRoot ? 14 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isBest
                                ? LinearGradient(
                                    colors: [
                                      bestColor.withValues(alpha: 0.5),
                                      bestColor.withValues(alpha: 0.15),
                                    ],
                                  )
                                : null,
                            border: isBest
                                ? null
                                : Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                          ),
                          child: AppAvatar(
                            radius: isRoot ? 17 : 13,
                            avatarIndex: comment.authorAvatarIndex,
                            uidSeed: comment.authorUid,
                            isPremium: comment.authorIsPremium,
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
                                      comment.authorAlias,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: isRoot ? null : 13,
                                          ),
                                    ),
                                  ),
                                  if (comment.authorIsPremium)
                                    const PremiumNameBadge(),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 8,
                                      ),
                                      child: Text(
                                        communityRelativeTime(
                                          context,
                                          comment.createdAt,
                                        ),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (isBest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bestColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                        border: Border.all(
                                          color: bestColor.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: bestColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            l10n.communityBestAnswer,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: bestColor,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (comment.isEdited)
                                Text(
                                  l10n.communityEdited,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (replyingToAlias != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.subdirectory_arrow_right_rounded,
                                        size: 12,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          l10n.communityReplyingTo(
                                            replyingToAlias!,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                  fontSize: isRoot ? null : 13,
                                ),
                              ),
                              if ((communityId != null && postId != null) ||
                                  onReply != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (communityId != null && postId != null)
                                      CommentLikeButton(
                                        communityId: communityId!,
                                        postId: postId!,
                                        commentId: comment.id,
                                      ),
                                    if (onReply != null) ...[
                                      const SizedBox(width: 10),
                                      TextButton.icon(
                                        onPressed: onReply,
                                        icon: const Icon(
                                          Icons.reply_outlined,
                                          size: 14,
                                        ),
                                        label: Text(l10n.communityReply),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }
}
