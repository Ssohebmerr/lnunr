import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../data/community_repository.dart';

/// Compact heart + count for a single comment. Hidden for signed-out viewers.
class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({
    super.key,
    required this.communityId,
    required this.postId,
    required this.commentId,
  });

  final String communityId;
  final String postId;
  final String commentId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final repo = context.read<CommunityRepository>();
    final theme = Theme.of(context);

    return StreamBuilder<({int count, bool liked})>(
      stream: repo.watchCommentLikes(communityId, postId, commentId, uid),
      builder: (context, snap) {
        final count = snap.data?.count ?? 0;
        final liked = snap.data?.liked ?? false;
        final color = liked
            ? AuraColors.rose
            : theme.colorScheme.onSurfaceVariant;

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            repo.toggleCommentLike(
              communityId: communityId,
              postId: postId,
              commentId: commentId,
              uid: uid,
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 14,
                  color: color,
                ),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: liked ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
