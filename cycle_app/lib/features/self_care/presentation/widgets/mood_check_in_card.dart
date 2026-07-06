import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/self_care_content.dart';

/// Daily one-tap mood check-in. Feeds the AI whisper and builds a mood
/// history the reports/AI can reference. Controlled by the parent tab.
class MoodCheckInCard extends StatelessWidget {
  const MoodCheckInCard({
    super.key,
    required this.selected,
    required this.onSelect,
    this.history = const [],
  });

  final String? selected;
  final ValueChanged<String> onSelect;

  /// Recent mood entries (newest first) for the weekly trend strip.
  final List<({String date, String mood})> history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final done = selected != null;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  done ? l10n.moodCheckInDone : l10n.moodCheckInTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (done)
                Icon(Icons.check_circle_rounded,
                    size: 18, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final mood in SelfCareContent.moods)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MoodChip(
                      mood: mood,
                      lang: lang,
                      selected: selected == mood.key,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect(mood.key);
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (history.length >= 2) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.moodTrendTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _MoodTrendStrip(history: history),
          ],
        ],
      ),
    );
  }
}

/// A compact weekly strip: one dot per logged day (oldest → newest).
class _MoodTrendStrip extends StatelessWidget {
  const _MoodTrendStrip({required this.history});

  final List<({String date, String mood})> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // History arrives newest-first; show up to 7 days oldest → newest.
    final days = history.take(7).toList().reversed.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final entry in days)
          Builder(builder: (_) {
            final mood = SelfCareContent.moodByKey(entry.mood);
            final dayNum = entry.date.length >= 2
                ? entry.date.substring(entry.date.length - 2)
                : entry.date;
            return Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (mood?.color ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.18),
                  ),
                  child: Text(mood?.emoji ?? '·',
                      style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNum,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final MoodOption mood;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? mood.color.withValues(alpha: 0.22)
              : theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? mood.color.withValues(alpha: 0.7)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              mood.label(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
