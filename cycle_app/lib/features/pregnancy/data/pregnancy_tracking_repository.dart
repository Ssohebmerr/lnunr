import 'package:cycle_aura/menstrudel/database/app_database.dart';

import 'pregnancy_log_models.dart';

class PregnancyTrackingRepository {
  PregnancyTrackingRepository({AppDatabase? db})
      : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  // --- Weight ---

  Future<int> insertWeight(PregnancyWeightLog log) async {
    final db = await _db.database;
    return db.insert('pregnancy_weight_logs', log.toMap());
  }

  Future<List<PregnancyWeightLog>> recentWeights({int limit = 30}) async {
    final db = await _db.database;
    final rows = await db.query(
      'pregnancy_weight_logs',
      orderBy: 'logged_at DESC',
      limit: limit,
    );
    return rows.map(PregnancyWeightLog.fromMap).toList();
  }

  // --- Kicks ---

  Future<int> insertKickSession(PregnancyKickSession session) async {
    final db = await _db.database;
    return db.insert('pregnancy_kick_sessions', session.toMap());
  }

  Future<int> updateKickSession(PregnancyKickSession session) async {
    final db = await _db.database;
    return db.update(
      'pregnancy_kick_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<PregnancyKickSession?> activeKickSession() async {
    final db = await _db.database;
    final rows = await db.query(
      'pregnancy_kick_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PregnancyKickSession.fromMap(rows.first);
  }

  Future<List<PregnancyKickSession>> kickSessionsSince(DateTime since) async {
    final db = await _db.database;
    final rows = await db.query(
      'pregnancy_kick_sessions',
      where: 'started_at >= ?',
      whereArgs: [since.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return rows.map(PregnancyKickSession.fromMap).toList();
  }

  // --- Contractions ---

  Future<int> insertContraction(PregnancyContraction c) async {
    final db = await _db.database;
    return db.insert('pregnancy_contractions', c.toMap());
  }

  Future<List<PregnancyContraction>> contractionsSince(DateTime since) async {
    final db = await _db.database;
    final rows = await db.query(
      'pregnancy_contractions',
      where: 'started_at >= ?',
      whereArgs: [since.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return rows.map(PregnancyContraction.fromMap).toList();
  }
}
