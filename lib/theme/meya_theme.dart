import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MEYA colours for one appearance (light, dark, or a high contrast variant).
///
/// The light palette is exactly the MEYA brand palette. The others are
/// derived from it so text always meets WCAG 2.2 contrast:
/// at least 4.5:1 for normal text (AA) and 7:1 in the high contrast
/// palettes (AAA). Run `test/theme_contrast_test.dart` to check.
@immutable
class MeyaPalette {
  /// Brand accent: buttons, icons, links and headings.
  final Color navy;

  /// Secondary accent: selection and highlights.
  final Color blue;

  /// Page background.
  final Color surface;

  /// Cards, rows, sheets and text fields.
  final Color card;

  /// Main text.
  final Color text;

  /// Secondary text and icons.
  final Color muted;

  /// Text and icons placed on [navy].
  final Color onNavy;

  final Color success;
  final Color error;
  final Brightness brightness;

  const MeyaPalette({
    required this.navy,
    required this.blue,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.onNavy,
    required this.success,
    required this.error,
    required this.brightness,
  });

  /// The MEYA brand palette: #044D8C, #49B1F2, #EBF2F2, #0D0D0D, #424D8C.
  static const light = MeyaPalette(
    navy: Color(0xFF044D8C),
    blue: Color(0xFF49B1F2),
    surface: Color(0xFFEBF2F2),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0D0D0D),
    muted: Color(0xFF424D8C),
    onNavy: Color(0xFFFFFFFF),
    success: Color(0xFF1F7A4D),
    error: Color(0xFFB3261E),
    brightness: Brightness.light,
  );

  /// Dark mode: #0D0D0D background, the light blue as accent.
  static const dark = MeyaPalette(
    navy: Color(0xFF49B1F2),
    blue: Color(0xFF49B1F2),
    surface: Color(0xFF0D0D0D),
    card: Color(0xFF17212B),
    text: Color(0xFFEBF2F2),
    muted: Color(0xFFAEB8E6),
    onNavy: Color(0xFF0D0D0D),
    success: Color(0xFF6FD3A0),
    error: Color(0xFFFFB4AB),
    brightness: Brightness.dark,
  );

  static const highContrastLight = MeyaPalette(
    navy: Color(0xFF033A6B),
    blue: Color(0xFF044D8C),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF000000),
    muted: Color(0xFF1E2655),
    onNavy: Color(0xFFFFFFFF),
    success: Color(0xFF0F5132),
    error: Color(0xFF8C1D18),
    brightness: Brightness.light,
  );

  static const highContrastDark = MeyaPalette(
    navy: Color(0xFF8FD3FF),
    blue: Color(0xFF8FD3FF),
    surface: Color(0xFF000000),
    card: Color(0xFF0D0D0D),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFFDDE3FA),
    onNavy: Color(0xFF000000),
    success: Color(0xFF9BE8C0),
    error: Color(0xFFFFDAD6),
    brightness: Brightness.dark,
  );

  bool get isHighContrast =>
      identical(this, highContrastLight) || identical(this, highContrastDark);
}

/// Carries the active [MeyaPalette] inside the theme.
@immutable
class MeyaPaletteExtension extends ThemeExtension<MeyaPaletteExtension> {
  final MeyaPalette palette;

  const MeyaPaletteExtension(this.palette);

  @override
  MeyaPaletteExtension copyWith({MeyaPalette? palette}) =>
      MeyaPaletteExtension(palette ?? this.palette);

