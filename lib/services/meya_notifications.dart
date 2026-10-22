import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/meya_strings.dart';
import 'meya_sound_settings.dart';

/// Phone notifications: shown by the system with sound and vibration, in
/// the app and when MEYA is in the background.
///
/// Messages and invitations use the notification sound chosen in MEYA's
/// settings (copied to android/app/src/main/res/raw as meya_<id>.mp3). An
/// Android channel's sound cannot change once created, so each sound has
/// its own channel and the others are removed.
///
/// On a locked phone the text is hidden ("Contents hidden") unless the
/// person allows it in the phone's settings.
class MeyaNotifications {
  MeyaNotifications._();

  static final MeyaNotifications instance = MeyaNotifications._();

  static const _callChannelId = 'meya_calls_v1';
  static const _messageChannelPrefix = 'meya_messages_';
  static const _invitationsId = 1;
  static const _callId = 2;

  /// Payloads carried by a notification, given back when it is tapped.
  static const invitationsPayload = 'invitations';
  static const callPayload = 'call';
  static const statusPayload = 'status';
  static String conversationPayload(String conversationId) =>
      'conversation:$conversationId';

  static final _messageVibration = Int64List.fromList([0, 350, 150, 350]);
  static final _callVibration =
      Int64List.fromList([0, 900, 500, 900, 500, 900, 500, 900]);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _messageChannelId;

  /// Called with the payload when a notification is tapped.
  void Function(String payload)? onOpen;

  /// Prepares notifications. Returns the payload of the notification that
  /// launched MEYA, if any.
  Future<String?> init() async {
    if (_ready) return null;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) onOpen?.call(payload);
        },
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp == true
          ? launch?.notificationResponse?.payload
          : null;
    } on MissingPluginException {
      return null; // Tests and platforms without notifications.
    } catch (error) {
      debugPrint('MEYA notifications: not available ($error).');
      return null;
    }
  }

  /// Asks for permission to show notifications (Android 13 and later).
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (error) {
      debugPrint('MEYA notifications: permission request failed ($error).');
    }
  }

  /// Whether the phone lets MEYA show notifications.
  Future<bool> enabled() async {
    if (!_ready) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<String> _messageChannel() async {
    final sound = MeyaSoundSettings.instance.notification.id;
    final id = '$_messageChannelPrefix$sound';
    if (_messageChannelId == id) return id;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Remove the channels of sounds no longer chosen.
      for (final channel in await android.getNotificationChannels() ?? const []) {
        if (channel.id.startsWith(_messageChannelPrefix) && channel.id != id) {
          await android.deleteNotificationChannel(channelId: channel.id);
        }
      }
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          tr('Messages and invitations'),
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('meya_$sound'),
          vibrationPattern: _messageVibration,
          enableVibration: true,
        ),
      );
    }
    _messageChannelId = id;
    return id;
  }

  Future<void> _show(
    int id,
    String title,
    String body,
    String payload, {
    bool call = false,
    bool ongoing = true,
  }) async {
    if (!_ready) return;
    try {
      final details = call
          ? AndroidNotificationDetails(
              _callChannelId,
              tr('Calls'),
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.call,
              visibility: NotificationVisibility.public,
              // The ringtone already plays in MEYA; the phone vibrates.
              playSound: false,
              enableVibration: true,
              vibrationPattern: _callVibration,
              ongoing: ongoing,
              autoCancel: !ongoing,
            )
          : AndroidNotificationDetails(
              await _messageChannel(),
              tr('Messages and invitations'),
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.message,
              visibility: NotificationVisibility.private,
              enableVibration: true,
              vibrationPattern: _messageVibration,
            );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
        payload: payload,
      );
    } catch (error) {
      debugPrint('MEYA notifications: could not show ($error).');
    }
  }

  static int _conversationNotificationId(String conversationId) =>
      // Fixed ids 1 and 2 are taken; stay positive and 32-bit.
      1000 + (conversationId.hashCode & 0x3fffffff);

  /// A new message in [conversationId]; replaces the earlier one there.
  Future<void> showMessage({
    required String conversationId,
    required String title,
    required String body,
  }) =>
      _show(
        _conversationNotificationId(conversationId),
        title,
        body.isEmpty ? tr('New message') : body,
        conversationPayload(conversationId),
      );

  /// Removes the notification of a conversation once it is opened.
  Future<void> clearConversation(String conversationId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _conversationNotificationId(conversationId));
    } catch (_) {
      // Nothing shown.
    }
  }

  Future<void> showInvitation() => _show(
        _invitationsId,
        tr('Invitations'),
        tr('Someone who scanned your QR code wants to connect with you on MEYA.'),
        invitationsPayload,
      );

  /// [name] shared a new status.
  Future<void> showStatus(String name) => _show(
        _conversationNotificationId('status:$name'),
        name,
        tr('Posted a new status'),
        statusPayload,
      );

  /// A reaction or status from [name] that arrived while MEYA was closed
  /// (which of the two is only known once MEYA opens).
  Future<void> showActivity(String name) => _show(
        _conversationNotificationId('activity:$name'),
        name,
        tr('New activity'),
        statusPayload,
      );

  /// A connection request (from a QR code or an invite link) that arrived
  /// while MEYA was closed; it is handled when MEYA opens.
  Future<void> showConnectionRequest() => _show(
        _invitationsId,
        tr('Invitations'),
        tr('Someone wants to connect with you on MEYA. Open MEYA to continue.'),
        invitationsPayload,
      );

  /// Someone connected with one of this phone's invite links.
  Future<void> showConnectedByLink() => _show(
        _invitationsId,
        tr('New contact'),
        tr('Someone connected with your invite link. Compare safety numbers to verify them.'),
        invitationsPayload,
      );

  /// [ongoing] keeps it until the call is answered or ends; a call seen only
  /// through a push (MEYA closed) can be swiped away instead.
  Future<void> showIncomingCall(
    String name, {
    required bool video,
    bool ongoing = true,
  }) =>
      _show(
        _callId,
        name,
        video ? tr('Incoming video call') : tr('Incoming call'),
        callPayload,
        call: true,
        ongoing: ongoing,
      );

  Future<void> cancelCall() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _callId);
    } catch (_) {
      // Nothing shown.
    }
  }

  Future<void> showMissedCall(String name) => _show(
        _callId,
        tr('Missed call from {0}', [name]),
        tr('Tap to open MEYA.'),
        callPayload,
      );
}
