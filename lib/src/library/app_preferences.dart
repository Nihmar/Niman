import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/theme.dart';

/// The settings the app keeps for itself (#1258), whichever library is
/// open — none included: the language, the theme and the custom themes,
/// the shortcuts, the logging, the updates and the tray.
///
/// Reached through `LibrarySession.appSettings`; they live in the app's
/// own database, not in a library's `.niman/settings.json`.
abstract interface class AppPreferences {
  /// Whether the in-app debug log buffer records events.
  ///
  /// Also applies the persisted value to the live logger.
  Future<bool> get debugLogsEnabled;

  /// Sets (and persists) the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled});

  /// Whether the app checks GitHub Releases for updates (issue #81,
  /// default false). The manual check in Settings works regardless.
  Future<bool> get autoUpdateEnabled;

  /// Sets (and persists) the auto-update toggle.
  Future<void> setAutoUpdateEnabled({required bool enabled});

  /// Whether the window's × hides Niman to the tray and leaves it
  /// running (#209, default on); the desktops only.
  Future<bool> get closeToTray;

  /// Sets (and persists) the close-to-tray choice.
  Future<void> setCloseToTray({required bool enabled});

  /// The UI language ([AppLanguage.system] by default).
  Future<AppLanguage> get language;

  /// Sets (and persists) the UI language.
  Future<void> setLanguage(AppLanguage language);

  /// How bright the app is ([AppBrightness.system] by default).
  Future<AppBrightness> get themeBrightness;

  /// The keyboard shortcuts changed on this device (#159), as stored;
  /// null while none was.
  Future<String?> get keyMap;

  /// Keeps [json] as this device's changed shortcuts.
  Future<void> setKeyMap(String json);

  /// The commands pinned in the palette on this device (#208), as
  /// stored; null while none was.
  Future<String?> get pinnedCommands;

  /// Keeps [json] as this device's pinned commands.
  Future<void> setPinnedCommands(String json);

  /// Sets (and persists) the brightness choice.
  Future<void> setThemeBrightness(AppBrightness brightness);

  /// The theme the app wears ([AppPalette.niman] by default).
  ///
  /// A setting that points at a custom theme this installation no longer
  /// holds reads as that default, and the setting is repaired to match:
  /// there is always something to wear.
  Future<AppTheme> get theme;

  /// Sets (and persists) the theme, by its id.
  Future<void> setTheme(AppTheme theme);

  /// The custom themes this installation holds, by name (issue #269).
  Future<List<CustomTheme>> customThemes();

  /// The custom theme with [id], or null when there is none (or its
  /// stored colors are unreadable).
  Future<CustomTheme?> customTheme(String id);

  /// Stores [theme]: the row with its id, or a new one.
  Future<void> saveCustomTheme(CustomTheme theme);

  /// Renames the custom theme with [id].
  Future<void> renameCustomTheme(String id, String name);

  /// Deletes the custom theme with [id], and returns the theme in force
  /// afterwards: deleting the one being worn falls back to the app's own
  /// colors.
  Future<AppTheme> deleteCustomTheme(String id);

  /// Whether [name] is a custom theme's name already,
  /// case-insensitively.
  Future<bool> customThemeNameTaken(String name);
}
