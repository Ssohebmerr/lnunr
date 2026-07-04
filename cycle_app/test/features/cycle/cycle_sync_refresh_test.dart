import 'package:cycle_aura/core/app_home_refresh.dart';
import 'package:cycle_aura/features/cycle/data/cycle_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the daily-log "won't save" fix: a self-save must sync data WITHOUT
/// firing the global home refresh (which recreates the log form mid-edit).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onCycleDataChanged(notifyHomeRefresh: false) does NOT fire refresh',
      () async {
    final before = HomeRefreshScope.notifier.value;
    await CycleSyncService().onCycleDataChanged(notifyHomeRefresh: false);
    expect(
      HomeRefreshScope.notifier.value,
      before,
      reason: 'a self-save must not recreate the live log form',
    );
  });

  test('onCycleDataChanged() fires the home refresh by default', () async {
    final before = HomeRefreshScope.notifier.value;
    await CycleSyncService().onCycleDataChanged();
    expect(HomeRefreshScope.notifier.value, greaterThan(before));
  });
}
