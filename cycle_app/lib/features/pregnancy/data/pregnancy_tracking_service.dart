import 'pregnancy_log_models.dart';
import 'pregnancy_tracking_repository.dart';

/// Flo-style pregnancy trackers: weight, kicks, contractions.
class PregnancyTrackingService {
  PregnancyTrackingService({PregnancyTrackingRepository? repository})
      : _repo = repository ?? PregnancyTrackingRepository();

  final PregnancyTrackingRepository _repo;

  static const kickGoal = 10;

  Future<void> logWeight(double weightKg, {String? note}) async {
    await _repo.insertWeight(
      PregnancyWeightLog(loggedAt: DateTime.now(), weightKg: weightKg, note: note),
    );
  }

  Future<List<PregnancyWeightLog>> recentWeights({int limit = 30}) =>
      _repo.recentWeights(limit: limit);

  Future<PregnancyKickSession?> activeKickSession() =>
      _repo.activeKickSession();

  Future<PregnancyKickSession> startKickSession() async {
    final existing = await _repo.activeKickSession();
    if (existing != null) return existing;

    final session = PregnancyKickSession(startedAt: DateTime.now(), kickCount: 0);
    final id = await _repo.insertKickSession(session);
    return session.copyWith(id: id);
  }

  Future<PregnancyKickSession> registerKick(PregnancyKickSession session) async {
    final count = session.kickCount + 1;
    final reached = count >= kickGoal;
    final updated = PregnancyKickSession(
      id: session.id,
      startedAt: session.startedAt,
      kickCount: count,
      endedAt: reached ? DateTime.now() : null,
      goalReached: reached,
    );
    await _repo.updateKickSession(updated);
    return updated;
  }

  Future<void> endKickSession(PregnancyKickSession session) async {
    await _repo.updateKickSession(
      session.copyWith(endedAt: DateTime.now()),
    );
  }

  Future<PregnancyContraction> recordContraction({
    required DateTime startedAt,
    required DateTime endedAt,
    int? intensity,
  }) async {
    final c = PregnancyContraction(
      startedAt: startedAt,
      endedAt: endedAt,
      intensity: intensity,
    );
    await _repo.insertContraction(c);
    return c;
  }

  Future<List<PregnancyContraction>> todayContractions() {
    final start = DateTime.now();
    final since = DateTime(start.year, start.month, start.day);
    return _repo.contractionsSince(since);
  }

  Future<List<PregnancyKickSession>> todayKickSessions() {
    final start = DateTime.now();
    final since = DateTime(start.year, start.month, start.day);
    return _repo.kickSessionsSince(since);
  }

  Future<PregnancyTrackingSummary> buildSummary() async {
    final weights = await _repo.recentWeights(limit: 30);
    final todayKicks = await todayKickSessions();
    final todayCs = await todayContractions();

    double? latest;
    double? change;
    if (weights.isNotEmpty) {
      latest = weights.first.weightKg;
      if (weights.length >= 2) {
        change = double.parse(
          (latest - weights.last.weightKg).toStringAsFixed(1),
        );
      }
    }

    final kickTotal = todayKicks.fold<int>(0, (s, e) => s + e.kickCount);
    int? lastKickMins;
    if (todayKicks.isNotEmpty && todayKicks.first.endedAt != null) {
      lastKickMins = DateTime.now()
          .difference(todayKicks.first.endedAt!)
          .inMinutes
          .clamp(0, 9999);
    }

    int? avgSecs;
    if (todayCs.isNotEmpty) {
      final total = todayCs.fold<int>(0, (s, c) => s + c.durationSeconds);
      avgSecs = (total / todayCs.length).round();
    }

    int? intervalMins;
    if (todayCs.length >= 2) {
      final a = todayCs[0].startedAt;
      final b = todayCs[1].startedAt;
      intervalMins = a.difference(b).inMinutes.abs();
    }

    return PregnancyTrackingSummary(
      latestWeightKg: latest,
      weightChangeKg: change,
      weightLogCount: weights.length,
      todayKicks: kickTotal,
      lastKickSessionMinutes: lastKickMins,
      todayContractions: todayCs.length,
      avgContractionSeconds: avgSecs,
      lastContractionIntervalMinutes: intervalMins,
    );
  }
}
