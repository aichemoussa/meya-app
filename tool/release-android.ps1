# Builds MEYA for Android and publishes it as a GitHub release, so the
# "Download for Android" button on the website serves the new version.
#
# For each update:
#   1. Raise the version in pubspec.yaml (e.g. 1.0.0+1 -> 1.0.1+2). The number
#      after + must always go up, or phones refuse the update.
#   2. Commit, then tag that commit v<version> in the SOURCE repository
#      (AGPL: the source for each published build must be available).
#   3. Run:  .\tool\release-android.ps1 -Notes "What changed, in plain words"
#
# Needs: the signing key (tool/create-signing-key.ps1), the GitHub CLI signed
# in once with `gh auth login`, and tool/release.config.ps1 (copy
# tool/release.config.example.ps1 and fill it in; it is never committed).

param(
  [Parameter(Mandatory = $true)][string]$Notes,
  # Where the downloadable APK is published.
  [string]$Repo = 'aichemoussa/meya-website',
  # Where the matching source code is published.
  [string]$SourceRepo = 'aichemoussa/meya-app'
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

$config = Join-Path $PSScriptRoot 'release.config.ps1'
if (-not (Test-Path $config)) {
  Write-Host 'Missing tool\release.config.ps1. Copy tool\release.config.example.ps1 and fill it in.'
  exit 1
}
. $config

if (-not (Test-Path 'android\key.properties')) {
  Write-Host 'No signing key found. Run .\tool\create-signing-key.ps1 first.'
  exit 1
}

$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$version = $versionLine.Matches[0].Groups[1].Value
$name = $version.Split('+')[0]
$tag = "v$name"

gh release view $tag --repo $Repo *> $null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Release $tag already exists. Raise the version in pubspec.yaml first."
  exit 1
}

# The source for this build must be public before the binary is.
gh api "repos/$SourceRepo/git/ref/tags/$tag" *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Tag $tag does not exist in $SourceRepo yet. Push the source and its tag first."
  exit 1
}

# Real phones only (ARM); emulators use the debug build instead. The
# Supabase address and publishable key are public by design.
flutter build apk --release --target-platform android-arm,android-arm64 `
  "--dart-define=MEYA_SUPABASE_URL=$MeyaSupabaseUrl" `
  "--dart-define=MEYA_SUPABASE_KEY=$MeyaSupabaseKey" `
  "--dart-define=MEYA_REPORT_EMAIL=$MeyaReportEmail"
if ($LASTEXITCODE -ne 0) { Write-Host 'The build failed. Nothing was published.'; exit 1 }

New-Item -ItemType Directory -Force 'build\release' | Out-Null
$apk = 'build\release\meya.apk'
Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' $apk -Force
$hash = (Get-FileHash $apk -Algorithm SHA256).Hash.ToLower()
$sizeMb = [math]::Round((Get-Item $apk).Length / 1MB, 1)

$body = @"
$Notes

**Install:** download ``meya.apk`` on your Android phone and open it. The first time, your phone asks you to allow installs from your browser.

Size: $sizeMb MB
SHA-256: ``$hash``

**Source code:** https://github.com/$SourceRepo/tree/$tag
MEYA is free software under the GNU Affero General Public License v3.0 (AGPL-3.0-only).
"@

gh release create $tag $apk --repo $Repo --title "MEYA $name" --notes $body
if ($LASTEXITCODE -ne 0) { Write-Host 'Publishing to GitHub failed.'; exit 1 }

Write-Host ''
Write-Host "Published MEYA $name. The website download now serves this version."
