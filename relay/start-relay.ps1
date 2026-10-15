# Starts the MEYA relay and a Cloudflare quick tunnel in front of it.
#
# Optional: enable TURN for calls on difficult networks. Create the file
# relay\turn.secret.ps1 (it is git-ignored) with these two lines, using the
# key from Cloudflare dashboard > Realtime > TURN Server:
#   $env:MEYA_TURN_KEY_ID = '<TURN key ID>'
#   $env:MEYA_TURN_KEY_TOKEN = '<TURN key API token>'

$ErrorActionPreference = 'Stop'
$secret = Join-Path $PSScriptRoot 'turn.secret.ps1'
if (Test-Path $secret) { . $secret }

# Only this PC (and the tunnel) can reach the relay directly.
$env:MEYA_RELAY_ADDR = '127.0.0.1:8787'
$env:MEYA_RELAY_DB = Join-Path $PSScriptRoot 'meya_relay.db'

$relay = Start-Process -PassThru -NoNewWindow `
  -FilePath (Join-Path $PSScriptRoot 'target\release\meya-relay.exe')

try {
  # Prints the public https://....trycloudflare.com address. The app must be
  # built with --dart-define=MEYA_RELAY_URL=wss://<that address>/v1/ws
  & 'C:\Program Files (x86)\cloudflared\cloudflared.exe' tunnel `
    --no-autoupdate --url http://127.0.0.1:8787
}
finally {
  Stop-Process -Id $relay.Id -ErrorAction SilentlyContinue
}
