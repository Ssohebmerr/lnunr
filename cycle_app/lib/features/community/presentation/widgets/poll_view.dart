import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_post.dart';

/// Interactive poll block shown inside a poll post card.
///
/// Before voting: tappable option rows. After voting (or for the author):
/// animated percentage bars with the viewer's choice highlighted. Votes can
/// be changed by tapping another option.
class PollView extends StatelessWidget {
  const PollView({super.key, required this.post, required this.accentColor});

  final CommunityPost post;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final options = post.pollOptions;
    if (options == null || options.length < 2) return const SizedBox.shrink();

    final repo = context.read<CommunityRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<PollResults>(
      stream: repo.watchPollResults(post.communityId, post.id, uid),
      initialData: const PollResults(),
      builder: (context, snap) {
        final results = snap.data ?? const PollResults();
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final showResults = results.hasVoted || post.authorUid == uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PollOptionRow(
                  label: options[i],
                  accentColor: accentColor,
                  fraction: showResults ? results.fractionFor(i) : 0,
                  showResults: showResults,
                  isMine: results.myVote == i,
                  onTap: uid == null
                      ? null
                      : () async {
                          if (results.myVote == i) return;
                          HapticFeedback.selectionClick();
                          try {
                            await repo.votePoll(
                              communityId: post.communityId,
                              postId: post.id,
                              uid: uid,
                              optionIndex: i,
                            );
                          } catch (e) {
                            debugPrint('PollView vote failed: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.errorGeneric)),
                              );
                            }
                          }
                        },
                ),
              ),
            Text(
              showResults
                  ? l10n.communityPollVotesCount(results.totalVotes)
                  : l10n.communityPollTapToVote,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.label,
    required this.accentColor,
    required this.fraction,
    required this.showResults,
    required this.isMine,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final double fraction;
  final bool showResults;
  final bool isMine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = (fraction * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: isDark ? 0.05 : 0.03,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isMine
                  ? accentColor.withValues(alpha: 0.55)
                  : theme.colorScheme.outline.withValues(alpha: 0.12),
              width: isMine ? 1.4 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              children: [
                // Result bar fill
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      widthFactor: showResults ? fraction.clamp(0.0, 1.0) : 0,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: isMine ? 0.28 : 0.14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      if (isMine) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isMine
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showResults) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isMine
                                ? accentColor
                                : theme.colorScheme.onSurfaceVariant,
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
