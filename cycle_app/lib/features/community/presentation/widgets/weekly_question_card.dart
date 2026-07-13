import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_weekly_questions.dart';
import 'community_ui.dart';

/// "Question of the week" banner shown at the top of a community's posts.
/// The same question is shown to every member for the whole week.
class WeeklyQuestionCard extends StatelessWidget {
  const WeeklyQuestionCard({
    super.key,
    required this.topic,
    required this.onAnswer,
  });

  final String topic;

  /// Called with the localized question text; opens the composer pre-filled.
  final void Function(String question) onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final question = weeklyQuestionFor(topic).forLocale(lang);
    final isDark = theme.brightness == Brightness.dark;
    final accent = CommunityTopicPalette.iconColor(topic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AuraColors.darkCard.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.communityWeeklyQuestion,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                onPressed: () => onAnswer(question),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text(l10n.communityWeeklyAnswer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
