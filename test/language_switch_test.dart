import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/l10n/meya_strings.dart';
import 'package:meya/main.dart';
import 'package:meya/screens/appearance_page.dart';
import 'package:meya/screens/calendar_page.dart';
import 'package:meya/screens/chats_page.dart';
import 'package:meya/screens/invitations_page.dart';
import 'package:meya/screens/people_page.dart';
import 'package:meya/screens/privacy_page.dart';
import 'package:meya/screens/profile_page.dart';
import 'package:meya/screens/status_page.dart';
import 'package:meya/screens/security_page.dart';
import 'package:meya/screens/sounds_page.dart';
import 'package:meya/services/meya_sound_settings.dart';
import 'package:meya/theme/meya_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MeyaDatabase database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MeyaSettings.instance.load();
    await MeyaSoundSettings.instance.load();
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await MeyaSettings.instance.setLanguage('');
    await database.close();
  });

  Future<void> switchThroughAllLanguages(
    WidgetTester tester,
    Widget page,
  ) async {
    await tester.pumpWidget(MeyaApp(database: database));
    await tester.pump();
    meyaNavigatorKey.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await tester.pump(const Duration(milliseconds: 500));

    for (final language in meyaLanguages) {
      await MeyaSettings.instance.setLanguage(language.tag);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: language.tag);
      expect(MeyaStrings.current, language.tag);
    }
  }

  testWidgets('settings survive switching through every language',
      (tester) async {
    await switchThroughAllLanguages(
      tester,
      SettingsPage(name: 'Ana', username: 'ana', database: database),
    );
  });

  testWidgets('appearance page survives every language', (tester) async {
    await switchThroughAllLanguages(tester, const AppearancePage());
  });

  testWidgets('home, chats, calendar and people survive every language',
      (tester) async {
    await switchThroughAllLanguages(
      tester,
      SpacePage(name: 'Ana', username: 'ana', database: database),
    );
    await switchThroughAllLanguages(tester, ChatsPage(database: database));
    await switchThroughAllLanguages(tester, CalendarPage(database: database));
    await switchThroughAllLanguages(tester, PeoplePage(database: database));
    await switchThroughAllLanguages(tester, PrivacyPage(database: database));
    await switchThroughAllLanguages(tester, ProfilePage(database: database));
    await switchThroughAllLanguages(tester, StatusHubPage(database: database));
    await switchThroughAllLanguages(tester, InvitationsPage(database: database));
  });

  testWidgets('security and sounds pages survive every language',
      (tester) async {
    await switchThroughAllLanguages(tester, const SecurityPage());
    await switchThroughAllLanguages(tester, const SoundsPage());
  });
}
