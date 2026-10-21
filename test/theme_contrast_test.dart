import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/theme/meya_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final palettes = {
    'light': MeyaPalette.light,
    'dark': MeyaPalette.dark,
    'high contrast light': MeyaPalette.highContrastLight,
    'high contrast dark': MeyaPalette.highContrastDark,
  };

  for (final entry in palettes.entries) {
    final p = entry.value;
    // WCAG 2.2: 4.5:1 for normal text (AA); 7:1 for the high contrast
    // palettes (AAA).
    final minimum = p.isHighContrast ? 7.0 : 4.5;

    group('${entry.key} palette meets WCAG text contrast', () {
      final pairs = {
        'text on page': (p.text, p.surface),
        'text on card': (p.text, p.card),
        'secondary text on page': (p.muted, p.surface),
        'secondary text on card': (p.muted, p.card),
        'accent on page': (p.navy, p.surface),
        'accent on card': (p.navy, p.card),
        'button text on accent': (p.onNavy, p.navy),
        'error on card': (p.error, p.card),
        'success on card': (p.success, p.card),
      };
      pairs.forEach((name, colours) {
        test(name, () {
          expect(
            contrast(colours.$1, colours.$2),
            greaterThanOrEqualTo(minimum),
          );
        });
      });
    });
  }

  test('light palette is exactly the MEYA brand palette', () {
    const p = MeyaPalette.light;
    expect(p.navy, const Color(0xFF044D8C));
    expect(p.blue, const Color(0xFF49B1F2));
    expect(p.card, const Color(0xFFEBF2F2));
    // White pages.
    expect(p.surface, const Color(0xFFFFFFFF));
    expect(p.text, const Color(0xFF0D0D0D));
    expect(p.muted, const Color(0xFF424D8C));
  });

  testWidgets('settings switch the app between light and dark', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = MeyaSettings.instance;
    late Color background;

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          themeMode: settings.themeMode,
          theme: buildMeyaTheme(MeyaPalette.light),
          darkTheme: buildMeyaTheme(MeyaPalette.dark),
          home: Builder(
            builder: (context) {
              background = context.meya.surface;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await settings.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(background, MeyaPalette.light.surface);

    await settings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(background, MeyaPalette.dark.surface);
  });
}
