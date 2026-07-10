$ErrorActionPreference = "Stop"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$outDir = Join-Path $PSScriptRoot "..\public\images\screenshots"
$uiDump = Join-Path $env:TEMP "lune_ui_dump.xml"

function Wait-Device {
  for ($i = 0; $i -lt 60; $i++) {
    if (& $adb devices 2>$null | Select-String "device$") { return }
    Start-Sleep -Seconds 2
  }
  throw "No emulator connected"
}

function Tap([int]$x, [int]$y) {
  & $adb shell input tap $x $y 2>$null | Out-Null
  Start-Sleep -Milliseconds 800
}

function Back { & $adb shell input keyevent 4 2>$null | Out-Null; Start-Sleep -Milliseconds 900 }

function Swipe-Up { & $adb shell input swipe 540 1900 540 900 350 2>$null | Out-Null; Start-Sleep -Milliseconds 600 }

function Refresh-UiDump {
  & $adb shell uiautomator dump /sdcard/window_dump.xml 2>$null | Out-Null
  Start-Sleep -Milliseconds 400
  cmd /c "`"$adb`" pull /sdcard/window_dump.xml `"$uiDump`" >nul 2>&1"
  return Get-Content $uiDump -Raw -ErrorAction SilentlyContinue
}

function Tap-Desc([string[]]$patterns) {
  $xml = Refresh-UiDump
  if (-not $xml) { return $false }
  foreach ($pat in $patterns) {
    $re = [regex]::Escape($pat)
    $m = [regex]::Match($xml, "content-desc=`"([^`"]*$re[^`"]*)`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"")
    if (-not $m.Success) {
      $m = [regex]::Match($xml, "text=`"([^`"]*$re[^`"]*)`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"")
    }
    if ($m.Success) {
      $cx = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2
      $cy = ([int]$m.Groups[3].Value + [int]$m.Groups[5].Value) / 2
      Write-Host "    tap [$pat] -> $cx,$cy" -ForegroundColor DarkGray
      Tap $cx $cy
      return $true
    }
  }
  return $false
}

function Tap-Continue {
  Tap-Desc @('متابعة', 'Continue', 'Get started', 'ابدئي', 'التالي') | Out-Null
  if (-not $?) { Tap 540 2280 }
}

function Type-Text([string]$text) {
  & $adb shell input text ($text -replace ' ', '%s') 2>$null | Out-Null
  Start-Sleep -Milliseconds 400
}

function Capture([string]$name) {
  $path = Join-Path $outDir "$name.png"
  & $adb shell screencap -p /sdcard/lune_cap.png 2>$null | Out-Null
  cmd /c "`"$adb`" pull /sdcard/lune_cap.png `"$path`" >nul 2>&1"
  if ((Test-Path $path) -and (Get-Item $path).Length -gt 5000) {
    Write-Host "  ✓ $name.png" -ForegroundColor Green
  } else {
    Write-Host "  ✗ $name.png" -ForegroundColor Red
  }
  Start-Sleep -Seconds 1
}

function Complete-Onboarding([switch]$Pregnancy) {
  Write-Host "`n=== Onboarding ===" -ForegroundColor Cyan
  Start-Sleep -Seconds 2
  Tap-Desc @('مستخدمة جديدة', 'New user', 'إعداد خاص') | Out-Null
  Start-Sleep -Seconds 2

  # Age gate
  Tap-Desc @('18', '25', '34', '13') | Out-Null
  Start-Sleep -Seconds 1
  Tap-Continue

  # Step 0 welcome
  Tap-Continue

  # Step 1 profile
  Tap 540 1050
  Type-Text "Lune"
  Tap-Desc @('تاريخ الميلاد', 'Birth', 'ميلاد') | Out-Null
  if (-not $?) { Tap 540 1350 }
  Start-Sleep -Seconds 1
  Tap-Desc @('OK', 'موافق', 'تأكيد') | Out-Null
  if (-not $?) { Tap 900 2050 }
  Tap-Continue

  # Step 2 goals
  Start-Sleep -Seconds 1
  Capture "goals"
  if ($Pregnancy) {
    Tap-Desc @('حامل', 'Pregnant', 'Pregnancy', 'حمل') | Out-Null
    if (-not $?) { Swipe-Up; Tap-Desc @('حامل', 'Pregnant') | Out-Null }
  } else {
    Tap-Desc @('عام', 'General', 'تتبع', 'Track') | Out-Null
    if (-not $?) { Tap 540 750 }
  }

  # Step 3 cycle
  Tap-Continue

  # Step 4 privacy
  Tap-Desc @('أوافق', 'Accept', 'privacy', 'خصوصية', 'Policy') | Out-Null
  if (-not $?) { Tap 120 1200 }
  Tap-Continue

  # Step 5 finish
  Tap-Desc @('ابدئي', 'Get started', 'Start') | Out-Null
  if (-not $?) { Tap-Continue }

  Start-Sleep -Seconds 2
  Tap-Desc @('متابعة', 'Continue', 'Allow', 'Not now', 'Later', 'موافق') | Out-Null
  Start-Sleep -Seconds 3
}

function Tap-Nav([string]$label) {
  Tap-Desc @($label) | Out-Null
}

function Launch-App {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  & $adb shell monkey -p com.lune.app -c android.intent.category.LAUNCHER 1 2>$null | Out-Null
  $ErrorActionPreference = $prev
  Start-Sleep -Seconds 5
}

Wait-Device
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
& $adb shell pm clear com.lune.app 2>$null | Out-Null
Start-Sleep -Seconds 2
Launch-App

Complete-Onboarding

Write-Host "`n=== Capturing ===" -ForegroundColor Cyan

Tap-Desc @('الرئيسية', 'Home') | Out-Null
if (-not $?) { Tap 135 2280 }
Start-Sleep -Seconds 2
Capture "home"

Swipe-Up
Tap-Desc @('التقويم', 'Calendar', 'calendar') | Out-Null
if (-not $?) { Tap 200 1300 }
Start-Sleep -Seconds 2
Capture "calendar"
Back

Tap-Desc @('تسجيل', 'Log', 'سجل') | Out-Null
if (-not $?) { Tap 540 2280 }
Start-Sleep -Seconds 2
Capture "log"
Back

Tap-Desc @('العناية', 'Self', 'self') | Out-Null
if (-not $?) { Tap 756 2280 }
Start-Sleep -Seconds 2
Capture "self-care"

Tap-Desc @('المجتمع', 'Community') | Out-Null
if (-not $?) { Tap 324 2280 }
Start-Sleep -Seconds 2
Capture "community"

Tap-Desc @('حسابي', 'Account', 'حساب') | Out-Null
if (-not $?) { Tap 945 2280 }
Start-Sleep -Seconds 1

Tap-Desc @('Premium', 'بريميوم', 'ترقية') | Out-Null
if (-not $?) { Tap 540 650 }
Start-Sleep -Seconds 2
Capture "premium"
Back

Swipe-Up
Tap-Desc @('الشريك', 'Partner') | Out-Null
Start-Sleep -Seconds 2
Capture "partner"
Back

Swipe-Up
Tap-Desc @('الخصوصية', 'Privacy', 'Privacy &') | Out-Null
Start-Sleep -Seconds 2
Capture "privacy"
Back

Tap-Desc @('الرئيسية', 'Home') | Out-Null
if (-not $?) { Tap 135 2280 }
Start-Sleep -Seconds 1

Tap-Desc @('التقارير', 'Reports', 'reports') | Out-Null
if (-not $?) { Tap 980 180 }
Start-Sleep -Seconds 2
Capture "analytics"

Tap-Desc @('طبيب', 'Doctor', 'Doctor report') | Out-Null
Start-Sleep -Seconds 2
Capture "doctor-report"
Back
Back

Tap-Desc @('Lune AI', 'AI', 'ذكاء') | Out-Null
if (-not $?) { Tap 850 180 }
Start-Sleep -Seconds 2
Capture "ai"
Back

Tap-Desc @('الرئيسية', 'Home') | Out-Null
Swipe-Up; Swipe-Up
Tap-Desc @('مجلة', 'Magazine', 'Magazine') | Out-Null
Start-Sleep -Seconds 2
Capture "magazine"
Back

Tap-Desc @('حسابي', 'Account') | Out-Null
Swipe-Up
Tap-Desc @('تخفي', 'Stealth', 'Calculator') | Out-Null
if (-not $?) {
  & $adb shell am start -n com.lune.app/.MainActivity -d "lune://stealth" 2>$null | Out-Null
}
Start-Sleep -Seconds 2
Capture "stealth"

# Pregnancy home — second onboarding pass
& $adb shell pm clear com.lune.app 2>$null | Out-Null
Start-Sleep -Seconds 2
Launch-App
Complete-Onboarding -Pregnancy
Start-Sleep -Seconds 2
Capture "pregnancy"

Write-Host "`nDone — run: node scripts/crop-screenshots.mjs" -ForegroundColor Green
