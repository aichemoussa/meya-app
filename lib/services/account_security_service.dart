
import 'meya_secure_storage.dart';

class AccountSecurityService {
  static const _storage = meyaSecureStorage;

  static const _passcodeKey = 'meya_account_passcode';

  static Future<void> savePasscode(String passcode) async {
    await _storage.write(
      key: _passcodeKey,
      value: passcode,
    );
  }

  static Future<String?> getPasscode() async {
    return _storage.read(key: _passcodeKey);
  }

  static Future<bool> hasPasscode() async {
    final passcode = await getPasscode();
    return passcode != null && passcode.isNotEmpty;
  }

  static Future<bool> verifyPasscode(String passcode) async {
    final storedPasscode = await getPasscode();
    return storedPasscode != null && storedPasscode == passcode;
  }

  static Future<void> clearPasscode() async {
    await _storage.delete(key: _passcodeKey);
  }
}
