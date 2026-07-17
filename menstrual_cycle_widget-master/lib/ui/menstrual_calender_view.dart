import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../menstrual_cycle_widget.dart';
import '../widget_languages/language_functions.dart';
import '../widget_languages/languages.dart';
import 'calender_view/calender_view.dart';
import 'text_style/custom_text_style.dart';

class MenstrualCycleCalenderView extends StatefulWidget {
  final Color? daySelectedColor;
  final String? logPeriodText;
  final Color? themeColor;
  final Color? backgroundColorCode;
  final bool? hideInfoView;
  final bool? hideBottomBar;
  final bool? hideLogPeriodButton;
  final bool? isExpanded;
  final Function? onDateSelected;
  final Function? onDataChanged;

  const MenstrualCycleCalenderView(
      {super.key,
      this.daySelectedColor,
      this.themeColor = Colors.black,
      this.backgroundColorCode = Colors.white,
      this.logPeriodText,
      this.hideLogPeriodButton = false,
      this.hideBottomBar = false,
      this.onDateSelected,
      this.onDataChanged,
      this.isExpanded = false,
      this.hideInfoView = false});

  @override
  State<MenstrualCycleCalenderView> createState() =>
      _MenstrualCycleCalenderViewState();
}

class _MenstrualCycleCalenderViewState
    extends State<MenstrualCycleCalenderView> {
  List<DateTime>? selectedMonthsDays;
  List<DateTime>? selectedWeekDays;
  DateTime _selectedDateTime = DateTime.now();
  String? currentMonth;
  bool isExpanded = false;
  String displayMonth = "";
  String today = "";
  DateTime _selectedDate = DateTime.now();
  bool isExpandable = true;

  DateTime get selectedDateTime => _selectedDateTime;
  final _instance = MenstrualCycleWidget.instance!;

  List<String> futurePeriodDays = [];
  List<String> futureOvulationDays = [];
  List<String>? pastAllPeriodsDays = [];

  List<String> weekTitles = [];

  Color? selectedColor = Colors.grey;
  String _logPeriodText = WidgetBaseLanguage.logPeriodLabel;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isExpanded ?? false;
    weekTitles = getWeekTitle();
    _selectedDateTime = DateTime.now();
    selectedMonthsDays = _daysInMonth(selectedDateTime);
    selectedWeekDays = CalenderDateUtils.daysInRange(
            _firstDayOfWeek(selectedDateTime), _lastDayOfWeek(selectedDateTime))
        .toList();
    initializeDateFormatting(getLanguageCode(), null).then((_) {
      if (!mounted) return;
      setState(() {
        var monthFormat = CalenderDateUtils.formatDayMonth(selectedDateTime);
        displayMonth =
            "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
        var todayFormat = CalenderDateUtils.formatDay(selectedDateTime);
        today = todayFormat;
      });
    });

    if (widget.logPeriodText != null && widget.logPeriodText!.isNotEmpty) {
      _logPeriodText = widget.logPeriodText!;
    }
    init();
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
    selectedColor = (widget.daySelectedColor != null)
        ? widget.daySelectedColor
        : Colors.grey;
    _instance.calculateLastPeriodDate();
    pastAllPeriodsDays = _instance.pastAllPeriodDays;
    futurePeriodDays = await initFuturePeriodDay();
    futureOvulationDays = await initFutureOvulationDay();
    if (mounted) setState(() {});
  }

  Widget calendarGridView() {
    return SimpleGestureDetector(
      onSwipeUp: _onSwipeUp,
      onSwipeDown: _onSwipeDown,
      onSwipeLeft: _onSwipeLeft,
      onSwipeRight: _onSwipeRight,
      swipeConfig: const SimpleSwipeConfig(
        verticalThreshold: 10.0,
        horizontalThreshold: 40.0,
        swipeDetectionMoment: SwipeDetectionMoment.onUpdate,
      ),
      child: Column(children: <Widget>[
        GridView.count(
          childAspectRatio: 1.5,
          primary: false,
          shrinkWrap: true,
          crossAxisCount: 7,
          padding: const EdgeInsets.only(bottom: 0.0),
          children: calendarBuilder(),
        ),
      ]),
    );
  }

  List<Widget> calendarBuilder() {
    List<Widget> dayWidgets = [];

    // Add weekday headers
    _addWeekdayHeaders(dayWidgets);

    // Generate calendar days
    _addCalendarDays(dayWidgets);

    return dayWidgets;
  }