  @override
  MeyaPaletteExtension lerp(
    covariant ThemeExtension<MeyaPaletteExtension>? other,
    double t,
  ) {
    if (other is! MeyaPaletteExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension MeyaThemeContext on BuildContext {
  /// The MEYA colours for the current appearance.
  MeyaPalette get meya =>
      Theme.of(this).extension<MeyaPaletteExtension>()?.palette ??
      MeyaPalette.light;
}

/// Builds the full Material theme for one palette.
ThemeData buildMeyaTheme(MeyaPalette p, {bool reduceMotion = false}) {
  final highContrast = p.isHighContrast;
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.navy,
    onPrimary: p.onNavy,
    secondary: p.blue,
    onSecondary: p.brightness == Brightness.light ? p.text : p.onNavy,
    error: p.error,
    onError: p.brightness == Brightness.light ? Colors.white : Colors.black,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    surfaceContainerLowest: p.card,
    surfaceContainerLow: p.card,
    surfaceContainer: p.card,
    surfaceContainerHigh: Color.alphaBlend(p.navy.withValues(alpha: 0.08), p.card),
    surfaceContainerHighest:
        Color.alphaBlend(p.navy.withValues(alpha: 0.14), p.card),
    errorContainer: Color.alphaBlend(p.error.withValues(alpha: 0.16), p.card),
    onErrorContainer: p.text,
    outline: highContrast ? p.text : p.muted,
    outlineVariant: p.muted.withValues(alpha: highContrast ? 0.8 : 0.35),
  );

  final borderSide = highContrast
      ? BorderSide(color: p.text, width: 1.5)
      : BorderSide.none;

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.surface,
    canvasColor: p.surface,
    cardColor: p.card,
    dividerColor: p.muted.withValues(alpha: highContrast ? 0.8 : 0.25),
    fontFamily: 'Roboto',
    extensions: [MeyaPaletteExtension(p)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.text,
      contentTextStyle: TextStyle(color: p.surface),
      // The snack bar is inverted (dark on light pages, light on dark ones),
      // so its action uses the accent of the opposite palette.
      actionTextColor: p.brightness == Brightness.light
          ? (highContrast
              ? MeyaPalette.highContrastDark.navy
              : MeyaPalette.dark.navy)
          : (highContrast
              ? MeyaPalette.highContrastLight.navy
              : MeyaPalette.light.navy),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.onNavy : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? p.navy
            : p.muted.withValues(alpha: 0.25),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: TextStyle(color: p.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: p.navy, width: highContrast ? 3 : 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    ),
    pageTransitionsTheme: reduceMotion
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoAnimationTransitionsBuilder(),
              TargetPlatform.iOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.linux: _NoAnimationTransitionsBuilder(),
              TargetPlatform.macOS: _NoAnimationTransitionsBuilder(),
              TargetPlatform.windows: _NoAnimationTransitionsBuilder(),
            },
          )
        : null,
  );
}

class _NoAnimationTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

/// Appearance and accessibility settings, applied to the whole app as soon
/// as they change. Stored on this device only.
class MeyaSettings extends ChangeNotifier {
  MeyaSettings._();

  static final MeyaSettings instance = MeyaSettings._();

  static const _themeKey = 'meya_theme_mode';
  static const _textScaleKey = 'meya_text_scale';
  static const _reduceMotionKey = 'meya_reduce_motion';
  static const _highContrastKey = 'meya_high_contrast';
  static const _languageKey = 'meya_language';

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  String _language = '';

  ThemeMode get themeMode => _themeMode;

  /// A language tag such as 'fr' or 'pt_BR', or '' to follow the phone.
  String get language => _language;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _themeMode = switch (preferences.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _textScale =
          (preferences.getDouble(_textScaleKey) ?? 1.0).clamp(0.85, 1.6);
      _reduceMotion = preferences.getBool(_reduceMotionKey) ?? false;
      _highContrast = preferences.getBool(_highContrastKey) ?? false;
      _language = preferences.getString(_languageKey) ?? '';
    } catch (error) {
      debugPrint('MEYA settings: using defaults ($error).');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale.clamp(0.85, 1.6);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_textScaleKey, _textScale);
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_reduceMotionKey, value);
  }

  Future<void> setLanguage(String tag) async {
    _language = tag;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, tag);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_highContrastKey, value);
  }
}
