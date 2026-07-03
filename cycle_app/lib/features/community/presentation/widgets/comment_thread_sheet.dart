import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/premium/premium_badge.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/community_comment.dart';
import '../community_feed_utils.dart';

typedef CommentActionCallback = void Function(CommunityComment comment);

Future<void> showCommentThreadSheet({
  required BuildContext context,
  required CommunityComment root,
  required List<CommunityComment> allComments,
  required String? bestAnswerId,
  required CommentActionCallback onCommentTap,
}) {
  final l10n = AppLocalizations.of(context)!;
  final replies = collectThreadReplies(root.id, allComments);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.75;

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: maxHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1420).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
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
                          gradient: AuraDecorations.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.forum_rounded,
                          size: 17,
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
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
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
                        onTap: () => onCommentTap(root),
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
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.5),
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
                            onTap: () => onCommentTap(entry.value),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
    this.isBest = false,
    this.isRoot = false,
    this.isLast = false,
  });

  final CommunityComment comment;
  final VoidCallback onTap;
  final bool isBest;
  final bool isRoot;
  final bool isLast;

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Material(
                    color: isRoot
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.08),
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
                                      Expanded(
                                        child: Text(
                                          comment.authorAlias,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: isRoot ? null : 13,
                                          ),
                                        ),
                                      ),
                                      if (comment.authorIsPremium)
                                        const PremiumNameBadge(),
                                      if (isBest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bestColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                            border: Border.all(
                                              color: bestColor
                                                  .withValues(alpha: 0.2),
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
                                                style: theme
                                                    .textTheme.labelSmall
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
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.text,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      fontSize: isRoot ? null : 13,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
