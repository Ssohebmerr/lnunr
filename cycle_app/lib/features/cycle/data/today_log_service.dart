import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// Summary of the user's daily log entry (symptoms, water, etc.).
class TodayLogSummary {
  const TodayLogSummary({
    required this.symptoms,
    required this.waterCups,
    required this.hasEntry,
  });

  final List<String> symptoms;
  final int waterCups;
  final bool hasEntry;
}

/// Reads today's saved log from the local cycle database.
class TodayLogService {
  Future<TodayLogSummary?> loadToday() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return null;

    try {
      final logs = await widget.getSymptomsData(DateTime.now());
      final symptoms = logs.symptomData
              ?.map((s) => s.symptomName?.trim() ?? '')
              .where((n) => n.isNotEmpty)
              .toList() ??
          [];

      final waterRaw = logs.waterValue?.trim() ?? '0';
      final waterCups = int.tryParse(waterRaw.split('.').first) ?? 0;

      final hasEntry = symptoms.isNotEmpty || waterCups > 0;

      return TodayLogSummary(
        symptoms: symptoms,
        waterCups: waterCups,
        hasEntry: hasEntry,
      );
    } catch (_) {
      return null;
    }
  }
}
