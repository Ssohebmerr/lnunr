import 'package:flutter/material.dart';

import '../../menstrual_cycle_widget.dart';
import '../../widget_languages/languages.dart';
import '../text_style/custom_text_style.dart';

/// get future prediction due periods dates of next period
initFuturePeriodDay() async {
  final instance = MenstrualCycleWidget.instance!;

  List<String> futurePeriodDays = [];
  int cycleLength = instance.getCycleLength();
  int periodLength = instance.getPeriodDuration();
  if (instance.getPreviousPeriodDay().isNotEmpty) {
    DateTime nextPeriodDate = CalenderDateUtils.dateFormat
        .parse(instance.getPreviousPeriodDay())
        .add(Duration(days: cycleLength));
    // printLogs("Dates: ${defaultDateFormat.format(nextPeriodDate)}");
    for (int index = 0; index < futureMonthCount; index++) {
      for (int i = 1; i <= periodLength; i++) {
        DateTime addDate = nextPeriodDate.add(Duration(days: i));
        // printLogs("Dates: ${defaultDateFormat.format(addDate)}");
        futurePeriodDays.add(defaultDateFormat.format(addDate));
        // futurePeriodDays
      }
      DateTime newDatetime = nextPeriodDate.add(Duration(days: cycleLength));
      nextPeriodDate = newDatetime;
    }
  }
  return futurePeriodDays;
}

/// get future prediction ovulation dates
initFutureOvulationDay() async {
  final instance = MenstrualCycleWidget.instance!;
  List<String> futureOvulationDays = [];
  int cycleLength = instance.getCycleLength();
  if (instance.getPreviousPeriodDay().isNotEmpty) {
    DateTime nextPeriodDate = CalenderDateUtils.dateFormat
        .parse(instance.getPreviousPeriodDay())
        .add(Duration(days: cycleLength));
    // printLogs("Dates: ${defaultDateFormat.format(nextPeriodDate)}");
    for (int index = 0; index < futureMonthCount; index++) {
      // Ovulation day
      DateTime ovulationDate = nextPeriodDate
          .add(Duration(days: cycleLength))
          .add(const Duration(days: -14));
      futureOvulationDays.add(defaultDateFormat.format(ovulationDate));
      //printLogs("Dates: ${defaultDateFormat.format(ovulationDate)}");
      DateTime newDatetime = nextPeriodDate.add(Duration(days: cycleLength));
      nextPeriodDate = newDatetime;
    }
  }
  return futureOvulationDays;
}

Widget getInformationView(Color daySelectedColor, Color themeColor) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final items = <_CalendarLegendItemData>[
        _CalendarLegendItemData(
          label: WidgetBaseLanguage.periodLabel,
          color: defaultMenstruationColor,
        ),
        _CalendarLegendItemData(
          label: WidgetBaseLanguage.predictOvulationDateLabel,
          color: defaultOvulationColor,
          outlined: true,
        ),
        _CalendarLegendItemData(
          label: WidgetBaseLanguage.predictPeriodDateLabel,
          color: defaultMenstruationColor,
          outlined: true,
        ),
        _CalendarLegendItemData(
          label: WidgetBaseLanguage.selectedDateLabel,
          color: daySelectedColor,
        ),
        _CalendarLegendItemData(
          label: WidgetBaseLanguage.todayLabel,
          color: themeColor,
        ),
      ];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final item in items)
              _CalendarLegendItem(item: item, theme: theme),
          ],
        ),
      );
    },
  );
}

class _CalendarLegendItemData {
  const _CalendarLegendItemData({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;
}

class _CalendarLegendItem extends StatelessWidget {
  const _CalendarLegendItem({required this.item, required this.theme});

  final _CalendarLegendItemData item;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.outlined ? Colors.transparent : item.color,
            border: Border.all(
              color: item.color,
              width: item.outlined ? 1.4 : 0,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          item.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: getFontFamily(),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

Widget progressIndicator() {
  return Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(),
      child: Container(
        width: 30,
        alignment: Alignment.centerRight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: <Color>[
            Color.fromRGBO(33, 33, 33, 0.0),
            Color.fromRGBO(33, 33, 33, 0.74)
          ], stops: <double>[
            0.0,
            1
          ]),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            backgroundColor: Colors.transparent,
            strokeWidth: 3,
          ),
        ),
      ),
    ),
  );
}
