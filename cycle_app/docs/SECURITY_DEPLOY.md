# Security deploy checklist (staged rollout)

Use this order after merging the server security hardening changes.

> **Status (2026-07-24):** Post-audit hardening in code — story update lockdown,
> AI age/consent via Cloud Functions only, Pub/Sub OIDC on Play webhook, CORS
> closed to allow-list, Storage Premium for community media, Wear `allowBackup=false`,
> release builds fail without keystore. Console steps below remain manual.

## Security item status

| Item | Code / rules | Console / ops | Notes |
|------|----------------|---------------|-------|
| Firestore rules | ✅ Hardened | — | Stories author cannot rewrite moderation/media; AI eligibility fields protected |
| Storage rules | ✅ Premium create | — | Community media upload requires `isPremium` |
| App Check (client) | ✅ Sends token | ⏳ Register apps | Android Play Integrity, iOS App Attest, Web reCAPTCHA Enterprise |
| App Check (enforce) | ⏳ `APP_CHECK_ENFORCE=false` | ⏳ Enforce after APK | Flip env var, then Console Enforce for Firestore/Storage |
| Auth reCAPTCHA | — | ⏳ Enable in Console | Email/password fraud prevention |
| API key restrictions | — | ⏳ GCP Credentials | Android `com.luneapp.cycle`, iOS bundle, web referrers |
| IP rate limits | ✅ Active | — | `/chat`, community submit, etc. |
| Community text sanitize | ✅ Client + server | — | HTML strip, length caps |
| AI age/consent | ✅ Server-only write | — | `/syncAiEligibility`; chat rejects teen birth years |
| Play RTDN webhook | ✅ OIDC required | ⏳ RTDN push auth | Set `PLAY_WEBHOOK_AUDIENCE` to push URL |
| `grantTesterPremium` | ✅ Gated | ⏳ `TESTER_PREMIUM_ENABLED=false` | Debug UI only in `kDebugMode` |
| Release signing | ✅ Fails without keystore | — | No silent debug signing for release |
| Historical Gemini keys | — | ⏳ **Rotate** | Old `AQ.Ab8…` values may still exist in git history |
| Billing alerts | — | ⏳ Budget $50–100 | Usage and billing → Budgets |
| MFA (owner) | — | ⏳ Google 2FA | Owner Google account |
| Rule tests (emulator) | ✅ `npm run test:rules` | — | Run locally before deploy |

Legend: ✅ done in repo/deploy · ⏳ manual Console step · — not applicable

---

## 1. Firebase Console (before enforcement)

1. **Google Cloud Console → APIs → Credentials**  
   Restrict the Web API key to:
   - Android app: `com.luneapp.cycle` (+ SHA-1 of upload keystore)
   - iOS bundle: `com.lune.app`
   - HTTP referrers: `https://lune-7d956.web.app/*`, `https://lune-7d956.firebaseapp.com/*`

2. **Rotate compromised Gemini / AI Studio keys**  
   Keys of the form `AQ.Ab8…` were previously committed in `app_secrets.dart` and
   remain recoverable from git history. In Google AI Studio / Cloud Console:
   - Delete or rotate every old key
   - Keep only Secret Manager secrets used by Cloud Functions (`GEMINI_API_KEY`, `DEEPSEEK_API_KEY`)

3. **Firebase Console → App Check**  
   - Register Android (Play Integrity) and iOS (App Attest) if not already done  
   - Register **Web** app with **reCAPTCHA Enterprise**  
   - Copy the site key → set `window.LUNE_RECAPTCHA_SITE_KEY` in admin hosting or inject before deploy

4. **Firebase Console → Authentication → Settings**  
   - Enable **reCAPTCHA Enterprise** fraud prevention for Email/Password (and Anonymous if offered)  
   - Review **Authorized domains** (only your domains)

5. **Cloud Functions environment** (see `firebase/functions/.env.example`)  
   - `TESTER_PREMIUM_ENABLED=false`  
   - `APP_CHECK_ENFORCE=false` (first deploy after this hardening; flip later)  
   - `PLAY_WEBHOOK_AUDIENCE=https://us-central1-lune-7d956.cloudfunctions.net/googlePlayWebhook`

