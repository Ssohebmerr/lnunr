import 'package:flutter/material.dart';

import '../../../core/ai/models/ai_insight.dart';

import '../../../core/ai/widgets/ai_insight_card.dart';
import '../../../core/widgets/app_surface.dart';

import '../../../l10n/app_localizations.dart';

import '../../cycle/data/cycle_bridge_service.dart';

import '../data/pregnancy_development_content.dart';

import '../data/pregnancy_fetal_stage.dart';

import '../data/pregnancy_growth_display.dart';

import 'pregnancy_tracking_section.dart';

import 'pregnancy_week_picker.dart';

/// Pregnancy-mode home: week scrubber, fetal art, trackers, optional deep-dive.

class HomePregnancySection extends StatefulWidget {
  const HomePregnancySection({
    super.key,

    required this.data,

    this.onOpenCalendar,
  });

  final CycleDashboardData data;

  final VoidCallback? onOpenCalendar;

  @override
  State<HomePregnancySection> createState() => _HomePregnancySectionState();
}

class _HomePregnancySectionState extends State<HomePregnancySection> {
  late int _selectedWeek;

  int _selectedEarlyDay = 1;

  @override
  void initState() {
    super.initState();

    _selectedWeek = widget.data.pregnancyWeek.clamp(
      minPregnancyVisualWeek,
      maxPregnancyVisualWeek,
    );

    if (_selectedWeek == minPregnancyVisualWeek) {
      _selectedEarlyDay = widget.data.cycleDay.clamp(1, 7);
    }
  }

  @override
  void didUpdateWidget(covariant HomePregnancySection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data.pregnancyWeek != widget.data.pregnancyWeek) {
      _selectedWeek = widget.data.pregnancyWeek.clamp(
        minPregnancyVisualWeek,
        maxPregnancyVisualWeek,
      );

      if (_selectedWeek == minPregnancyVisualWeek) {
        _selectedEarlyDay = widget.data.cycleDay.clamp(1, 7);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final lang = Localizations.localeOf(context).languageCode;

    final currentWeek = widget.data.pregnancyWeek.clamp(
      minPregnancyVisualWeek,
      maxPregnancyVisualWeek,
    );

    final selectedDay = _selectedWeek == minPregnancyVisualWeek
        ? _selectedEarlyDay
        : (_selectedWeek == currentWeek ? widget.data.cycleDay.clamp(1, 7) : 7);

    final weekInfo = PregnancyDevelopmentContent.forWeek(_selectedWeek, lang);

    final nextInfo = PregnancyDevelopmentContent.nextWeekPreview(_selectedWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        if (widget.data.expectedDueDate.isNotEmpty &&
            widget.data.expectedDueDate != '—') ...[
          Wrap(
            spacing: 8,

            runSpacing: 8,

            children: [
              AppStatChip(
                icon: Icons.event_available_outlined,

                label: l10n.pregnancyDueDate(widget.data.expectedDueDate),

                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],

        PregnancyWeekPicker(
          currentWeek: currentWeek,

          selectedWeek: _selectedWeek,

          onWeekSelected: (w) => setState(() {
            _selectedWeek = w;
            if (w == minPregnancyVisualWeek) _selectedEarlyDay = 1;
          }),
        ),

        const SizedBox(height: 10),

        PregnancyBabyHeroCard(
          week: _selectedWeek,
          gestationalDay: selectedDay,
          lang: lang,
          onGestationalDaySelected: (day) =>
              setState(() => _selectedEarlyDay = day),
        ),

        const SizedBox(height: 12),

        const PregnancyTrackingSection(),

        if (widget.onOpenCalendar != null) ...[
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: widget.onOpenCalendar,

            icon: const Icon(Icons.calendar_month_outlined),

            label: Text(l10n.homeOpenCalendar),
          ),
        ],

        const SizedBox(height: 12),

        AppGlassCard(
          blur: false,

          padding: EdgeInsets.zero,

          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),

            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),

              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

              leading: Icon(
                Icons.favorite_outline_rounded,

                color: theme.colorScheme.secondary,
              ),

              title: Text(
                l10n.pregnancyYourBody,

                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              children: [
                Text(
                  weekInfo.maternalFor(lang),

                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),

                if (nextInfo != null) ...[
                  const SizedBox(height: 16),

                  Text(
                    l10n.pregnancyBabyNextWeek,

                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,

                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  PregnancyGrowthStatsRow(info: nextInfo, lang: lang),

                  const SizedBox(height: 6),

                  Text(
                    nextInfo.bodyFor(lang),

                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],

                const SizedBox(height: 12),

                const AiInsightCard(
                  type: AiInsightType.prenatalTip,
                  compact: true,
                  margin: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
