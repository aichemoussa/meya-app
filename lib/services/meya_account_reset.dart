import 'dart:io';

import 'package:flutter/foundation.dart';

import 'meya_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/meya_database.dart';
import 'meya_blob_store.dart';
import 'meya_calendar_service.dart';
import 'meya_e2ee.dart';
import 'meya_message_service.dart';
import 'meya_profile_service.dart';
import 'meya_relay_session.dart';
import 'meya_status_service.dart';
import 'profile_photo_service.dart';

/// Deletes the MEYA account from this phone: messages, contacts, keys,
/// media, settings and the profile. This cannot be undone.
///
/// Contacts keep the messages they already received. To talk again, both
/// people need to connect again in person.
class MeyaAccountReset {
  static Future<void> deleteEverything(MeyaDatabase database) async {
    Future<void> step(String name, Future<void> Function() action) async {
      try {
        await action();
      } catch (error) {
        debugPrint('MEYA account reset: $name failed ($error).');
      }
    }

    await step('relay', () => MeyaRelaySession.instance.stop());

    await step('database', () async {
      await database.transaction(() async {
        for (final table in database.allTables.toList().reversed) {
          await database.delete(table).go();
        }
      });
    });

    await step('encryption keys', () => MeyaE2ee.instance.closeAndDeleteStore());
    await step('media', () => MeyaBlobStore.instance.deleteAll());
    await step('open copies', () => MeyaTempFiles.clear());
    await step('statuses', () => MeyaStatusService.instance.deleteAll());
    await step('calendar', () => MeyaCalendarService.instance.deleteAll());
    await step('profiles', () => MeyaProfileService.instance.deleteAll());
    await step('profile photo', () => ProfilePhotoService.removePhoto());
    await step('settings', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
    });
    // Last: the device identity, relay signing key, passcode and storage key.
    await step('secure storage', () => meyaSecureStorage.deleteAll());
    await step('cache', () async {
      final cache = await getTemporaryDirectory();
      if (await cache.exists()) {
        await for (final entity in cache.list()) {
          await entity.delete(recursive: true);
        }
      }
    });
    MeyaMessageService.instance.clearMemoryCache();
  }

  /// Size in bytes of everything MEYA keeps on this phone.
  static Future<int> appDataBytes() async {
    var total = 0;
    for (final getDirectory in [
      getApplicationSupportDirectory,
      getApplicationDocumentsDirectory,
    ]) {
      try {
        final directory = await getDirectory();
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      } catch (_) {
        // A folder that cannot be listed is skipped.
      }
    }
    return total;
  }
}
