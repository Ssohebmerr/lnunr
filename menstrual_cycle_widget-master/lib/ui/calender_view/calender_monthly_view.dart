import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/ui/calender_view/scroll_to_index.dart';
import '../../menstrual_cycle_widget.dart';
import '../../widget_languages/languages.dart';
import '../text_style/custom_text_style.dart';
import 'calender_view.dart';

class CalenderMonthlyView extends StatefulWidget {
  final ValueChanged<DateTime>? onDateSelected;
  final Color? selectedColor;
  final Color? todayColor;
  final DateTime? initialDate;
  final double? borderRadius;
  final Function? onDataChanged;
  final int cycleLength;
  final Color themeColor;
  final Color? backgroundColor;
  final int periodLength;
  final bool isFromCalender;
  final bool hideInfoView;

  const CalenderMonthlyView({
    super.key,
    this.onDateSelected,
    required this.themeColor,
    this.backgroundColor,
    this.selectedColor,
    this.todayColor,
    this.initialDate,
    this.onDataChanged,
    this.borderRadius = 20,
    this.cycleLength = defaultCycleLength,
    this.periodLength = defaultPeriodDuration,
    this.isFromCalender = true,
    this.hideInfoView = false,
  });

  @override
  State<CalenderMonthlyView> createState() => _CalenderMonthlyViewState();
}

class _CalenderMonthlyViewState extends State<CalenderMonthlyView> {
  DateTime _selectedDate = DateTime.now();
  List<List<DateTime>> monthWidgets = [];
  List<String> monthTitle = [];
  bool isEditMode = false;
  List<DateTime> selectedPeriodsDate = [];
  bool isChangedData = false;
  List<String> weekTitles = [];
  List<String> futurePeriodDays = [];
  List<String> futureOvulationDays = [];
  List<String>? pastAllPeriodsDays = [];
  final _instance = MenstrualCycleWidget.instance!;

  int pastMonthCount = 3;
  int nextMonthCount = 3;
  int nextMonthIncrementCount = 3;
  int pastMonthDecrementCount = 3;

  late AutoScrollController controller;
  bool isInitialScroll = true;

