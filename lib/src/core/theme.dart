// The app's look, as it is stored (T-M6-05, issue #269): how bright it
// is, and which palette it wears. The theme model those two name — and
// the global the app root listens to — is `core/app_theme.dart`.
//
// The ids here are the ones in `app_settings`: a palette's own, or
// `custom:<id>` for a theme of the user's own. The theme is app-side and
// not a property of a library (design.md: the theme is app-side, and not
// synced) — the same eyes read every library on the same screen (user,
// 2026-09-10).

/// How bright the app is, plus the "follow the device" choice.
enum AppBrightness {
  /// Follow the OS setting (the default).
  system('system'),

  /// Light, whatever the OS says.
  day('day'),

  /// Dark, whatever the OS says.
  night('night');

  new(this.id);

  /// The persisted id.
  final String id;

  /// The brightness with this [id]; anything unknown is [system].
  static AppBrightness fromId(String? id) {
    for (final value in AppBrightness.values) {
      if (value.id == id) return value;
    }
    return AppBrightness.system;
  }
}

/// A set of colors the app can wear, day and night.
///
/// Each one is a mapping and nothing more: `ui/theme/` turns its color
/// roles into a Material scheme and the markdown colors, so a new entry
/// here plus a file of hex values is the whole of adding a palette.
enum AppPalette {
  /// The device's own colors (Material You): the wallpaper palette on
  /// Android 12 and up, the accent color on Windows, macOS and GTK,
  /// falling back to the shipped seed where the OS offers neither.
  system('system'),

  /// Catppuccin — Latte by day, Mocha by night.
  catppuccin('catppuccin'),

  /// Solarized — Schoonover's light and dark.
  solarized('solarized'),

  /// Gruvbox — the medium light and dark variants.
  gruvbox('gruvbox'),

  /// Niman — the app's own colors, taken from the logo.
  niman('niman');

  new(this.id);

  /// The persisted id.
  final String id;

  /// The palette with this [id]; anything unknown is [system].
  static AppPalette fromId(String? id) {
    for (final value in AppPalette.values) {
      if (value.id == id) return value;
    }
    return AppPalette.system;
  }
}
