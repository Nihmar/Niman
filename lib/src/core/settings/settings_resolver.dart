import 'package:copist/src/core/settings/library_config_repo.dart';
import 'package:copist/src/core/settings/library_setting.dart';
import 'package:copist/src/core/settings/library_settings.dart';

/// Reads and writes a setting where it currently lives (T-ML-10).
///
/// Every setting here has an app-wide value. A library may answer one for
/// itself in its own `settings.json`; while it does, this reads and
/// writes there, and otherwise it reads and writes the app value. So the
/// settings screen edits whatever scope a row is in without knowing which
/// one that is, and changing scope is its own action.
///
/// A stored override that makes no sense — a hand-typed `"linkType":
/// "wikilnk"` — is treated as no override at all, the way the rest of the
/// file treats a value it cannot use.
final class SettingsResolver {
  /// Creates a resolver over the app settings and, when a library is
  /// open, its config. With a null config nothing is overridden and
  /// every read and write goes to the app.
  const new(this._app, this._config);

  final AppSettingsRepo _app;
  final LibraryConfigRepo? _config;

  /// The settings this library answers for itself.
  Future<Set<LibrarySetting>> overridden() async {
    final config = _config;
    if (config == null) return const {};
    return {
      for (final key in (await config.config).overrides.keys)
        ?LibrarySetting.fromId(key),
    };
  }

  /// Starts answering [setting] in this library, seeded with the app's
  /// current value so nothing changes at the moment of the switch.
  Future<void> overrideHere(LibrarySetting setting) async {
    final config = _config;
    if (config == null) return;
    await config.setOverride(setting, await _appValue(setting));
  }

  /// Stops answering [setting] here; the library follows the app again.
  Future<void> followApp(LibrarySetting setting) async {
    await _config?.clearOverride(setting);
  }

  /// Whether the note editor shows the row-number column.
  Future<bool> lineNumbers() =>
      _read(LibrarySetting.lineNumbers, _asBool, _app.lineNumbersEnabled);

  /// Sets it where it lives.
  Future<void> setLineNumbers({required bool enabled}) => _write(
    LibrarySetting.lineNumbers,
    enabled,
    () => _app.setLineNumbersEnabled(enabled: enabled),
  );

  /// Whether opening a note raises the keyboard.
  Future<bool> editorAutofocus() => _read(
    LibrarySetting.editorAutofocus,
    _asBool,
    _app.editorAutofocusEnabled,
  );

  /// Sets it where it lives.
  Future<void> setEditorAutofocus({required bool enabled}) => _write(
    LibrarySetting.editorAutofocus,
    enabled,
    () => _app.setEditorAutofocusEnabled(enabled: enabled),
  );

  /// Whether a reminder's text keeps its markers.
  Future<bool> reminderShowTokens() => _read(
    LibrarySetting.reminderShowTokens,
    _asBool,
    _app.reminderShowTokens,
  );

  /// Sets it where it lives.
  Future<void> setReminderShowTokens({required bool enabled}) => _write(
    LibrarySetting.reminderShowTokens,
    enabled,
    () => _app.setReminderShowTokens(enabled: enabled),
  );

  /// The preview layout mode.
  Future<PreviewLayoutMode> previewMode() => _read(
    LibrarySetting.previewMode,
    (raw) => switch (raw) {
      'auto' => PreviewLayoutMode.auto,
      'split' => PreviewLayoutMode.split,
      'fullScreen' => PreviewLayoutMode.fullScreen,
      _ => null,
    },
    _app.previewMode,
  );

  /// Sets it where it lives.
  Future<void> setPreviewMode(PreviewLayoutMode mode) => _write(
    LibrarySetting.previewMode,
    mode.name,
    () => _app.setPreviewMode(mode),
  );

  /// The editor's share of the split.
  Future<double> splitRatio() => _read(
    LibrarySetting.splitRatio,
    (raw) => raw is num ? _clampRatio(raw.toDouble()) : null,
    _app.splitRatio,
  );

