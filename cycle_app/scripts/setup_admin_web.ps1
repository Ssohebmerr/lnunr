# One-time setup: register Firebase Web app and refresh config for admin panel.
# Run from repo root: .\cycle_app\scripts\setup_admin_web.ps1

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> Creating Firebase Web app (if missing)..."
firebase apps:create WEB "Lune Web Admin" --project lune-7d956 2>$null

Write-Host "==> Refreshing FlutterFire config..."
flutterfire configure --project=lune-7d956 --platforms=web,android --yes

Write-Host "==> Deploying hosting + rules + functions..."
firebase deploy --only hosting,firestore:rules,firestore:indexes,functions

Write-Host ""
Write-Host "Done. Open: https://lune-7d956.web.app/admin/"
Write-Host ""
Write-Host "Reset admin password (run from repo root):" -ForegroundColor Yellow
Write-Host '  .\cycle_app\scripts\setup-admin.ps1 -Email "you@example.com" -Password "YourNewPass123"'
Write-Host ""
Write-Host "Default bootstrap key in script: Lune-Admin-2026 (must match Firebase secret ADMIN_BOOTSTRAP_KEY)"
