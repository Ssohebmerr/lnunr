# Cycle Aura — Launch Checklist (Phase 4)

Step-by-step guide to publish **Cycle Aura** on Google Play and prepare App Store.

## 1. Firebase deploy (required)

From `cycle_app/`:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting
```

Verify:

- [ ] Privacy policy loads: `https://lune-7d956.web.app/privacy-policy.html`
- [ ] Terms load: `https://lune-7d956.web.app/terms-of-service.html`
- [ ] Landing page loads: `https://lune-7d956.web.app/`

### Secrets & keys

| Secret | Where | Purpose |
|--------|-------|---------|
| `GEMINI_API_KEY` | Firebase Functions secrets | AI moderation (fail-closed) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Firebase Functions secrets | Verify Play Billing purchases |

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT
# Paste JSON from Google Cloud service account with Play Developer API access
```

### Firebase App Check (Console)

1. Firebase Console → **App Check** → register Android app (`com.lune.app`)
2. Enable **Play Integrity** for production
3. Add debug token for local testing (debug builds log token in Logcat)
4. For iOS: enable **App Attest** + add debug token

### Crashlytics

1. Firebase Console → enable **Crashlytics** for project `lune-7d956`
2. Build a release APK/AAB once — first crash report initializes the dashboard

---

## 2. Google Play Console

### App signing & build

```bash
cd cycle_app
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** first.

### Subscription product

1. **Monetize → Products → Subscriptions**
2. Create subscription ID: `premium_monthly` (must match `play_billing_service.dart`)
3. Set price, billing period (monthly), free trial if desired
4. Activate after app is in a test track

### Store listing

- [ ] App name: **Cycle Aura**
- [ ] Short + full description (AR + EN if targeting both)
- [ ] Screenshots (phone 6.7", 6.1", tablet if applicable)
- [ ] Feature graphic 1024×500
- [ ] App icon 512×512
- [ ] Category: Health & Fitness
- [ ] Contact email: `support@cycleaura.app`
- [ ] Privacy policy URL (see above)

### App content

- [ ] **Privacy policy** URL linked
- [ ] **Data safety** — use `docs/GOOGLE_PLAY_DATA_SAFETY.md`
- [ ] **Content rating** (IARC) — answers in same doc
- [ ] **Target audience** — not primarily children; communities 18+
- [ ] **News app / COVID / Financial** — all No
- [ ] **Ads** — No ads
- [ ] **UGC** — Yes; describe moderation (AI + report/block)

### Permissions justification

| Permission | Why |
|------------|-----|
| `BILLING` | Premium subscription |
| `INTERNET` | Firebase, AI, communities |
| `POST_NOTIFICATIONS` | Optional cycle reminders (user enables in settings) |
| `USE_BIOMETRIC` | Optional app lock |
| `CAMERA` / photos | Optional profile avatar only |

---

## 3. iOS / App Store (optional)

### Firebase & Apple

```bash
cd cycle_app
flutterfire configure
```

- [ ] Add `GoogleService-Info.plist` to `ios/Runner/`
- [ ] Apple Developer → enable **Sign in with Apple** for bundle `com.cycleaura.cycleAura`
- [ ] Xcode → Runner target → Signing & Capabilities → Sign in with Apple (entitlements file included)

### App Store Connect

- [ ] Privacy nutrition labels (mirror Data Safety doc)
- [ ] Sign in with Apple required when Google Sign-In is offered ✓
- [ ] Export compliance / encryption (standard HTTPS exemption)

---

## 4. Pre-submission smoke test

- [ ] Fresh install → onboarding → privacy consent
- [ ] Guest mode works without account
- [ ] Email sign-up / sign-in
- [ ] Google sign-in (Android)
- [ ] Apple sign-in (iOS)
- [ ] Premium purchase in **license test** account (Play)
- [ ] Cloud sync blocked without Premium
- [ ] AI chat: 5 free messages/day, then paywall
- [ ] Community: minor sees adults-only gate; adult joins after guidelines checkbox
- [ ] Report + block user flow
- [ ] Delete account removes data (check Firestore + Storage)
- [ ] Support email opens from Account tab

---

## 5. CI

GitHub Actions workflow: `.github/workflows/flutter_ci.yml`

Runs `flutter analyze` + `flutter test` on push/PR to `main`/`master`.

---

## 6. After launch

- [ ] Monitor Crashlytics for release crashes
- [ ] Monitor `communityReports` in admin dashboard
- [ ] Respond to Play Console policy emails within 7 days
- [ ] Update landing page Play Store link when live

## 7. Store listing assets

See **`docs/STORE_LISTING.md`** for screenshot ideas, descriptions, and asset sizes.

Build release AAB:

```powershell
cd cycle_app
.\scripts\build_release.ps1
```

Signing: copy `android/key.properties.example` → `android/key.properties` and add your upload keystore.

---

## Quick reference

| Item | Value |
|------|-------|
| Package (Android) | `com.lune.app` |
| Bundle (iOS) | `com.cycleaura.cycleAura` |
| Premium SKU | `premium_monthly` |
| Firebase project | `lune-7d956` |
| Support | `support@cycleaura.app` |