  /// Sets it where it lives (clamped to the allowed range).
  Future<void> setSplitRatio(double ratio) => _write(
    LibrarySetting.splitRatio,
    _clampRatio(ratio),
    () => _app.setSplitRatio(ratio),
  );

  /// The tree's sort order.
  Future<TreeSort> treeSort() => _read(
    LibrarySetting.treeSort,
    (raw) => switch (raw) {
      'nameAsc' => TreeSort.nameAsc,
      'nameDesc' => TreeSort.nameDesc,
      _ => null,
    },
    _app.treeSort,
  );

  /// Sets it where it lives.
  Future<void> setTreeSort(TreeSort sort) =>
      _write(LibrarySetting.treeSort, sort.name, () => _app.setTreeSort(sort));

  /// What the editor's link button inserts.
  Future<LinkType> linkType() => _read(
    LibrarySetting.linkType,
    (raw) => switch (raw) {
      'wikilink' => LinkType.wikilink,
      'markdown' => LinkType.markdown,
      _ => null,
    },
    _app.linkType,
  );

  /// Sets it where it lives.
  Future<void> setLinkType(LinkType type) =>
      _write(LibrarySetting.linkType, type.name, () => _app.setLinkType(type));

  /// Spaces added per indent level.
  Future<int> indentWidth() => _read(
    LibrarySetting.indentWidth,
    (raw) => raw is num ? _clampIndent(raw.toInt()) : null,
    _app.indentWidth,
  );

  /// Sets it where it lives (clamped to the allowed range).
  Future<void> setIndentWidth(int width) => _write(
    LibrarySetting.indentWidth,
    _clampIndent(width),
    () => _app.setIndentWidth(width),
  );

  /// The arranged editor toolbar (empty = the shipped one).
  Future<String> editorToolbar() => _read(
    LibrarySetting.editorToolbar,
    (raw) => raw is String ? raw : null,
    _app.editorToolbar,
  );

  /// Sets it where it lives.
  Future<void> setEditorToolbar(String layout) => _write(
    LibrarySetting.editorToolbar,
    layout,
    () => _app.setEditorToolbar(layout),
  );

  /// The library's answer for [setting] when it has a usable one, the
  /// app's otherwise.
  Future<T> _read<T>(
    LibrarySetting setting,
    T? Function(Object? raw) decode,
    Future<T> Function() fromApp,
  ) async {
    final raw = await _config?.overrideOf(setting);
    if (raw != null) {
      final decoded = decode(raw);
      if (decoded != null) return decoded;
    }
    return await fromApp();
  }

  /// Writes [value] where [setting] lives: the library's own file while
  /// it overrides the setting, the app database otherwise.
  Future<void> _write(
    LibrarySetting setting,
    Object value,
    Future<void> Function() toApp,
  ) async {
    final config = _config;
    if (config != null && await config.overrides(setting)) {
      await config.setOverride(setting, value);
      return;
    }
    await toApp();
  }

  /// The app's value for [setting], for seeding a new override.
  Future<Object> _appValue(LibrarySetting setting) async {
    return switch (setting) {
      LibrarySetting.lineNumbers => await _app.lineNumbersEnabled(),
      LibrarySetting.editorAutofocus => await _app.editorAutofocusEnabled(),
      LibrarySetting.reminderShowTokens => await _app.reminderShowTokens(),
      LibrarySetting.previewMode => (await _app.previewMode()).name,
      LibrarySetting.splitRatio => await _app.splitRatio(),
      LibrarySetting.treeSort => (await _app.treeSort()).name,
      LibrarySetting.linkType => (await _app.linkType()).name,
      LibrarySetting.indentWidth => await _app.indentWidth(),
      LibrarySetting.editorToolbar => await _app.editorToolbar(),
    };
  }

  static bool? _asBool(Object? raw) => raw is bool ? raw : null;

  static double _clampRatio(double ratio) => ratio < minSplitRatio
      ? minSplitRatio
      : ratio > maxSplitRatio
      ? maxSplitRatio
      : ratio;

  static int _clampIndent(int width) => width < 2
      ? 2
      : width > 8
      ? 8
      : width;
}
