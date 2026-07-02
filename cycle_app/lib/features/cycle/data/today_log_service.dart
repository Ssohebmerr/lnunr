import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// Summary of the user's daily log entry (symptoms, water, weight, temp, sleep, meditation, notes).
class TodayLogSummary {
  const TodayLogSummary({
    required this.symptoms,
    required this.waterCups,
    required this.weight,
    required this.bodyTemperature,
    required this.sleepTime,
    required this.meditationTime,
    required this.notes,
    required this.hasEntry,
  });

  final List<String> symptoms;
  final int waterCups;
  final String? weight;
  final String? bodyTemperature;
  final String? sleepTime;
  final String? meditationTime;
  final String? notes;
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

      final weightRaw = logs.weight?.trim();
      final weight = (weightRaw != null && weightRaw != '0' && weightRaw != '0.0') ? weightRaw : null;

      final tempRaw = logs.bodyTemperature?.trim();
      final bodyTemp = (tempRaw != null && tempRaw != '0' && tempRaw != '0.0') ? tempRaw : null;

      final sleepRaw = logs.sleepTime?.trim();
      final sleepTime = (sleepRaw != null && sleepRaw != '0') ? sleepRaw : null;

      final medRaw = logs.meditationTime?.trim();
      final meditationTime = (medRaw != null && medRaw != '0') ? medRaw : null;

      final notesRaw = logs.notes?.trim();
      final notes = (notesRaw != null && notesRaw.isNotEmpty) ? notesRaw : null;

      final hasEntry = symptoms.isNotEmpty ||
          waterCups > 0 ||
          weight != null ||
          bodyTemp != null ||
          sleepTime != null ||
          meditationTime != null ||
          notes != null;

      return TodayLogSummary(
        symptoms: symptoms,
        waterCups: waterCups,
        weight: weight,
        bodyTemperature: bodyTemp,
        sleepTime: sleepTime,
        meditationTime: meditationTime,
        notes: notes,
        hasEntry: hasEntry,
      );
    } catch (_) {
      return null;
    }
  }
}
