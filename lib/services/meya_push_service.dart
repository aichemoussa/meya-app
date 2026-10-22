import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/database_encryption.dart';
import '../l10n/meya_strings.dart';
import '../theme/meya_theme.dart';
import 'device_identity_service.dart';
import 'meya_notifications.dart';
import 'meya_sound_settings.dart';
import 'supabase_relay_transport.dart';

/// Wakes MEYA when something arrives while it is closed, through Firebase
/// Cloud Messaging (Google's push service).
///
/// The push is empty: no sender, no content, no type. The server sends it
/// only for envelopes marked as something the person sees (a message, a
/// connection request or a call). On receiving it, MEYA:
/// - if its main screen is running, simply reconnects and handles
///   everything as usual;
/// - otherwise asks the relay which waiting envelopes should alert and from
///   which device, looks up that contact's name (read-only), and shows a
///   notification. Nothing is decrypted or deleted until MEYA is opened, so
///   the encryption state is only ever changed by the app itself.
///
/// Configure with the Firebase project's Android app values:
///   --dart-define=MEYA_FIREBASE_API_KEY=...
///   --dart-define=MEYA_FIREBASE_APP_ID=...
///   --dart-define=MEYA_FIREBASE_SENDER_ID=...
///   --dart-define=MEYA_FIREBASE_PROJECT_ID=...
/// Without them, MEYA works as before, without pushes.
class MeyaPushService {
  MeyaPushService._();

  static final MeyaPushService instance = MeyaPushService._();

  static const _apiKey = String.fromEnvironment('MEYA_FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('MEYA_FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('MEYA_FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('MEYA_FIREBASE_PROJECT_ID');

  /// Where the main screen listens for wake-ups from the push handler.
  static const mainPortName = 'meya_main_wake';

  static bool get configured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty &&
      SupabaseRelayTransport.configured &&
      Platform.isAndroid;

  static const _options = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
  );

  static Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _options);
    }
  }

  ReceivePort? _wakePort;
  bool _started = false;

  /// Starts listening for pushes. [onWake] runs when one arrives while the
  /// main screen is up (in the foreground or in the background).
  Future<void> start({required VoidCallback onWake}) async {
    if (!configured) return;
    _listenForWakeUps(onWake);
    if (_started) return;
    try {
      await _ensureFirebase();
      FirebaseMessaging.onBackgroundMessage(meyaPushBackgroundHandler);
      FirebaseMessaging.onMessage.listen((_) => onWake());
      FirebaseMessaging.instance.onTokenRefresh.listen(_register);
      _started = true;
    } catch (error) {
      debugPrint('MEYA push: not available ($error).');
    }
  }

  void _listenForWakeUps(VoidCallback onWake) {
    _wakePort?.close();
    IsolateNameServer.removePortNameMapping(mainPortName);
    final port = ReceivePort()
      ..listen((message) {
        // The push handler asks with a reply port and waits for an answer,
        // so it knows this screen is really alive.
        if (message is SendPort) message.send('awake');
        onWake();
      });
    IsolateNameServer.registerPortWithName(port.sendPort, mainPortName);
    _wakePort = port;
  }

  /// Stops forwarding wake-ups to the main screen (it is going away).
  void stop() {
    IsolateNameServer.removePortNameMapping(mainPortName);
    _wakePort?.close();
    _wakePort = null;
  }

  /// Sends this phone's push token to the relay. Call once the relay is
  /// connected (this phone is signed in and its device ID is bound).
  Future<void> registerToken() async {
    if (!_started) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (error) {
      debugPrint('MEYA push: token not registered ($error).');
    }
  }

  Future<void> _register(String token) async {
    final deviceId = await DeviceIdentityService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return;
    await SupabaseRelayTransport.registerPushToken(deviceId, token);
  }
}

