import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/period_logs/log_day.dart';
import 'package:cycle_aura/menstrudel/services/log_service.dart';
import 'package:cycle_aura/menstrudel/services/period_service.dart';
import 'package:cycle_aura/menstrudel/services/widget_controller.dart';

class DataRefreshCoordinator {
  final LogService logService;
  final PeriodService periodService;
  final WidgetController widgetController;

  /// Optional hook invoked after logs change, with the fresh log list.
  /// Used by the app shell to mirror bleeding days into other stores.
  Future<void> Function(List<LogDay> logs)? onLogsSynced;

  AppLocalizations? _l10n;
  bool _hasTriggeredInitialRefresh = false;

  DataRefreshCoordinator({
    required this.logService,
    required this.periodService,
    required this.widgetController,
  }) {
    logService.addListener(_onLogServiceChanged);
  }

  void registerL10n(AppLocalizations l10n) {
    _l10n = l10n;
    _tryInitialRefresh();
  }

  void _onLogServiceChanged() {
    _tryInitialRefresh();
  }

  void _tryInitialRefresh() {
    if (_hasTriggeredInitialRefresh) return;
    if (!logService.hasLoadedOnce) return;
    if (_l10n == null) return;

    _hasTriggeredInitialRefresh = true;

    periodService.refreshData(
      currentLogs: logService.logs,
      l10n: _l10n!,
      widgetController: widgetController,
    );
  }

  Future<void> resetAllData() async {
    _hasTriggeredInitialRefresh = false;
    await logService.loadLogs();
    await periodService.refreshData(
      currentLogs: logService.logs,
      l10n: _l10n!,
      widgetController: widgetController,
    );
  }

  void onLogsChanged([AppLocalizations? l10n]) async {
    _l10n = l10n ?? _l10n;

    final updates = await periodService.recalculatePeriods(
      logService.logs,
    );

    await logService.updateLogPeriodReferences(updates);

    await periodService.refreshData(
      currentLogs: logService.logs,
      l10n: _l10n,
      widgetController: widgetController,
    );

    await onLogsSynced?.call(logService.logs);
  }

  void dispose() {
    logService.removeListener(_onLogServiceChanged);
  }
}
