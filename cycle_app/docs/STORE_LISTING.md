# Google Play Store Listing Guide — Lune

Use this when preparing your Play Console listing **before** first upload.

**Brand:** Lune = moon. Tagline: *Your cycle has phases — like the moon.* See `docs/BRAND_MOON.md` for photography, social, and visual rules.

## Required assets

| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512×512 PNG | Crescent + orbit on rose→lavender gradient |
| Feature graphic | 1024×500 JPG/PNG | Logo + tagline on brand gradient (see BRAND_MOON.md) |
| Phone screenshots | Min 2, max 8 | 16:9 or 9:16; **#1 must show cycle ring** |
| 7-inch tablet | Optional | If `supportsTablet` |
| 10-inch tablet | Optional | Recommended for health apps |

### Screenshot ideas (in order)

1. **Home** — cycle ring + phase (moon metaphor hero)
2. **Daily log** — symptom tracking
3. **Analytics / Reports** — charts and cycle insights
4. **Doctor report** — PDF export screen
5. **AI chat** — Lune whisper (Premium; show disclaimer)
6. **Self-care** — breathing / journal / affirmations
7. **Community** — anonymous support (blur any test names)
8. **Privacy** — Privacy Center + stealth mode note

Capture on a **1080×2400** emulator or device. Use blush/lavender backdrop or soft moon bokeh for marketing frames. Arabic + English variants if targeting both.

## Text content

### App name (30 chars max)
`Lune`

### Short description (80 chars)
```
Your cycle has phases — like the moon. Private Arabic tracker & wellness.
```
Arabic option:
```
دورتكِ لها أطوار كالقمر. تتبع خاص بالعربية مع عافية ومجتمعات آمنة 18+.
```

### Full description (4000 chars max)

```
Lune means moon — and your cycle has phases, just like the sky.

Lune is a private, Arabic-first menstrual cycle and wellness companion. Track your phases with calm clarity: periods, symptoms, mood, fertility, pregnancy, menopause, and more — with your data encrypted on your device by default.

🌙 Why Lune?
The moon cycles through phases every month. So does your body. Lune turns that natural rhythm into a gentle, private tool — no ads, no data selling, no noise.

✨ What you get (free)
• Cycle calendar, predictions, and daily log
• 8 personal goal modes that reshape home, reports, and care tips
• Self-care: breathing, journal, gentle challenges
• Lune Magazine — evidence-based articles in Arabic & English
• Stealth mode — optional calculator disguise for local privacy
• Works offline for core tracking

💎 Lune Premium (optional)
• Lune AI — warm wellness chat (30 messages/day), not medical advice
• Encrypted cloud backup
• Safe communities for adults 18+ only

🔒 Privacy first
• AES-256 local encryption
• Cloud, AI, and community only with your consent
• Delete your account instantly in-app
• Full trust center at lune-7d956.web.app

Lune is a wellness tracker, not a medical device. Always consult a healthcare professional for medical concerns.

Privacy policy: https://lune-7d956.web.app/privacy-policy.html
Support: merrsoheb@gmail.com
```

Arabic full description — adapt the same structure using tagline **دورتكِ لها أطوار — كالقمر** from `BRAND_MOON.md`.

Highlight bullets for Data Safety alignment:
- Local-first, encrypted on device (AES-256)
- Optional cloud backup (Premium)
- Lune AI — wellness companion, **not medical advice** (Premium)
- Communities **18+ only**, moderated, report/block
- **Stealth mode** — optional calculator disguise (disclose clearly; not extra encryption)
- Account deletion in-app (immediate)
- No ads, no data selling

Link privacy policy: `https://lune-7d956.web.app/privacy-policy.html`

## Category & tags

- **Category:** Health & Fitness
- **Tags:** period tracker, menstrual, women's health, cycle, wellness, Arabic, moon

## Contact details

- Email: `merrsoheb@gmail.com`
- Website: `https://lune-7d956.web.app/`
- Privacy policy URL: required (see above)

## Before first upload checklist

- [ ] Release AAB built (`scripts/build_release.ps1`)
- [ ] Feature graphic 1024×500 with moon tagline (`docs/BRAND_MOON.md`)
- [ ] `premium_monthly` and `premium_yearly` subscriptions created in Play Console
- [ ] RTDN configured (`docs/PLAY_LAUNCH_CHECKLIST.md`)
- [ ] Data Safety form filled (`docs/GOOGLE_PLAY_DATA_SAFETY.md`)
- [ ] Content rating (IARC) completed — target **18+** for UGC
- [ ] Target audience: not designed for children under 13
- [ ] Test on Internal testing track first

See also: `docs/PLAY_LAUNCH_CHECKLIST.md`, `docs/BRAND_MOON.md`