/// Handles a push while MEYA's main screen is not running. Runs in its own
/// isolate, so it must not touch the encryption engine or the database
/// connection the app uses.
@pragma('vm:entry-point')
Future<void> meyaPushBackgroundHandler(RemoteMessage message) async {
  // If MEYA's main screen is running, it fetches and notifies by itself.
  // It must answer, though: after Android closes the screen, the port name
  // can outlive it, and a push handed to it would be lost.
  final mainScreen =
      IsolateNameServer.lookupPortByName(MeyaPushService.mainPortName);
  if (mainScreen != null) {
    final reply = ReceivePort();
    mainScreen.send(reply.sendPort);
    final answered = await reply.first
        .timeout(const Duration(seconds: 3), onTimeout: () => null) !=
        null;
    reply.close();
    if (answered) return;
    IsolateNameServer.removePortNameMapping(MeyaPushService.mainPortName);
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await MeyaSettings.instance.load();
    await MeyaSoundSettings.instance.load();
    MeyaStrings.setCurrent(_localeFor(MeyaSettings.instance.language));

    final deviceId = await DeviceIdentityService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return;
    final alerts = await SupabaseRelayTransport.pendingAlerts(deviceId);

    // Each envelope alerts once, even if more pushes arrive before MEYA is
    // opened.
    final preferences = await SharedPreferences.getInstance();
    const seenKey = 'meya_push_alerted_v1';
    final seen = preferences.getStringList(seenKey) ?? <String>[];
    final fresh = [for (final a in alerts) if (!seen.contains(a.$1)) a];
    if (fresh.isEmpty) return;
    await preferences.setStringList(
      seenKey,
      [...seen, ...fresh.map((a) => a.$1)].reversed.take(300).toList().reversed.toList(),
    );

    final contacts = await _contactsFor({for (final a in fresh) a.$2});
    final notifications = MeyaNotifications.instance;
    await notifications.init();

    final shown = <String>{};
    for (final (_, sender, kind) in fresh.reversed) {
      // One notification per sender and kind: the newest.
      if (!shown.add('$sender/$kind')) continue;
      final contact = contacts[sender];
      final name = contact?.$2 ?? 'MEYA';
      switch (kind) {
        case 'call':
          await notifications.showIncomingCall(name, video: false, ongoing: false);
        case 'invite':
          await notifications.showConnectionRequest();
        case 'activity':
          await notifications.showActivity(name);
        default:
          await notifications.showMessage(
            conversationId: contact == null ? 'unknown' : 'direct_${contact.$1}',
            title: name,
            body: tr('New message'),
          );
      }
    }
  } catch (error) {
    debugPrint('MEYA push: background check failed ($error).');
  }
}

Locale _localeFor(String tag) {
  if (tag.isEmpty) return PlatformDispatcher.instance.locale;
  if (tag == 'zh_Hans') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
  }
  final parts = tag.split('_');
  return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(tag);
}

/// Contact ID and name for each sender device, read-only. Returns nothing
/// on any problem (the notification then just says "MEYA").
Future<Map<String, (String, String)>> _contactsFor(Set<String> deviceIds) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'meya.sqlite'));
    if (!file.existsSync()) return {};
    final key = await MeyaDatabaseEncryption.readExistingKey();
    if (key == null) return {};
    final database = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      database.execute(MeyaDatabaseEncryption.keyPragma(key));
      final result = <String, (String, String)>{};
      for (final deviceId in deviceIds) {
        final rows = database.select(
          'SELECT c.contact_id, c.display_name FROM contact_devices d '
          'JOIN contacts c ON c.contact_id = d.contact_id '
          'WHERE d.device_id = ? LIMIT 1',
          [deviceId],
        );
        if (rows.isNotEmpty) {
          result[deviceId] = (
            rows.first['contact_id'] as String,
            rows.first['display_name'] as String,
          );
        }
      }
      return result;
    } finally {
      database.close();
    }
  } catch (error) {
    debugPrint('MEYA push: contact names unavailable ($error).');
    return {};
  }
}