// Helper method to add weekday headers
  void _addWeekdayHeaders(List<Widget> dayWidgets) {
    for (var day in weekTitles) {
      dayWidgets.add(
        CalendarCell(
          themeColor: widget.themeColor!,
          selectedColor: selectedColor,
          todayColor: defaultMenstruationColor,
          isDayOfWeek: true,
          dayOfWeek: day,
          multipleDateSelectionCallBack: () {},
          dayOfWeekStyle: TextStyle(
            fontFamily: getFontFamily(),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            height: 1.2,
          ),
        ),
      );
    }
  }

// Helper method to add calendar days
  void _addCalendarDays(List<Widget> dayWidgets) {
    List<DateTime>? calendarDays =
        isExpanded ? selectedMonthsDays : selectedWeekDays;

    bool monthStarted = false;
    bool monthEnded = false;

    for (var day in calendarDays!) {
      day = CalenderDateUtils.getDay(day);

      // Normalize time to the start of the day
      day = _normalizeDay(day);

      // Update month boundary flags
      if (monthStarted && day.day == 1) {
        monthEnded = true;
      }
      if (CalenderDateUtils.isFirstDayOfMonth(day)) {
        monthStarted = true;
      }

      dayWidgets.add(
        CalendarCell(
          themeColor: widget.themeColor!,
          selectedColor: selectedColor,
          todayColor: defaultMenstruationColor,
          onDateSelected: () => handleSelectedDateCallback(day),
          currentDay: day,
          multipleDateSelectionCallBack: () {},
          previousPeriodDate: _instance.getPreviousPeriodDay(),
          pastAllPeriodsDays: pastAllPeriodsDays,
          futurePeriodDays: futurePeriodDays,
          futureOvulationDays: futureOvulationDays,
          cycleLength: _instance.getCycleLength(),
          periodDuration: _instance.getPeriodDuration(),
          dateStyles: configureDateStyle(monthStarted, monthEnded),
          isSelected: CalenderDateUtils.isSameDay(_selectedDate, day),
        ),
      );
    }
  }

