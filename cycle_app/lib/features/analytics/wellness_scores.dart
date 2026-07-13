/// Turns the user's real daily logs into 0–100 mood / energy / sleep scores
/// for the Analytics page — replacing the cycle-phase guesses that used to
/// power those tiles. Pure Dart (no Flutter/Firebase) so it is fully unit
/// testable; the cycle bridge maps store rows into [WellnessDayLog]s.
library;

/// One day's log reduced to what the wellness scores need.
class WellnessDayLog {
  const WellnessDayLog({this.symptomIds = const {}, this.sleepTime});

  /// Selected symptom ids from the daily log (feelings, mind, energy, …).
  final Set<int> symptomIds;

  /// Raw sleep window as stored by the cycle store: `"H:MTh:m"` (bed T wake).
  /// `null`, empty, or `"0"` mean sleep wasn't logged that day.
  final String? sleepTime;
}

/// Aggregated real scores. A `null` score means the user never logged that
/// dimension in the window — callers fall back to the phase estimate.
class RealWellnessScores {
  const RealWellnessScores({
    this.mood,
    this.energy,
    this.sleep,
    this.moodDays = 0,
    this.energyDays = 0,
    this.sleepDays = 0,
  });

  final double? mood;
  final double? energy;
  final double? sleep;

  /// Number of days that contributed to each score.
  final int moodDays;
  final int energyDays;
  final int sleepDays;

  bool get isEmpty => mood == null && energy == null && sleep == null;
}

class WellnessScoreEngine {
  WellnessScoreEngine._();

  /// Feeling/mind symptom ids that read as positive. Ids come from the cycle
  /// store's fixed default catalogue (see DailyLogWriter's alias map).
  static const Set<int> positiveMoodIds = {
    21003, // happy
    21004, // frisky
    21011, // grateful
    21013, // excited
    21014, // calm
    21016, // focused
    21020, // motivated
    21022, // creative
    21023, // productive
    21131, // confident
  };

  /// Feeling/mind symptom ids that read as negative.
  static const Set<int> negativeMoodIds = {
    21001, // sensitive
    21005, // mood swings
    21006, // irritated
    21007, // sad
    21008, // tension
    21009, // angry
    21010, // insecure
    21012, // anxiety
    21015, // distracted
    21017, // depressed
    21018, // confused
    21019, // stressed
  };

  /// Energy-word ids mapped straight to a 0–100 level.
  static const Map<int, double> energyLevelById = {
    21037: 15, // exhausted
    21038: 35, // tired
    21054: 35, // fatigue (symptom, reads as low energy)
    21039: 60, // ok
    21040: 85, // energetic
    21041: 95, // energized
  };

  /// Aggregates a window of daily logs into real scores. Days that logged
  /// nothing for a dimension simply don't count toward it.
  static RealWellnessScores fromLogs(Iterable<WellnessDayLog> logs) {
    var moodSum = 0.0, energySum = 0.0, sleepSum = 0.0;
    var moodDays = 0, energyDays = 0, sleepDays = 0;

    for (final log in logs) {
      final positives = log.symptomIds.where(positiveMoodIds.contains).length;
      final negatives = log.symptomIds.where(negativeMoodIds.contains).length;
      if (positives + negatives > 0) {
        // 50 = balanced, all-positive day = 100, all-negative day = 0.
        moodSum += 50 + 50 * (positives - negatives) / (positives + negatives);
        moodDays++;
      }

      final levels = log.symptomIds
          .where(energyLevelById.containsKey)
          .map((id) => energyLevelById[id]!)
          .toList();
      if (levels.isNotEmpty) {
        energySum += levels.reduce((a, b) => a + b) / levels.length;
        energyDays++;
      }

      final hours = sleepHours(log.sleepTime);
      if (hours != null) {
        sleepSum += sleepScoreForHours(hours);
        sleepDays++;
      }
    }

    return RealWellnessScores(
      mood: moodDays > 0 ? moodSum / moodDays : null,
      energy: energyDays > 0 ? energySum / energyDays : null,
      sleep: sleepDays > 0 ? sleepSum / sleepDays : null,
      moodDays: moodDays,
      energyDays: energyDays,
      sleepDays: sleepDays,
    );
  }

  /// Parses the stored `"H:MTh:m"` bed/wake window into slept hours.
  /// Overnight windows (bed 23:00 → wake 07:00) wrap across midnight.
  /// Returns null for missing/unparseable values or absurd durations.
  static double? sleepHours(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '0' || !trimmed.contains('T')) {
      return null;
    }
    try {
      final parts = trimmed.split('T');
      final bed = _minutesOfDay(parts[0]);
      final wake = _minutesOfDay(parts[1]);
      var minutes = wake - bed;
      if (minutes <= 0) minutes += 24 * 60;
      final hours = minutes / 60.0;
      if (hours < 1 || hours > 18) return null;
      return hours;
    } catch (_) {
      return null;
    }
  }

  static int _minutesOfDay(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0].trim()) * 60 + int.parse(p[1].trim());
  }

  /// 0–100 sleep-quality score from slept hours (7–9h is the sweet spot).
  static double sleepScoreForHours(double hours) {
    if (hours >= 7 && hours <= 9) return 95;
    if (hours >= 6 && hours < 7 || hours > 9 && hours <= 10) return 75;
    if (hours >= 5 && hours < 6 || hours > 10 && hours <= 11) return 55;
    if (hours >= 4 && hours < 5) return 40;
    return 30;
  }
}
