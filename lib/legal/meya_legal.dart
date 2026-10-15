import 'package:flutter/foundation.dart';

/// Texts shown in About MEYA. They describe what the app does today.
/// Drafts: to be reviewed by PRIMA ELITE FZ-LLC's legal counsel before the
/// public release.

const meyaCompany = 'PRIMA ELITE FZ-LLC';
const meyaCompanyAddress = 'Ras Al Khaimah Economic Zone (RAKEZ), United Arab Emirates';
const meyaWebsite = 'https://meya-app.pages.dev/';

/// MEYA is AGPL-3.0: where anyone can get the source of the app they run.
const meyaSourceCode = 'https://github.com/aichemoussa/meya-app';
const meyaLegalUpdated = 'October 2026';

/// Where reports of abuse go. Set it when building a release:
/// --dart-define=MEYA_REPORT_EMAIL=safety@your-domain
const meyaReportEmail = String.fromEnvironment('MEYA_REPORT_EMAIL');

const meyaDescription =
    'MEYA is a private messenger for the people closest to you. You add '
    'people only in person, by scanning their QR code, and every message, '
    'voice message, photo, video, file, status and planned call is '
    'encrypted on your phone before it leaves, with proven open-source '
    'end-to-end encryption that is built to resist future quantum computers. '
    'Only the people in the conversation can read it.';

class LegalSection {
  final String heading;
  final String body;

  const LegalSection(this.heading, this.body);
}

const privacyPolicy = [
  LegalSection(
    'Who we are',
    'MEYA is developed by $meyaCompany, $meyaCompanyAddress. This policy '
        'explains what information MEYA handles and why.',
  ),
  LegalSection(
    'What stays on your phone',
    'Your name, MEYA ID, About, profile photo, contacts, messages, voice '
        'messages, photos, videos, files, status and calendar are stored on '
        'your phone. Everything MEYA stores there is encrypted with keys kept '
        'in your phone\'s secure key storage, and it is left out of cloud '
        'backups. MEYA has no copy of it.',
  ),
  LegalSection(
    'What our service providers handle',
    'Messages travel through a relay run on Supabase (our hosting provider). '
        'To deliver them it sees a random device ID for each phone, an '
        'anonymous sign-in for that phone, the public key that phone signs in '
        'with, which device sent an envelope to which device and when, the '
        'size of each envelope, and the network (IP) address your phone '
        'connects from. Envelope contents are end-to-end encrypted: the relay '
        'cannot read messages, media, status, profiles or calls. Envelopes '
        'are deleted once the receiving phone confirms delivery. When a call '
        'cannot connect directly, Cloudflare relays the encrypted call and '
        'sees the network addresses of both phones, but not the call itself.',
  ),
  LegalSection(
    'What MEYA never collects',
    'MEYA does not read your address book, has no public directory, shows '
        'no advertising, contains no analytics or tracking libraries, and '
        'does not sell or share data.',
  ),
  LegalSection(
    'Who sees your profile and status',
    'Your name, About and profile photo are shared, end-to-end encrypted, '
        'with your MEYA connections. Your status goes only to the people you '
        'choose, and disappears when it expires.',
  ),
  LegalSection(
    'Your choices',
    'You can change your profile at any time, remove a contact, limit how '
        'long media is kept, and delete your account from your phone in '
        'Settings › Account. Deleting removes everything MEYA stored on that '
        'phone. Messages you already sent remain on the phones of the people '
        'who received them.',
  ),
  LegalSection(
    'Data protection law',
    'MEYA is operated from the United Arab Emirates. Where the UAE Personal '
        'Data Protection Law (Federal Decree-Law No. 45 of 2021) or other laws '
        'apply, you can ask $meyaCompany about the limited information the '
        'relay handles. Because messages are end-to-end encrypted, we cannot '
        'access or disclose their contents.',
  ),
  LegalSection(
    'Changes',
    'If this policy changes, the new version will be shown in the app '
        'before it applies. Last updated: $meyaLegalUpdated.',
  ),
];

