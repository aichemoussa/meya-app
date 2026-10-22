import 'screens/groups_page.dart';
import 'screens/qr_scanner_page.dart';
import 'screens/people_page.dart';
import 'screens/invitations_page.dart';
import 'screens/invite_share.dart';

import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bridge/frb_generated.dart';
import 'database/account_repository.dart';
import 'database/meya_database.dart';
import 'services/meya_account_service.dart';
import 'services/meya_relay_session.dart';
import 'services/meya_connection_service.dart';
import 'services/meya_e2ee.dart';
import 'services/meya_message_service.dart';
import 'screens/create_passcode_page.dart';
import 'screens/enter_passcode_page.dart';
import 'screens/recovery_code_page.dart';
import 'services/account_security_service.dart';
import 'screens/login_page.dart';
import 'screens/privacy_page.dart';
import 'screens/security_page.dart';
import 'screens/appearance_page.dart';
import 'screens/chat_page.dart';
import 'screens/chats_page.dart';
import 'database/contact_repository.dart';
import 'theme/meya_logo.dart';
import 'theme/meya_theme.dart';
import 'legal/meya_legal.dart';
import 'l10n/meya_strings.dart';
import 'services/meya_account_storage.dart';
import 'services/meya_call_service.dart';
import 'services/meya_calendar_service.dart';
import 'services/meya_invite_service.dart';
import 'services/meya_media_settings.dart';
import 'services/meya_notifications.dart';
import 'services/meya_pairing_service.dart';
import 'services/meya_push_service.dart';
import 'services/meya_profile_service.dart';
import 'services/meya_group_service.dart';
import 'services/meya_sound_settings.dart';
import 'services/meya_status_service.dart';
import 'services/profile_photo_service.dart';
import 'services/webrtc_call_engine.dart';
import 'screens/about_meya_page.dart';
import 'screens/account_page.dart';
import 'screens/call_page.dart';
import 'screens/calendar_page.dart';
import 'screens/calls_page.dart';
import 'database/call_log_repository.dart';
import 'screens/profile_page.dart';
import 'screens/sounds_page.dart';
import 'screens/status_page.dart';
import 'screens/storage_media_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await MeyaSettings.instance.load();
  await MeyaMediaSettings.instance.load();
  await MeyaSoundSettings.instance.load();
  await MeyaMessageService.instance.loadSettings();
  LicenseRegistry.addLicense(meyaLicenses);
  final database = MeyaDatabase();
  runApp(MeyaApp(database: database));
}

final GlobalKey<ScaffoldMessengerState> meyaScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> meyaNavigatorKey = GlobalKey<NavigatorState>();

class MeyaApp extends StatelessWidget {
  final MeyaDatabase database;

  const MeyaApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final settings = MeyaSettings.instance;

    // Rebuilds the whole app as soon as an appearance setting changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final reduceMotion = settings.reduceMotion;
        final highContrast = settings.highContrast;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: meyaScaffoldMessengerKey,
          navigatorKey: meyaNavigatorKey,
          title: 'MEYA',
          locale: settings.language.isEmpty
              ? null
              : meyaLanguages
                  .firstWhere(
                    (language) => language.tag == settings.language,
                    orElse: () => meyaLanguages.first,
                  )
                  .locale,
          supportedLocales: [for (final language in meyaLanguages) language.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          themeMode: settings.themeMode,
          theme: buildMeyaTheme(
            highContrast ? MeyaPalette.highContrastLight : MeyaPalette.light,
            reduceMotion: reduceMotion,
          ),
          darkTheme: buildMeyaTheme(
            highContrast ? MeyaPalette.highContrastDark : MeyaPalette.dark,
            reduceMotion: reduceMotion,
          ),
          // Used when high contrast is switched on in the phone's own
          // accessibility settings.
          highContrastTheme: buildMeyaTheme(
            MeyaPalette.highContrastLight,
            reduceMotion: reduceMotion,
          ),
          highContrastDarkTheme: buildMeyaTheme(
            MeyaPalette.highContrastDark,
            reduceMotion: reduceMotion,
          ),
          themeAnimationDuration:
              reduceMotion ? Duration.zero : kThemeAnimationDuration,
          builder: (context, child) {
            MeyaStrings.setCurrent(Localizations.localeOf(context));
            final media = MediaQuery.of(context);
            // MEYA's text size multiplies the phone's own text size.
            final systemScale = media.textScaler.scale(16) / 16;
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(systemScale * settings.textScale),
                disableAnimations: media.disableAnimations || reduceMotion,
                highContrast: media.highContrast || highContrast,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: WelcomePage(database: database),
        );
      },
    );
  }
}

