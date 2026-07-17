import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';

/// Lune-branded cycle ring with readable Arabic phase labels (legend below).
class LuneCycleRing extends StatelessWidget {
  const LuneCycleRing({
    super.key,
    this.size = 240,
    this.phase,
    this.cycleDay,
    this.cycleLength,
    this.periodDuration,
  });

  final double size;
  final String? phase;
  final int? cycleDay;
  final int? cycleLength;
  final int? periodDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final palette = _LuneCyclePalette.forTheme(isDark);
    final totalDays = math.max(10, cycleLength ?? 28);
    final selectedDay = (cycleDay ?? 1).clamp(1, totalDays).toInt();
    final periodDays = (periodDuration ?? 5)
        .clamp(2, math.min(8, totalDays - 4))
        .toInt();
    final phaseLabel = phase?.trim().isNotEmpty == true
        ? phase!.trim()
        : _fallbackPhase(
            isAr: isAr,
            day: selectedDay,
            totalDays: totalDays,
            periodDays: periodDays,
          );

    return Semantics(
      label: isAr
          ? 'اليوم $selectedDay من دورة مدتها $totalDays يومًا، $phaseLabel'
          : 'Cycle day $selectedDay of $totalDays, $phaseLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _LuneCycleRingPainter(
                    palette: palette,
                    totalDays: totalDays,
                    selectedDay: selectedDay,
                    periodDays: periodDays,
                  ),
                ),
                Container(
                  width: size * 0.53,
                  height: size * 0.53,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: palette.centerFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.centerBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: palette.centerBorder.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phaseLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.messageText,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$selectedDay',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: palette.titleText,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr ? 'من $totalDays يومًا' : 'of $totalDays days',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.messageText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LunePhaseLegend(isAr: isAr, palette: palette, theme: theme),
        ],
      ),
    );
  }

  String _fallbackPhase({
    required bool isAr,
    required int day,
    required int totalDays,
    required int periodDays,
  }) {
    final ovulationDay = math.max(periodDays + 2, totalDays - 14);
    if (day <= periodDays) return isAr ? 'مرحلة الحيض' : 'Menstruation';
    if (day < ovulationDay - 1) {
      return isAr ? 'الطور الجُريبي' : 'Follicular phase';
    }
    if (day <= ovulationDay + 1) return isAr ? 'الإباضة' : 'Ovulation';
    return isAr ? 'الطور الأصفري' : 'Luteal phase';
  }
}

class _LuneCycleRingPainter extends CustomPainter {
  const _LuneCycleRingPainter({
    required this.palette,
    required this.totalDays,
    required this.selectedDay,
    required this.periodDays,
  });

  final _LuneCyclePalette palette;
  final int totalDays;
  final int selectedDay;
  final int periodDays;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 25;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    const gap = 0.045;
    const strokeWidth = 21.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = palette.centerBorder.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final remainingDays = totalDays - periodDays;
    final ovulationDays = math.min(3, math.max(1, remainingDays ~/ 4));
    final lutealDays = math.min(12, math.max(1, remainingDays ~/ 2));
    final follicularDays = remainingDays - ovulationDays - lutealDays;
    final segments = <(int, Color)>[
      (periodDays, palette.menstruation),
      (follicularDays, palette.follicular),
      (ovulationDays, palette.ovulation),
      (lutealDays, palette.luteal),
    ];

    var angle = startAngle;
    for (final segment in segments) {
      final sweep = segment.$1 / totalDays * math.pi * 2;
      canvas.drawArc(
        rect,
        angle + gap / 2,
        math.max(0.01, sweep - gap),
        false,
        Paint()
          ..color = segment.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      angle += sweep;
    }

    final markerAngle =
        startAngle + ((selectedDay - 0.5) / totalDays) * math.pi * 2;
    final marker = Offset(
      center.dx + radius * math.cos(markerAngle),
      center.dy + radius * math.sin(markerAngle),
    );
    canvas.drawCircle(marker, 10, Paint()..color = palette.selectedBorder);
    canvas.drawCircle(marker, 7, Paint()..color = palette.selectedFill);
  }

  @override
  bool shouldRepaint(covariant _LuneCycleRingPainter oldDelegate) {
    return oldDelegate.totalDays != totalDays ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.periodDays != periodDays ||
        oldDelegate.palette != palette;
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
            (palette.follicular, 'الطور الجُريبي'),
            (palette.ovulation, 'الإباضة'),
            (palette.luteal, 'الطور الأصفري'),
          ]
        : [
            (palette.menstruation, 'Period'),
            (palette.follicular, 'Follicular'),
            (palette.ovulation, 'Ovulation'),
            (palette.luteal, 'Luteal'),
          ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: items
          .map((e) => _LegendChip(color: e.$1, label: e.$2, theme: theme))
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
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
