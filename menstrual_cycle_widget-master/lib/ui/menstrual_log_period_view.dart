import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../menstrual_cycle_widget.dart';
import '../widget_languages/languages.dart';
import 'model/display_symptoms_data.dart';
import 'model/log_report.dart';
import 'model/user_symptoms_logs.dart';
import 'text_style/custom_text_style.dart';

class MenstrualLogPeriodView extends StatefulWidget {
  final DateTime? symptomsLogDate;
  final Function? onSuccess;
  final Function? onError;
  final Color themeColor;
  final bool? isRequiredWaterView;
  final bool? isRequiredBodyTemperatureView;
  final bool? isRequiredWeightView;
  final bool? isRequiredSleepView;
  final DisplaySymptomsData? displaySymptomsData;
  final bool? isShowCustomSymptomsOnly;
  final bool? isRequiredMeditationView;
  final List<SymptomsCategory>? customSymptomsList;

  /// When true, the view is shown inside a parent tab (no [Navigator.pop]).
  final bool embeddedInTab;

  /// Called when the user discards unsaved edits in [embeddedInTab] mode.
  final VoidCallback? onDiscardChanges;

  const MenstrualLogPeriodView(
      {super.key,
      this.symptomsLogDate,
      required this.onSuccess,
      required this.onError,
      required this.displaySymptomsData,
      this.themeColor = Colors.black,
      this.isRequiredWaterView = true,
      this.isRequiredBodyTemperatureView = true,
      this.isRequiredMeditationView = true,
      this.isShowCustomSymptomsOnly = false,
      this.customSymptomsList,
      this.isRequiredSleepView = true,
      this.isRequiredWeightView = true,
      this.embeddedInTab = false,
      this.onDiscardChanges});

  @override
  State<MenstrualLogPeriodView> createState() => _MenstrualLogPeriodViewState();
}

class _MenstrualLogPeriodViewState extends State<MenstrualLogPeriodView> {
  List<SymptomsCategory> symptomsList = [];
  List<SymptomsData> existingSymptomsList = [];

  final dbHelper = MenstrualCycleDbHelper.instance;
  final mInstance = MenstrualCycleWidget.instance!;

  List<LogReport> logReportList = [
    LogReport(type: "weight", mainValue: 20, subValue: 0),
    LogReport(type: "bodyTemp", mainValue: 35, subValue: 1),
    LogReport(type: "sleepBedTime", mainValue: 0, subValue: 0),
    LogReport(type: "meditation", mainValue: 0, subValue: 0),
    LogReport(type: "water"),
    LogReport(type: "sleepWakeUpTime", mainValue: 0, subValue: 0),
  ];

