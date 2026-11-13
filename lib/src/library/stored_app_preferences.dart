import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/app_preferences.dart';
import 'package:niman/src/library/session_themes.dart';

/// The [AppPreferences] kept in the app's database: its settings table
/// through [AppSettingsRepo], and the themes through [SessionThemes].
final class StoredAppPreferences implements AppPreferences {
  /// Settings read from and written to [appDatabase]; the themes go
  /// through [themes], which also puts a library's books on screen.
  new({required this.appDatabase, required this.themes});

  /// The app's settings database, opened once per session.
  final Future<AppDatabase> Function() appDatabase;

  /// The theme the app wears and the custom themes.
  final SessionThemes themes;

  static const _log = AppLogger(name: 'session');

  Future<AppSettingsRepo> get _repo async =>
      AppSettingsRepo(await appDatabase());

  @override
  Future<bool> get debugLogsEnabled async {
    final enabled = await (await _repo).debugLogsEnabled();
    AppLog.enabled = enabled;
    return enabled;
  }

  @override
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    _log.info('debug logging set to $enabled');
    await (await _repo).setDebugLogsEnabled(enabled: enabled);
    AppLog.enabled = enabled;
  }

  @override
  Future<bool> get autoUpdateEnabled async =>
      await (await _repo).autoUpdateEnabled();

  @override
  Future<void> setAutoUpdateEnabled({required bool enabled}) async {
    _log.info('auto-update set to $enabled');
    await (await _repo).setAutoUpdateEnabled(enabled: enabled);
  }

  @override
  Future<bool> get closeToTray async => await (await _repo).closeToTray();

  @override
  Future<void> setCloseToTray({required bool enabled}) async {
    _log.info('close to tray: $enabled');
    await (await _repo).setCloseToTray(enabled: enabled);
  }

  @override
  Future<AppLanguage> get language async => await (await _repo).language();

  @override
  Future<void> setLanguage(AppLanguage language) async {
    _log.info('language set to ${language.id}');
    await (await _repo).setLanguage(language);
  }

  @override
  Future<AppBrightness> get themeBrightness async =>
      await (await _repo).themeBrightness();

  @override
  Future<void> setThemeBrightness(AppBrightness brightness) async {
    _log.info('theme brightness set to ${brightness.id}');
    await (await _repo).setThemeBrightness(brightness);
  }

  @override
  Future<String?> get keyMap async => await (await _repo).keyMap();

  @override
  Future<void> setKeyMap(String json) async {
    _log.info('key map set');
    await (await _repo).setKeyMap(json);
  }

  @override
  Future<String?> get pinnedCommands async =>
      await (await _repo).pinnedCommands();

  @override
  Future<void> setPinnedCommands(String json) async {
    await (await _repo).setPinnedCommands(json);
  }

  @override
  Future<AppTheme> get theme => themes.theme;

  @override
  Future<void> setTheme(AppTheme theme) => themes.setTheme(theme);

  @override
  Future<List<CustomTheme>> customThemes() => themes.customThemes();

  @override
  Future<CustomTheme?> customTheme(String id) => themes.customTheme(id);

  @override
  Future<void> saveCustomTheme(CustomTheme theme) =>
      themes.saveCustomTheme(theme);

  @override
  Future<void> renameCustomTheme(String id, String name) =>
      themes.renameCustomTheme(id, name);

  @override
  Future<AppTheme> deleteCustomTheme(String id) => themes.deleteCustomTheme(id);

  @override
  Future<bool> customThemeNameTaken(String name) =>
      themes.customThemeNameTaken(name);
}
