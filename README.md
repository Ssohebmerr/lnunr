# Lune

Private menstrual cycle tracker with AI assistant, optional cloud sync, and moderated communities.

## Repository layout

| Path | Description |
|------|-------------|
| `cycle_app/` | Main Flutter app (Google Play / App Store) |
| `menstrual_cycle_widget-master/` | Shared cycle tracking widget package |
| `menstrudel/` | Legacy Menstrudel app (linked privacy docs) |

## Getting started

```bash
cd cycle_app
flutter pub get
flutter run
```

Firebase is pre-configured for project `lune-7d956`. For a new machine:

```bash
flutterfire configure
```

## Publishing

See **[cycle_app/docs/PLAY_LAUNCH_CHECKLIST.md](cycle_app/docs/PLAY_LAUNCH_CHECKLIST.md)** for Firebase deploy, Play Console, App Check, Crashlytics, and pre-launch testing.

Policy reference: **[cycle_app/docs/GOOGLE_PLAY_DATA_SAFETY.md](cycle_app/docs/GOOGLE_PLAY_DATA_SAFETY.md)**

## Deploy hosting + backend

```bash
cd cycle_app
firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting
```

## CI

`.github/workflows/flutter_ci.yml` runs analyze + tests on push/PR.

## Support

- Email: support@cycleaura.app
- Privacy: https://lune-7d956.web.app/privacy-policy.html
- Terms: https://lune-7d956.web.app/terms-of-service.html
