import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_aura/menstrudel/models/watch_sync/shared_context.dart';
import 'package:cycle_aura/menstrudel/models/watch_sync/circle_data.dart';

/// Enhanced sync service that sends cycle data to both Apple Watch and Wear OS.
///
/// Protocol:
/// - Phone -> Watch: CircleData (currentValue, maxValue, phase, daysUntilPeriod)
/// - Watch -> Phone: LogRequest (timestamp) to log a period entry
///
/// Communication methods:
/// - Apple Watch: WatchConnectivity framework (updateApplicationContext)
/// - Wear OS: Data Layer API (PutDataMapRequest via /lune/cycle path)
class WatchSyncService {
  final _watch = WatchConnectivity();
  StreamSubscription? _subscription;
  static const _processedTimestampsKey = 'processed_watch_timestamps';

  void Function()? onPeriodLogRequested;

  /// Current cycle data cached for Wear OS Data Layer sync
  int _lastCircleCurrentValue = 0;
  int _lastCircleMaxValue = 28;
  String _lastPhase = 'Unknown';
  int _lastDaysUntilPeriod = 0;

  Future<void> initialize({required void Function() onPeriodLog}) async {
    onPeriodLogRequested = onPeriodLog;

    if (kDebugMode) debugPrint('[WatchSync] Initializing...');

    try {
      if (!await _watch.isSupported) {
        if (kDebugMode) debugPrint('[WatchSync] Not supported on this platform');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        if (!await _watch.isPaired) {
          if (kDebugMode) debugPrint('[WatchSync] No watch paired (Android)');
          _subscription = _watch.contextStream.listen(_handleContext);
          return;
        }
      }

      // Drain missed contexts
      final missedContexts = await _watch.receivedApplicationContexts;
      for (final context in missedContexts) {
        await _handleContext(context);
      }

      _subscription = _watch.contextStream.listen(_handleContext);

      if (kDebugMode) debugPrint('[WatchSync] Listening on context stream');
    } catch (e) {
      if (kDebugMode) debugPrint('[WatchSync] Init failed: $e');
    }
  }

  Future<void> _handleContext(Map<dynamic, dynamic> contextMap) async {
    final context = SharedContextData.fromJson(contextMap);

    if (context.logRequest == null) return;

    final timestamp = context.logRequest!.timestamp;
    final prefs = await SharedPreferences.getInstance();
    final processedIds = prefs.getStringList(_processedTimestampsKey) ?? [];

    if (processedIds.contains(timestamp.toString())) {
      if (kDebugMode) debugPrint('[WatchSync] Ignoring duplicate log request: $timestamp');
      return;
    }

    if (kDebugMode) debugPrint('[WatchSync] Processing log request: $timestamp');
    onPeriodLogRequested?.call();

    processedIds.add(timestamp.toString());
    // Keep only last 50 entries to avoid unbounded growth
    if (processedIds.length > 50) {
      processedIds.removeRange(0, processedIds.length - 50);
    }
    await prefs.setStringList(_processedTimestampsKey, processedIds);
  }

  /// Send cycle data to the watch.
  /// [phase] should be one of: "Menstruation", "Follicular", "Ovulation", "Luteal"
  /// [daysUntilPeriod] is the number of days until the next period starts.
  Future<void> sendCircleData({
    required int circleMaxValue,
    required int circleCurrentValue,
    String phase = 'Unknown',
    int daysUntilPeriod = 0,
  }) async {
    if (!await _watch.isSupported) {
      if (kDebugMode) debugPrint('[WatchSync] Not supported');
      return;
    }

    if (!await _watch.isPaired) {
      if (kDebugMode) debugPrint('[WatchSync] No watch paired');
      return;
    }

    // Cache for Wear OS Data Layer
    _lastCircleCurrentValue = circleCurrentValue;
    _lastCircleMaxValue = circleMaxValue;
    _lastPhase = phase;
    _lastDaysUntilPeriod = daysUntilPeriod;

    final circleData = CircleData(
      currentValue: circleCurrentValue,
      maxValue: circleMaxValue,
    );

    final context = SharedContextData(circleData: circleData);

    // Also include phase and daysUntilPeriod in the context map
    final contextMap = context.toJson();
    contextMap['circleData'] = {
      ...contextMap['circleData'] as Map<String, dynamic>,
      'phase': phase,
      'daysUntilPeriod': daysUntilPeriod,
    };

    if (kDebugMode) debugPrint('[WatchSync] Sending: day $circleCurrentValue/$circleMaxValue, phase: $phase');

    // Send via WatchConnectivity (works on both iOS and Android)
    _watch.updateApplicationContext(contextMap);

    // Also send via direct Wear OS Data Layer method channel for reliability
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        const channel = MethodChannel('com.lune.app/wear_sync');
        await channel.invokeMethod('sendCycleData', {
          'currentValue': circleCurrentValue,
          'maxValue': circleMaxValue,
          'phase': phase,
          'daysUntilPeriod': daysUntilPeriod,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('[WatchSync] Wear Data Layer channel failed: $e');
      }
    }
  }

  /// Get the last cached cycle data (for UI display or Wear OS Data Layer).
  Map<String, dynamic> getLastCycleData() {
    return {
      'currentValue': _lastCircleCurrentValue,
      'maxValue': _lastCircleMaxValue,
      'phase': _lastPhase,
      'daysUntilPeriod': _lastDaysUntilPeriod,
    };
  }

  void dispose() {
    _subscription?.cancel();
  }
}
