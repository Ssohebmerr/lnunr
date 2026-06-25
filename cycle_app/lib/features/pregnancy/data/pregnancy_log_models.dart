/// A single weight entry during pregnancy (stored in kg).
class PregnancyWeightLog {
  const PregnancyWeightLog({
    this.id,
    required this.loggedAt,
    required this.weightKg,
    this.note,
  });

  final int? id;
  final DateTime loggedAt;
  final double weightKg;
  final String? note;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'logged_at': loggedAt.toIso8601String(),
        'weight_kg': weightKg,
        'note': note,
      };

  factory PregnancyWeightLog.fromMap(Map<String, dynamic> map) {
    return PregnancyWeightLog(
      id: map['id'] as int?,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }
}

/// Kick-counting session (Flo-style: count toward 10 kicks).
class PregnancyKickSession {
  const PregnancyKickSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    required this.kickCount,
    this.goalReached = false,
  });

  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int kickCount;
  final bool goalReached;

  Duration get elapsed =>
      (endedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'kick_count': kickCount,
        'goal_reached': goalReached ? 1 : 0,
      };

  factory PregnancyKickSession.fromMap(Map<String, dynamic> map) {
    return PregnancyKickSession(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      kickCount: map['kick_count'] as int? ?? 0,
      goalReached: (map['goal_reached'] as int? ?? 0) == 1,
    );
  }

  PregnancyKickSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? kickCount,
    bool? goalReached,
  }) {
    return PregnancyKickSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      kickCount: kickCount ?? this.kickCount,
      goalReached: goalReached ?? this.goalReached,
    );
  }
}

/// One recorded contraction with start/end and duration.
class PregnancyContraction {
  const PregnancyContraction({
    this.id,
    required this.startedAt,
    required this.endedAt,
    this.intensity,
  });

  final int? id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? intensity;

  int get durationSeconds => endedAt.difference(startedAt).inSeconds;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'intensity': intensity,
      };

  factory PregnancyContraction.fromMap(Map<String, dynamic> map) {
    return PregnancyContraction(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: DateTime.parse(map['ended_at'] as String),
      intensity: map['intensity'] as int?,
    );
  }
}

/// Summary for AI context and reports.
class PregnancyTrackingSummary {
  const PregnancyTrackingSummary({
    this.latestWeightKg,
    this.weightChangeKg,
    this.weightLogCount = 0,
    this.todayKicks = 0,
    this.lastKickSessionMinutes,
    this.todayContractions = 0,
    this.avgContractionSeconds,
    this.lastContractionIntervalMinutes,
  });

  final double? latestWeightKg;
  final double? weightChangeKg;
  final int weightLogCount;
  final int todayKicks;
  final int? lastKickSessionMinutes;
  final int todayContractions;
  final int? avgContractionSeconds;
  final int? lastContractionIntervalMinutes;

  Map<String, dynamic> toPromptMap() => {
        if (latestWeightKg != null) 'latestWeightKg': latestWeightKg,
        if (weightChangeKg != null) 'weightChangeKg': weightChangeKg,
        'weightLogCount': weightLogCount,
        'todayKicks': todayKicks,
        if (lastKickSessionMinutes != null)
          'lastKickSessionMinutes': lastKickSessionMinutes,
        'todayContractions': todayContractions,
        if (avgContractionSeconds != null)
          'avgContractionSeconds': avgContractionSeconds,
        if (lastContractionIntervalMinutes != null)
          'lastContractionIntervalMinutes': lastContractionIntervalMinutes,
      };
}
