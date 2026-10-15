# Stores the Cloudflare TURN key as Supabase secrets, so the turn-credentials
# function can hand out short-lived TURN passes. The token is typed hidden and
# never written to disk or to the console.
#
# Needs tool\release.config.ps1 (see release.config.example.ps1) for the
# Supabase project reference.

$ErrorActionPreference = 'Stop'

$config = Join-Path $PSScriptRoot 'release.config.ps1'
if (-not (Test-Path $config)) {
  Write-Host 'Missing tool\release.config.ps1. Copy tool\release.config.example.ps1 and fill it in.'
  exit 1
}
. $config

$keyId = Read-Host 'Cloudflare Turn Token ID (Key ID)'
$secure = Read-Host 'Cloudflare TURN API Token (hidden)' -AsSecureString
$token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

if ([string]::IsNullOrWhiteSpace($keyId) -or [string]::IsNullOrWhiteSpace($token)) {
  Write-Host 'Both values are needed. Nothing was saved.'
  exit 1
}

npx supabase secrets set "MEYA_TURN_KEY_ID=$($keyId.Trim())" "MEYA_TURN_KEY_TOKEN=$($token.Trim())" --project-ref $MeyaSupabaseProjectRef
$token = $null
Write-Host 'Done. Calls now get Cloudflare TURN when they need it.'
