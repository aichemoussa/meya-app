import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/l10n/meya_strings.dart';
import 'package:meya/l10n/translations.dart';

Set<String> placeholders(String text) =>
    RegExp(r'\{\d\}').allMatches(text).map((m) => m.group(0)!).toSet();

void main() {
  test('MEYA offers 20 languages, three of them right to left', () {
    expect(meyaLanguages, hasLength(20));
    expect(
      meyaLanguages.where((l) => l.rtl).map((l) => l.tag),
      unorderedEquals(['ar', 'fa', 'ur']),
    );
    // Every language except English has a full translation table.
    for (final language in meyaLanguages.where((l) => l.tag != 'en')) {
      expect(meyaTranslations.containsKey(language.tag), isTrue,
          reason: language.tag);
    }
  });

  test('every language translates the same strings', () {
    final reference = meyaTranslations['fr']!.keys.toSet();
    meyaTranslations.forEach((tag, table) {
      expect(table.keys.toSet(), reference, reason: tag);
    });
  });

  test('translations keep every placeholder such as {0}', () {
    meyaTranslations.forEach((tag, table) {
      table.forEach((english, translated) {
        expect(
          placeholders(translated),
          placeholders(english),
          reason: '$tag: "$english" → "$translated"',
        );
        expect(translated.trim(), isNotEmpty, reason: '$tag: $english');
      });
    });
  });

  test('placeholders are filled in and unknown text falls back to English', () {
    expect(
      MeyaStrings.translate('fr', 'Version {0}', ['1.0']),
      'Version 1.0',
    );
    expect(
      MeyaStrings.translate('de', '{0} was removed.', ['Ana']),
      'Ana wurde entfernt.',
    );
    expect(MeyaStrings.translate('ja', 'Not a MEYA string', []),
        'Not a MEYA string');
    expect(MeyaStrings.translate('xx', 'Settings', []), 'Settings');
  });

  test('locales map to the right translation table', () {
    expect(MeyaStrings.tagFor(const Locale('pt', 'BR')), 'pt_BR');
    expect(MeyaStrings.tagFor(const Locale('pt', 'PT')), 'pt_PT');
    expect(MeyaStrings.tagFor(const Locale('pt')), 'pt_BR');
    expect(
      MeyaStrings.tagFor(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      'zh_Hans',
    );
    expect(MeyaStrings.tagFor(const Locale('ar')), 'ar');
  });

  testWidgets('context.tr follows the app language', (tester) async {
    late String text;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('es'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            text = context.tr('Settings');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(text, 'Ajustes');
  });
}