class WelcomePage extends StatefulWidget {
  final MeyaDatabase database;

  const WelcomePage({super.key, required this.database});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  /// Opens the account straight away when the person did not sign out:
  /// the phone closing MEYA in the background is not signing out. With the
  /// app lock on, the passcode is asked first.
  Future<void> _loadAccount() async {
    try {
      final user = await MeyaAccountStorage.loadUser();
      final account = await AccountRepository(widget.database).getActiveAccount();
      if (user != null &&
          account != null &&
          !await MeyaAccountStorage.isSignedOut() &&
          mounted) {
        final space = MaterialPageRoute<void>(
          builder: (_) => SpacePage(
            name: account.name,
            username: account.username,
            database: widget.database,
          ),
        );
        if (!await AccountSecurityService.isAppLockEnabled()) {
          if (mounted) Navigator.pushReplacement(context, space);
          return;
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (lockContext) => EnterPasscodePage(
              database: widget.database,
              onUnlocked: () async =>
                  Navigator.pushReplacement(lockContext, space),
              onErased: () => Navigator.pushAndRemoveUntil(
                lockContext,
                MaterialPageRoute<void>(
                  builder: (_) => WelcomePage(database: widget.database),
                ),
                (route) => false,
              ),
            ),
          ),
        );
        return;
      }
    } catch (error) {
      debugPrint('MEYA: could not reopen the account ($error).');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  void _createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupPage(database: widget.database),
      ),
    );
  }

  void _login() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          database: widget.database,
          onUnlocked: (account) async {
            await MeyaAccountStorage.saveUser(
              MeyaUser(
                userId: account.accountId,
                name: account.name,
                username: account.username,
              ),
            );

            if (!context.mounted) {
              return;
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => SpacePage(
                  name: account.name,
                  username: account.username,
                  database: widget.database,
                ),
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usually only for a moment, while the account is reopened.
    if (_loading) {
      return const Scaffold(body: Center(child: MeyaLogo(size: 96)));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const MeyaLogo(size: 96),
              const SizedBox(height: 28),
              Text(
                'MEYA',
                style: TextStyle(
                  color: context.meya.navy,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Private connections.\nSimply yours.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 22,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('A simple, private space for the people who matter to you.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.meya.muted, fontSize: 16, height: 1.5),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _createAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('Get Started'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading ? null : _login,
                child: Text(
                  context.tr('Already have a MEYA account? Log in'),
                  style: TextStyle(
                    color: context.meya.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  final MeyaDatabase database;

  const ProfileSetupPage({super.key, required this.database});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _checkingUsername = false;
  bool _usernameTaken = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim().toLowerCase();

    if (username.length < 3) {
      if (mounted) {
        setState(() {
          _usernameTaken = false;
        });
      }
      return;
    }

    setState(() {
      _checkingUsername = true;
    });

    final repository = AccountRepository(widget.database);
    final existing = await repository.getAccountByUsername(username);

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingUsername = false;
      _usernameTaken = existing != null;
    });
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim().toLowerCase();
    final repository = AccountRepository(widget.database);
    final existing = await repository.getAccountByUsername(username);

    if (!mounted) {
      return;
    }

    if (existing != null) {
      setState(() {
        _usernameTaken = true;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePasscodePage(
          onPasscodeCreated: (_) async {
            final accountService = MeyaAccountService(repository);
            final account = await accountService.createAccount(
              name: name,
              username: username,
            );

            await MeyaAccountStorage.saveUser(
              MeyaUser(
                userId: account.accountId,
                name: account.name,
                username: account.username,
              ),
            );

            // MEYA cannot reset a forgotten passcode by email or SMS, so the
            // person gets a recovery code to write down before going on.
            final recoveryCode = await AccountSecurityService.createRecoveryCode();

            if (!context.mounted) {
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RecoveryCodePage(
                  code: recoveryCode,
                  onDone: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpacePage(
                        name: account.name,
                        username: account.username,
                        database: widget.database,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Create your MEYA profile'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Text(
                context.tr('Your name'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: context.tr('Enter your name')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('Please enter your name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('MEYA ID'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onChanged: (_) => _checkUsername(),
                decoration: InputDecoration(
                  hintText: context.tr('Choose your MEYA ID'),
                  prefixText: '@',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('Please choose a MEYA ID');
                  }
                  if (value.trim().length < 3) {
                    return context.tr('Use at least 3 characters');
                  }
                  if (_usernameTaken) {
                    return context.tr('This MEYA ID is already used on this device');
                  }
                  return null;
                },
              ),
              if (_checkingUsername) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('Checking your MEYA ID…'),
                  style: TextStyle(color: context.meya.muted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr('Your MEYA ID identifies you inside your private MEYA space.'),
                style: TextStyle(color: context.meya.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _checkingUsername ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('Continue'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpacePage extends StatefulWidget {
  final String name;
  final String username;
  final MeyaDatabase database;

  const SpacePage({
    super.key,
    required this.name,
    required this.username,
    required this.database,
  });

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage>
    with WidgetsBindingObserver {
  final MeyaRelaySession _relaySession = MeyaRelaySession.instance;
  final List<StreamSubscription<void>> _subscriptions = [];

  late String _name = widget.name;
  late String _username = widget.username;
  String? _photoPath;
  int _photoVersion = 0;
  List<CalendarEvent> _upcoming = [];
  int _statusCount = 0;

  // App lock: when the person left MEYA, and whether the lock is switched on
  // (read when they leave, so it is ready the moment they come back).
  DateTime? _leftAt;
  bool _appLockOn = false;
  bool _lockShowing = false;

  @override
  void initState() {
    super.initState();
    final messages = MeyaMessageService.instance;
    messages.configure(database: widget.database);
    MeyaStatusService.instance.configure(database: widget.database);
    MeyaProfileService.instance.configure(database: widget.database);

    messages.setSilentHandler('status', MeyaStatusService.instance.handleIncoming);
    messages.setSilentHandler(
      'status_clear',
      MeyaStatusService.instance.handleIncoming,
    );
    messages.setSilentHandler('profile', MeyaProfileService.instance.handleIncoming);
    // The person who accepted a connection shares their profile as soon as
    // the encrypted session is confirmed.
    messages.setSilentHandler('session_init', (contact, deviceId, _) async {
      // People met through a group get no profile, only group messages.
      if (contact.trustState == 'trusted') {
        await MeyaProfileService.instance.share(only: contact);
      }
      await MeyaGroupService.instance.sessionStarted(deviceId);
    });
    final groups = MeyaGroupService.instance..configure(database: widget.database);
    for (final kind in MeyaGroupService.kinds) {
      messages.setSilentHandler(kind, groups.handleIncoming);
    }
    messages.setCallPlanHandler(MeyaCalendarService.instance.handleIncoming);

    final calls = MeyaCallService.instance;
    calls.configure(
      send: messages.sendSilent,
      createEngine: WebRtcCallEngine.new,
    );
    calls.onIncoming = _showIncomingCall;
    calls.onMissed = _showMissedCall;
    calls.onRecord = (record) => unawaited(
          CallLogRepository(widget.database)
              .add(
                callId: record.callId,
                contactId: record.contact.contactId,
                outgoing: record.outgoing,
                video: record.video,
                startedAt: record.startedAt,
                durationSeconds: record.duration.inSeconds,
                outcome: record.outcome,
              )
              .catchError((Object error) {
            debugPrint('MEYA call log: not saved ($error).');
          }),
        );
    for (final kind in const ['call_offer', 'call_answer', 'call_end']) {
      messages.setSilentHandler(kind, calls.handleSignal);
    }

    MeyaConnectionService.instance.configure(
      database: widget.database,
      onIncomingRequest: _showIncomingRequestNotification,
      onConnectedByLink: _showConnectedByLink,
      onSecurityWarning: _showSecurityWarning,
      onChat: messages.handleIncoming,
      onBlob: messages.handleBlobChunk,
      onSessionStarted: _onSessionStarted,
    );
    _relaySession.addMessageListener(_handleRelayMessage);
    _relaySession.addErrorListener(_handleRelayError);
    _relaySession.addConnectedListener(_onRelayConnected);
    WidgetsBinding.instance.addObserver(this);

    _subscriptions
      ..add(MeyaCalendarService.instance.changes.listen((_) => _loadOverview()))
      ..add(MeyaStatusService.instance.changes.listen((_) => _loadOverview()))
      ..add(messages.incoming.listen((message) async {
        if (MeyaCallService.instance.inCall) return;
        final onScreen = WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed;
        if (onScreen && message.conversationId == messages.activeConversationId) {
          return;
        }
        if (await messages.isMuted(message.conversationId)) return;
        final notifications = MeyaNotifications.instance;
        if (await notifications.enabled()) {
          // The phone plays the chosen sound and vibrates.
          await notifications.showMessage(
            conversationId: message.conversationId,
            title: message.title,
            body: message.body,
          );
        } else {
          // Notifications are switched off for MEYA: sound and buzz here.
          MeyaSoundSettings.instance.playNotification();
          unawaited(HapticFeedback.vibrate());
        }
      }));
    _subscriptions.add(
      MeyaStatusService.instance.posted.listen((contact) async {
        if (MeyaCallService.instance.inCall) return;
        final conversationId = 'direct_${contact.contactId}';
        if (await messages.isMuted(conversationId)) return;
        await MeyaNotifications.instance.showStatus(contact.displayName);
      }),
    );
    calls.addListener(_onCallChanged);

    unawaited(_startNotifications());
    unawaited(MeyaPushService.instance.start(
      // A push while this screen is up: reconnect and fetch as usual.
      onWake: () => unawaited(_relaySession.wake().catchError(
        (Object error) => debugPrint('MEYA push: reconnect failed ($error).'),
      )),
    ));
    unawaited(_startInviteLinks());
    unawaited(_startRelaySession());
    unawaited(MeyaMediaSettings.instance.applyKeepMedia());
    _loadOverview();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerRecoveryCode());
  }

  /// Invite links already handled in this run (the launch link is offered
  /// again whenever this screen is rebuilt, e.g. after the app lock).
  static final Set<String> _handledInvites = {};

  Future<void> _startInviteLinks() async {
    final links = AppLinks();
    _subscriptions.add(
      links.uriLinkStream.listen((uri) => _openInvite(uri.toString())),
    );
    try {
      final initial = await links.getInitialLink();
      if (initial != null) await _openInvite(initial.toString());
    } catch (error) {
      debugPrint('MEYA invite: launch link unavailable ($error).');
    }
  }

  /// Connects with the person who sent an invite link, after asking.
  Future<void> _openInvite(String link) async {
    final invite = MeyaInviteService.parse(link);
    if (invite == null || !mounted) return;
    if (!_handledInvites.add(invite.token)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('Connect on MEYA?')),
        content: Text(dialogContext.tr(
          'You opened an invite link. Connect with the person who sent it? Your encrypted chat opens as soon as their phone receives your request.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('Connect')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = meyaScaffoldMessengerKey.currentState;
    try {
      await MeyaPairingService.instance.startConnection(
        database: widget.database,
        recipientIdentityId: invite.identityId,
        recipientIdentityPublicKey: invite.identityPublicKey,
        recipientDeviceId: invite.deviceId,
        inviteToken: invite.token,
      );
      await MeyaInviteService.instance.markConnectedByLink(invite.identityId);
      messenger?.showSnackBar(SnackBar(
        content: Text(tr('Request sent. Your chat appears as soon as their phone receives it.')),
      ));
    } on PairingException catch (error) {
      messenger?.showSnackBar(SnackBar(
        content: Text(tr(error.message, [?error.detail])),
      ));
    }
  }

  void _showConnectedByLink() {
    unawaited(MeyaNotifications.instance.showConnectedByLink());
    meyaScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(tr('Someone connected with your invite link. Compare safety numbers to verify them.')),
    ));
  }

  Future<void> _startNotifications() async {
    final notifications = MeyaNotifications.instance
      ..onOpen = _openFromNotification;
    final launchedWith = await notifications.init();
    await notifications.requestPermission();
    if (launchedWith != null) _openFromNotification(launchedWith);
    await _askToStayAwake();
  }

  static const _battery = MethodChannel('meya/battery');
  static const _batteryAskedKey = 'meya_battery_asked_at';

  /// Android puts apps to sleep to save battery, which cuts MEYA's
  /// connection: messages and calls then wait until MEYA is opened. Asks
  /// (at most every 3 days) to be left out, through Android's own dialog.
  Future<void> _askToStayAwake() async {
    if (!Platform.isAndroid) return;
    try {
      if (await _battery.invokeMethod<bool>('isExempt') == true) return;
      final preferences = await SharedPreferences.getInstance();
      final askedAt = preferences.getInt(_batteryAskedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - askedAt < const Duration(days: 3).inMilliseconds) return;
      await preferences.setInt(_batteryAskedKey, now);
      if (!mounted) return;
      final allow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('Keep messages coming')),
          content: Text(dialogContext.tr(
            'So that messages and calls reach you while MEYA is in the background or your phone is locked, allow MEYA to run without battery restrictions.',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('Not now')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('Allow')),
            ),
          ],
        ),
      );
      if (allow == true) await _battery.invokeMethod<bool>('requestExemption');
    } catch (error) {
      debugPrint('MEYA battery: could not ask ($error).');
    }
  }

  /// Opens what a tapped notification is about.
  Future<void> _openFromNotification(String payload) async {
    final navigator = meyaNavigatorKey.currentState;
    if (navigator == null) return;
    if (payload == MeyaNotifications.invitationsPayload) {
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => InvitationsPage(database: widget.database),
      ));
      return;
    }
    const prefix = 'conversation:';
    if (!payload.startsWith(prefix)) return;
    final conversationId = payload.substring(prefix.length);
    if (conversationId.startsWith('group_')) {
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => GroupChatPage(
          database: widget.database,
          groupId: conversationId.substring('group_'.length),
        ),
      ));
      return;
    }
    if (conversationId.startsWith('direct_')) {
      final contact = await ContactRepository(widget.database)
          .getContactById(conversationId.substring('direct_'.length));
      if (contact == null) return;
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => ChatPage(database: widget.database, contact: contact),
      ));
    }
  }

  /// The person who scanned the QR code starts the session, then shares
  /// their profile with the new contact.
  Future<void> _onSessionStarted(String deviceId) async {
    await MeyaMessageService.instance.sendSessionInit(deviceId);
    final contact =
        await ContactRepository(widget.database).getContactByDeviceId(deviceId);
    if (contact != null) {
      await MeyaProfileService.instance.share(only: contact);
    }
  }

  Future<void> _loadOverview() async {
    final user = await MeyaAccountStorage.loadUser();
    final photo = await ProfilePhotoService.getPhotoPath();
    final upcoming = await MeyaCalendarService.instance.upcoming(limit: 3);
    final statuses = await MeyaStatusService.instance.contactStatuses();
    if (!mounted) return;
    if (photo != null) await FileImage(File(photo)).evict();
    if (!mounted) return;
    setState(() {
      if (user != null) {
        _name = user.name;
        _username = user.username;
      }
      _photoPath = photo;
      _photoVersion++;
      _upcoming = upcoming;
      _statusCount = statuses.length;
    });
  }

  /// Relay messages are handled one at a time, in arrival order, so the
  /// encryption sessions always advance in a consistent order.
  Future<void> _relayQueue = Future.value();

  Future<void> _startRelaySession() async {
    // Open the encryption engine first: incoming messages need it.
    try {
      final identityKey = await MeyaE2ee.instance.open();
      final accounts = AccountRepository(widget.database);
      final account = await accounts.getActiveAccount();
      if (account != null && account.identityPublicKey != identityKey) {
        await accounts.updateIdentityPublicKey(
          accountId: account.accountId,
          identityPublicKey: identityKey,
        );
      }
    } catch (error) {
      _showSecurityWarning(context.tr('MEYA encryption could not start: {0}', [error]));
      return;
    }

    try {
      await _relaySession.keepConnected();
    } catch (error) {
      _handleRelayError(error);
    }
  }

  void _handleRelayMessage(Map<String, dynamic> message) {
    _relayQueue = _relayQueue.then(
      (_) => MeyaConnectionService.instance
          .handleRelayMessage(message)
          .catchError((Object error) {
        debugPrint('MEYA relay message handling failed: $error');
      }),
    );
  }

  /// Sends whatever waited while offline.
  void _onRelayConnected() {
    if (_offlineNotified) {
      _offlineNotified = false;
      meyaScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tr('Back online.'))));
    }
    unawaited(MeyaPushService.instance.registerToken());
    unawaited(MeyaMessageService.instance.retryPending());
    // A photo or name changed while offline, or sharing it failed.
    unawaited(
      MeyaProfileService.instance.shareIfChanged().catchError((Object error) {
        debugPrint('MEYA profile: sharing failed ($error).');
      }),
    );
    // Call servers ready before the first call, so it starts sooner.
    unawaited(_relaySession.prefetchIceServers());
  }

  bool _offlineNotified = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
      AccountSecurityService.isAppLockEnabled().then((on) => _appLockOn = on);
    }
    if (state == AppLifecycleState.resumed) {
      // After a longer time away the connection may have died unnoticed:
      // renew it and fetch what is waiting.
      final away = _leftAt == null
          ? Duration.zero
          : DateTime.now().difference(_leftAt!);
      final reconnect = away > const Duration(seconds: 20)
          ? _relaySession.wake()
          : _relaySession.keepConnected();
      unawaited(
        reconnect.catchError((Object error) {
          debugPrint('MEYA relay: reconnect on resume failed ($error).');
        }),
      );
      _lockIfAway();
    }
  }

  /// Asks for the passcode when the person comes back after a while.
  Future<void> _lockIfAway() async {
    final left = _leftAt;
    _leftAt = null;
    if (left == null || !_appLockOn || _lockShowing || !mounted) return;
    if (DateTime.now().difference(left) < AccountSecurityService.appLockGrace) {
      return;
    }
    final navigator = meyaNavigatorKey.currentState;
    if (navigator == null) return;
    _lockShowing = true;
    await navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (lockContext) => PopScope(
          canPop: false,
          child: EnterPasscodePage(
            database: widget.database,
            onUnlocked: () async => Navigator.of(lockContext).pop(),
            onErased: () => navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => WelcomePage(database: widget.database),
              ),
              (route) => false,
            ),
          ),
        ),
      ),
    );
    _lockShowing = false;
  }

  /// Accounts made before recovery codes existed are asked once per session.
  Future<void> _offerRecoveryCode() async {
    if (await AccountSecurityService.hasRecoveryCode() || !mounted) return;
    final setUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('Set up a recovery code')),
        content: Text(
          dialogContext.tr('If you forget your passcode, a recovery code is the only way to keep your account. It takes a minute.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('Set up now')),
          ),
        ],
      ),
    );
    if (setUp != true || !mounted) return;
    final code = await AccountSecurityService.createRecoveryCode();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (routeContext) => RecoveryCodePage(
          code: code,
          onDone: () => Navigator.pop(routeContext),
        ),
      ),
    );
  }

  /// Says once that MEYA is offline; it keeps reconnecting by itself and
  /// sends queued messages when it is back.
  void _handleRelayError(Object error) {
    debugPrint('MEYA relay: $error');
    if (_offlineNotified || _relaySession.isConnected) return;
    _offlineNotified = true;
    meyaScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          tr('You are offline. Messages will be sent when MEYA reconnects.'),
        ),
      ),
    );
  }

  void _showIncomingCall() {
    // Ready by the time the call is answered.
    unawaited(_relaySession.prefetchIceServers());
    final navigator = meyaNavigatorKey.currentState;
    if (navigator == null) return;
    var showing = false;
    navigator.popUntil((route) {
      showing = route.settings.name == CallPage.routeName;
      return true;
    });
    if (!showing) navigator.push(CallPage.route());
  }

  void _showMissedCall(Contact contact) {
    unawaited(MeyaNotifications.instance.showMissedCall(contact.displayName));
    meyaScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(tr('Missed call from {0}', [contact.displayName])),
      ),
    );
  }

  void _showSecurityWarning(String message) {
    meyaScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void _showIncomingRequestNotification() {
    unawaited(MeyaNotifications.instance.showInvitation());
    meyaScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(context.tr('Someone who scanned your QR code wants to connect with you on MEYA.')),
        action: SnackBarAction(
          label: context.tr('Open'),
          onPressed: () {
            meyaNavigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => InvitationsPage(database: widget.database),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _relaySession.removeMessageListener(_handleRelayMessage);
    _relaySession.removeErrorListener(_handleRelayError);
    _relaySession.removeConnectedListener(_onRelayConnected);
    MeyaCallService.instance.removeListener(_onCallChanged);
    MeyaPushService.instance.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Keeps the incoming-call notification in step with the call: shown
  /// while it rings, gone once it is answered, declined or ends.
  void _onCallChanged() {
    final calls = MeyaCallService.instance;
    final contact = calls.contact;
    if (calls.phase == CallPhase.incoming && contact != null) {
      unawaited(MeyaNotifications.instance
          .showIncomingCall(contact.displayName, video: calls.video));
    } else {
      unawaited(MeyaNotifications.instance.cancelCall());
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    await _loadOverview();
  }

  /// The bottom bar's tab: Chats, News, Groups, Calls, Your Space.
  int _tab = 0;

  void _selectTab(int tab) {
    setState(() => _tab = tab);
    if (tab == 4) _loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    // Each tab opens fresh, so it always shows the latest.
    final page = switch (_tab) {
      0 => ChatsPage(
          database: widget.database,
          onNewChat: (context) => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => NewChatPage(database: widget.database),
            ),
          ),
        ),
      1 => StatusHubPage(database: widget.database),
      2 => GroupsPage(database: widget.database),
      3 => CallsPage(database: widget.database),
      _ => _space(context),
    };
    return PopScope(
      // Back goes to Chats first, then leaves MEYA.
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(0);
      },
      child: Scaffold(
        body: KeyedSubtree(key: ValueKey(_tab), child: page),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: context.tr('Chats'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.dynamic_feed_outlined),
              selectedIcon: const Icon(Icons.dynamic_feed),
              label: context.tr('News'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: const Icon(Icons.group),
              label: context.tr('Groups'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.call_outlined),
              selectedIcon: const Icon(Icons.call),
              label: context.tr('Calls'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.tr('Your Space'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _space(BuildContext context) {
    final colors = context.meya;
    final photoPath = _photoPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Your Space')),
        actions: [
          IconButton(
            tooltip: context.tr('Settings'),
            onPressed: () => _open(
              SettingsPage(
                name: _name,
                username: _username,
                database: widget.database,
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Material(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(ProfilePage(database: widget.database)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        key: ValueKey(_photoVersion),
                        radius: 28,
                        backgroundColor: colors.navy,
                        foregroundImage:
                            photoPath == null ? null : FileImage(File(photoPath)),
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'M',
                          style: TextStyle(
                            color: colors.onNavy,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@$_username',
                              style: TextStyle(color: colors.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.muted),
                    ],
                  ),
                ),
              ),
            ),
            if (_upcoming.isNotEmpty) ...[
              const SizedBox(height: 16),
              Material(
                color: colors.navy,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _open(CalendarPage(database: widget.database)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_outlined, color: colors.onNavy),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Next: {0}', [_upcoming.first.plan.title]),
                                style: TextStyle(
                                  color: colors.onNavy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatCallTime(
                                  context,
                                  _upcoming.first.start,
                                  _upcoming.first.plan.durationMinutes,
                                ),
                                style: TextStyle(color: colors.onNavy),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              context.tr('Your Space'),
              style: TextStyle(
                color: colors.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Your people. Your conversations. Your privacy.'),
              style: TextStyle(color: colors.muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 28),
            _SpaceItem(
              icon: Icons.chat_bubble_outline,
              title: context.tr('Chats'),
              subtitle: context.tr('Your conversations'),
              onTap: () => _open(
                ChatsPage(
                  database: widget.database,
                  onNewChat: (context) => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NewChatPage(database: widget.database),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SpaceItem(
              icon: Icons.auto_awesome_outlined,
              title: context.tr('Status'),
              subtitle: _statusCount == 0
                  ? context.tr('Share text, a photo or a video')
                  : _statusCount == 1
                      ? context.tr('1 new status from your connections')
                      : context.tr('{0} statuses from your connections', [_statusCount]),
              onTap: () => _open(StatusHubPage(database: widget.database)),
            ),
            const SizedBox(height: 12),
            _SpaceItem(
              icon: Icons.calendar_month_outlined,
              title: context.tr('Calendar'),
              subtitle: _upcoming.isEmpty
                  ? context.tr('Plan calls with your people')
                  : _upcoming.length == 1
                      ? context.tr('1 upcoming call')
                      : context.tr('{0} upcoming calls', [_upcoming.length]),
              onTap: () => _open(CalendarPage(database: widget.database)),
            ),
            const SizedBox(height: 12),
            _SpaceItem(
              icon: Icons.people_outline,
              title: context.tr('People'),
              subtitle: context.tr('Your MEYA connections'),
              onTap: () => _open(PeoplePage(database: widget.database)),
            ),
            const SizedBox(height: 12),
            _SpaceItem(
              icon: Icons.group_outlined,
              title: context.tr('Groups'),
              subtitle: context.tr('Your private groups'),
              onTap: () => _open(GroupsPage(database: widget.database)),
            ),
            const SizedBox(height: 12),
            _SpaceItem(
              icon: Icons.person_add_outlined,
              title: context.tr('Invitations'),
              subtitle: context.tr('Connection requests from people you trust'),
              onTap: () => _open(InvitationsPage(database: widget.database)),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final String name;
  final String username;
  final MeyaDatabase database;

  const SettingsPage({
    super.key,
    required this.name,
    required this.username,
    required this.database,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Signs out (or finishes deleting the account) and returns to Welcome.
  Future<void> _signOut(BuildContext context) async {
    await MeyaAccountStorage.setSignedOut(true);
    try {
      await MeyaRelaySession.instance.stop();
    } catch (_) {
      // Already disconnected.
    }
    meyaNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => WelcomePage(database: database)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            _SettingsSection(
              title: context.tr('Profile'),
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: context.tr('Profile'),
                  subtitle: context.tr('Photo, name, MEYA ID and About'),
                  onTap: () => _push(context, ProfilePage(database: database)),
                ),
                const SizedBox(height: 10),
                _SettingsItem(
                  icon: Icons.auto_awesome_outlined,
                  title: context.tr('Status'),
                  subtitle: context.tr('Text, photo or video for your connections'),
                  onTap: () => _push(context, StatusHubPage(database: database)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Privacy'),
              items: [
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: context.tr('Privacy'),
                  subtitle: context.tr('Discovery, presence and connection controls'),
                  onTap: () => _push(context, PrivacyPage(database: database)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Security'),
              items: [
                _SettingsItem(
                  icon: Icons.shield_outlined,
                  title: context.tr('Security'),
                  subtitle: context.tr('PIN, app lock and trusted devices'),
                  onTap: () => _push(context, const SecurityPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Appearance & Accessibility'),
              items: [
                _SettingsItem(
                  icon: Icons.accessibility_new_outlined,
                  title: context.tr('Appearance & Accessibility'),
                  subtitle: context.tr('Theme, language, text size and accessibility'),
                  onTap: () => _push(context, const AppearancePage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Sounds'),
              items: [
                _SettingsItem(
                  icon: Icons.music_note_outlined,
                  title: context.tr('Sounds'),
                  subtitle: context.tr('Call ringtone and notification sound'),
                  onTap: () => _push(context, const SoundsPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Storage & Media'),
              items: [
                _SettingsItem(
                  icon: Icons.storage_outlined,
                  title: context.tr('Storage & Media'),
                  subtitle: context.tr('Storage use, photo quality and keeping media'),
                  onTap: () => _push(context, const StorageMediaPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Account'),
              items: [
                _SettingsItem(
                  icon: Icons.manage_accounts_outlined,
                  title: context.tr('Account'),
                  subtitle: context.tr('Account details, sign out and deletion'),
                  onTap: () => _push(
                    context,
                    AccountPage(
                      database: database,
                      onSignedOut: () => _signOut(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: context.tr('Legal & About'),
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: context.tr('About MEYA'),
                  subtitle: context.tr('Privacy, terms, accessibility and licences'),
                  onTap: () => _push(context, const AboutMeyaPage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewChatPage extends StatefulWidget {
  final MeyaDatabase database;

  const NewChatPage({super.key, required this.database});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await _loadTrustedContacts(widget.database);
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _scan() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MeyaQrScannerPage(database: widget.database),
      ),
    );
    await _load();
  }

  void _openChat(Contact contact) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(database: widget.database, contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('New Chat'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ContactRow(
              icon: Icons.qr_code_scanner,
              title: context.tr('Add someone new'),
              subtitle: context.tr('Scan their MEYA QR code in person'),
              onTap: _scan,
            ),
            const SizedBox(height: 8),
            _ContactRow(
              icon: Icons.share_outlined,
              title: context.tr('Share an invite link'),
              onTap: () => shareInviteLink(context, widget.database),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                context.tr('Choose a person'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.tr('You have no MEYA contacts yet. Scan someone\'s QR code to add them.'),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              ..._contacts.map(
                (contact) => _ContactRow(
                  contact: contact,
                  subtitle: context.tr('Trusted connection'),
                  onTap: () => _openChat(contact),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<List<Contact>> _loadTrustedContacts(MeyaDatabase database) async {
  final account = await AccountRepository(database).getActiveAccount();
  return ContactRepository(database).getTrustedContacts(
    excludeIdentityId: account?.identityId ?? account?.accountId,
  );
}

/// One tappable row: either a contact (initial avatar) or an action (icon).
class _ContactRow extends StatelessWidget {
  final Contact? contact;
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ContactRow({
    this.contact,
    this.icon,
    this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = title ??
        ((contact?.displayName.trim().isEmpty ?? true)
            ? context.tr('MEYA contact')
            : contact!.displayName.trim());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            child: icon != null
                ? Icon(icon, color: colorScheme.primary)
                : Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: context.meya.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.meya.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.meya.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: context.meya.navy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.meya.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.meya.muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.meya.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SpaceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.meya.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.meya.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: context.meya.navy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.meya.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: context.meya.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.meya.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturePage extends StatelessWidget {
  final String title;
  final String description;

  const FeaturePage({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: context.meya.card,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.construction_outlined,
                    color: context.meya.navy,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.text,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
