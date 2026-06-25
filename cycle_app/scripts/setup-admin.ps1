# Creates Lune admin via Firebase Auth + admins/{uid} in Firestore.
# Usage:
#   .\scripts\setup-admin.ps1 -Email "you@gmail.com" -Password "YourPass123"

param(
  [Parameter(Mandatory = $true)]
  [string]$Email,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  [string]$BootstrapKey = "Lune-Admin-2026"
)

$body = @{
  data = @{
    email        = $Email.Trim().ToLower()
    password     = $Password
    bootstrapKey = $BootstrapKey
  }
} | ConvertTo-Json -Depth 3

$url = "https://us-central1-lune-7d956.cloudfunctions.net/bootstrapAdmin"

Write-Host "Creating admin for $Email ..." -ForegroundColor Cyan

try {
  $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
  $result = $response.result
  Write-Host ""
  Write-Host "Done!" -ForegroundColor Green
  Write-Host "UID:   $($result.uid)"
  Write-Host "Email: $($result.email)"
  Write-Host ""
  Write-Host "Login:" -ForegroundColor Yellow
  Write-Host "  Web:  https://lune-7d956.web.app/admin/"
  Write-Host "  App:  Account -> Admin (after sign-in with same email)"
} catch {
  $detail = $_.ErrorDetails.Message
  if ($detail) {
    try {
      $json = $detail | ConvertFrom-Json
      Write-Host "Failed: $($json.error)" -ForegroundColor Red
    } catch {
      Write-Host "Failed: $detail" -ForegroundColor Red
    }
  } else {
    Write-Host "Failed: $_" -ForegroundColor Red
  }
  exit 1
}
