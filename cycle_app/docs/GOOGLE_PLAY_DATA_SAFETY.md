# Google Play — Data Safety & Policy Checklist (Cycle Aura)

Use this when filling **Play Console → App content → Data safety** and before publishing.

## App identity

| Field | Value |
|-------|-------|
| Package | `com.lune.app` |
| Privacy policy URL | `https://lune-7d956.web.app/privacy-policy.html` |
| Terms of Service URL | `https://lune-7d956.web.app/terms-of-service.html` |
| Support email | `support@cycleaura.app` |
| Account deletion | In-app: **Account → Privacy & data → Delete account** (server-side via `deleteUserAccount`) |

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
| Health & fitness (cycle logs) | App functionality | No (not sold) | Yes if cloud sync on | Yes |
| Messages (AI chat) | App functionality | Google Gemini | Yes | Yes |
| User-generated content (community posts) | App functionality | Other users (anonymous) | Yes | Yes |
| App interactions (likes, memberships) | App functionality | No | Yes | Yes |
| Purchase history (premium) | App functionality | Google Play | Yes | Via Google Play / account deletion |
| Photos (profile avatar) | App functionality | Firebase Storage | Yes | Yes (account deletion) |

### Not collected

- Precise location
- Contacts, SMS, call logs
- Community post photos/videos (uploads disabled in current release)
- Advertising ID for tracking
- Financial info (card numbers) — handled by PayPal

---

## Play Console answers (recommended)

- **Does your app collect or share user data?** → Yes (optional features)
- **Is all data encrypted in transit?** → Yes
- **Can users request data deletion?** → Yes (in-app account deletion)
- **Committed to Google Play Families / health policies?** → Follow Health apps guidance; not a regulated medical device
- **Ads** → No ads
- **Data sold** → No
- **Data used for tracking** → No

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
- [x] Community media uploads disabled until visual moderation ships
- [x] Firebase Storage rules (`storage.rules`) — community media writes blocked; profile photos owner-only
- [x] Google Play Billing on Android (`in_app_purchase` + `verifyPlayPurchase` Cloud Function); PayPal removed from Android UI
- [x] Terms of Service hosted at `/terms-of-service.html` + linked in onboarding & Privacy Center
- [x] Contact support (`support@cycleaura.app`) in Account & Privacy Center
- [x] Full account deletion Cloud Function (`deleteUserAccount`) — posts, comments, storage, partner data, Auth user
- [x] Consent withdrawal toggles in Privacy Center (cloud / AI / communities)
- [x] Premium gating: cloud sync, advanced AI, daily insights; free tier 5 AI messages/day

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
| Age gate | Community join/post/comment/**read** requires 18+ (Firestore + UI) |
| Guidelines acceptance | Required dialog before joining a community |

Support email must respond to abuse reports within a reasonable time (document your SLA internally).

---

## Google Play Content rating (IARC questionnaire)

Use these answers when completing **Play Console → App content → Content rating**:

| Question area | Recommended answer |
|---------------|-------------------|
| Target age | **18+** for community/social features; core tracker usable by adults |
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

Update `PrivacyConstants.supportEmail` and Play Console contact to your real support address before launch.
