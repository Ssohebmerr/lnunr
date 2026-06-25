import '../../cycle/data/cycle_bridge_service.dart';

/// Fertility level derived from cycle dashboard (for conceive / avoid modes).
enum FertilityLevel { high, moderate, low, unknown }

class GoalModeAnalytics {
  GoalModeAnalytics._();

  static FertilityLevel fertilityLevel(CycleDashboardData data) {
    if (data.isOvulationDay) return FertilityLevel.high;

    final phase = data.phase.toLowerCase();
    final chances = data.pregnancyChances.toLowerCase();

    if (_containsAny(chances, ['high', 'elevated', 'عال', 'مرتف', 'عالية'])) {
      return FertilityLevel.high;
    }
    if (_containsAny(chances, ['low', 'منخفض', 'قليل'])) {
      return FertilityLevel.low;
    }
    if (_containsAny(phase, [
      'ovulation',
      'fertile',
      'fertility',
      'إباض',
      'خصوب',
      'خصبة',
    ])) {
      return FertilityLevel.high;
    }
    if (_containsAny(phase, [
      'menstrual',
      'period',
      'حيض',
      'طمث',
    ])) {
      return FertilityLevel.low;
    }
    if (data.cycleDay >= 9 && data.cycleDay <= 16) {
      return FertilityLevel.moderate;
    }
    if (_containsAny(phase, ['luteal', 'أصفار', 'follicular', 'جريبي'])) {
      return FertilityLevel.moderate;
    }
    return FertilityLevel.unknown;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  static bool hasFertilityData(CycleDashboardData data) {
    return data.pregnancyChances.isNotEmpty &&
        data.pregnancyChances != '—' &&
        data.pregnancyChances != '-';
  }
}
