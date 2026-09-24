/// The app theme as the home-screen widgets wear it (issue 6).
///
/// The launcher inflates widget layouts out of process, so a widget
/// cannot read the app's `Theme`: Dart serializes the resolved colors
/// into every payload under `theme`, and the native providers apply
/// them with `RemoteViews` setters. Payloads without a theme render
/// the layout defaults (the system night twin), so widgets pushed
/// before this never break.
///
/// Colors cross as `#AARRGGBB` strings (a 32-bit ARGB int would
/// overflow the native `getInt`), and round-trip through the tap URIs:
/// the native row factories append the payload's theme to the fill-in
/// URI, so the background toggle re-pushes the same theme instead of
/// flashing the defaults. A tap without theme params (an old widget)
/// resolves live in the pushing isolate.
///
/// Pure Dart, no I/O: `dart:ui` only.
library;

import 'dart:ui' show Brightness, Color, PlatformDispatcher;

import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// The widget theme: whether the app is dark, and the card, text and
/// accent colors the native side applies.
typedef WidgetTheme = ({
  bool dark,
  String background,
  String primary,
  String secondary,
  String accent,
});

/// The short URI query keys carrying a theme on tap URIs.
/// Whether the app is dark (`1`) or light (`0`).
const String widgetThemeDarkKey = 'td';

/// The card background (`#AARRGGBB`).
const String widgetThemeBackgroundKey = 'bg';

/// The primary text (`#AARRGGBB`).
const String widgetThemePrimaryKey = 'fg';

/// The secondary text (`#AARRGGBB`).
const String widgetThemeSecondaryKey = 'fs';

/// The accent (`#AARRGGBB`).
const String widgetThemeAccentKey = 'ac';

/// The theme the widgets wear right now: the app's brightness choice
/// (the device brightness for `system`) in the app's theme.
///
/// [platform] is injected in tests; production reads the dispatcher,
/// which also answers in the background isolate.
WidgetTheme resolveWidgetTheme({Brightness? platform}) {
  final brightness = switch (AppThemes.brightness) {
    AppBrightness.day => Brightness.light,
    AppBrightness.night => Brightness.dark,
    AppBrightness.system =>
      platform ?? PlatformDispatcher.instance.platformBrightness,
  };
  final scheme = themeColors(AppThemes.effective, brightness).scheme;
  return (
    dark: brightness == Brightness.dark,
    // The card stays translucent like the shipped colors (#E6 alpha).
    background: _hex(scheme.surface.withValues(alpha: 0xE6 / 0xFF)),
    primary: _hex(scheme.onSurface),
    secondary: _hex(scheme.onSurfaceVariant),
    accent: _hex(scheme.primary),
  );
}

/// The JSON shape a payload carries under `theme`.
Map<String, Object?> widgetThemeToMap(WidgetTheme theme) {
  return {
    'dark': theme.dark,
    'background': theme.background,
    'primary': theme.primary,
    'secondary': theme.secondary,
    'accent': theme.accent,
  };
}

/// Reads a payload's `theme` map, or null when it carries none (or a
/// broken one — an old or hand-made payload renders the defaults).
WidgetTheme? widgetThemeFromMap(Map<String, Object?>? map) {
  if (map == null) return null;
  final dark = map['dark'];
  final background = map['background'];
  final primary = map['primary'];
  final secondary = map['secondary'];
  final accent = map['accent'];
  if (dark is! bool ||
      !_isHex(background) ||
      !_isHex(primary) ||
      !_isHex(secondary) ||
      !_isHex(accent)) {
    return null;
  }
  return (
    dark: dark,
    background: background! as String,
    primary: primary! as String,
    secondary: secondary! as String,
    accent: accent! as String,
  );
}

/// Reads a tap URI's theme params, or null when they are absent or
/// broken (an old widget resolves live instead).
WidgetTheme? widgetThemeFromUri(Uri? uri) {
  if (uri == null) return null;
  final params = uri.queryParameters;
  final darkRaw = params[widgetThemeDarkKey];
  final background = params[widgetThemeBackgroundKey];
  final primary = params[widgetThemePrimaryKey];
  final secondary = params[widgetThemeSecondaryKey];
  final accent = params[widgetThemeAccentKey];
  final bool dark;
  if (darkRaw == '1') {
    dark = true;
  } else if (darkRaw == '0') {
    dark = false;
  } else {
    return null;
  }
  if (!_isHex(background) ||
      !_isHex(primary) ||
      !_isHex(secondary) ||
      !_isHex(accent)) {
    return null;
  }
  return (
    dark: dark,
    background: background!,
    primary: primary!,
    secondary: secondary!,
    accent: accent!,
  );
}

/// Appends [theme]'s params to [params] (a URI query map under
/// construction); a null theme appends nothing.
void appendWidgetThemeParams(Map<String, String> params, WidgetTheme? theme) {
  if (theme == null) return;
  params[widgetThemeDarkKey] = theme.dark ? '1' : '0';
  params[widgetThemeBackgroundKey] = theme.background;
  params[widgetThemePrimaryKey] = theme.primary;
  params[widgetThemeSecondaryKey] = theme.secondary;
  params[widgetThemeAccentKey] = theme.accent;
}

bool _isHex(Object? value) {
  return value is String && RegExp(r'^#[0-9A-Fa-f]{8}$').hasMatch(value);
}

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
