import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/ai/models/ai_insight.dart';
import '../../../core/ai/widgets/ai_insight_card.dart';
import '../../../l10n/app_localizations.dart';
import 'condition_widgets.dart';

/// A short titled paragraph used in the "understanding" area.
class ConditionEducation {
  const ConditionEducation({required this.title, required this.body});
  final String title;
  final String body;
}

/// Shared home body for ongoing-condition goals (menopause, PCOS) that are a
/// life stage rather than a countdown.
///
/// Structure: banner → condition-specific hero cards → cycle context + tip →
/// interactive symptom logger → understanding cards → daily ritual checklist →
/// doctor note. The symptom chips and ritual checklist persist to
/// [ConditionLogStore] via [ConditionTrackChips] / [ConditionRitualChecklist],
/// so nothing here is a dead button.
///
/// Content is passed in already-localized so this widget stays presentation
/// only and each goal keeps its own copy.
class ConditionModeSection extends StatelessWidget {
  const ConditionModeSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.cycleContextLabel,
    required this.cycleContextValue,
    required this.trackItems,
    required this.education,
    required this.dailyTip,
    required this.ritualItems,
    required this.doctorNote,
    this.heroExtras = const [],
    this.onOpenCalendar,
    this.aiInsightType,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  /// e.g. "Cycle regularity" / "62%".
  final String cycleContextLabel;
  final String cycleContextValue;

  /// Loggable symptoms (key + localized label) shown as interactive chips.
  final List<ConditionItem> trackItems;
  final List<ConditionEducation> education;
  final String dailyTip;

  /// Daily rituals shown as a tick-off checklist.
  final List<ConditionItem> ritualItems;
  final String doctorNote;

  /// Condition-specific interactive cards inserted below the banner
  /// (e.g. hot-flash counter, cycle-gap card).
  final List<Widget> heroExtras;
  final VoidCallback? onOpenCalendar;

  /// AI reading of what this goal has actually logged. The card hides itself
  /// when AI is unavailable, so passing a type is always safe.
  final AiInsightType? aiInsightType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Banner ─────────────────────────────────────────────────────────
        AppGlassCard(
          blur: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(colors: gradient),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Condition-specific hero cards ─────────────────────────────────
        for (final extra in heroExtras) ...[
          extra,
          const SizedBox(height: 12),
        ],

        // ── Cycle context + daily tip ─────────────────────────────────────
        // IntrinsicHeight gives the Row a bounded height so the two cards can
        // stretch to equal height. Without it, CrossAxisAlignment.stretch
        // inside the scrolling home list forces an infinite height and the
        // section fails to lay out.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppGlassCard(
                  blur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.timeline_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        cycleContextValue,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        cycleContextLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppGlassCard(
                  blur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        dailyTip,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── AI reading of the user's own logged pattern ────────────────────
        if (aiInsightType != null) ...[
          AiInsightCard(
            type: aiInsightType!,
            margin: EdgeInsets.zero,
            blur: false,
          ),
          const SizedBox(height: 14),
        ],

        // ── Symptom logger (interactive) ──────────────────────────────────
        AppSectionHeader(title: l10n.conditionHowAreYouToday),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.conditionTapToLog,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ConditionTrackChips(items: trackItems),
        const SizedBox(height: 16),

        // ── Understanding ─────────────────────────────────────────────────
        AppSectionHeader(title: l10n.conditionUnderstanding),
        const SizedBox(height: 8),
        ...education.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppGlassCard(
              blur: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.body,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Rituals (interactive checklist) ───────────────────────────────
        if (ritualItems.isNotEmpty) ...[
          const SizedBox(height: 2),
          AppSectionHeader(title: l10n.conditionDailyRituals),
          const SizedBox(height: 8),
          ConditionRitualChecklist(items: ritualItems),
          const SizedBox(height: 14),
        ],

        // ── Doctor note ───────────────────────────────────────────────────
        AppGlassCard(
          blur: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_information_outlined,
                    color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.conditionWhenToSeeDoctor,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorNote,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (onOpenCalendar != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOpenCalendar,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(l10n.homeOpenCalendar),
          ),
        ],
      ],
    );
  }
}
