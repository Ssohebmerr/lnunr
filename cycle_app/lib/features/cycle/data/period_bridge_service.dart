import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../menstrudel/database/repositories/logs_repository.dart';
import '../../../menstrudel/models/flows/flow_enum.dart';
import '../../../menstrudel/models/period_logs/log_day.dart';

/// Keeps period (bleeding) days consistent between the two local stores:
///
/// 1. The `menstrual_cycle_widget` encrypted DB (`tblUserPeriodsLogs`) —
///    edited from the Home tab calendars, onboarding, and settings.
/// 2. The Menstrudel DB (`period_logs.flow`) — edited from the Wellness Hub
///    daily logs and the smartwatch.
///
/// Only bleeding days are mirrored; symptoms, pain levels, vitals, pills,
/// sanitary, sex, and LARC data stay in their own store.
class PeriodBridgeService {
  PeriodBridgeService._();

  static final PeriodBridgeService instance = PeriodBridgeService._();

  bool _syncing = false;

  /// Set by [MenstrudelProviders] once the Menstrudel service tree exists.
  /// Called after a widget→Menstrudel sync changed Menstrudel data, so the
  /// in-memory services (LogService/PeriodService) can reload.
  Future<void> Function()? onMenstrudelDataChanged;

  /// Menstrudel → widget: mirror Menstrudel bleeding days into the widget DB.
  ///
  /// Returns true when the widget DB was changed.
  Future<bool> syncMenstrudelToWidget(List<LogDay> logs) async {
    if (_syncing) return false;
    final api = MenstrualCycleWidget.instance;
    if (api == null) return false;

    _syncing = true;
    try {
      final target = logs
          .where((l) => l.flow != FlowRate.none)
          .map((l) => DateUtils.dateOnly(l.date))
          .toSet();

      final db = MenstrualCycleDbHelper.instance;
      final current = await _widgetPeriodDays(db);
      if (setEquals(current, target)) return false;

      await db.clearPeriodLog(api.getCustomerId());
      if (target.isNotEmpty) {
        await db.insertPeriodLog(target.toList()..sort());
      }
      await api.calculateLastPeriodDate();
      return true;
    } catch (e) {
      debugPrint('PeriodBridge: Menstrudel→widget sync failed: $e');
      return false;
    } finally {
      _syncing = false;
    }
  }

  /// Widget → Menstrudel: mirror widget period days into Menstrudel logs.
  ///
  /// - Widget days missing in Menstrudel become medium-flow logs.
  /// - Menstrudel bleeding logs for days no longer marked in the widget are
  ///   deleted when empty, or downgraded to no-flow when they carry symptoms.
  ///
  /// Returns true when Menstrudel data was changed.
  Future<bool> syncWidgetToMenstrudel() async {
    if (_syncing) return false;
    final api = MenstrualCycleWidget.instance;
    if (api == null) return false;

    _syncing = true;
    var changed = false;
    try {
      final widgetDays = await _widgetPeriodDays(MenstrualCycleDbHelper.instance);

      final repo = LogsRepository();
      final logs = await repo.readAllLogs();
      final logByDay = {
        for (final log in logs) DateUtils.dateOnly(log.date): log,
      };

      for (final day in widgetDays) {
        final existing = logByDay[day];
        if (existing == null) {
          await repo.upsertLog(LogDay(date: day, flow: FlowRate.medium));
          changed = true;
        } else if (existing.flow == FlowRate.none) {
          await repo.upsertLog(existing.copyWith(flow: FlowRate.medium));
          changed = true;
        }
      }

      for (final log in logs) {
        if (log.flow == FlowRate.none) continue;
        if (widgetDays.contains(DateUtils.dateOnly(log.date))) continue;

        final hasOtherData = log.symptoms.isNotEmpty || log.painLevel != null;
        if (hasOtherData) {
          await repo.upsertLog(log.copyWith(flow: FlowRate.none));
        } else if (log.id != null) {
          await repo.deleteLog(log.id!);
        }
        changed = true;
      }
      return changed;
    } catch (e) {
      debugPrint('PeriodBridge: widget→Menstrudel sync failed: $e');
      return false;
    } finally {
      _syncing = false;
    }
  }

  Future<Set<DateTime>> _widgetPeriodDays(MenstrualCycleDbHelper db) async {
    final raw = await db.getPastPeriodDates();
    return raw
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(DateUtils.dateOnly)
        .toSet();
  }
}
