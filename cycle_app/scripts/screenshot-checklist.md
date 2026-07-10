# Capture Lune app screenshots (Android emulator required)

**Brand:** Lune = moon. Shot #1 must show the **cycle ring** (phase UI). See `docs/BRAND_MOON.md` for photography mood, captions, and Play Store framing.

## Prerequisites

1. Android Studio AVD created and running, OR `flutter emulators --create`
2. App running: `flutter run -d <device_id>`

## Marketing frames (optional)

- Backdrop: blush `#FADADD` or lavender `#C9B8E8` surface
- Caption overlay: **دورتكِ لها أطوار — كالقمر**
- Soft crescent bokeh in background (optional; keep subtle)

## Quick capture

```powershell
cd cycle_app
.\scripts\capture-screenshots.ps1
```

## Manual (per screen)

Navigate to each screen in the app, then:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb exec-out screencap -p > public/images/screenshots/home.png
```

## Files

| PNG | Screen in app |
|-----|---------------|
| home.png | Home tab |
| calendar.png | Cycle calendar |
| log.png | Daily log |
| goals.png | Goal selection |
| ai.png | Lune AI chat |
| analytics.png | Reports / analytics |
| doctor-report.png | Doctor report |
| self-care.png | Self-care tab |
| pregnancy.png | Pregnancy mode |
| community.png | Community |
| magazine.png | Lune Magazine |
| stealth.png | Stealth mode |
| premium.png | Subscription |
| partner.png | Partner mode |
| privacy.png | Privacy center |

If no emulator is available, run `node scripts/svg-to-png.mjs` to rasterize SVG placeholders to PNG until real captures exist.