  @override
  void initState() {
    super.initState();
    weekTitles = getWeekTitle();
    controller = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);
    init();
    _selectedDate = widget.initialDate ?? DateTime.now();
    generateMonthData(true);
  }

  getWeekTitle() {
    return [
      WidgetBaseLanguage.weekTitlesSun,
      WidgetBaseLanguage.weekTitlesMon,
      WidgetBaseLanguage.weekTitlesTue,
      WidgetBaseLanguage.weekTitlesWed,
      WidgetBaseLanguage.weekTitlesThu,
      WidgetBaseLanguage.weekTitlesFri,
      WidgetBaseLanguage.weekTitlesSat,
    ];
  }

  init() async {
    _instance.calculateLastPeriodDate();
    pastAllPeriodsDays = _instance.pastAllPeriodDays;
    futurePeriodDays = await initFuturePeriodDay();
    futureOvulationDays = await initFutureOvulationDay();
    if (mounted) setState(() {});
  }

  DateTime getDateTimeFromMonthsAgo(int monthsAgo) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    // Subtract months and adjust year if necessary
    month -= monthsAgo;
    while (month <= 0) {
      month += 12;
      year -= 1;
    }

    // Return the calculated date
    return DateTime(year, month);
  }

  void generateMonthData(bool isConsiderFutureDate) async {
    //printLogs(("isConsiderFutureDate == $isConsiderFutureDate");
    monthWidgets.clear();
    monthTitle.clear();
    // Past month data
    for (int index = pastMonthCount; index > 0; index--) {
      DateTime currantMonth = getDateTimeFromMonthsAgo(index);
      monthTitle.add(CalenderDateUtils.displayMonthYear.format(currantMonth));
      monthWidgets
          .add(monthCalendarBuilder(currantMonth, isConsiderFutureDate));
    }
    monthTitle.add(CalenderDateUtils.displayMonthYear.format(_selectedDate));
    monthWidgets.add(monthCalendarBuilder(_selectedDate, isConsiderFutureDate));
    // Next month data
    if (isConsiderFutureDate) {
      DateTime nextMonth = CalenderDateUtils.nextMonth(_selectedDate);
      for (int index = 0; index < nextMonthCount; index++) {
        monthTitle.add(CalenderDateUtils.displayMonthYear.format(nextMonth));
        monthWidgets.add(monthCalendarBuilder(nextMonth, isConsiderFutureDate));
        nextMonth = CalenderDateUtils.nextMonth(nextMonth);
      }
    }

    //setState(() {});
    if (isInitialScroll) {
      await controller.scrollToIndex(3,
          preferPosition: AutoScrollPosition.begin);
      isInitialScroll = false;
    }
  }

  List<DateTime> _daysInMonth(DateTime month) {
    var first = CalenderDateUtils.firstDayOfMonth(month);
    var daysBefore = first.weekday % 7;
    var firstToDisplay = first.subtract(Duration(days: daysBefore));
    var last = CalenderDateUtils.lastDayOfMonth(month);
    var daysAfter = (7 - (last.weekday % 7)) % 7;
    var lastToDisplay = last.add(Duration(days: daysAfter + 1));
    return CalenderDateUtils.daysInRange(firstToDisplay, lastToDisplay)
        .toList();
  }

  void previousMonth() {
    _selectedDate = CalenderDateUtils.previousMonth(_selectedDate);
  }

  void nextMonth() {
    _selectedDate = CalenderDateUtils.nextMonth(_selectedDate);
  }

  titleCalendarBuilder() {
    List<Widget> dayWidgets = [];
    for (var day in weekTitles) {
      dayWidgets.add(
        CalendarCell(
          themeColor: widget.themeColor,
          isDayOfWeek: true,
          multipleDateSelectionCallBack: () {},
          dayOfWeekStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontFamily: getFontFamily(),
              fontSize: 10.5,
              height: 1.2),
          dayOfWeek: day,
        ),
      );
    }
    return dayWidgets;
  }

  monthCalendarBuilder(selectedDate, isConsiderFutureDate) {
    List<DateTime> dayWidgets = [];
    List<DateTime>? calendarDays = _daysInMonth(selectedDate);
    for (var day in calendarDays) {
      day = CalenderDateUtils.getDay(day);
      if (day.hour > 0) {
        day = day.toLocal();
        day = day.subtract(Duration(hours: day.hour));
      }
      bool isBeforeCurrentDate = day.isBefore(DateTime.now());
      if (isBeforeCurrentDate) {
        dayWidgets.add(day);
      } else if (isConsiderFutureDate) {
        dayWidgets.add(day);
      }
    }
    return dayWidgets;
  }

  void _launchDateSelectionCallback(DateTime day) {
    //printLogs(("_launchDateSelectionCallback Day Click-------");
    if (!isEditMode) {
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(day);
      }
    }
  }

  void dateSelectionCallBack(DateTime day, bool isChecked) {
    int index = selectedPeriodsDate.indexOf(day);
    if (index > -1) {
      if (!isChecked) {
        //printLogs(("REMOVE Date $day");
        selectedPeriodsDate.removeAt(index);
      }
    } else {
      if (isChecked) {
        //printLogs(("ADD Date $day");
        selectedPeriodsDate.add(day);
      }
    }
  }

  /// Store user's periods data to firebase
  saveSelectedPeriodDate() async {
    final dbHelper = MenstrualCycleDbHelper.instance;
    final instance = MenstrualCycleWidget.instance!;
    String encryptedUserid = instance.getCustomerId();

    selectedPeriodsDate.sort((a, b) => a.compareTo(b));
    if (selectedPeriodsDate.isNotEmpty) {
      DateTime lastPeriodDate = selectedPeriodsDate[0].add(Duration(days: -1));
      await dbHelper.clearPeriodLogAfterSpecificDate(
          encryptedUserid, CalenderDateUtils.dateDayFormat(lastPeriodDate));
      await dbHelper.insertPeriodLog(selectedPeriodsDate);
    } else {
      await dbHelper.clearPeriodLog(encryptedUserid);
    }
    isChangedData = true;
    widget.onDataChanged?.call(isChangedData);
    isEditMode = false;
    generateMonthData(true);

    //printLogs(("Old data.... ${pastAllPeriodsDays.toString()}");
    pastAllPeriodsDays = await instance.calculateLastPeriodDate();
    //printLogs(("New .... ${pastAllPeriodsDays.toString()}");
    futurePeriodDays = await initFuturePeriodDay();
    futureOvulationDays = await initFutureOvulationDay();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final background =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isFromCalender)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context, isChangedData),
              icon: Icon(Icons.close_rounded, color: widget.themeColor),
            ),
          ),
        if (!widget.hideInfoView) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: getInformationView(
              widget.selectedColor ?? Colors.grey,
              widget.themeColor,
            ),
          ),
          Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
        SizedBox(
          height: 40,
          child: GridView.count(
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: titleCalendarBuilder(),
          ),
        ),
        Expanded(child: _modernMonthList()),
        _modernFooter(),
      ],
    );

    if (widget.isFromCalender) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && context.mounted) {
            Navigator.pop(context, isChangedData);
          }
        },
        child: Scaffold(
          backgroundColor: background,
          body: SafeArea(child: content),
        ),
      );
    }

    return Material(color: background, child: content);
  }

  Widget _modernMonthList() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleModernScroll,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        physics: const ClampingScrollPhysics(),
        itemCount: monthWidgets.length,
        itemBuilder: (context, index) {
          final days = monthWidgets[index];
          if (days.isEmpty) return const SizedBox.shrink();
          final targetMonth = days.firstWhere(
            (date) => date.day == 1,
            orElse: () => days.first,
          );
          final theme = Theme.of(context);

          return AutoScrollTag(
            key: ValueKey('month-${targetMonth.year}-${targetMonth.month}'),
            controller: controller,
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMonthYear(targetMonth),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontFamily: getFontFamily(),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GridView.count(
                    childAspectRatio: 1.15,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 7,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: [
                      for (final rawDay in days)
                        _modernDayCell(rawDay, targetMonth, theme),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modernDayCell(
    DateTime rawDay,
    DateTime targetMonth,
    ThemeData theme,
  ) {
    final day = CalenderDateUtils.getDay(rawDay);
    final isOutsideMonth =
        day.year != targetMonth.year || day.month != targetMonth.month;
    return CalendarCell(
      themeColor: widget.themeColor,
      selectedColor: widget.selectedColor,
      todayColor: widget.todayColor,
      isEditMode: isEditMode,
      multipleDateSelectionCallBack: (value) {
        dateSelectionCallBack(rawDay, value == true);
      },
      onDateSelected: () => _launchDateSelectionCallback(rawDay),
      currentDay: rawDay,
      isBlankDay: isOutsideMonth,
      previousPeriodDate: _instance.getPreviousPeriodDay(),
      pastAllPeriodsDays: pastAllPeriodsDays,
      futurePeriodDays: futurePeriodDays,
      futureOvulationDays: futureOvulationDays,
      cycleLength: widget.cycleLength,
      periodDuration: widget.periodLength,
      dateStyles: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontFamily: getFontFamily(),
        fontWeight: FontWeight.w600,
      ),
      isSelected: CalenderDateUtils.isSameDay(_selectedDate, rawDay),
    );
  }

  bool _handleModernScroll(ScrollNotification notification) {
    if (notification is! ScrollEndNotification) return false;
    if (notification.metrics.pixels < 10) {
      pastMonthCount += 1;
      final month = getDateTimeFromMonthsAgo(pastMonthCount);
      monthTitle.insert(0, CalenderDateUtils.displayMonthYear.format(month));
      monthWidgets.insert(0, monthCalendarBuilder(month, false));
      setState(() {});
    } else if (notification.metrics.pixels + 80 >=
            notification.metrics.maxScrollExtent &&
        !isEditMode &&
        nextMonthCount <= futureMonthCount) {
      var nextMonth = DateTime.now();
      for (var index = 0; index <= nextMonthCount; index++) {
        nextMonth = CalenderDateUtils.nextMonth(nextMonth);
      }
      for (var index = 0; index < nextMonthIncrementCount; index++) {
        monthTitle.add(CalenderDateUtils.displayMonthYear.format(nextMonth));
        monthWidgets.add(monthCalendarBuilder(nextMonth, true));
        nextMonth = CalenderDateUtils.nextMonth(nextMonth);
      }
      nextMonthCount += nextMonthIncrementCount;
      setState(() {});
    }
    return false;
  }

  Widget _modernFooter() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.56),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: isEditMode
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      generateMonthData(true);
                      setState(() => isEditMode = false);
                    },
                    child: Text(WidgetBaseLanguage.cancelLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: saveSelectedPeriodDate,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.themeColor,
                    ),
                    child: Text(WidgetBaseLanguage.saveLabel),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  generateMonthData(false);
                  setState(() => isEditMode = true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_calendar_outlined, size: 19),
                label: Text(WidgetBaseLanguage.editPeriodDateLabel),
              ),
            ),
    );
  }

  // Kept temporarily as an internal fallback for package-level consumers.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, d) {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.pop(context, isChangedData);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFromCalender)
                IconButton(
                  onPressed: () {
                    Navigator.pop(context, isChangedData);
                  },
                  iconSize: 25.0,
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 10.0),
                  icon: Icon(
                    Icons.close,
                    color: widget.themeColor,
                  ),
                ),
              if (!widget.hideInfoView)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: getInformationView(
                      widget.selectedColor!, widget.themeColor),
                ),
              GridView.count(
                childAspectRatio: 1.5,
                primary: false,
                shrinkWrap: true,
                crossAxisCount: 7,
                padding: const EdgeInsets.only(bottom: 0.0),
                children: titleCalendarBuilder(),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollUpdateNotification ||
                          notification is ScrollEndNotification) {
                        /* printMenstrualCycleLogs(
                            "pixels ${notification.metrics.pixels}");
                        printMenstrualCycleLogs(
                            "minScrollExtent ${notification.metrics.minScrollExtent}");
                        printMenstrualCycleLogs(
                            "minScrollExtent ${notification.metrics.maxScrollExtent}");*/

                        if (notification.metrics.pixels < 10) {
                          //printMenstrualCycleLogs('Reached top');
                          //
                          pastMonthCount = pastMonthCount + 1;
                          DateTime currantMonth =
                              getDateTimeFromMonthsAgo(pastMonthCount);
                          monthTitle.insert(
                              0,
                              CalenderDateUtils.displayMonthYear
                                  .format(currantMonth));
                          monthWidgets.insert(
                              0, monthCalendarBuilder(currantMonth, false));

                          setState(() {});
                        } else if (notification.metrics.pixels + 100 >
                                notification.metrics.maxScrollExtent &&
                            !isEditMode) {
                          //printMenstrualCycleLogs('Reached bottom');
                          if (nextMonthCount <= futureMonthCount) {
                            DateTime nextMonth = DateTime.now();
                            for (int index = 0;
                                index <= nextMonthCount;
                                index++) {
                              nextMonth =
                                  CalenderDateUtils.nextMonth(nextMonth);
                            }
                            for (int index = nextMonthCount;
                                index <
                                    nextMonthCount + nextMonthIncrementCount;
                                index++) {
                              monthTitle.add(CalenderDateUtils.displayMonthYear
                                  .format(nextMonth));
                              monthWidgets
                                  .add(monthCalendarBuilder(nextMonth, true));
                              nextMonth =
                                  CalenderDateUtils.nextMonth(nextMonth);
                            }
                            nextMonthCount =
                                nextMonthCount + nextMonthIncrementCount;

                            setState(() {});
                          }
                        }
                      }
                      return true;
                    },
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      controller: controller,
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: monthWidgets.length,
                      itemBuilder: (BuildContext context, int index) {
                        bool monthStarted = false;
                        return AutoScrollTag(
                          key: ValueKey(index),
                          controller: controller,
                          index: index,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                monthTitle[index],
                                style: TextStyle(
                                    color: widget.themeColor,
                                    fontFamily: getFontFamily(),
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              GridView.count(
                                childAspectRatio: 1.5,
                                primary: false,
                                shrinkWrap: true,
                                crossAxisCount: 7,
                                padding: const EdgeInsets.only(bottom: 0.0),
                                children: List.generate(
                                    monthWidgets[index].length, (childIndex) {
                                  DateTime day = CalenderDateUtils.getDay(
                                      monthWidgets[index][childIndex]);

                                  if (CalenderDateUtils.isFirstDayOfMonth(
                                      day)) {
                                    monthStarted = true;
                                  }
                                  return CalendarCell(
                                    themeColor: widget.themeColor,
                                    selectedColor: widget.selectedColor,
                                    todayColor: widget.todayColor,
                                    isEditMode: isEditMode,
                                    multipleDateSelectionCallBack: (value) {
                                      dateSelectionCallBack(
                                          monthWidgets[index][childIndex],
                                          value);
                                    },
                                    onDateSelected: () =>
                                        _launchDateSelectionCallback(
                                            monthWidgets[index][childIndex]),
                                    currentDay: monthWidgets[index][childIndex],
                                    isBlankDay: (monthStarted) ? false : true,
                                    previousPeriodDate:
                                        _instance.getPreviousPeriodDay(),
                                    pastAllPeriodsDays: pastAllPeriodsDays,
                                    futurePeriodDays: futurePeriodDays,
                                    futureOvulationDays: futureOvulationDays,
                                    cycleLength: widget.cycleLength,
                                    periodDuration: widget.periodLength,
                                    dateStyles: TextStyle(
                                        fontFamily: getFontFamily(),
                                        color: widget.themeColor,
                                        fontWeight: FontWeight.normal),
                                    isSelected: false,
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
              ),
              if (isEditMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: [
                      Divider(
                        color: widget.themeColor,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isEditMode) {
                                  generateMonthData(true);
                                  isEditMode = false;
                                } else {
                                  isEditMode = true;
                                }
                              });
                            },
                            child: Container(
                              height: 40,
                              width: 150,
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(left: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0, color: widget.themeColor),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  WidgetBaseLanguage.cancelLabel,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: getFontFamily(),
                                      color: widget.themeColor),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              saveSelectedPeriodDate();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: widget.themeColor,
                                shape: BoxShape.rectangle,
                                border: Border.all(
                                    width: 1.0, color: widget.themeColor),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              height: 40,
                              width: 150,
                              child: Center(
                                child: Text(
                                  WidgetBaseLanguage.saveLabel,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: getFontFamily(),
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                ),
              if (!isEditMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isEditMode) {
                          isEditMode = false;
                        } else {
                          generateMonthData(false);
                          isEditMode = true;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          shape: BoxShape.rectangle,
                          border:
                              Border.all(width: 1.0, color: widget.themeColor),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          WidgetBaseLanguage.editPeriodDateLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: getFontFamily(),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
