# Watch / Wear OS Audit (Phase 6)

Audit date: 2026-06-27. Read-only review of phone-to-watch sync.

## What exists

| Component | Path | Status |
|-----------|------|--------|
| Phone sync service | `lib/menstrudel/services/wear_sync_service.dart` | Implemented |
| Wear OS app module | `android/wear/` | Implemented (Compose UI, cycle ring, log period) |
| Apple Watch app | `ios/WatchApp/` | Implemented (WCSession, cycle ring, complications) |
| Android MethodChannel | `android/app/.../MainActivity.kt` | `com.lune.app/wear_sync` |
| Data models | `lib/menstrudel/models/watch_sync/` | CircleData, SharedContextData |

## What works (by design)

- Phone sends cycle day, max days, phase, days-until-period to watch.
- Watch can send log-period request back to phone (deduplicated via SharedPreferences).
- Dual path on Android: WatchConnectivity + Wear Data Layer channel.
- Wear UI supports AR/EN strings and phase colors.

## Gaps / needs device testing

1. **Pairing gate on Android**: `WatchSyncService.initialize()` returns early when `!isPaired` on Android but still listens to context — verify on real Wear OS paired device.
2. **iOS Watch target**: Xcode project must include WatchApp target and capabilities; not verifiable in CI without macOS + watch simulator.
3. **Log period from watch**: Watch sends timestamp only; phone must wire `onPeriodLogRequested` to actual Menstrudel log flow — confirm end-to-end on device.
4. **Offline watch**: Watch shows last synced data; no standalone cycle calculation on watch without phone sync.
5. **No automated tests** for watch sync (platform channels + native code).

## Recommended next steps (separate PR)

1. Manual QA checklist: pair watch, open phone app, confirm ring updates within 30s.
2. Tap "Log Period" on watch, confirm entry appears in phone logs.
3. Add integration test mock for `MethodChannel('com.lune.app/wear_sync')` on Android.
4. Document Xcode steps to embed WatchApp in Runner scheme.

## CI note

GitHub Actions cannot build Wear OS or Apple Watch without additional runners and signing. Keep watch builds as manual release checklist items.
