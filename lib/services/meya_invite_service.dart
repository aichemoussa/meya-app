import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meya_secure_storage.dart';

/// What an invite link carries: who to connect with, and a one-time token.
class MeyaInvite {
  final String identityId;
  final String identityPublicKey;
  final String deviceId;
  final String token;

  const MeyaInvite({
    required this.identityId,
    required this.identityPublicKey,
    required this.deviceId,
    required this.token,
  });
}

/// One-time invite links, for connecting with someone who is not nearby.
///
/// The link holds the same identity as the QR code (identity ID, identity
/// key, device ID) but no name, plus a random token. It is shared through
/// any app (WhatsApp, Telegram, email...). The data sits after `#`, so even
/// the website that serves the link never receives it.
///
/// The phone that made the link keeps only a hash of each token. The first
/// connection request carrying a valid token is accepted automatically, so
/// both phones end up with an encrypted chat without anyone tapping Accept.
/// A token works once and expires after [lifetime].
///
/// Contacts made this way were not met in person: MEYA says so until their
/// safety number is compared.
class MeyaInviteService {
  MeyaInviteService._();

  static final MeyaInviteService instance = MeyaInviteService._();

  static const lifetime = Duration(days: 7);

  /// Unused links kept at most; the oldest is dropped beyond this.
  static const maxOpenInvites = 20;

  static const linkBase = 'https://meya-app.pages.dev/i#';
  static const appLinkBase = 'meya://invite/';
  static const _version = 'L1';
  static const _invitesKey = 'meya_invites_v1';
  static const _linkContactsKey = 'meya_link_contacts_v1';

  /// The clock; tests replace it.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  static String _hash(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  static String _newToken() {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(16, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  /// The shareable link for [invite].
  static String linkFor(MeyaInvite invite) {
    final payload = [
      'MEYA',
      _version,
      invite.identityId,
      invite.identityPublicKey,
      invite.deviceId,
      invite.token,
    ].join('|');
    return linkBase +
        base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  }

  /// Reads an invite from a link (https or meya://), or null when [link] is
  /// not a valid MEYA invite.
  static MeyaInvite? parse(String link) {
    final text = link.trim();
    String? encoded;
    if (text.startsWith(linkBase)) {
      encoded = text.substring(linkBase.length);
    } else if (text.startsWith(appLinkBase)) {
      encoded = text.substring(appLinkBase.length);
    }
    if (encoded == null || encoded.isEmpty || encoded.length > 2048) {
      return null;
    }
    try {
      final padded = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
      final parts = utf8.decode(base64Url.decode(padded)).split('|');
      if (parts.length != 6 || parts[0] != 'MEYA' || parts[1] != _version) {
        return null;
      }
      final invite = MeyaInvite(
        identityId: parts[2],
        identityPublicKey: parts[3],
        deviceId: parts[4],
        token: parts[5],
      );
      if (invite.identityId.isEmpty ||
          invite.identityPublicKey.isEmpty ||
          invite.deviceId.isEmpty ||
          invite.token.length < 16) {
        return null;
      }
      return invite;
    } catch (_) {
      return null;
    }
  }

  /// Hash -> expiry (ms since epoch) of this phone's unused invites.
  Future<Map<String, int>> _load() async {
    final stored = await meyaSecureStorage.read(key: _invitesKey);
    if (stored == null || stored.isEmpty) return {};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic>) return {};
      final nowMs = now().millisecondsSinceEpoch;
      return {
        for (final entry in decoded.entries)
          if (entry.value is int && (entry.value as int) > nowMs)
            entry.key: entry.value as int,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(Map<String, int> invites) =>
      meyaSecureStorage.write(key: _invitesKey, value: jsonEncode(invites));

  /// Creates a new one-time invite for this phone's identity.
  Future<MeyaInvite> create({
    required String identityId,
    required String identityPublicKey,
    required String deviceId,
  }) async {
    final token = _newToken();
    final invites = await _load();
    invites[_hash(token)] = now().add(lifetime).millisecondsSinceEpoch;
    while (invites.length > maxOpenInvites) {
      final oldest = invites.entries
          .reduce((a, b) => a.value <= b.value ? a : b)
          .key;
      invites.remove(oldest);
    }
    await _save(invites);
    return MeyaInvite(
      identityId: identityId,
      identityPublicKey: identityPublicKey,
      deviceId: deviceId,
      token: token,
    );
  }

  /// Uses up [token]: true only the first time a valid, unexpired token is
  /// presented.
  Future<bool> consume(String token) async {
    if (token.isEmpty || token.length > 128) return false;
    final invites = await _load();
    final used = invites.remove(_hash(token)) != null;
    await _save(invites);
    return used;
  }

  /// Remembers that the contact with [identityId] was connected by link,
  /// not in person.
  Future<void> markConnectedByLink(String identityId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_linkContactsKey) ?? [];
    if (!ids.contains(identityId)) {
      await preferences.setStringList(_linkContactsKey, [...ids, identityId]);
    }
  }

  Future<bool> connectedByLink(String identityId) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_linkContactsKey) ?? const [])
        .contains(identityId);
  }
}
