# Interactive screenshot capture for Lune (Android emulator)
$ErrorActionPreference = "Stop"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$outDir = Join-Path $PSScriptRoot "..\public\images\screenshots"

if (-not (Test-Path $adb)) {
  Write-Host "adb not found at $adb" -ForegroundColor Red
  Write-Host "Install Android SDK platform-tools or capture manually."
  exit 1
}

$devices = & $adb devices | Select-String "device$"
if (-not $devices) {
  Write-Host "No Android device/emulator connected." -ForegroundColor Yellow
  Write-Host "Start an AVD from Android Studio, run: flutter run -d <id>"
  Write-Host "Then re-run this script."
  exit 1
}

$screens = @(
  @{ file = "home"; hint = "Home tab — cycle ring" },
  @{ file = "calendar"; hint = "Cycle calendar" },
  @{ file = "log"; hint = "Daily log tab" },
  @{ file = "goals"; hint = "Goal selection / onboarding" },
  @{ file = "ai"; hint = "Lune AI chat" },
  @{ file = "analytics"; hint = "Reports / analytics" },
  @{ file = "doctor-report"; hint = "Doctor report" },
  @{ file = "self-care"; hint = "Self-care tab" },
  @{ file = "pregnancy"; hint = "Pregnancy mode home" },
  @{ file = "community"; hint = "Community tab" },
  @{ file = "magazine"; hint = "Lune Magazine" },
  @{ file = "stealth"; hint = "Stealth / calculator mode" },
  @{ file = "premium"; hint = "Premium subscription screen" },
  @{ file = "partner"; hint = "Partner mode" },
  @{ file = "privacy"; hint = "Privacy center" }
)

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Write-Host "Connected. Navigate in the app, press Enter to capture each screen.`n"

foreach ($s in $screens) {
  $path = Join-Path $outDir "$($s.file).png"
  Write-Host "[$($s.file).png] $($s.hint)" -ForegroundColor Cyan
  Read-Host "Press Enter when ready"
  & $adb shell screencap -p /sdcard/lune_cap.png | Out-Null
  & $adb pull /sdcard/lune_cap.png $path 2>&1 | Out-Null
  if (Test-Path $path) { Write-Host "  Saved $path" -ForegroundColor Green }
}

Write-Host "`nDone. Deploy: firebase deploy --only hosting"
