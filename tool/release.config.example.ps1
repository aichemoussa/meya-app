# Copy this file to tool\release.config.ps1 (which Git ignores) and fill it in.
# These values are baked into the app at build time.

# Your Supabase project address and its PUBLISHABLE key (never the secret key).
$MeyaSupabaseUrl = 'https://<project-ref>.supabase.co'
$MeyaSupabaseKey = 'sb_publishable_...'

# Where the in-app "Report" feature sends reports.
$MeyaReportEmail = 'reports@example.com'

# Your Supabase project reference, used by tool\set-turn-secrets.ps1.
$MeyaSupabaseProjectRef = '<project-ref>'

# Wake-up pushes: the Firebase project's Android app values (Firebase console >
# Project settings > Your apps). They are public identifiers, not secrets.
# Leave them empty to build without pushes.
$MeyaFirebaseApiKey = ''
$MeyaFirebaseAppId = ''
$MeyaFirebaseSenderId = ''
$MeyaFirebaseProjectId = ''