// Helper to normalize day to the start of the day
  DateTime _normalizeDay(DateTime day) {
    if (day.hour > 0) {
      day = day.toLocal();
      day = day.subtract(Duration(hours: day.hour));
    }
    return day;
  }

  /*List<Widget> calendarBuilder() {
    List<Widget> dayWidgets = [];
    List<DateTime>? calendarDays =
        isExpanded ? selectedMonthsDays : selectedWeekDays;

    for (var day in weekTitles) {
      dayWidgets.add(
        CalendarCell(
          themeColor: widget.themeColor!,
          selectedColor: selectedColor,
          todayColor: defaultMenstruationColor,
          isDayOfWeek: true,
          dayOfWeek: day,
          multipleDateSelectionCallBack: () {},
          dayOfWeekStyle: TextStyle(
              color: widget.themeColor,
              fontWeight: FontWeight.w800,
              fontSize: 11),
        ),
      );
    }

    bool monthStarted = false;
    bool monthEnded = false;

    for (var day in calendarDays!) {
      day = CalenderDateUtils.getDay(day);
      if (day.hour > 0) {
        day = day.toLocal();
        day = day.subtract(Duration(hours: day.hour));
      }

      if (monthStarted && day.day == 01) {
        monthEnded = true;
      }

      if (CalenderDateUtils.isFirstDayOfMonth(day)) {
        monthStarted = true;
      }

      dayWidgets.add(
        CalendarCell(
          themeColor: widget.themeColor!,
          selectedColor: selectedColor,
          todayColor: defaultMenstruationColor,
          onDateSelected: () => handleSelectedDateCallback(day),
          currentDay: day,
          multipleDateSelectionCallBack: () {},
          previousPeriodDate: _instance.getPreviousPeriodDay(),
          pastAllPeriodsDays: pastAllPeriodsDays,
          futurePeriodDays: futurePeriodDays,
          futureOvulationDays: futureOvulationDays,
          cycleLength: _instance.getCycleLength(),
          periodDuration: _instance.getPeriodDuration(),
          dateStyles: configureDateStyle(monthStarted, monthEnded),
          isSelected: CalenderDateUtils.isSameDay(_selectedDate, day),
        ),
      );
    }
    return dayWidgets;
  }*/

  TextStyle configureDateStyle(monthStarted, monthEnded) {
    TextStyle? dateStyles;
    TextStyle normalTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      fontFamily: getFontFamily(),
    );

    if (isExpanded) {
      final TextStyle body1StyleDisabled =
          normalTextStyle.copyWith(color: Colors.grey);
      dateStyles =
          monthStarted && !monthEnded ? normalTextStyle : body1StyleDisabled;
    } else {
      dateStyles = normalTextStyle;
    }
    return dateStyles;
  }

  Widget bottomView() {
    if (isExpandable) {
      final theme = Theme.of(context);
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 6, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: <Widget>[
            if (!widget.hideLogPeriodButton!) ...[
              TextButton.icon(
                onPressed: _openMonthlyCalendar,
                style: TextButton.styleFrom(
                  foregroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.water_drop_outlined, size: 16),
                label: Text(
                  _logPeriodText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: getFontFamily(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatFullDate(
                  selectedDateTime,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: getFontFamily(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: isExpanded ? 'Collapse calendar' : 'Expand calendar',
              onPressed: toggleExpanded,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: widget.themeColor,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Future<void> _openMonthlyCalendar() async {
    final value = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MenstrualCycleMonthlyCalenderView(
          themeColor: widget.themeColor,
          hideInfoView: widget.hideInfoView!,
          isShowCloseIcon: true,
          onDataChanged: (_) {},
        ),
      ),
    );
    if (value == true) await init();
    widget.onDataChanged?.call(value ?? false);
  }

  Widget _calendarHeader() {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        children: [
          _headerIconButton(
            tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
            icon: rtl ? Icons.chevron_right : Icons.chevron_left,
            onPressed: isExpanded ? previousMonth : previousWeek,
          ),
          Expanded(
            child: Text(
              displayMonth,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: getFontFamily(),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _headerIconButton(
            tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
            icon: rtl ? Icons.chevron_left : Icons.chevron_right,
            onPressed: isExpanded ? nextMonth : nextWeek,
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: WidgetBaseLanguage.todayLabel,
            child: InkWell(
              onTap: resetToToday,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.themeColor!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.themeColor!.withValues(alpha: 0.25),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 21,
                      color: widget.themeColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        today,
                        style: TextStyle(
                          color: widget.themeColor,
                          fontSize: 8,
                          fontFamily: getFontFamily(),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: widget.themeColor),
    );
  }

  @override
  Widget build(BuildContext buildContext) {
    return Directionality(
      textDirection:
          (isArabicLanguage()) ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: widget.backgroundColorCode ?? Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _calendarHeader(),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: calendarGridView(),
            ),
            const SizedBox(height: 10),
            (widget.hideInfoView!)
                ? const SizedBox()
                : getInformationView(selectedColor!, widget.themeColor!),
            (widget.hideBottomBar!) ? const SizedBox() : bottomView()
          ],
        ),
      ),
    );
  }

  void resetToToday() {
    _selectedDateTime = DateTime.now();
    var firstDayOfCurrentWeek = _firstDayOfWeek(selectedDateTime);
    var lastDayOfCurrentWeek = _lastDayOfWeek(selectedDateTime);

    setState(() {
      selectedWeekDays = CalenderDateUtils.daysInRange(
              firstDayOfCurrentWeek, lastDayOfCurrentWeek)
          .toList();
      selectedMonthsDays = _daysInMonth(selectedDateTime);
      var monthFormat = CalenderDateUtils.formatDayMonth(selectedDateTime);

      displayMonth =
          "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
      var todayFormat = CalenderDateUtils.formatDay(selectedDateTime);

      today = todayFormat;
    });

    // _launchDateSelectionCallback(selectedDateTime);
  }

  void nextMonth() {
    setState(() {
      _selectedDateTime = CalenderDateUtils.nextMonth(selectedDateTime);
      var firstDateOfNewMonth =
          CalenderDateUtils.firstDayOfMonth(selectedDateTime);
      var lastDateOfNewMonth =
          CalenderDateUtils.lastDayOfMonth(selectedDateTime);
      updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
      selectedMonthsDays = _daysInMonth(selectedDateTime);
      var monthFormat = CalenderDateUtils.formatMonth(selectedDateTime);
      displayMonth =
          "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
    });
    // _launchDateSelectionCallback(selectedDateTime);
  }

  void previousMonth() {
    setState(() {
      _selectedDateTime = CalenderDateUtils.previousMonth(selectedDateTime);
      var firstDateOfNewMonth =
          CalenderDateUtils.firstDayOfMonth(selectedDateTime);
      var lastDateOfNewMonth =
          CalenderDateUtils.lastDayOfMonth(selectedDateTime);
      updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
      selectedMonthsDays = _daysInMonth(selectedDateTime);
      var monthFormat = CalenderDateUtils.formatMonth(selectedDateTime);

      displayMonth =
          "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
    });
    // _launchDateSelectionCallback(selectedDateTime);
  }

  void nextWeek() {
    setState(() {
      _selectedDateTime = CalenderDateUtils.nextWeek(selectedDateTime);
      var firstDayOfCurrentWeek = _firstDayOfWeek(selectedDateTime);
      var lastDayOfCurrentWeek = _lastDayOfWeek(selectedDateTime);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeekDays = CalenderDateUtils.daysInRange(
              firstDayOfCurrentWeek, lastDayOfCurrentWeek)
          .toList();
      var monthFormat = CalenderDateUtils.formatMonth(selectedDateTime);

      displayMonth =
          "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
    });
    // _launchDateSelectionCallback(selectedDateTime);
  }

  void previousWeek() {
    setState(() {
      _selectedDateTime = CalenderDateUtils.previousWeek(selectedDateTime);
      var firstDayOfCurrentWeek = _firstDayOfWeek(selectedDateTime);
      var lastDayOfCurrentWeek = _lastDayOfWeek(selectedDateTime);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeekDays = CalenderDateUtils.daysInRange(
              firstDayOfCurrentWeek, lastDayOfCurrentWeek)
          .toList();
      var monthFormat = CalenderDateUtils.formatMonth(selectedDateTime);

      displayMonth =
          "${monthFormat[0].toUpperCase()}${monthFormat.substring(1)}";
    });
    //  _launchDateSelectionCallback(selectedDateTime);
  }

  void updateSelectedRange(DateTime start, DateTime end) {}

  void _onSwipeUp() {
    if (isExpanded) toggleExpanded();
  }

  void _onSwipeDown() {
    if (!isExpanded) toggleExpanded();
  }

  void _onSwipeRight() {
    if (isExpanded) {
      previousMonth();
    } else {
      previousWeek();
    }
  }

  void _onSwipeLeft() {
    if (isExpanded) {
      nextMonth();
    } else {
      nextWeek();
    }
  }

  void toggleExpanded() {
    if (isExpandable) {
      setState(() => isExpanded = !isExpanded);
    }
  }

  void handleSelectedDateCallback(DateTime day) {
    var firstDayOfCurrentWeek = _firstDayOfWeek(day);
    var lastDayOfCurrentWeek = _lastDayOfWeek(day);
    if (selectedDateTime.month > day.month) {
      previousMonth();
    }
    if (selectedDateTime.month < day.month) {
      nextMonth();
    }
    setState(() {
      _selectedDate = day;
      selectedWeekDays = CalenderDateUtils.daysInRange(
              firstDayOfCurrentWeek, lastDayOfCurrentWeek)
          .toList();
      selectedMonthsDays = _daysInMonth(day);
    });
    _launchDateSelectionCallback(day);
  }

  void _launchDateSelectionCallback(DateTime day) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(day);
    }
    /* if (widget.onMonthChanged != null) {
      widget.onMonthChanged!(day);
    }*/
  }

  _firstDayOfWeek(DateTime date) {
    var day = DateTime.utc(date.year, date.month, date.day, 12);
    return day.subtract(Duration(days: day.weekday));
  }

  _lastDayOfWeek(DateTime date) {
    return _firstDayOfWeek(date).add(const Duration(days: 7));
  }

  List<DateTime> _daysInMonth(DateTime month) {
    var first = CalenderDateUtils.firstDayOfMonth(month);
    var daysBefore = first.weekday;
    var firstToDisplay = first.subtract(Duration(days: daysBefore));
    var last = CalenderDateUtils.lastDayOfMonth(month);

    var daysAfter = 7 - last.weekday;

    // If the last day is sunday (7) the entire week must be rendered
    if (daysAfter == 0) {
      daysAfter = 7;
    }

    var lastToDisplay = last.add(Duration(days: daysAfter));
    return CalenderDateUtils.daysInRange(firstToDisplay, lastToDisplay)
        .toList();
  }
}
