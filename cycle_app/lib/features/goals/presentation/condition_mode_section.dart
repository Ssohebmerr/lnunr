import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';

/// A short titled paragraph used in the "understanding" area.
class ConditionEducation {
  const ConditionEducation({required this.title, required this.body});
  final String title;
  final String body;
}

/// Shared home body for ongoing-condition goals (menopause, PCOS) that are a
/// life stage rather than a countdown. Structure: banner → cycle context →
/// what-to-track → understanding cards → daily tip → rituals → doctor note.
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
    required this.trackLabels,
    required this.education,
    required this.dailyTip,
    required this.rituals,
    required this.doctorNote,
    this.onOpenCalendar,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  /// e.g. "Cycle regularity" / "62%".
  final String cycleContextLabel;
  final String cycleContextValue;

  final List<String> trackLabels;
  final List<ConditionEducation> education;
  final String dailyTip;
  final List<String> rituals;
  final String doctorNote;
  final VoidCallback? onOpenCalendar;

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
                  padding: const EdgeInsets.all(11),
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

        // ── Cycle context + daily tip ─────────────────────────────────────
        Row(
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
        const SizedBox(height: 14),

        // ── What to track ─────────────────────────────────────────────────
        AppSectionHeader(title: l10n.conditionWhatToTrack),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trackLabels
              .map((t) => AppStatChip(icon: Icons.add_circle_outline, label: t))
              .toList(),
        ),
        const SizedBox(height: 14),

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

        // ── Rituals ───────────────────────────────────────────────────────
        if (rituals.isNotEmpty) ...[
          const SizedBox(height: 2),
          AppSectionHeader(title: l10n.conditionDailyRituals),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rituals
                .map((r) => AppStatChip(icon: Icons.spa_outlined, label: r))
                .toList(),
          ),
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
