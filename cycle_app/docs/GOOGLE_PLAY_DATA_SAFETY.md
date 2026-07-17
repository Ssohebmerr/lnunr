# Google Play — Data Safety & Policy Checklist (Lune)

Use this when filling **Play Console → App content → Data safety** and before publishing.

## App identity

| Field | Value |
|-------|-------|
| Package | `com.luneapp.cycle` |
| Privacy policy URL | `https://lune-7d956.web.app/privacy-policy.html` |
| Terms of Service URL | `https://lune-7d956.web.app/terms-of-service.html` |
| Support email | `merrsoheb@gmail.com` |
| Account deletion (in-app) | **Account → Privacy Center → Delete account** (server-side via `deleteUserAccount`) |
| Account deletion (web URL for the form) | `https://lune-7d956.web.app/your-data-ends.html` — includes email-based deletion for users without the app |

Deploy privacy policy:

```bash
cd cycle_app
firebase deploy --only hosting
firebase deploy --only firestore:rules,functions
```

---

## Data types to declare

### Collected (optional — user must opt in)

| Data type | Purpose | Shared? | Encrypted in transit | User can delete |
|-----------|---------|---------|----------------------|-----------------|
| Email address | Account / sign-in | Firebase only | Yes | Yes (delete account) |
| Health info (cycle logs, symptoms, moods, BBT) | Tracking + optional AI personalization | AI-relevant context is processed by Gemini / DeepSeek only after explicit consent; never sold | Yes when AI/cloud features are on | Yes |
| Messages and submitted AI content | App functionality | Google Gemini / DeepSeek (service providers) | Yes | Yes |
| User-generated content (community posts) | App functionality | Other users (anonymous) | Yes | Yes |
| App interactions (likes, memberships) | App functionality | No | Yes | Yes |
| Purchase history (premium) | App functionality | Google Play | Yes | Via Google Play / account deletion |
| Photos (profile avatar, community stories — Premium) | App functionality | Firebase Storage | Yes | Yes (account deletion) |
| Crash logs & diagnostics (**Crashlytics**) | Analytics / diagnostics | Firebase only | Yes | Deleted with account |
| Device or other IDs (Firebase installation ID) | Analytics / diagnostics | Firebase only | Yes | Deleted with account |

### Not collected

- Precise location
- Contacts, SMS, call logs
- Community post photos/videos for **Premium** users (stories; moderated)
- Advertising ID for tracking
- Financial info (card numbers) — handled by Google Play Billing

---

## Play Console answers (recommended)

- **Does your app collect or share user data?** → Yes (optional features)
- **Is all data encrypted in transit?** → Yes
- **Can users request data deletion?** → Yes (in-app account deletion)
- **Account deletion URL** (required — app has account creation) →
  `https://lune-7d956.web.app/your-data-ends.html`
- **Committed to Google Play Families / health policies?** → Follow Health apps guidance; not a regulated medical device
- **Health apps declaration** → complete it: Health & wellness → cycle/period tracking; not a medical device
- **Ads** → No ads
- **Data sold** → No
- **Data used for tracking** → No

### AI-generated content (Play AI content policy)

Users can flag any AI chat reply in-app: flag icon under each response →
reason picker (Medical / Inaccurate / Inappropriate) → `aiReports` collection
→ admin dashboard review. Cite this if the review team asks how offensive AI
output is reported.

### Third-party AI launch checks (manual — do not skip)

- [ ] In Data safety, declare that AI messages/submitted content and relevant
      health context leave the device for app functionality. Do not describe
      the AI context as anonymous or local-only.
- [ ] Confirm the production Gemini and DeepSeek account/API terms prohibit
      sale, advertising use, and provider training beyond the disclosed Lune
      feature, and document retention/deletion. If the current plan does not
      provide these controls, change the provider plan/config before release.
- [ ] Keep a copy of the provider terms/DPA and screenshots of the in-app AI
      disclosure in case Google requests proof of limited use and consent.

---

## Technical controls implemented

