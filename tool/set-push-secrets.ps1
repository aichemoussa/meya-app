# Sets up wake-up pushes (Firebase Cloud Messaging) on Supabase:
#   1. stores the Firebase service account JSON and a new shared secret as
#      Supabase function secrets (for functions/push);
#   2. prints the SQL that stores the push function's address and the same
#      secret in Vault (for the database trigger). Paste it into the Supabase
#      dashboard's SQL editor and run it once.
#
# The service account file comes from the Firebase console: Project settings
# > Service accounts > Generate new private key. Keep it private; it never
# goes into Git or the app.
#
# Needs tool\release.config.ps1 (see release.config.example.ps1).

$ErrorActionPreference = 'Stop'

$config = Join-Path $PSScriptRoot 'release.config.ps1'
if (-not (Test-Path $config)) {
  Write-Host 'Missing tool\release.config.ps1. Copy tool\release.config.example.ps1 and fill it in.'
  exit 1
}
. $config

$path = (Read-Host 'Path to the Firebase service account JSON file').Trim('"', ' ')
if (-not (Test-Path $path)) {
  Write-Host 'File not found. Nothing was saved.'
  exit 1
}
$account = Get-Content -Raw $path | ConvertFrom-Json
if (-not $account.client_email -or -not $account.private_key -or -not $account.project_id) {
  Write-Host 'This is not a service account file. Nothing was saved.'
  exit 1
}

$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$secret = [Convert]::ToHexString($bytes).ToLower()

# Through a temporary env file, so the key never appears on a command line.
$envFile = Join-Path ([IO.Path]::GetTempPath()) "meya-push-$([Guid]::NewGuid()).env"
try {
  $compact = $account | ConvertTo-Json -Compress -Depth 5
  Set-Content -Path $envFile -NoNewline -Value (
    "MEYA_FCM_SERVICE_ACCOUNT='$compact'`nMEYA_PUSH_SECRET=$secret`n")
  npx supabase secrets set --env-file $envFile --project-ref $MeyaSupabaseProjectRef
} finally {
  Remove-Item $envFile -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'Now run this once in the Supabase SQL editor:'
Write-Host ''
Write-Host "select vault.create_secret('$MeyaSupabaseUrl/functions/v1/push', 'meya_push_url');"
Write-Host "select vault.create_secret('$secret', 'meya_push_secret');"
Write-Host ''
Write-Host 'Phones are then woken when a message, request or call arrives.'
$secret = $null
