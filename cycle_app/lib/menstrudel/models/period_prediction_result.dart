import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

class PeriodPredictionResult {
  final DateTime estimatedStartDate;
  final DateTime estimatedEndDate;
  final int daysUntilDue;
  final int averageCycleLength;
  final int averagePeriodDuration;
  final CyclePredictionEstimate? evidence;

  PeriodPredictionResult({
    required this.estimatedStartDate,
    required this.estimatedEndDate,
    required this.daysUntilDue,
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    this.evidence,
  });

  @override
  String toString() {
    return 'Prediction: Start=${estimatedStartDate.toIso8601String().substring(0, 10)}, End=${estimatedEndDate.toIso8601String().substring(0, 10)}, Due in=$daysUntilDue days, Avg Cycle=$averageCycleLength, Avg Duration=$averagePeriodDuration';
  }
}
