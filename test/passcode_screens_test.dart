import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/screens/enter_passcode_page.dart';
import 'package:meya/screens/recovery_code_page.dart';
import 'package:meya/screens/security_page.dart';
import 'package:meya/services/account_security_service.dart';
import 'package:meya/theme/meya_theme.dart';

Widget app(Widget home) => MaterialApp(
      theme: buildMeyaTheme(MeyaPalette.light),
      home: home,
    );

/// Lets storage and hashing finish, which happen across several microtasks.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  late MeyaDatabase database;
  late DateTime clock;
  var unlocked = 0;
  var erased = 0;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AccountSecurityService.iterations = 50;
    AccountSecurityService.useIsolate = false;
    clock = DateTime(2026, 10, 15, 12);
    AccountSecurityService.now = () => clock;
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    unlocked = 0;
    erased = 0;
  });

  tearDown(() async {
    AccountSecurityService.iterations = 100000;
    AccountSecurityService.useIsolate = true;
    AccountSecurityService.now = DateTime.now;
    await database.close();
  });

  Widget unlockScreen({bool withDatabase = true}) => app(
        EnterPasscodePage(
          database: withDatabase ? database : null,
          onUnlocked: () async => unlocked++,
          onErased: () => erased++,
        ),
      );

  Future<void> tryPasscode(WidgetTester tester, String passcode) async {
    await typeInto(tester, find.byType(TextField), passcode);
    await tester.tap(find.text('Unlock'));
    await settle(tester);
  }

  testWidgets('the right passcode unlocks; a wrong one shows an error',
      (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(unlockScreen());
    await settle(tester);

    await tryPasscode(tester, '1111');
    expect(find.text('Incorrect passcode. Try again.'), findsOneWidget);
    expect(unlocked, 0);

    await tryPasscode(tester, '4821');
    expect(unlocked, 1);
  });

  testWidgets('five wrong tries lock the screen with a countdown that frees '
      'it by itself', (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(unlockScreen());
    await settle(tester);

    for (var i = 0; i < 5; i++) {
      await tryPasscode(tester, '0000');
    }
    expect(find.textContaining('Too many wrong tries. Try again in 0:'),
        findsOneWidget);
    final unlock = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(unlock.onPressed, isNull, reason: 'button disabled while locked');

    // Even the right passcode is refused during the wait.
    expect(unlocked, 0);

    clock = clock.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    await settle(tester);
    expect(find.textContaining('Too many wrong tries'), findsNothing);
    await tryPasscode(tester, '4821');
    expect(unlocked, 1);
  });

  testWidgets('"Forgot passcode?" is offered only where it can work',
      (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(unlockScreen(withDatabase: false));
    await settle(tester);
    expect(find.text('Forgot passcode?'), findsNothing);

    await tester.pumpWidget(unlockScreen());
    await settle(tester);
    expect(find.text('Forgot passcode?'), findsOneWidget);
  });

  testWidgets('forgot passcode: the recovery code resets it, shows a new '
      'code, and the old passcode stops working', (tester) async {
    await AccountSecurityService.savePasscode('4821');
    final oldCode = await AccountSecurityService.createRecoveryCode();

    await tester.pumpWidget(unlockScreen());
    await settle(tester);

    await tester.tap(find.text('Forgot passcode?'));
    await settle(tester);
    expect(find.text('Forgot your passcode?'), findsOneWidget);
    expect(find.text('Erase everything and start over'), findsOneWidget);

    await tester.tap(find.text('Use my recovery code'));
    await settle(tester);

    // A wrong code is refused.
    await typeInto(tester, find.byType(TextField), 'AAAA-AAAA-AAAA-AAAA-AAAA-AAAA');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('That recovery code is not right.'), findsOneWidget);

    // The right code, typed in lower case with spaces, is accepted.
    await typeInto(tester, find.byType(TextField),
        oldCode.toLowerCase().replaceAll('-', ' '));
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Choose a new passcode'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await typeInto(tester, fields.at(0), '9753');
    await typeInto(tester, fields.at(1), '9753');
    await tester.tap(find.text('Save passcode'));
    await settle(tester);

    // A new recovery code is shown once, and cannot be skipped.
    expect(find.byType(RecoveryCodePage), findsOneWidget);
    final next = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));
    expect(next.onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Back on the unlock screen, with the new passcode in force.
    expect(find.text('Passcode changed. Enter it to unlock.'), findsOneWidget);
    await tryPasscode(tester, '4821');
    expect(unlocked, 0, reason: 'the old passcode no longer works');
    await tryPasscode(tester, '9753');
    expect(unlocked, 1);

    // The code that was just used stops working.
    expect((await AccountSecurityService.checkRecoveryCode(oldCode)).ok, isFalse);
  });

  testWidgets('erase asks first and does nothing if cancelled', (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(unlockScreen());
    await settle(tester);
    await tester.tap(find.text('Forgot passcode?'));
    await settle(tester);

    await tester.tap(find.text('Erase everything and start over'));
    await settle(tester);
    expect(find.text('Delete your MEYA account from this phone?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(erased, 0);
    expect(await AccountSecurityService.hasPasscode(), isTrue);
  });

  testWidgets('with no recovery code set up, the screen says so',
      (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(unlockScreen());
    await settle(tester);
    await tester.tap(find.text('Forgot passcode?'));
    await settle(tester);
    await tester.tap(find.text('Use my recovery code'));
    await settle(tester);
    expect(find.textContaining('No recovery code was set up'), findsOneWidget);
  });

  testWidgets('change passcode needs the current one', (tester) async {
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(app(const ChangePasscodePage()));
    await settle(tester);

    final fields = find.byType(TextFormField);
    await typeInto(tester, fields.at(0), '0000');
    await typeInto(tester, fields.at(1), '5566');
    await typeInto(tester, fields.at(2), '5566');
    await tester.tap(find.text('Save passcode'));
    await settle(tester);
    expect(find.text('Your current passcode is not right.'), findsOneWidget);
    expect((await AccountSecurityService.checkPasscode('4821')).ok, isTrue);

    await typeInto(tester, fields.at(0), '4821');
    await tester.tap(find.text('Save passcode'));
    await settle(tester);
    expect((await AccountSecurityService.checkPasscode('5566')).ok, isTrue);
    expect((await AccountSecurityService.checkPasscode('4821')).ok, isFalse);
  });

  testWidgets('security settings: app lock is remembered and the PIN screen '
      'is gone', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AccountSecurityService.savePasscode('4821');
    await tester.pumpWidget(app(const SecurityPage()));
    await settle(tester);

    expect(find.text('Change passcode'), findsOneWidget);
    expect(find.text('Change security PIN'), findsNothing);
    expect(find.text('Recovery code'), findsOneWidget);
    expect(find.textContaining('Not set up'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);

    expect(await AccountSecurityService.isAppLockEnabled(), isFalse);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(await AccountSecurityService.isAppLockEnabled(), isTrue);
  });
}