6. **Play Console → RTDN Pub/Sub push**  
   Enable authentication on the push subscription that targets `googlePlayWebhook`.
   Unauthenticated POSTs now return **401**.

---

## 2. Local verification (before deploy)

```bash
cd cycle_app/firebase/functions
npm install
npm run test:unit
npm run test:rules

cd ../..
flutter test
node scripts/verify-security.mjs
```

`verify-security.mjs` checks `/chat` without auth (expects 401). App Check behavior depends on
`APP_CHECK_ENFORCE` on the deployed functions.

---

## 3. Deploy backend (monitoring mode)

```bash
cd cycle_app
firebase deploy --only functions,firestore:rules,storage
```

At this stage:
- IP rate limits are **active**
- App Check is **logged but not enforced** (`APP_CHECK_ENFORCE=false`)
- Story / AI eligibility / webhook OIDC hardenings are live after deploy

---

## 4. Release Flutter app

Ship a build that includes `CloudFunctionsClient` (sends `X-Firebase-AppCheck` on all function calls)
and calls `/syncAiEligibility` for consent/age (no direct Firestore writes to those fields).

Verify on a test device:
- Age gate → AI consent → Chat / analyze work
- Community submit works
- Play purchase verification works

**APK / AAB:** `android/key.properties` + `upload-keystore.jks` required for release
(debug signing fallback removed).

```bash
flutter build appbundle --release
```

---

## 5. Deploy admin web with reCAPTCHA

Set the reCAPTCHA Enterprise site key (see step 1) then redeploy hosting:

```bash
firebase deploy --only hosting
```

Test admin login and one `adminApi` action (admin endpoints now require App Check when enforcement is on).

---

## 6. Enforce App Check on Functions

Set in `firebase/functions/.env`:

```
APP_CHECK_ENFORCE=true
```

Redeploy functions:

```bash
firebase deploy --only functions
```

Manual checks:

```bash
node scripts/verify-security.mjs
```

- App call to `/chat` **with** App Check → 200 (premium user)
- Script call **without** `X-Firebase-AppCheck` → 401 `app_check_required`
- Optional: `LUNE_IP_FLOOD=1 node scripts/verify-security.mjs` → 429 `ip_rate_limited`

---

## 7. Enforce App Check on Firestore & Storage

Only after steps 4–6 succeed:

Firebase Console → App Check → **Enforce** for:
- Cloud Firestore
- Cloud Storage
- Cloud Functions (if not already enforced)

App Check for Firestore & Storage is enforced **from the Console toggle only** (staged
+ instantly reversible), **not** hardcoded in `firestore.rules`. The hardcoded
`request.app != null` gate was removed on 2026-07-11: a failed attestation (sideloaded
build, web without reCAPTCHA, or an App Check outage) would silently break core
`users`/`backups` writes with no way to soften it — the Console monitoring→enforce path
is the safe equivalent. `anonymousQuestions` create requires `request.auth != null`
(the app always holds at least an anonymous session), which blocks unauthenticated
spam without depending on App Check.

---

## 8. Ongoing monitoring

- Firebase Console → **Usage and billing** → budget alerts for Functions + AI  
- Watch logs for `app_check_missing`, `ip_rate_limited`, `pubsub_oidc_invalid`  
- Rotate admin passwords; enable 2FA on owner Google account  
- Keep `TESTER_PREMIUM_ENABLED=false` in production forever after QA

---

## Bot / page-refresh note

Marketing pages (`public/*.html`) are static. Automated page refresh only consumes **Hosting bandwidth**, not Firestore or AI. Real abuse targets Cloud Functions directly — mitigated by IP limits, App Check, premium gates, and reCAPTCHA on auth.

`/admin/` is crawl-disallowed in `robots.txt` but still publicly reachable — security depends on Firebase Auth + admin claims (+ App Check when enforced).
