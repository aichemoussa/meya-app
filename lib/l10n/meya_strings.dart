import 'package:flutter/widgets.dart';

import 'translations.dart';

/// A language MEYA is available in.
class MeyaLanguage {
  /// 'fr', 'pt_BR', 'zh_Hans', …
  final String tag;
  final String nativeName;
  final String englishName;
  final bool rtl;

  const MeyaLanguage(this.tag, this.nativeName, this.englishName, {this.rtl = false});

  Locale get locale => switch (tag) {
        'pt_BR' => const Locale('pt', 'BR'),
        'pt_PT' => const Locale('pt', 'PT'),
        'zh_Hans' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        _ => Locale(tag),
      };
}

const meyaLanguages = <MeyaLanguage>[
  MeyaLanguage('en', 'English', 'English'),
  MeyaLanguage('fr', 'Français', 'French'),
  MeyaLanguage('ar', 'العربية', 'Arabic', rtl: true),
  MeyaLanguage('es', 'Español', 'Spanish'),
  MeyaLanguage('de', 'Deutsch', 'German'),
  MeyaLanguage('pt_BR', 'Português (Brasil)', 'Portuguese (Brazil)'),
  MeyaLanguage('pt_PT', 'Português (Portugal)', 'Portuguese (Portugal)'),
  MeyaLanguage('it', 'Italiano', 'Italian'),
  MeyaLanguage('zh_Hans', '简体中文', 'Chinese (Simplified)'),
  MeyaLanguage('ru', 'Русский', 'Russian'),
  MeyaLanguage('ja', '日本語', 'Japanese'),
  MeyaLanguage('tr', 'Türkçe', 'Turkish'),
  MeyaLanguage('fa', 'فارسی', 'Persian', rtl: true),
  MeyaLanguage('hi', 'हिन्दी', 'Hindi'),
  MeyaLanguage('ur', 'اردو', 'Urdu', rtl: true),
  MeyaLanguage('id', 'Bahasa Indonesia', 'Indonesian'),
  MeyaLanguage('ko', '한국어', 'Korean'),
  MeyaLanguage('nl', 'Nederlands', 'Dutch'),
  MeyaLanguage('bn', 'বাংলা', 'Bengali'),
  MeyaLanguage('sw', 'Kiswahili', 'Swahili'),
];

/// Looks up translations. English text is the key, so anything not yet
/// translated simply shows in English.
class MeyaStrings {
  static String _current = 'en';

  /// The language in use, set by the app whenever it changes.
  static String get current => _current;

  static void setCurrent(Locale locale) {
    _current = tagFor(locale);
  }

  static String tagFor(Locale locale) {
    switch (locale.languageCode) {
      case 'pt':
        return locale.countryCode == 'PT' ? 'pt_PT' : 'pt_BR';
      case 'zh':
        return 'zh_Hans';
      default:
        return locale.languageCode;
    }
  }

  static String translate(String tag, String english, List<Object?> args) {
    var text = meyaTranslations[tag]?[english] ?? english;
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', '${args[i]}');
    }
    return text;
  }
}

/// Translates [english] into the current language. Use `context.tr` inside
/// widgets so they rebuild when the language changes.
String tr(String english, [List<Object?> args = const []]) =>
    MeyaStrings.translate(MeyaStrings.current, english, args);

extension MeyaTranslate on BuildContext {
  String tr(String english, [List<Object?> args = const []]) =>
      MeyaStrings.translate(
        MeyaStrings.tagFor(Localizations.localeOf(this)),
        english,
        args,
      );
}
