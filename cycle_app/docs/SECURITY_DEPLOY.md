# Security deploy checklist (staged rollout)

Use this order after merging the server security hardening changes.

> **Status (2026-07-11):** Code hardening complete (sanitization, explicit server-only
> Firestore rules, emulator rule tests, `verify-security.mjs`). Backend deploy + APK +
> Console enforcement remain staged — see tables below.

## Security item status

| Item | Code / rules | Console / ops | Notes |
|------|----------------|---------------|-------|
| Firestore rules | ✅ Hardened | — | No `if true`; server collections explicitly denied |
| Storage rules | ✅ Hardened | — | User-scoped paths only |
| App Check (client) | ✅ Sends token | ⏳ Register apps | Android Play Integrity, iOS App Attest, Web reCAPTCHA Enterprise |
| App Check (enforce) | ⏳ `APP_CHECK_ENFORCE=false` | ⏳ Enforce after APK | Flip env var, then Console Enforce for Firestore/Storage |
| Auth reCAPTCHA | — | ⏳ Enable in Console | Email/password fraud prevention |
| API key restrictions | — | ⏳ GCP Credentials | Android `com.lune.app`, iOS bundle, web referrers |
| IP rate limits | ✅ Active | — | `/chat`, community submit, etc. |
| Community text sanitize | ✅ Client + server | — | HTML strip, length caps |
| `grantTesterPremium` | ✅ Gated | ⏳ `TESTER_PREMIUM_ENABLED=false` | Debug UI only in `kDebugMode` |
| Billing alerts | — | ⏳ Budget $50–100 | Usage and billing → Budgets |
| MFA (owner) | — | ⏳ Google 2FA | Owner Google account |
| Rule tests (emulator) | ✅ `npm run test:rules` | — | Run locally before deploy |

Legend: ✅ done in repo/deploy · ⏳ manual Console step · — not applicable

---

## 1. Firebase Console (before enforcement)

1. **Google Cloud Console → APIs → Credentials**  
   Restrict the Web API key to:
   - Android app: `com.lune.app`
   - iOS bundle: `com.lune.app`
   - HTTP referrers: `https://lune-7d956.web.app/*`, `https://lune-7d956.firebaseapp.com/*`

2. **Firebase Console → App Check**  
   - Register Android (Play Integrity) and iOS (App Attest) if not already done  
   - Register **Web** app with **reCAPTCHA Enterprise**  
   - Copy the site key → set `window.LUNE_RECAPTCHA_SITE_KEY` in admin hosting or inject before deploy

3. **Firebase Console → Authentication → Settings**  
   - Enable **reCAPTCHA Enterprise** fraud prevention for Email/Password (and Anonymous if offered)  
   - Review **Authorized domains** (only your domains)

4. **Cloud Functions environment** (see `firebase/functions/.env.example`)  
   - `TESTER_PREMIUM_ENABLED=false`  
   - `APP_CHECK_ENFORCE=false` (first deploy)

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

---

## 4. Release Flutter app

Ship a build that includes `CloudFunctionsClient` (sends `X-Firebase-AppCheck` on all function calls).

Verify on a test device:
- Chat / analyze work
- Community submit works
- Play purchase verification works

**APK build tip (OneDrive):** copy project to `C:\temp\lune-apk-build` and run:

```bash
flutter build apk --release
```

---

## 5. Deploy admin web with reCAPTCHA

Set the reCAPTCHA Enterprise site key (see step 1) then redeploy hosting:

```bash
firebase deploy --only hosting
```

Test admin login and one `adminApi` action.

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
- Watch logs for `app_check_missing`, `ip_rate_limited`  
- Rotate admin passwords; enable 2FA on owner Google account

---

## Bot / page-refresh note

Marketing pages (`public/*.html`) are static. Automated page refresh only consumes **Hosting bandwidth**, not Firestore or AI. Real abuse targets Cloud Functions directly — mitigated by IP limits, App Check, premium gates, and reCAPTCHA on auth.
