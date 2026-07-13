import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../data/condition_catalog.dart';
import '../data/condition_log_store.dart';
import '../data/goal_mode_content.dart';

/// "Your trends" block for the life-stage condition goals, shown in Reports.
///
/// Turns the daily logs captured on the Home screen ([ConditionLogStore])
/// into visible history: a 14-day bar chart (hot flashes / mood / symptom
/// load depending on the goal), the most frequent symptoms over 30 days, and
/// a consistency row (days logged + ritual completion). Without this the
/// logging chips write data nobody ever sees again.
class ConditionTrendsSection extends StatefulWidget {
  const ConditionTrendsSection({super.key, required this.goal});

  final UserGoalTypes goal;

  @override
  State<ConditionTrendsSection> createState() => _ConditionTrendsSectionState();
}

class _TrendData {
  const _TrendData({
    required this.symptoms30,
    required this.rituals7,
    required this.metric14,
  });

  /// dayKey → logged symptom slugs, last 30 days.
  final Map<String, Set<String>> symptoms30;

  /// dayKey → completed ritual slugs, last 7 days.
  final Map<String, Set<String>> rituals7;

  /// dayKey → metric value (hot flashes or mood), last 14 days.
  final Map<String, int> metric14;

  bool get isEmpty =>
      symptoms30.isEmpty && rituals7.isEmpty && metric14.isEmpty;
}

class _ConditionTrendsSectionState extends State<ConditionTrendsSection> {
  late final Future<_TrendData> _future = _load();

  Future<_TrendData> _load() async {
    final metricName = switch (widget.goal) {
      UserGoalTypes.menopause => ConditionLogStore.metricHotFlash,
      UserGoalTypes.postpartum => ConditionLogStore.metricMood,
      _ => null,
    };
    final symptoms = await ConditionLogStore.symptomHistory(days: 30);
    final rituals = await ConditionLogStore.ritualHistory(days: 7);
    final metric = metricName == null
        ? <String, int>{}
        : await ConditionLogStore.metricHistory(metricName, days: 14);
    return _TrendData(symptoms30: symptoms, rituals7: rituals, metric14: metric);
  }

  Color get _accent => switch (widget.goal) {
    UserGoalTypes.menopause => const Color(0xFF8D6E63),
    UserGoalTypes.pcos => const Color(0xFF26A69A),
    _ => const Color(0xFFEC407A),
  };

  int get _ritualCatalogSize => GoalModeContent.rituals(widget.goal).length;

  /// The last [days] dayKeys, oldest first (today last).
  static List<String> _dayKeys(int days) {
    final now = DateTime.now();
    return List.generate(
      days,
      (i) => ConditionLogStore.dayKey(
        now.subtract(Duration(days: days - 1 - i)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<_TrendData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: l10n.conditionTrendsTitle),
            if (data.isEmpty)
              _EmptyTrendsCard(text: l10n.conditionTrendsEmpty)
            else ...[
              _buildChartCard(context, l10n, data),
              const SizedBox(height: 12),
              _buildTopSymptomsCard(context, l10n, data),
              _buildConsistencyRow(context, l10n, data),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    AppLocalizations l10n,
    _TrendData data,
  ) {
    final days = _dayKeys(14);
    final (title, icon, maxScale) = switch (widget.goal) {
      UserGoalTypes.menopause => (
        l10n.conditionTrendHotFlashes,
        Icons.local_fire_department_outlined,
        0,
      ),
      UserGoalTypes.postpartum => (
        l10n.conditionTrendMood,
        Icons.sentiment_satisfied_alt_outlined,
        5,
      ),
      _ => (l10n.conditionTrendSymptomsPerDay, Icons.bubble_chart_outlined, 0),
    };

    final values = switch (widget.goal) {
      UserGoalTypes.pcos =>
        days.map((d) => data.symptoms30[d]?.length ?? 0).toList(),
      _ => days.map((d) => data.metric14[d] ?? 0).toList(),
    };

    return _TrendBarChartCard(
      title: title,
      subtitle: l10n.conditionTrendLast14Days,
      todayLabel: l10n.conditionTrendToday,
      icon: icon,
      accent: _accent,
      values: values,
      fixedMax: maxScale > 0 ? maxScale : null,
    );
  }

  Widget _buildTopSymptomsCard(
    BuildContext context,
    AppLocalizations l10n,
    _TrendData data,
  ) {
    final lang = Localizations.localeOf(context).languageCode;
    final labels = ConditionCatalog.symptomLabels(widget.goal, lang);

    final counts = <String, int>{};
    for (final set in data.symptoms30.values) {
      for (final slug in set) {
        counts[slug] = (counts[slug] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(5).toList();
    final maxCount = shown.first.value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        blur: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 18, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.conditionTopSymptoms,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.conditionTrendLast30Days,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final entry in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        labels[entry.key] ?? entry.key.replaceAll('_', ' '),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: entry.value / maxCount,
                          minHeight: 8,
                          color: _accent,
                          backgroundColor: theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyRow(
    BuildContext context,
    AppLocalizations l10n,
    _TrendData data,
  ) {
    final theme = Theme.of(context);

    final loggedDays = <String>{
      ...data.symptoms30.keys,
      ...data.metric14.keys,
      ...data.rituals7.keys,
    }.length;

    final catalog = _ritualCatalogSize;
    final ritualsDone = data.rituals7.values.fold<int>(
      0,
      (sum, set) => sum + set.length,
    );
    final completion = catalog == 0
        ? 0
        : ((ritualsDone / (catalog * 7)) * 100).clamp(0, 100).round();

    Widget statCard(IconData icon, String value, String label, String hint) {
      return Expanded(
        child: AppGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: _accent),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                hint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statCard(
            Icons.event_available_outlined,
            '$loggedDays/30',
            l10n.conditionDaysLogged,
            l10n.conditionTrendLast30Days,
          ),
          const SizedBox(width: 12),
          statCard(
            Icons.spa_outlined,
            '$completion%',
            l10n.conditionRitualCompletion,
            l10n.conditionTrendLast7Days,
          ),
        ],
      ),
    );
  }
}

class _EmptyTrendsCard extends StatelessWidget {
  const _EmptyTrendsCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      child: Row(
        children: [
          Icon(
            Icons.query_stats_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight 14-bar chart — one bar per day, oldest at the start, today at
/// the end (highlighted). Deliberately dependency-free so it renders the same
/// in LTR and RTL.
class _TrendBarChartCard extends StatelessWidget {
  const _TrendBarChartCard({
    required this.title,
    required this.subtitle,
    required this.todayLabel,
    required this.icon,
    required this.accent,
    required this.values,
    this.fixedMax,
  });

  final String title;
  final String subtitle;
  final String todayLabel;
  final IconData icon;
  final Color accent;
  final List<int> values;

  /// Fixed scale ceiling (e.g. 5 for mood); otherwise the data maximum.
  final int? fixedMax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataMax = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final max = fixedMax ?? (dataMax > 0 ? dataMax : 1);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _Bar(
                      fraction: max == 0 ? 0 : values[i] / max,
                      isToday: i == values.length - 1,
                      accent: accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0–$max',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                todayLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.isToday,
    required this.accent,
  });

  final double fraction;
  final bool isToday;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = fraction.clamp(0.0, 1.0);
    // Zero days keep a faint 3px stub so the timeline stays readable.
    final height = clamped == 0 ? 3.0 : (6 + clamped * 84);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: clamped == 0
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
                : accent.withValues(alpha: isToday ? 1 : 0.45 + clamped * 0.35),
          ),
        ),
      ],
    );
  }
}
