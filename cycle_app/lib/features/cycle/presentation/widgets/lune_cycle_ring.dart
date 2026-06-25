import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../../core/theme/app_design_tokens.dart';

/// Lune-branded cycle ring with readable Arabic phase labels (legend below).
class LuneCycleRing extends StatelessWidget {
  const LuneCycleRing({
    super.key,
    this.size = 240,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final palette = _LuneCyclePalette.forTheme(isDark);

    return Semantics(
      label: isAr ? 'حلقة تتبع الدورة الشهرية' : 'Cycle tracking ring',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenstrualCyclePhaseView(
          key: ValueKey(
            'lune-ring-${Localizations.localeOf(context).languageCode}',
          ),
          size: size,
          isAutoSetData: true,
          viewType: MenstrualCycleViewType.circleText,
          theme: MenstrualCycleTheme.arcs,
          // Outside arc labels break Arabic (drawn char-by-char). Use legend.
          phaseTextBoundaries: PhaseTextBoundaries.none,
          arcStrokeWidth: 22,
          isRemoveBackgroundPhaseColor: false,
          dayTitle: isAr ? 'يوم' : null,
          menstruationColor: palette.menstruation,
          menstruationBackgroundColor: palette.menstruationBg,
          menstruationDayTextColor: Colors.white,
          follicularPhaseColor: palette.follicular,
          follicularBackgroundColor: palette.follicularBg,
          follicularPhaseDayTextColor: isDark ? Colors.white : AuraColors.plum,
          ovulationColor: palette.ovulation,
          ovulationBackgroundColor: palette.ovulationBg,
          ovulationDayTextColor: isDark ? AuraColors.plum : Colors.white,
          lutealPhaseColor: palette.luteal,
          lutealPhaseBackgroundColor: palette.lutealBg,
          lutealPhaseDayTextColor: palette.lutealText,
          centralCircleBackgroundColor: palette.centerFill,
          centralCircleBorderColor: palette.centerBorder,
          centralCircleBorderSize: 2,
          centralCircleSize: 28,
          selectedDayBackgroundColor: palette.selectedFill,
          selectedDayTextColor: palette.selectedText,
          selectedDayCircleBorderColor: palette.selectedBorder,
          selectedDayCircleSize: 20,
          dayTextColor: palette.dayText,
          titleTextColor: palette.titleText,
          titleTextSize: isAr ? 19 : 22,
          titleFontWeight: FontWeight.w800,
          messageTextColor: palette.messageText,
          messageTextSize: isAr ? 11.5 : 12,
          messageFontWeight: FontWeight.w500,
          spaceBtnTitleMessage: 5,
        ),
        const SizedBox(height: 12),
        _LunePhaseLegend(isAr: isAr, palette: palette, theme: theme),
        ],
      ),
    );
  }
}

class _LunePhaseLegend extends StatelessWidget {
  const _LunePhaseLegend({
    required this.isAr,
    required this.palette,
    required this.theme,
  });

  final bool isAr;
  final _LuneCyclePalette palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = isAr
        ? [
            (palette.menstruation, 'الحيض'),
            (palette.follicular, 'جريبية'),
            (palette.ovulation, 'الإباضة'),
            (palette.lutealText, 'اللوتئية'),
          ]
        : [
            (palette.menstruation, 'Period'),
            (palette.follicular, 'Follicular'),
            (palette.ovulation, 'Ovulation'),
            (palette.lutealText, 'Luteal'),
          ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: items
          .map(
            (e) => _LegendChip(
              color: e.$1,
              label: e.$2,
              theme: theme,
            ),
          )
          .toList(),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.theme,
  });

  final Color color;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LuneCyclePalette {
  const _LuneCyclePalette({
    required this.menstruation,
    required this.menstruationBg,
    required this.follicular,
    required this.follicularBg,
    required this.ovulation,
    required this.ovulationBg,
    required this.luteal,
    required this.lutealBg,
    required this.lutealText,
    required this.centerFill,
    required this.centerBorder,
    required this.selectedFill,
    required this.selectedText,
    required this.selectedBorder,
    required this.dayText,
    required this.titleText,
    required this.messageText,
  });

  final Color menstruation;
  final Color menstruationBg;
  final Color follicular;
  final Color follicularBg;
  final Color ovulation;
  final Color ovulationBg;
  final Color luteal;
  final Color lutealBg;
  final Color lutealText;
  final Color centerFill;
  final Color centerBorder;
  final Color selectedFill;
  final Color selectedText;
  final Color selectedBorder;
  final Color dayText;
  final Color titleText;
  final Color messageText;

  static _LuneCyclePalette forTheme(bool isDark) {
    if (isDark) {
      return _LuneCyclePalette(
        menstruation: AuraColors.darkRose,
        menstruationBg: AuraColors.darkRose.withValues(alpha: 0.28),
        follicular: AuraColors.lavenderSoft,
        follicularBg: AuraColors.lavenderSoft.withValues(alpha: 0.22),
        ovulation: AuraColors.peachGold,
        ovulationBg: AuraColors.peachGold.withValues(alpha: 0.24),
        luteal: const Color(0xFF4A3D52),
        lutealBg: const Color(0xFF4A3D52).withValues(alpha: 0.35),
        lutealText: AuraColors.darkCream.withValues(alpha: 0.85),
        centerFill: AuraColors.darkCard,
        centerBorder: AuraColors.darkRose.withValues(alpha: 0.45),
        selectedFill: AuraColors.roseDeep,
        selectedText: Colors.white,
        selectedBorder: Colors.white.withValues(alpha: 0.9),
        dayText: AuraColors.darkCream.withValues(alpha: 0.9),
        titleText: AuraColors.darkCream,
        messageText: AuraColors.darkCream.withValues(alpha: 0.72),
      );
    }

    return _LuneCyclePalette(
      menstruation: AuraColors.roseDeep,
      menstruationBg: AuraColors.roseDeep.withValues(alpha: 0.22),
      follicular: AuraColors.lavender,
      follicularBg: AuraColors.lavender.withValues(alpha: 0.24),
      ovulation: AuraColors.peachGold,
      ovulationBg: AuraColors.peachGold.withValues(alpha: 0.26),
      luteal: AuraColors.blush,
      lutealBg: AuraColors.blush.withValues(alpha: 0.55),
      lutealText: AuraColors.plumMuted,
      centerFill: Colors.white.withValues(alpha: 0.92),
      centerBorder: AuraColors.rose.withValues(alpha: 0.45),
      selectedFill: AuraColors.roseDeep,
      selectedText: Colors.white,
      selectedBorder: Colors.white,
      dayText: AuraColors.plum,
      titleText: AuraColors.plum,
      messageText: AuraColors.plumMuted,
    );
  }
}
