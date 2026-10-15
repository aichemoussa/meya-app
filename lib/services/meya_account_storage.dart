
import 'meya_secure_storage.dart';

class MeyaUser {
  final String userId;
  final String name;
  final String username;

  const MeyaUser({
    required this.userId,
    required this.name,
    required this.username,
  });
}

/// The signed-in person's basic profile, kept in the phone's secure storage.
class MeyaAccountStorage {
  static const _storage = meyaSecureStorage;

  static const _userIdKey = 'meya_user_id';
  static const _userNameKey = 'meya_user_name';
  static const _usernameKey = 'meya_username';
  static const _aboutKey = 'meya_about';

  // Used by the first version of Status, which stayed on this device.
  static const _legacyStatusKeys = [
    'meya_status_text',
    'meya_status_emoji',
    'meya_status_visibility',
    'meya_status_expiry',
  ];

  static Future<void> saveUser(MeyaUser user) async {
    await _storage.write(key: _userIdKey, value: user.userId);
    await _storage.write(key: _userNameKey, value: user.name);
    await _storage.write(key: _usernameKey, value: user.username);
  }

  static Future<MeyaUser?> loadUser() async {
    final userId = await _storage.read(key: _userIdKey);
    final name = await _storage.read(key: _userNameKey);
    final username = await _storage.read(key: _usernameKey);

    if (userId == null || name == null || username == null) {
      return null;
    }

    return MeyaUser(userId: userId, name: name, username: username);
  }

  static Future<void> saveAbout(String about) async {
    await _storage.write(key: _aboutKey, value: about);
  }

  static Future<String> loadAbout() async {
    return await _storage.read(key: _aboutKey) ?? '';
  }

  static Future<void> clearUser() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _aboutKey);
    for (final key in _legacyStatusKeys) {
      await _storage.delete(key: key);
    }
  }
}
