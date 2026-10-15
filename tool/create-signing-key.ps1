# Creates MEYA's Android release signing key. Run this ONCE, yourself.
#
# Every MEYA update must be signed with this same key, or phones refuse to
# install it. Back up the key file and the password somewhere safe (a password
# manager plus a USB stick). If either is lost, nobody can update MEYA anymore
# and everyone would have to uninstall and start over.
#
# The password is typed hidden. It is written only to android/key.properties,
# which git ignores; it never appears on screen.

$ErrorActionPreference = 'Stop'

$keyDir = Join-Path $env:USERPROFILE '.meya'
$keyFile = Join-Path $keyDir 'meya-release.jks'
$props = Join-Path $PSScriptRoot '..\android\key.properties'

if (Test-Path $keyFile) {
  Write-Host "A key already exists at $keyFile. Nothing was changed."
  exit 1
}

$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
if (-not (Test-Path $keytool)) { $keytool = 'keytool' }

$secure = Read-Host 'Choose a password for the key (at least 8 characters, hidden)' -AsSecureString
$again = Read-Host 'Type it again (hidden)' -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$plain2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($again))

if ($plain -ne $plain2) { Write-Host 'The passwords differ. Nothing was saved.'; exit 1 }
if ($plain.Length -lt 8) { Write-Host 'Use at least 8 characters. Nothing was saved.'; exit 1 }

New-Item -ItemType Directory -Force $keyDir | Out-Null

# Passwords go through environment variables so they do not show up in the
# process list.
$env:MEYA_KEY_PASS = $plain
& $keytool -genkeypair -v -keystore $keyFile -alias meya -keyalg RSA -keysize 4096 `
  -validity 10000 -storepass:env MEYA_KEY_PASS -keypass:env MEYA_KEY_PASS `
  -dname 'CN=MEYA, O=MEYA'
$env:MEYA_KEY_PASS = $null
if ($LASTEXITCODE -ne 0) { Write-Host 'keytool failed. Nothing was saved.'; exit 1 }

# key.properties is a Java properties file: backslashes must be doubled.
$storePath = $keyFile -replace '\\', '\\'
@"
storeFile=$storePath
storePassword=$plain
keyAlias=meya
keyPassword=$plain
"@ | Set-Content -Encoding ascii $props
$plain = $null; $plain2 = $null

Write-Host ''
Write-Host "Key created: $keyFile"
Write-Host 'Now back up that file and your password somewhere safe.'
