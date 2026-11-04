import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/custom_theme_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';

/// The theme the app wears and the custom themes this installation holds
/// (issue #269), in the app database, and the theme a library's books are
/// put on screen with (#280).
final class SessionThemes {
  /// Themes kept in [appDatabase]; [onCustomThemesChanged] runs after a
  /// custom theme is saved or deleted, since the books' look may name it.
  new({required this.appDatabase, required this.onCustomThemesChanged});

  /// The app's settings database, opened once per session.
  final Future<AppDatabase> Function() appDatabase;

  /// Called once a custom theme was saved or deleted.
  final Future<void> Function() onCustomThemesChanged;

  final AppLogger _log = const AppLogger(name: 'session');

  /// The theme the app wears.
  ///
  /// A setting that points at a custom theme this installation no longer
  /// holds is repaired here, to Niman's own colors: there is always
  /// something to wear (issue #269).
  Future<AppTheme> get theme async {
    final settings = AppSettingsRepo(await appDatabase());
    final id = await settings.themeId();
    final customId = AppTheme.customIdIn(id);
    if (customId == null) return themeFromId(id);
    final custom = await CustomThemeRepo(await appDatabase()).byId(customId);
    if (custom != null) return themeFromId(id, custom: custom);
    _log.warning('theme $id is gone; wearing Niman instead');
    await settings.setThemeId(AppPalette.niman.id);
    return const BuiltinAppTheme(AppPalette.niman);
  }

  /// Sets (and persists) the theme, by its id.
  Future<void> setTheme(AppTheme theme) async {
    _log.info('theme set to ${theme.id}');
    await AppSettingsRepo(await appDatabase()).setThemeId(theme.id);
  }

  /// The custom themes this installation holds, by name (issue #269).
  Future<List<CustomTheme>> customThemes() async =>
      await CustomThemeRepo(await appDatabase()).list();

  /// The custom theme with [id], or null.
  Future<CustomTheme?> customTheme(String id) async =>
      await CustomThemeRepo(await appDatabase()).byId(id);

  /// Stores [theme]: the row with its id, or a new one.
  Future<void> saveCustomTheme(CustomTheme theme) async {
    _log.info('custom theme ${theme.id} saved as "${theme.name}"');
    await CustomThemeRepo(await appDatabase()).save(theme);
    await onCustomThemesChanged();
  }

  /// Renames the custom theme with [id].
  Future<void> renameCustomTheme(String id, String name) async {
    _log.info('custom theme $id renamed to "$name"');
    await CustomThemeRepo(await appDatabase()).rename(id, name);
  }

  /// Deletes the custom theme with [id], and returns the theme in force
  /// afterwards: deleting the one being worn falls back to the app's own
  /// colors.
  Future<AppTheme> deleteCustomTheme(String id) async {
    _log.info('custom theme $id deleted');
    await CustomThemeRepo(await appDatabase()).delete(id);
    await onCustomThemesChanged();
    // Reading it back repairs a setting that pointed at the deleted
    // theme, so what comes out is what the app wears from here on.
    return await theme;
  }

  /// Whether [name] is a custom theme's name already.
  Future<bool> customThemeNameTaken(String name) async =>
      await CustomThemeRepo(await appDatabase()).nameTaken(name);

  /// Puts [look] on screen with the theme it names: a shipped palette, or
  /// a custom theme of this device's — none, the app's, when that is gone.
  Future<void> publishEpubLook(EpubLook look) async {
    final id = look.theme;
    AppTheme? theme;
    if (id != null) {
      final customId = AppTheme.customIdIn(id);
      if (customId == null) {
        theme = themeFromId(id);
      } else {
        final custom = await CustomThemeRepo(await appDatabase())
            .byId(customId);
        if (custom != null) theme = themeFromId(id, custom: custom);
      }
    }
    EpubLooks.apply(look, theme: theme);
  }
}
