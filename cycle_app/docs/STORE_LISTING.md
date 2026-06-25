# Google Play Store Listing Guide — Cycle Aura

Use this when preparing your Play Console listing **before** first upload.

## Required assets

| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512×512 PNG | No transparency; matches launcher icon |
| Feature graphic | 1024×500 JPG/PNG | Banner at top of store page |
| Phone screenshots | Min 2, max 8 | 16:9 or 9:16; use real app UI |
| 7-inch tablet | Optional | If `supportsTablet` |
| 10-inch tablet | Optional | Recommended for health apps |

### Screenshot ideas (in order)

1. **Home** — cycle ring + phase + greeting
2. **Daily log** — symptom tracking
3. **AI chat** — wellness companion (show disclaimer)
4. **Insights** — charts and AI tip card
5. **Self-care** — breathing / journal
6. **Community** — anonymous support (blur any test names)
7. **Account** — privacy center + Premium
8. **Privacy** — onboarding consent screen

Capture on a **1080×2400** emulator or device. Use Arabic + English variants if targeting both.

## Text content

### App name (30 chars max)
`Cycle Aura`

### Short description (80 chars)
```
Private cycle tracker with AI wellness tips & safe adult communities.
```
Arabic option:
```
تتبع خاص للدورة مع نصائح AI ومجتمعات آمنة للبالغات.
```

### Full description (4000 chars max)
Highlight:
- Local-first, encrypted on device
- Optional cloud backup (Premium)
- AI wellness — not medical advice
- Communities 18+, moderated, report/block
- Account deletion in-app
- No ads, no data selling

Link privacy policy: `https://lune-7d956.web.app/privacy-policy.html`

## Category & tags

- **Category:** Health & Fitness
- **Tags:** period tracker, menstrual, women's health, cycle, wellness

## Contact details

- Email: `support@cycleaura.app`
- Website: `https://lune-7d956.web.app/`
- Privacy policy URL: required (see above)

## Before first upload checklist

- [ ] Release AAB built (`scripts/build_release.ps1`)
- [ ] `premium_monthly` subscription created in Play Console
- [ ] Data Safety form filled (`docs/GOOGLE_PLAY_DATA_SAFETY.md`)
- [ ] Content rating (IARC) completed
- [ ] Target audience: not designed for children
- [ ] Test on Internal testing track first

See also: `docs/PLAY_LAUNCH_CHECKLIST.md`
