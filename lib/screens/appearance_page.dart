import 'package:flutter/material.dart';

import '../l10n/meya_strings.dart';
import '../theme/meya_theme.dart';

/// Theme, text size and accessibility options. Every change applies to the
/// whole app immediately and is remembered on this device.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => tr('System default'),
        ThemeMode.light => tr('Light'),
        ThemeMode.dark => tr('Dark'),
      };

  static String _textSizeLabel(double scale) {
    if (scale < 0.95) return tr('Small');
    if (scale < 1.08) return tr('Default');
    if (scale < 1.25) return tr('Large');
    if (scale < 1.45) return tr('Extra large');
    return tr('Largest');
  }

  Future<void> _selectTheme(BuildContext context) async {
    final settings = MeyaSettings.instance;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) => Navigator.pop(context, mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode)),
                    subtitle: mode == ThemeMode.system
                        ? Text(context.tr('Follows your phone setting'))
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) await settings.setThemeMode(selected);
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final settings = MeyaSettings.instance;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: RadioGroup<String>(
            groupValue: settings.language,
            onChanged: (tag) => Navigator.pop(sheetContext, tag),
            child: ListView(
              shrinkWrap: true,
              children: [
                RadioListTile<String>(
                  value: '',
                  title: Text(context.tr('Phone language')),
                  subtitle: Text(context.tr('Follows your phone setting')),
                ),
                for (final language in meyaLanguages)
                  RadioListTile<String>(
                    value: language.tag,
                    title: Text(
                      language.nativeName,
                      textDirection:
                          language.rtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    subtitle: Text(language.englishName),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) await settings.setLanguage(selected);
  }

  static String _languageLabel(String tag) {
    if (tag.isEmpty) return tr('Phone language');
    return meyaLanguages
        .firstWhere(
          (language) => language.tag == tag,
          orElse: () => meyaLanguages.first,
        )
        .nativeName;
  }

  @override
  Widget build(BuildContext context) {
    final settings = MeyaSettings.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final theme = Theme.of(context);
        final heading = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('Appearance & Accessibility'))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Semantics(header: true, child: Text(context.tr('Appearance'), style: heading)),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_6_outlined),
                        title: Text(context.tr('Theme')),
                        subtitle: Text(_themeLabel(settings.themeMode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectTheme(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.format_size_outlined),
                        title: Text(context.tr('Text size')),
                        subtitle: Text(_textSizeLabel(settings.textScale)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: Slider(
                          value: settings.textScale,
                          min: 0.85,
                          max: 1.6,
                          divisions: 15,
                          label: _textSizeLabel(settings.textScale),
                          semanticFormatterCallback: _textSizeLabel,
                          onChanged: settings.setTextScale,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: Text(
                          context.tr('Preview: messages and menus will look like this.'),
                          style: TextStyle(
                            fontSize: 15,
                            color: context.meya.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(context.tr('Accessibility'), style: heading),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.contrast_outlined),
                        title: Text(context.tr('High contrast')),
                        subtitle: Text(
                          context.tr('Stronger colours and outlines for easier reading'),
                        ),
                        value: settings.highContrast,
                        onChanged: settings.setHighContrast,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.motion_photos_off_outlined),
                        title: Text(context.tr('Reduce motion')),
                        subtitle: Text(
                          context.tr('Turn off animations and page transitions'),
                        ),
                        value: settings.reduceMotion,
                        onChanged: settings.setReduceMotion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    context.tr('MEYA also follows your phone\'s own text size, high contrast and animation settings.'),
                    style: TextStyle(color: context.meya.muted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(header: true, child: Text(context.tr('Language'), style: heading)),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(context.tr('Language')),
                    subtitle: Text(_languageLabel(settings.language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectLanguage(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
