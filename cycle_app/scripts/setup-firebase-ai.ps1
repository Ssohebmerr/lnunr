# Enable Firebase AI for Lune (no Gemini Studio key in the app).
#
# Step 1 — Firebase Console (required, one time):
#   https://console.firebase.google.com/project/lune-7d956/ailogic
#   → Get started → choose "Gemini Developer API" → finish the wizard
#
# Step 2 — Cloud Functions backup (optional but recommended):
#   Stores the API key in Firebase Secrets (server only, not in the app).
#
# Usage:
#   .\scripts\setup-firebase-ai.ps1
#   .\scripts\setup-firebase-ai.ps1 -SkipSecret

param(
  [switch]$SkipSecret,
  [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=== Lune — Firebase AI setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Provisioning Firebase AI Logic (Android app)..." -ForegroundColor Yellow
Push-Location $projectRoot
try {
  node scripts/provision-ailogic.mjs
} catch {
  Write-Host "Provisioning failed. Enable manually:" -ForegroundColor Red
  Write-Host "   https://console.firebase.google.com/project/lune-7d956/ailogic"
  exit 1
} finally {
  Pop-Location
}
Write-Host ""

if (-not $SkipSecret) {
  Write-Host "2) Set server secret GEMINI_API_KEY (for Cloud Functions chat/analyze):" -ForegroundColor Yellow
  Write-Host "   You will be prompted to paste a key — it stays on Firebase only."
  Write-Host ""
  Push-Location $projectRoot
  try {
    firebase functions:secrets:set GEMINI_API_KEY
  } finally {
    Pop-Location
  }
  Write-Host ""
} else {
  Write-Host "2) Skipped GEMINI_API_KEY secret." -ForegroundColor DarkGray
  Write-Host ""
}

if (-not $SkipDeploy) {
  Write-Host "3) Deploying AI Cloud Functions..." -ForegroundColor Yellow
  Push-Location $projectRoot
  try {
    firebase deploy --only "functions:chat,functions:analyze,functions:moderate"
  } finally {
    Pop-Location
  }
  Write-Host ""
} else {
  Write-Host "3) Skipped deploy." -ForegroundColor DarkGray
  Write-Host ""
}

Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Then rebuild the app:" -ForegroundColor Yellow
Write-Host "  cd cycle_app"
Write-Host "  flutter run"
Write-Host ""
Write-Host "In the app: sign in → AI chat → accept AI consent → send a message."
Write-Host ""
