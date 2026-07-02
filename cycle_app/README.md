# Lune

تطبيق خاص لتتبع الدورة الشهرية مع مساعد ذكاء اصطناعي — مبني على حزمة `menstrual_cycle_widget`.

A private menstrual cycle tracker with an AI assistant — built on top of the `menstrual_cycle_widget` package.

## Features

- **Cycle tracking** — dashboard, phase view, calendars, insights graphs, and reports (powered by `menstrual_cycle_widget`, data encrypted locally)
- **Wellness Hub** (embedded Menstrudel module) — daily logs, contraceptive pills, sanitary products, sex activity, and LARC tracking
- **AI chat** — Gemini-powered assistant with cycle context injected (via Firebase Cloud Functions, or a local API key fallback)
- **Community** — anonymous communities, posts, comments, and likes on Firestore with AI moderation
- **Self-care** — phase-based tips, breathing exercises, affirmations, and a journal
- **Cloud sync** — encrypted, consent-gated backups to Firestore + local export/import
- **Premium** — Google Play Billing subscription (`premium_monthly`) verified server-side
- **Privacy first** — consent manager, privacy center, full data deletion; works fully offline without an account
- **Home screen widget** and **smartwatch connectivity**
- **Bilingual UI** — Arabic (default) and English; the cycle widget itself supports 19 languages

## Project layout

```
menstrual_cycle_widget-master/   # workspace root
├── cycle_app/                   # the app (this folder)
│   ├── lib/
│   │   ├── main.dart            # entry: Firebase, timezone, notifications, routing
│   │   ├── core/                # theme, locale, notifications, security, privacy, storage
│   │   ├── features/            # home shell, onboarding, auth, cycle, chat, community,
│   │   │                        # self-care, sync, privacy, premium
│   │   ├── menstrudel/          # vendored Menstrudel module (own SQLite DB)
│   │   ├── menstrudel_integration/  # glue layer (init, providers, wellness hub)
│   │   └── l10n/                # app ARB files (en, ar)
│   ├── firebase/functions/      # Cloud Functions: AI, Play Billing verify + RTDN
│   ├── firestore.rules
│   └── docs/                    # Google Play data-safety notes
└── menstrual_cycle_widget-master/   # local package dependency (cycle UI + encrypted DB)
```

## Architecture notes

- **State management:** `flutter_bloc` for app features, `provider` for Menstrudel services.
- **Routing:** `go_router` (`/` → `/onboarding` → `/home`, plus auth routes).
- **Two data stores:**
  1. `menstrual_cycle_widget` encrypted SQLite — primary cycle data (period dates, daily symptom logs). Accessed through `features/cycle/cycle_bridge_service.dart`.
  2. Menstrudel SQLite (`lib/menstrudel/database/`) — extended wellness data (pills, sanitary, sex, LARC, detailed logs).
- **Orchestration:** `features/cycle/cycle_sync_service.dart` keeps cycle config, profile, notifications, and the home widget in sync.
- **Localization:** app strings in `lib/l10n` (en/ar, generated via `flutter gen-l10n` from `l10n.yaml`); Menstrudel strings in `lib/menstrudel/l10n` (checked-in generated files).

## Getting started

Prerequisites: Flutter SDK ≥ 3.11, an Android/iOS toolchain, and the Firebase CLI (optional, for backend features).

```bash
cd cycle_app
flutter pub get
flutter run
```

The app works offline out of the box. Cloud features need:

1. A Firebase project (config lives in `lib/core/firebase/firebase_options.dart`, generated with `flutterfire configure`).
2. Deployed Cloud Functions with secrets:

```bash
cd firebase/functions
npm install
firebase deploy --only functions
# secrets: GEMINI_API_KEY, PAYPAL_CLIENT_ID, PAYPAL_SECRET
```

3. Firestore rules: `firebase deploy --only firestore:rules`

## Admin dashboard

A lightweight web dashboard lives in `public/admin/` (reports review, user management, stats). Deploy it with Firebase Hosting:

```bash
firebase deploy --only hosting
# opens at https://<project-id>.web.app/admin/
```

To grant admin access, create an empty document at `admins/{uid}` in Firestore (from the Firebase console) for each admin account. The dashboard shows the UID of any signed-in non-admin to make this easy.

Hosting also serves legal pages and a public landing page. Premium is purchased in-app via Google Play only.

## Release builds

Release signing is configured via `android/key.properties` + `android/upload-keystore.jks` (both git-ignored — **back them up somewhere safe**; losing them means losing the ability to update the app on Google Play).

```bash
flutter build apk --release --split-per-abi   # small per-device APKs
flutter build appbundle --release             # .aab for Google Play
```

R8 minification + resource shrinking are enabled (`android/app/proguard-rules.pro`). Outputs land in `build/app/outputs/`.

### Deploying the Firebase backend

```bash
npx firebase-tools login                      # one-time, opens browser
npx firebase-tools deploy --only firestore:rules,hosting
cd firebase/functions && npm install && cd ../..
npx firebase-tools deploy --only functions
# set secrets once:
npx firebase-tools functions:secrets:set GEMINI_API_KEY
npx firebase-tools functions:secrets:set PAYPAL_CLIENT_ID
npx firebase-tools functions:secrets:set PAYPAL_CLIENT_SECRET
```

## Development

```bash
flutter analyze          # keep it at "No issues found!"
flutter test
flutter gen-l10n         # regenerate app localizations after editing lib/l10n/*.arb
```
