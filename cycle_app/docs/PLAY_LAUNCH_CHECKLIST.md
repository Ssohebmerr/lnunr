# Lune — Launch Checklist

Step-by-step guide to publish **Lune** (`com.lune.app`, currently `1.0.22+23`) on Google Play and prepare App Store.

> ⚠️ **New personal developer accounts** (created after Nov 2023) must run a
> **closed test with 12 testers for 14 days** before production access is granted.
> Plan for this before announcing a launch date.

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
| `ADMIN_BOOTSTRAP_KEY` | Firebase Functions secrets | One-time admin bootstrap only — **rotate** if ever committed or exposed; never use defaults in scripts |

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

### Syncfusion (cycle charts — Community License)

Charts in `menstrual_cycle_widget` use **Syncfusion v32**. Google Play does **not** require a license key in the APK.

- [ ] Claim free **Community License**: [syncfusion.com/products/communitylicense](https://www.syncfusion.com/products/communitylicense)
- Eligibility: annual revenue &lt; $1M, ≤5 developers, ≤10 employees
- Flutter v32+: **no license key required in app code** ([Syncfusion docs](https://help.syncfusion.com/flutter/licensing/overview))
- [ ] Keep Syncfusion approval email for your records (not uploaded to Play Console)
- Details: **`docs/SYNCFUSION_COMMUNITY_LICENSE.md`**

---

## 2. Google Play Console

### App signing & build

```bash
cd cycle_app
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** first.

### Subscription products & Real-Time Developer Notifications (RTDN)

1. **Monetize → Products → Subscriptions**
2. Create BOTH subscription IDs (must match `play_billing_service.dart` exactly):
   - `premium_monthly` (monthly base plan)
   - `premium_yearly` (yearly base plan — app shows a savings badge for it)
3. Set price per plan, free trial if desired
4. Activate after app is in a test track
5. Add your Gmail under **Settings → License testing** to test purchases without real charges

#### RTDN (renewals, cancellations, refunds)

Google Play must notify your backend when subscriptions change:

1. Google Cloud Console → **Pub/Sub** → create topic e.g. `play-rtdn`
2. Play Console → **Monetize setup** → Real-time developer notifications → topic `projects/YOUR_PROJECT/topics/play-rtdn`
3. Pub/Sub → **Create subscription** → type **Push** → endpoint:
   `https://REGION-PROJECT.cloudfunctions.net/googlePlayWebhook`
4. Deploy functions (includes `googlePlayWebhook` + nightly `syncExpiredPlayPremium`)
5. Send **Test notification** from Play Console and confirm Cloud Functions logs show `Play RTDN test notification received`

Service account JSON (`GOOGLE_PLAY_SERVICE_ACCOUNT` secret) must have **View financial data** in Play Console → Users and permissions.

### Store listing

- [ ] App name: **Lune**
- [ ] Short + full description (AR + EN — add a Store listing per language).
      No diagnostic/treatment claims ("diagnoses", "treats") — use "tracks",
      "predicts", "wellness companion"
- [ ] Screenshots (phone 6.7", 6.1", tablet if applicable)
- [ ] **Wear OS screenshots** — the embedded watch app won't surface on watch
      Play without them
- [ ] Feature graphic 1024×500
- [ ] App icon 512×512
- [ ] Category: Health & Fitness
- [ ] Contact email: `merrsoheb@gmail.com`
- [ ] Privacy policy URL (see above)

### App content

- [ ] **Privacy policy** URL linked
- [ ] **App access** — app requires sign-in → choose "All or some functionality
      is restricted" and provide a **test account with `isPremium: true`**
      (grant via admin panel) + reviewer notes in English (how to log in,
      AI features need premium)
- [ ] **Data safety** — use `docs/GOOGLE_PLAY_DATA_SAFETY.md`; includes the
      **account deletion URL**: `https://lune-7d956.web.app/your-data-ends.html`
- [ ] **Health apps declaration** (mandatory for cycle trackers) — declare
      Health & wellness → cycle/period tracking; NOT a medical device
- [ ] **Content rating** (IARC) — answers in same doc
- [ ] **Target audience** — match the actual app behavior: core tracking is
      13+, while Lune AI and communities are 18+ only. Never select an
      under-13 age band. Keep the store listing and reviewer notes explicit
      about the restricted features.
- [ ] **News app / COVID / Financial / Government** — all No
- [ ] **Ads** — No ads
- [ ] **UGC** — Yes; describe moderation (AI + report/block)
- [ ] **AI-generated content** — if asked: users can flag any AI chat reply
      (flag icon under each response → `aiReports` collection → admin review)
- [ ] **Third-party AI data use** — disclose submitted AI content plus relevant
      cycle/health context; verify Gemini/DeepSeek production terms, retention,
      no-sale/no-ads/no-training controls, and keep evidence/DPA on file
- [ ] **Android developer verification** — open the verification page in Play
      Console and confirm `com.lune.app` is registered (manually register it if
      it was not auto-registered)

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

- [ ] Fresh install → age gate → onboarding → privacy consent (AI **not** auto-enabled)
- [ ] Guest mode works without account
- [ ] Email sign-up / sign-in
- [ ] Google sign-in (Android)
- [ ] Apple sign-in (iOS)
- [ ] Premium purchase in **license test** account (Play) + RTDN webhook log
- [ ] Cloud sync blocked without Premium + explicit consent
- [ ] AI chat and every generated AI card require 18+, Premium, and the
      prominent AI consent disclosure; revoking consent blocks new requests
- [ ] Community: under-13 blocked at onboarding; teen blocked from UGC; adult must enter birth year in setup sheet (no auto-fill)
- [ ] Report + block user flow
- [ ] Delete account removes data (check Firestore + Storage)
- [ ] Support email opens from Account tab (`merrsoheb@gmail.com`)
- [ ] Privacy policy + Terms links on subscription screen

---

## 5. Code compliance (release build)

- [ ] `flutter analyze` clean
- [ ] `flutter test` passes
- [ ] `flutter build appbundle --release` with upload keystore (`android/key.properties`)
- [ ] AI Diagnostic menu hidden in release (debug only)
- [ ] Firebase deploy: rules, functions, hosting

---

## 6. CI

GitHub Actions workflow: `.github/workflows/flutter_ci.yml`

Runs `flutter analyze` + `flutter test` on push/PR to `main`/`master`.

---

## 7. After launch

- [ ] Monitor Crashlytics for release crashes
- [ ] Monitor `communityReports` in admin dashboard
- [ ] Respond to Play Console policy emails within 7 days
- [ ] Update landing page Play Store link when live

---

## 8. Store listing assets

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
| Premium SKUs | `premium_monthly`, `premium_yearly` |
| Firebase project | `lune-7d956` |
| Support | `merrsoheb@gmail.com` |
| Account deletion URL | `https://lune-7d956.web.app/your-data-ends.html` |