  String currentDate = "";
  String logDate = "";
  String cycleDay = "";
  int intCycleDay = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize logDate synchronously to prevent null pointer and allow immediate render
    final date = widget.symptomsLogDate;
    if (date == null) {
      logDate = defaultDateFormat.format(DateTime.now());
    } else {
      try {
        logDate = defaultDateFormat.format(date);
      } catch (_) {
        logDate = defaultDateFormat.format(DateTime.now());
      }
    }
    // Populate the default categories and symptoms list immediately so the UI paints on frame 1
    regenerateData();
    // Trigger async load for existing logs from SQLite database
    init(widget.symptomsLogDate);
  }

  void processSymptomsCategory(
      List<SymptomsCategory> sourceList, bool checkVisibility) {
    for (SymptomsCategory defaultData in sourceList) {
      if (intCycleDay > mInstance.getPeriodDuration() &&
          defaultData.categoryName.toString() ==
              WidgetBaseLanguage.categoryPeriod) {
        continue;
      }
      if (checkVisibility && !isVisibleSymptoms(defaultData.categoryName!)) {
        continue;
      }
      if (!checkVisibility && defaultData.isVisibleCategory != 1) {
        continue;
      }

      SymptomsCategory symptoms = SymptomsCategory(symptomsData: []);
      symptoms.categoryId = defaultData.categoryId;
      symptoms.categoryName = defaultData.categoryName;
      symptoms.categoryColor = defaultData.categoryColor;

      List<SymptomsData> listSymptomsData =
          defaultData.symptomsData!.map((deSymptomsData) {
        bool isSelected = existingSymptomsList
            .any((existing) => existing.symptomId == deSymptomsData.symptomId);
        return SymptomsData(
          symptomName: deSymptomsData.symptomName,
          symptomId: deSymptomsData.symptomId,
          isSelected: isSelected,
        );
      }).toList();

      symptoms.symptomsData!.addAll(listSymptomsData);
      symptomsList.add(symptoms);
    }
  }

  void regenerateData() {
    if (widget.isShowCustomSymptomsOnly! == false) {
      // Process default symptoms data
      processSymptomsCategory(defaultSymptomsData, true);
    }
    // Process custom symptoms list
    if (widget.customSymptomsList != null &&
        widget.customSymptomsList!.isNotEmpty) {
      processSymptomsCategory(widget.customSymptomsList!, false);
    }
  }

  init(DateTime? date) async {
    setState(() {
      isLoading = true;
    });
    // Clear selection state synchronously so we don't display the previous day's selections while loading
    existingSymptomsList.clear();
    symptomsList.clear();
    regenerateData();

    // Reset default picker values in logReportList synchronously
    logReportList[0] = LogReport(type: "weight", mainValue: 20, subValue: 0, finalValue: "", mainIndex: 0, subIndex: 0);
    logReportList[1] = LogReport(type: "bodyTemp", mainValue: 35, subValue: 1, finalValue: "", mainIndex: 0, subIndex: 0);
    logReportList[2] = LogReport(type: "sleepBedTime", mainValue: 0, subValue: 0, finalValue: "", mainIndex: 0, subIndex: 0);
    logReportList[3] = LogReport(type: "meditation", mainValue: 0, subValue: 0, finalValue: "", mainIndex: 0, subIndex: 0, totalMin: 0);
    logReportList[4] = LogReport(type: "water", mainValue: 0, subValue: 0, finalValue: "", mainIndex: 0, subIndex: 0);
    logReportList[5] = LogReport(type: "sleepWakeUpTime", mainValue: 0, subValue: 0, finalValue: "", mainIndex: 0, subIndex: 0);

    try {
    //printMenstrualCycleLogs("init");
    if (date == null) {
      //printMenstrualCycleLogs("Date NUll");
      var now = DateTime.now();
      logDate = defaultDateFormat.format(now);
    } else {
      //printMenstrualCycleLogs("Date Not NUll");
      try {
        logDate = defaultDateFormat.format(date);
      } catch (e) {
        throw WidgetBaseLanguage.errorInvalidSymptomsDate;
      }
    }

    final dbHelper = MenstrualCycleDbHelper.instance;
    String lastPeriodDate = await dbHelper.getLastPeriodDate();

    if (lastPeriodDate.isNotEmpty) {
      String lastPeriodDay =
          await dbHelper.getLastPeriodDateFromInputDate(logDate);

      if (lastPeriodDay.isNotEmpty) {
        int difference = DateTime.parse(logDate)
            .difference(DateTime.parse(lastPeriodDay))
            .inDays;

        intCycleDay = (difference < 0) ? 0 : difference + 1;
        cycleDay = "${WidgetBaseLanguage.cycleDayTitle} $intCycleDay";
      } else {
        cycleDay = "";
        intCycleDay = 0;
      }
      //  printMenstrualCycleLogs('cycleDay ${cycleDay} --- intCycleDay $intCycleDay');
    }
    // Set existing data - start
    UserSymptomsLogs userSymptomsLogs = await mInstance.getSymptomsData(date);
    existingSymptomsList.clear();
    symptomsList.clear();
    existingSymptomsList.addAll(userSymptomsLogs.symptomData!);

    if (userSymptomsLogs.waterValue != null && userSymptomsLogs.waterValue!.isNotEmpty) {
      try {
        logReportList[4].mainValue = int.parse(userSymptomsLogs.waterValue!);
        logReportList[4].finalValue = userSymptomsLogs.waterValue!;
        logReportList[4].mainIndex = int.parse(userSymptomsLogs.waterValue!);
      } catch (_) {}
    }

    if (userSymptomsLogs.meditationTime != null && userSymptomsLogs.meditationTime!.isNotEmpty) {
      try {
        int totalMinutes = int.parse(userSymptomsLogs.meditationTime!);
        int hours = totalMinutes ~/ 60; // Integer division to get hours
        int minutes = totalMinutes % 60; // Modulus to get remaining minutes
        logReportList[3].mainValue = hours;
        logReportList[3].mainIndex = hours;
        logReportList[3].subValue = minutes;
        logReportList[3].subIndex = minutes;
        logReportList[3].totalMin = totalMinutes;
        logReportList[3].finalValue = "$hours h : $minutes m";
      } catch (_) {}
    }

    if (userSymptomsLogs.sleepTime != null && userSymptomsLogs.sleepTime!.isNotEmpty && userSymptomsLogs.sleepTime!.contains("T")) {
      try {
        List<String> startEndTime = userSymptomsLogs.sleepTime!.split("T");
        if (startEndTime.length == 2) {
          List<String> start = startEndTime[0].split(":");
          List<String> end = startEndTime[1].split(":");
          if (start.length == 2 && end.length == 2) {
            logReportList[2].mainValue = int.parse(start[0]);
            logReportList[2].mainIndex = int.parse(start[0]);
            logReportList[2].subValue = int.parse(start[1]);
            logReportList[2].subIndex = int.parse(start[1]);
            logReportList[2].finalValue =
                "${logReportList[2].mainValue} h : ${logReportList[2].subValue} m";

            logReportList[5].mainValue = int.parse(end[0]);
            logReportList[5].mainIndex = int.parse(end[0]);
            logReportList[5].subValue = int.parse(end[1]);
            logReportList[5].subIndex = int.parse(end[1]);
            logReportList[5].finalValue =
                "${logReportList[5].mainValue} h : ${logReportList[5].subValue} m";
          }
        }
      } catch (_) {}
    }

    if (userSymptomsLogs.bodyTemperature != null && userSymptomsLogs.bodyTemperature!.isNotEmpty && userSymptomsLogs.bodyTemperature != "0") {
      try {
        List<String> temp = userSymptomsLogs.bodyTemperature!.split(".");
        logReportList[1].mainValue = int.parse(temp[0]);
        logReportList[1].mainIndex = int.parse(temp[0]) - 35;
        if (temp.length > 1) {
          logReportList[1].subValue = int.parse(temp[1]);
          logReportList[1].subIndex = int.parse(temp[1]) - 1;
          if (logReportList[1].subIndex! < 0) {
            logReportList[1].subIndex = 0;
          }
        } else {
          logReportList[1].subValue = 0;
          logReportList[1].subIndex = 0;
        }
        logReportList[1].finalValue = userSymptomsLogs.bodyTemperature!;
      } catch (_) {}
    }

    if (userSymptomsLogs.weight != null && userSymptomsLogs.weight!.isNotEmpty && userSymptomsLogs.weight != "0") {
      try {
        List<String> weight = userSymptomsLogs.weight!.split(".");
        logReportList[0].mainValue = int.parse(weight[0]);
        logReportList[0].mainIndex = int.parse(weight[0]) - 20;
        if (weight.length > 1 && weight[1].isNotEmpty) {
          double decimalValue = double.parse("0.${weight[1]}");
          int sub = (decimalValue * 10).round();
          logReportList[0].subValue = sub;
          logReportList[0].subIndex = sub;
        } else {
          logReportList[0].subValue = 0;
          logReportList[0].subIndex = 0;
        }
        logReportList[0].finalValue = userSymptomsLogs.weight!;
      } catch (_) {}
    }

    // Set existing data - end
    currentDate = currentDateFormat.format(DateTime.now());

    regenerateData();

    final now = DateTime.now();
    int phaseId = (intCycleDay < 6)
        ? 1
        : (intCycleDay < 13)
            ? 2
            : (intCycleDay < 16)
                ? 3
                : (intCycleDay < 30)
                    ? 4
                    : 5;

    if (widget.isShowCustomSymptomsOnly! == false) {
      if (DateTime.parse(logDate) == DateTime(now.year, now.month, now.day)) {
        List<SymptomsData> listSymptomsData = defaultSymptomsData
            .expand((category) => category.symptomsData ?? <SymptomsData>[])
            .where((symptomsData) =>
                symptomsData.phaseIds?.contains(phaseId) ?? false)
            .toList();

        if (listSymptomsData.isNotEmpty) {
          symptomsList.insert(
            0,
            SymptomsCategory(
              categoryId: 99999,
              categoryName: WidgetBaseLanguage.feelingTodayTitle,
              symptomsData: listSymptomsData,
            ),
          );
        }
      }
    }
    } catch (e) {
      // Never leave the screen stuck on the loading spinner if any data source
      // throws (e.g. a corrupt date or decrypt failure) — fall back to an
      // editable empty form so the user can still log their day.
      debugPrint('MenstrualLogPeriodView.init failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool isVisibleSymptoms(String symptomName) {
    DisplaySymptomsData displaySymptomsData = widget.displaySymptomsData!;
    if (symptomName == WidgetBaseLanguage.categoryFeelings) {
      return displaySymptomsData.isRequiredFeelings;
    } else if (symptomName == WidgetBaseLanguage.categoryMind) {
      return displaySymptomsData.isRequiredMind;
    } else if (symptomName == WidgetBaseLanguage.categorySexualLife) {
      return displaySymptomsData.isRequiredSexualLife;
    } else if (symptomName == WidgetBaseLanguage.categoryEnergy) {
      return displaySymptomsData.isRequiredEnergy;
    } else if (symptomName == WidgetBaseLanguage.categoryPeriod) {
      return displaySymptomsData.isRequiredPeriod;
    } else if (symptomName == WidgetBaseLanguage.categorySymptoms) {
      return displaySymptomsData.isRequiredSymptoms;
    } else if (symptomName == WidgetBaseLanguage.categoryPain) {
      return displaySymptomsData.isRequiredPain;
    } else if (symptomName == WidgetBaseLanguage.categoryVaginalDischarge) {
      return displaySymptomsData.isRequiredVaginalDischarge;
    } else if (symptomName == WidgetBaseLanguage.categoryDigestion) {
      return displaySymptomsData.isRequiredDigestion;
    } else if (symptomName == WidgetBaseLanguage.categoryActivity) {
      return displaySymptomsData.isRequiredActivity;
    } else if (symptomName == WidgetBaseLanguage.categoryCravings) {
      return displaySymptomsData.isRequiredCravings;
    } else if (symptomName == WidgetBaseLanguage.categoryTests) {
      return displaySymptomsData.isRequiredTests;
    } else if (symptomName == WidgetBaseLanguage.categoryAilments) {
      return displaySymptomsData.isRequiredAilments;
    } else if (symptomName == WidgetBaseLanguage.categoryAppointments) {
      return displaySymptomsData.isRequiredAppointments;
    } else if (symptomName == WidgetBaseLanguage.categoryBirthControlPill) {
      return displaySymptomsData.isRequiredBirthControlPill;
    } else if (symptomName == WidgetBaseLanguage.categoryIUD) {
      return displaySymptomsData.isRequiredIUD;
    } else if (symptomName == WidgetBaseLanguage.categorySupplements) {
      return displaySymptomsData.isRequiredSupplements;
    } else if (symptomName == WidgetBaseLanguage.categoryUrine) {
      return displaySymptomsData.isRequiredUrine;
    } else if (symptomName == WidgetBaseLanguage.categoryOther) {
      return displaySymptomsData.isRequiredOther;
    }
    return false;
  }

  /// Save body temperature data
  saveBodyTempLog() {
    if (logReportList[1].subValue! > 0) {
      if (logReportList[1].subValue! > 9) {
        logReportList[1].finalValue =
            "${logReportList[1].mainValue}.${logReportList[1].subValue}";
      } else {
        logReportList[1].finalValue =
            "${logReportList[1].mainValue}.0${logReportList[1].subValue}";
      }
    } else {
      logReportList[1].finalValue = "${logReportList[1].mainValue}.0";
    }
    setState(() {});
    saveTodayLogsSilently();
  }

  /// save meditation data
  saveMeditationLog() {
    String hour = "00";
    String min = "00";
    if (logReportList[3].mainValue! > 9) {
      hour = "${logReportList[3].mainValue!}";
    } else {
      hour = "0${logReportList[3].mainValue!}";
    }
    if (logReportList[3].subValue! > 9) {
      min = "${logReportList[3].subValue!}";
    } else {
      min = "0${logReportList[3].subValue!}";
    }
    logReportList[3].finalValue = "$hour h : $min m";
    logReportList[3].totalMin =
        (logReportList[3].mainValue! * 60) + logReportList[3].subValue!;
    setState(() {});
    saveTodayLogsSilently();
  }

  /// save sleep data
  saveSleepLog() {
    int index = 2;
    String hour = "00";
    String min = "00";
    if (logReportList[index].mainValue! > 9) {
      hour = "${logReportList[index].mainValue!}";
    } else {
      hour = "0${logReportList[index].mainValue!}";
    }
    if (logReportList[index].subValue! > 9) {
      min = "${logReportList[index].subValue!}";
    } else {
      min = "0${logReportList[index].subValue!}";
    }
    logReportList[index].finalValue = "$hour h : $min m";
    logReportList[index].totalMin =
        (logReportList[index].mainValue! * 60) + logReportList[index].subValue!;
    setState(() {});
    saveTodayLogsSilently();
  }

  saveSleepWackUpLog() {
    int index = 5;
    String hour = "00";
    String min = "00";
    if (logReportList[index].mainValue! > 9) {
      hour = "${logReportList[index].mainValue!}";
    } else {
      hour = "0${logReportList[index].mainValue!}";
    }
    if (logReportList[index].subValue! > 9) {
      min = "${logReportList[index].subValue!}";
    } else {
      min = "0${logReportList[index].subValue!}";
    }
    logReportList[index].finalValue = "$hour h : $min m";
    logReportList[index].totalMin =
        (logReportList[index].mainValue! * 60) + logReportList[index].subValue!;
    setState(() {});
    saveTodayLogsSilently();
  }

  /// save drink water data
  saveWaterLog() {
    if (logReportList[4].mainValue! > 9) {
      logReportList[4].finalValue = "${logReportList[4].mainValue}";
    } else {
      logReportList[4].finalValue = "0${logReportList[4].mainValue}";
    }
    setState(() {});
    saveTodayLogsSilently();
  }

  /// save weight data
  saveWeightLog() {
    logReportList[0].finalValue =
        "${logReportList[0].mainValue}.${logReportList[0].subValue}";
    setState(() {});
    saveTodayLogsSilently();
  }

  /// save today logs to database
  Future<void> saveTodayLogs() async {
    List<SymptomsData> userLogData = [];
    for (int index = 0; index < symptomsList.length; index++) {
      for (int j = 0; j < symptomsList[index].symptomsData!.length; j++) {
        SymptomsData symptomsData = symptomsList[index].symptomsData![j];
        if (symptomsData.isSelected) {
          userLogData.add(symptomsData);
        }
      }
    }

    try {
      await mInstance.saveSymptomsLogs(
          userSymptomsData: userLogData,
          onError: widget.onError,
          cycleDay: intCycleDay,
          symptomsLogDate: DateTime.parse(logDate),
          onSuccess: (id) async {
            if (_canGoForward) {
              if (mounted) {
                await init(DateTime.parse(logDate));
                _shiftLogDate(1);
              }
            } else {
              widget.onSuccess?.call(id);
              if (mounted) {
                await init(DateTime.parse(logDate));
                _maybePopRoute();
              }
            }
          },
          waterValue: (logReportList[4].finalValue!.isNotEmpty)
              ? logReportList[4].finalValue.toString()
              : "0",
          bodyTemperature: (logReportList[1].finalValue!.isNotEmpty)
              ? logReportList[1].finalValue.toString()
              : "0",
          weight: (logReportList[0].finalValue!.isNotEmpty)
              ? logReportList[0].finalValue.toString()
              : "0",
          meditationTime: logReportList[3].totalMin!.toString(),
          sleepBedTime: TimeOfDay(
              hour: logReportList[2].mainValue!.toInt(),
              minute: logReportList[2].subValue!.toInt()),
          sleepWakeUpTime: TimeOfDay(
              hour: logReportList[5].mainValue!.toInt(),
              minute: logReportList[5].subValue!.toInt()));
    } catch (e) {
      widget.onError?.call();
    }
  }

  Future<void> saveTodayLogsSilently() async {
    List<SymptomsData> userLogData = [];
    for (int index = 0; index < symptomsList.length; index++) {
      for (int j = 0; j < symptomsList[index].symptomsData!.length; j++) {
        SymptomsData symptomsData = symptomsList[index].symptomsData![j];
        if (symptomsData.isSelected) {
          userLogData.add(symptomsData);
        }
      }
    }

    try {
      await mInstance.saveSymptomsLogs(
          userSymptomsData: userLogData,
          onError: null,
          cycleDay: intCycleDay,
          symptomsLogDate: DateTime.parse(logDate),
          onSuccess: (id) {
            // Silently saved to SQLite, no pop and no toast feedback
          },
          waterValue: (logReportList[4].finalValue!.isNotEmpty)
              ? logReportList[4].finalValue.toString()
              : "0",
          bodyTemperature: (logReportList[1].finalValue!.isNotEmpty)
              ? logReportList[1].finalValue.toString()
              : "0",
          weight: (logReportList[0].finalValue!.isNotEmpty)
              ? logReportList[0].finalValue.toString()
              : "0",
          meditationTime: logReportList[3].totalMin!.toString(),
          sleepBedTime: TimeOfDay(
              hour: logReportList[2].mainValue!.toInt(),
              minute: logReportList[2].subValue!.toInt()),
          sleepWakeUpTime: TimeOfDay(
              hour: logReportList[5].mainValue!.toInt(),
              minute: logReportList[5].subValue!.toInt()));
    } catch (e) {
      debugPrint('Silent save failed: $e');
    }
  }

  void _maybePopRoute() {
    if (!widget.embeddedInTab && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _onCancelPressed() {
    if (widget.embeddedInTab) {
      init(DateTime.parse(logDate));
      widget.onDiscardChanges?.call();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  bool get _canGoForward {
    final current = DateTime.parse(logDate);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return current.isBefore(todayDate);
  }

  void _shiftLogDate(int days) {
    final current = DateTime.parse(logDate);
    final target = current.add(Duration(days: days));
    if (days > 0) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (target.isAfter(todayDate)) return;
    }
    logDate = defaultDateFormat.format(target);
    init(target);
  }

  Future<void> _pickLogDate() async {
    final initial = DateTime.parse(logDate);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked == null) return;
    logDate = defaultDateFormat.format(picked);
    init(picked);
  }

  Color _cardFillColor(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.embeddedInTab) {
      return theme.brightness == Brightness.dark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surfaceContainerHighest;
    }
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white;
  }

  Color _onSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _mutedTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// open bottom sheet view for perform operation
  void _showBottomSheetView(
      {required BuildContext context,
      required String title,
      required String type,
      required Function onClick,
      required Widget childView}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: getFontFamily(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    childView,
                    Text(
                      type,
                      style: textStyle24Bold(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          WidgetBaseLanguage.cancelLabel,
                          style: TextStyle(fontFamily: getFontFamily()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.themeColor,
                        ),
                        onPressed: () {
                          onClick.call();
                          Navigator.pop(sheetContext);
                          setState(() {});
                        },
                        child: Text(
                          WidgetBaseLanguage.lblDone,
                          style: TextStyle(
                            fontFamily: getFontFamily(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// build water picker view
  Widget _buildWaterPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPicker(
          value: logReportList[4].mainIndex!,
          minValue: 0,
          maxValue: 20,
          onSelectedItemChanged: (index) {
            logReportList[4].mainValue = 0 + index;
            logReportList[4].mainIndex = index;
          },
        ),
      ],
    );
  }

  /// build body temperature view
  Widget _buildTemperaturePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPicker(
          value: logReportList[1].mainIndex!,
          minValue: 35,
          maxValue: 40,
          onSelectedItemChanged: (index) {
            logReportList[1].mainValue = 35 + index;
            logReportList[1].mainIndex = index;
          },
        ),
        Text(
          '.',
          style: textStyle24Bold(),
        ),
        _buildPicker(
          value: logReportList[1].subIndex!,
          minValue: 1,
          maxValue: 99,
          onSelectedItemChanged: (index) {
            logReportList[1].subValue = 1 + index;
            logReportList[1].subIndex = index;
          },
        ),
      ],
    );
  }

  /// build sleep picker view
  Widget _buildSleepPicker({bool isWakeUpTime = false}) {
    int logIndex = 2;
    if (isWakeUpTime) {
      logIndex = 5;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPicker(
          value: logReportList[logIndex].mainIndex!,
          minValue: 0,
          maxValue: 23,
          onSelectedItemChanged: (index) {
            logReportList[logIndex].mainValue = 0 + index;
            logReportList[logIndex].mainIndex = index;
          },
        ),
        Text(
          'h',
          style: textStyle24Bold(),
        ),
        _buildPicker(
          value: logReportList[logIndex].subIndex!,
          minValue: 0,
          maxValue: 60,
          onSelectedItemChanged: (index) {
            logReportList[logIndex].subValue = 0 + index;
            logReportList[logIndex].subIndex = index;
          },
        ),
        Text(
          'm',
          style: textStyle24Bold(),
        ),
      ],
    );
  }

  /// build meditation picker view
  Widget _buildMeditationPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPicker(
          value: logReportList[3].mainIndex!,
          minValue: 0,
          maxValue: 23,
          onSelectedItemChanged: (index) {
            logReportList[3].mainValue = 0 + index;
            logReportList[3].mainIndex = index;
          },
        ),
        Text(
          'h',
          style: textStyle24Bold(),
        ),
        _buildPicker(
          value: logReportList[3].subIndex!,
          minValue: 0,
          maxValue: 60,
          onSelectedItemChanged: (index) {
            logReportList[3].subValue = 0 + index;
            logReportList[3].subIndex = index;
          },
        ),
        Text(
          'm',
          style: textStyle24Bold(),
        ),
      ],
    );
  }

  /// build weight picker view
  Widget _buildWeightPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPicker(
          value: logReportList[0].mainIndex!,
          minValue: 20,
          maxValue: 300,
          onSelectedItemChanged: (index) {
            logReportList[0].mainValue = 20 + index;
            logReportList[0].mainIndex = index;
          },
        ),
        Text(
          '.',
          style: textStyle24Bold(),
        ),
        _buildPicker(
          value: logReportList[0].subIndex!,
          minValue: 0,
          isForWeight: true,
          maxValue: 9,
          onSelectedItemChanged: (index) {
            logReportList[0].subValue = 0 + index;
            logReportList[0].subIndex = index;
          },
        ),
      ],
    );
  }

  /// Build picker view
  Widget _buildPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onSelectedItemChanged,
    bool isForWeight = false,
  }) {
    return SizedBox(
      height: 150,
      width: 80,
      child: CupertinoPicker(
        magnification: 1.4,
        squeeze: 0.8,
        useMagnifier: true,
        scrollController: FixedExtentScrollController(initialItem: value),
        itemExtent: 32.0,
        onSelectedItemChanged: onSelectedItemChanged,
        children: List.generate(maxValue - minValue + 1, (index) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black;
          return Center(
            child: (isForWeight)
                ? Text(
                    (minValue + index).toString(),
                    style: textStyle24Bold().copyWith(color: textColor),
                  )
                : ((minValue + index) > 9)
                    ? Text(
                        (minValue + index).toString(),
                        style: textStyle24Bold().copyWith(color: textColor),
                      )
                    : Text(
                        "0${(minValue + index)}",
                        style: textStyle24Bold().copyWith(color: textColor),
                      ),
          );
        }),
      ),
    );
  }

  Widget sleepView({
    required String image,
    required String title,
    required String startTimeHintText,
    required String endTimeHintText,
    required Widget removeIcon,
    required Function onStartTimeClick,
    required Function onEndTimeClick,
    required Function onRemoveClick,
    required String typeString,
  }) {
    final onSurface = _onSurfaceColor(context);
    final muted = _mutedTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Card(
        color: _cardFillColor(context),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        image,
                        package: flutterPackageName,
                        width: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                          fontFamily: getFontFamily(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Row(
                    children: [
                      ClipOval(
                        child: Material(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD6D6D6), // Button color
                          child: InkWell(
                            splashColor: Colors.black26, // Splash color
                            onTap: () {
                              onRemoveClick.call();
                            },
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: removeIcon,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    WidgetBaseLanguage.logPeriodBedtime,
                    style: TextStyle(
                      fontSize: 15,
                      color: muted,
                      fontWeight: FontWeight.w600,
                      fontFamily: getFontFamily(),
                    ),
                  ),
                  SizedBox(),
                  Text(
                    WidgetBaseLanguage.logPeriodWakeUpTime,
                    style: TextStyle(
                      fontSize: 15,
                      color: muted,
                      fontWeight: FontWeight.w600,
                      fontFamily: getFontFamily(),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      onStartTimeClick.call();
                    },
                    child: Text(
                      startTimeHintText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                        fontFamily: getFontFamily(),
                      ),
                    ),
                  ),
                  const SizedBox(),
                  GestureDetector(
                    onTap: () {
                      onEndTimeClick.call();
                    },
                    child: Text(
                      endTimeHintText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                        fontFamily: getFontFamily(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Design log view for water, body temperature, weight etc
  Widget logView({
    required String image,
    required String title,
    required String hintText,
    required Widget addIcon,
    required Widget removeIcon,
    required Function onAddClick,
    required Function onRemoveClick,
    required String typeString,
  }) {
    final onSurface = _onSurfaceColor(context);
    final muted = _mutedTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Card(
        color: _cardFillColor(context),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        image,
                        package: flutterPackageName,
                        width: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                          fontFamily: getFontFamily(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Row(
                    children: [
                      ClipOval(
                        child: Material(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEDEDED), // Button color
                          child: InkWell(
                            splashColor: Colors.black26, // Splash color
                            onTap: () {
                              onRemoveClick.call();
                            },
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: removeIcon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ClipOval(
                        child: Material(
                          color: isDark ? widget.themeColor.withValues(alpha: 0.25) : const Color(0xFFFEECF3), // Button color
                          child: InkWell(
                            splashColor: Colors.black26, // Splash color
                            onTap: () {
                              onAddClick.call();
                            },
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: addIcon,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      onAddClick.call();
                    },
                    child: Text(
                      hintText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                        fontFamily: getFontFamily(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      typeString,
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontFamily: getFontFamily(),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  getTitle() {
    final now = DateTime.now();
    final difference = now.difference(DateTime.parse(logDate)).inDays;
    if (difference == 0) {
      return WidgetBaseLanguage.todayTitle;
    } else if (difference == 1) {
      return WidgetBaseLanguage.yesterdayTitle;
    } else {
      return CalenderDateUtils.graphDateFormat(DateTime.parse(logDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final embedded = widget.embeddedInTab;
    final surface = embedded
        ? Colors.transparent
        : const Color(0xfff2f2f2);
    final onSurface = _onSurfaceColor(context);
    final muted = _mutedTextColor(context);
    final cardColor = _cardFillColor(context);
    final primary = widget.themeColor;

    final body = SafeArea(
      top: !embedded,
      bottom: embedded,
      child: Padding(
        padding: EdgeInsets.only(top: embedded ? 0 : 40),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (embedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftLogDate(-1),
                        icon: Icon(Icons.chevron_left, color: primary),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickLogDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 16, color: primary),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          getTitle(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: getFontFamily(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (cycleDay.isNotEmpty)
                                    Text(
                                      cycleDay,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                        fontFamily: getFontFamily(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _canGoForward ? () => _shiftLogDate(1) : null,
                        icon: Icon(Icons.chevron_right,
                            color: _canGoForward
                                ? primary
                                : primary.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: onSurface,
                          size: 20,
                        ),
                      ),
                      onTap: () => _shiftLogDate(-1),
                    ),
                    Column(
                      children: [
                        Text(
                          getTitle(),
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: getFontFamily(),
                          ),
                        ),
                        (cycleDay.isNotEmpty)
                            ? Text(
                                cycleDay,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  fontFamily: getFontFamily(),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                    GestureDetector(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: _canGoForward
                              ? onSurface
                              : onSurface.withValues(alpha: 0.35),
                          size: 20,
                        ),
                      ),
                      onTap: () {
                        if (_canGoForward) _shiftLogDate(1);
                      },
                    )
                  ],
                ),
              SizedBox(
                height: 4,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.verified_user,
                      color: Colors.green,
                      size: 18,
                    ),
                    Text(
                      " ${WidgetBaseLanguage.protectedData}",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: getFontFamily(),
                      ),
                    )
                  ]),
              SizedBox(
                height: 5,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 0, left: 8, right: 8, bottom: 20),
                    child: Column(
                      children: [
                        ListView.builder(
                                padding: const EdgeInsets.all(8),
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: symptomsList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Card(
                                    color: cardColor,
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${symptomsList[index].categoryName}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: getFontFamily(),
                                            ),
                                          ),
                                          Divider(color: Color(0xFFD3D3D3)),
                                          Wrap(
                                              children: symptomsList[index]
                                                  .symptomsData!
                                                  .map((chip) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 3),
                                              child: Stack(
                                                alignment:
                                                    Alignment.bottomRight,
                                                children: [
                                                  FilterChip(
                                                    shape:
                                                        const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(50),
                                                      ),
                                                    ),
                                                    key: ValueKey(chip),
                                                    side: chip.isSelected
                                                        ? BorderSide(
                                                            color: Color(
                                                              int.parse(
                                                                  "0xff${symptomsList[index].categoryColor!.replaceAll("#", "")}"),
                                                            ),
                                                          )
                                                        : BorderSide.none,
                                                    label: Text(
                                                      "${chip.symptomName}",
                                                      style: TextStyle(
                                                          color: chip.isSelected ? Colors.white : null,
                                                          fontWeight: chip.isSelected ? FontWeight.bold : null,
                                                          fontFamily:
                                                              getFontFamily()),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    backgroundColor:
                                                        chip.isSelected
                                                            ? Color(
                                                                int.parse(
                                                                    "0xff${symptomsList[index].categoryColor!.replaceAll("#", "")}"),
                                                              )
                                                            : Color(
                                                                int.parse(
                                                                    "0x15${symptomsList[index].categoryColor!.replaceAll("#", "")}"),
                                                              ),
                                                    onSelected: (bool value) {
                                                      setState(() {
                                                        chip.isSelected =
                                                            !chip.isSelected;
                                                      });
                                                      saveTodayLogsSilently();
                                                    },
                                                  ),
                                                  (chip.isSelected)
                                                      ? const Icon(
                                                          Icons.check_circle_rounded,
                                                          color: Colors.white,
                                                          size: 16)
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        (widget.isRequiredWeightView!)
                            ? logView(
                                title: WidgetBaseLanguage.lblWeight,
                                addIcon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: widget.themeColor,
                                ),
                                hintText:
                                    (logReportList[0].finalValue!.isNotEmpty)
                                        ? logReportList[0].finalValue!
                                        : "000",
                                image: weightImage,
                                onAddClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      type: WidgetBaseLanguage.weightKg,
                                      onClick: saveWeightLog,
                                      childView: _buildWeightPicker(),
                                      title: WidgetBaseLanguage.lblWeightTitle);
                                },
                                onRemoveClick: () {
                                  setState(() {
                                    logReportList[0].finalValue = "";
                                  });
                                  saveTodayLogsSilently();
                                },
                                removeIcon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Color(0xFF2F2F2F),
                                ),
                                typeString: "/ ${WidgetBaseLanguage.weightKg}")
                            : const SizedBox(),
                        (widget.isRequiredBodyTemperatureView!)
                            ? logView(
                                title: WidgetBaseLanguage.lblBodyTemp,
                                addIcon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: widget.themeColor,
                                ),
                                hintText:
                                    (logReportList[1].finalValue!.isNotEmpty)
                                        ? logReportList[1].finalValue!
                                        : "000",
                                image: temperatureImage,
                                onAddClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      title:
                                          WidgetBaseLanguage.lblBodyTempTitle,
                                      childView: _buildTemperaturePicker(),
                                      onClick: saveBodyTempLog,
                                      type: "°${WidgetBaseLanguage.bodyTempC}");
                                },
                                onRemoveClick: () {
                                  setState(() {
                                    logReportList[1].finalValue = "";
                                  });
                                  saveTodayLogsSilently();
                                },
                                removeIcon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Color(0xFF2F2F2F),
                                ),
                                typeString:
                                    "/ °${WidgetBaseLanguage.bodyTempC}")
                            : const SizedBox(),
                        (widget.isRequiredSleepView!)
                            ? sleepView(
                                title: WidgetBaseLanguage.lblSleep,
                                startTimeHintText:
                                    (logReportList[2].finalValue!.isNotEmpty)
                                        ? logReportList[2].finalValue!
                                        : "00 h : 00 m",
                                endTimeHintText:
                                    (logReportList[5].finalValue!.isNotEmpty)
                                        ? logReportList[5].finalValue!
                                        : "00 h : 00 m",
                                image: sleepImage,
                                onEndTimeClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      type: "",
                                      onClick: saveSleepWackUpLog,
                                      childView:
                                          _buildSleepPicker(isWakeUpTime: true),
                                      title: WidgetBaseLanguage
                                          .logPeriodWakeUpTimeLog);
                                },
                                onStartTimeClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      type: "",
                                      onClick: saveSleepLog,
                                      childView: _buildSleepPicker(),
                                      title: WidgetBaseLanguage
                                          .logPeriodBedTimeLog);
                                },
                                onRemoveClick: () {
                                  setState(() {
                                    logReportList[2].finalValue = "";
                                    logReportList[2].mainValue = 0;
                                    logReportList[2].subValue = 0;
                                    logReportList[5].finalValue = "";
                                    logReportList[5].mainValue = 0;
                                    logReportList[5].subValue = 0;
                                  });
                                  saveTodayLogsSilently();
                                },
                                removeIcon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Color(0xFF2F2F2F),
                                ),
                                typeString: "")
                            : const SizedBox(),
                        (widget.isRequiredMeditationView!)
                            ? logView(
                                title: WidgetBaseLanguage.lblMeditation,
                                addIcon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: widget.themeColor,
                                ),
                                hintText:
                                    (logReportList[3].finalValue!.isNotEmpty)
                                        ? logReportList[3].finalValue!
                                        : "00 h : 00 m",
                                image: yogaImage,
                                onAddClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      type: "",
                                      onClick: saveMeditationLog,
                                      childView: _buildMeditationPicker(),
                                      title: WidgetBaseLanguage
                                          .lblMeditationTitle);
                                },
                                onRemoveClick: () {
                                  setState(() {
                                    logReportList[3].finalValue = "";
                                    logReportList[3].totalMin = 0;
                                  });
                                  saveTodayLogsSilently();
                                },
                                removeIcon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Color(0xFF2F2F2F),
                                ),
                                typeString: "")
                            : const SizedBox(),
                        (widget.isRequiredWaterView!)
                            ? logView(
                                title: WidgetBaseLanguage.lblWater,
                                addIcon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: widget.themeColor,
                                ),
                                hintText:
                                    (logReportList[4].finalValue!.isNotEmpty)
                                        ? logReportList[4].finalValue!
                                        : "00",
                                image: drinkWaterImage,
                                onAddClick: () {
                                  _showBottomSheetView(
                                      context: context,
                                      title: WidgetBaseLanguage.lblWaterTitle,
                                      childView: _buildWaterPicker(),
                                      onClick: saveWaterLog,
                                      type: WidgetBaseLanguage
                                          .graphWaterUnitLiter);
                                },
                                onRemoveClick: () {
                                  setState(() {
                                    logReportList[4].finalValue = "";
                                  });
                                  saveTodayLogsSilently();
                                },
                                removeIcon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Color(0xFF2F2F2F),
                                ),
                                typeString:
                                    "/ ${WidgetBaseLanguage.graphWaterUnitLiter}")
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
              if (embedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _onCancelPressed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary.withValues(alpha: 0.5)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            WidgetBaseLanguage.cancelLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: getFontFamily(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading ? null : saveTodayLogs,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            WidgetBaseLanguage.saveLogs,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: getFontFamily(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _onCancelPressed,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: onSurface,
                          ),
                          color: cardColor,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        margin: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            WidgetBaseLanguage.cancelLabel,
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontFamily: getFontFamily(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading ? null : saveTodayLogs,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primary,
                          ),
                          color: primary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        margin: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            WidgetBaseLanguage.saveLogs,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: getFontFamily(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
    );

    if (embedded) {
      return ColoredBox(color: surface, child: body);
    }

    return Scaffold(
      backgroundColor: surface,
      body: body,
    );
  }
}