- [x] Local-first storage; cloud/AI/communities require explicit consent
- [x] Encryption keys in `flutter_secure_storage` (Keystore / Keychain)
- [x] `android:allowBackup="false"` + `data_extraction_rules.xml`
- [x] Privacy policy hosted at public HTTPS URL
- [x] Onboarding privacy checkbox
- [x] Privacy Center with account deletion
- [x] Firestore rules: users own their data; authors can delete own posts
- [x] Cloud Functions keep Gemini API key server-side (preferred path)
- [x] **UGC safety (communities):** in-app report with reason categories, block user with confirmation, blocked-users management screen, AI pre-moderation, admin report review dashboard
- [x] Firestore rules: users cannot self-grant `isPremium`; community age gate enforced server-side; birth year write-once
- [x] AI moderation fails closed (rejects when Gemini unavailable)
- [x] Community media uploads enabled for Premium (`kCommunityMediaUploadsEnabled`); profile photos owner-only
- [x] Firebase Storage rules (`storage.rules`) — community media read requires 18+ (`isCommunityAdult`); profile photos signed-in users
- [x] Google Play Billing on Android (`in_app_purchase` + `verifyPlayPurchase` + `googlePlayWebhook` RTDN); PayPal fully removed
- [x] Terms of Service hosted at `/terms-of-service.html` + linked in onboarding, Privacy Center, and subscription screen
- [x] Contact support (`merrsoheb@gmail.com`) in Account & Privacy Center
- [x] Full account deletion Cloud Function (`deleteUserAccount`) — posts, comments, storage, partner data, Auth user
- [x] Consent withdrawal toggles in Privacy Center (cloud / AI / communities); privacy acceptance does **not** auto-enable AI
- [x] AI age + consent enforced centrally on-device and again in Cloud Functions before provider processing
- [x] Premium gating: cloud sync, AI chat (30 msgs/day), communities; core tracking free
- [x] Onboarding age gate: under-13 cannot complete setup; teens blocked from community UGC and **Lune AI**
- [x] Community `communityBirthYear` set only via explicit setup sheet (not copied from onboarding `birthDate`)
- [x] Firestore stories read requires `isCommunityAdult()` (aligned with posts/comments)

---

## User-generated content (Play Console)

When declaring **Social or communication** / UGC in Play Console:

| Control | Implementation |
|---------|----------------|
| Report content | Post/comment menu → reason picker → `communityReports` in Firestore |
| Block users | Confirm dialog → `users/{uid}/blockedUsers`; content hidden immediately |
| Manage blocks | Account → Community blocked users → unblock |
| Community guidelines | Shown in each community's About tab |
| Moderation | AI filter on create + admin dashboard at `/admin/` |
| Age gate | Community join/post/comment/**read**/stories requires 18+ (Firestore + Storage + UI) |
| Guidelines acceptance | Required dialog before joining a community |

Support email must respond to abuse reports within a reasonable time (document your SLA internally).

---

## Google Play Content rating (IARC questionnaire)

Use these answers when completing **Play Console → App content → Content rating**:

| Question area | Recommended answer |
|---------------|-------------------|
| Target age | Core tracker: **13+**; Lune AI and community/social features: **18+ only** |
| User interaction | Yes — anonymous communities with moderation |
| Shares location | No |
| Shares personal info | No (nicknames only in communities) |
| Sexual / reproductive health | Yes — menstrual cycle and fertility tracking (not pornographic) |
| Violence | No |
| Language | User-generated (moderated) |
| Controlled substance | No |
| Gambling | No |
| Digital purchases | Yes — Google Play subscription (Premium) |

**Expected rating:** Teen or Mature (varies by region) due to health + UGC topics. Communities are **18+ only** in-app.

---

## iOS release checklist

- [ ] Run `flutterfire configure` and add `GoogleService-Info.plist` to `ios/Runner/`
- [ ] Info.plist usage strings added (photos, Face ID, notifications)
- [ ] Sign in with Apple if offering Google Sign-In on iOS
- [ ] Home screen widget is Android-only (document in App Store description)

---

## Before each release

1. Privacy policy URL loads in browser (no login wall)
2. Account deletion tested on a test account
3. Data Safety form matches actual app behavior
4. `google-services.json` matches production package name
5. No secrets in APK (no hardcoded API keys in Dart)

---

## Support email

`PrivacyConstants.supportEmail` is already set to `merrsoheb@gmail.com` — use the same address as the Play Console contact email so abuse reports and deletion requests land in one inbox.