const termsOfUse = [
  LegalSection(
    'Using MEYA',
    'MEYA is provided by $meyaCompany. By using MEYA you agree to use it '
        'lawfully, to connect only with people who agree to connect with you, '
        'and not to use it to harm, harass or deceive others.',
  ),
  LegalSection(
    'Your account',
    'Your account exists only on your phone and is protected by your '
        'passcode. There is no password recovery: if you lose your phone or '
        'passcode, your account and messages cannot be restored.',
  ),
  LegalSection(
    'What is available',
    'MEYA is in development, and some features may change. Voice and video '
        'calls may not be available where local telecom rules do not allow '
        'them.',
  ),
  LegalSection(
    'Open source',
    'MEYA\'s source code is licensed under the GNU Affero General Public '
        'License, version 3 only (AGPL-3.0-only). Your rights under that '
        'licence are not limited by these terms.',
  ),
  LegalSection(
    'No warranty',
    'MEYA is provided as it is, without warranties, to the extent the law '
        'allows. $meyaCompany is not liable for loss of data stored on your '
        'phone.',
  ),
  LegalSection(
    'Law',
    'These terms are governed by the laws of the United Arab Emirates and '
        'the Emirate of Ras Al Khaimah. Last updated: $meyaLegalUpdated.',
  ),
];

const accessibilityStatement = [
  LegalSection(
    'Our goal',
    'MEYA aims to meet the Web Content Accessibility Guidelines (WCAG) 2.2 '
        'at level AA, applied to mobile apps.',
  ),
  LegalSection(
    'What MEYA supports',
    'Light and dark themes; a high contrast mode for both, meeting WCAG '
        'AAA contrast (at least 7:1); text contrast of at least 4.5:1 in all '
        'other themes; text sizes up to 1.6 times larger, on top of your '
        'phone\'s own text size; reduced motion; labels for screen readers '
        'such as TalkBack on buttons, photos and controls; and right-to-left '
        'layout for languages that need it.',
  ),
  LegalSection(
    'Known limits',
    'Voice messages have no transcript yet. Some screens may not yet be '
        'fully tested with every screen reader. We are working on both.',
  ),
  LegalSection(
    'Feedback',
    'If something in MEYA is hard to use, please tell $meyaCompany so we '
        'can fix it. Last reviewed: $meyaLegalUpdated.',
  ),
];

/// Licence notices added to Flutter's licence list (which already lists
/// every Dart and Flutter package MEYA uses).
Stream<LicenseEntry> meyaLicenses() async* {
  yield const LicenseEntryWithLineBreaks(
    ['MEYA'],
    'MEYA\n'
    'Copyright (C) 2026 $meyaCompany\n\n'
    'This program is free software: you can redistribute it and/or modify '
    'it under the terms of the GNU Affero General Public License as '
    'published by the Free Software Foundation, version 3.\n\n'
    'This program is distributed in the hope that it will be useful, but '
    'WITHOUT ANY WARRANTY; without even the implied warranty of '
    'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero '
    'General Public License for more details.\n\n'
    'You should have received a copy of the GNU Affero General Public '
    'License along with this program. If not, see '
    'https://www.gnu.org/licenses/agpl-3.0.html.',
  );
  yield const LicenseEntryWithLineBreaks(
    ['libsignal'],
    'libsignal\n'
    'Copyright 2013-2026 Signal Messenger, LLC\n\n'
    'Licensed under the GNU Affero General Public License, version 3 '
    '(AGPL-3.0-only). Source: https://github.com/signalapp/libsignal\n\n'
    'MEYA is not affiliated with or endorsed by Signal.',
  );
  yield const LicenseEntryWithLineBreaks(
    ['MEYA ringtones and notification sounds'],
    'Sounds by Joseph Sardin, BigSoundBank (https://bigsoundbank.com).\n\n'
    'Released under CC0 1.0 Universal (public domain dedication). No '
    'attribution is required; this credit is given with thanks.',
  );
}
