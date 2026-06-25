# Build release App Bundle for Google Play
Set-Location $PSScriptRoot\..

Write-Host "Building Cycle Aura release AAB..." -ForegroundColor Cyan
flutter build appbundle --release

$out = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $out) {
    Write-Host "Success: $out" -ForegroundColor Green
    Write-Host "Upload this file to Play Console > Internal testing" -ForegroundColor Yellow
} else {
    Write-Host "Build failed — check output above." -ForegroundColor Red
    exit 1
}
