import 'package:copist/src/core/language.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:drift/drift.dart';

/// The preview layout mode (settings, T-M2-08): follow the width (`auto`)
/// or force one of the two modes.
enum PreviewLayoutMode {
  /// Auto: split at >= 600 dp, full-screen switch on phones.
  auto,

  /// Forced side-by-side (desktop style) at any width.
  split,

  /// Forced single pane with the top switch.
  fullScreen,
}

/// The library tree sort order (T-UI-03).
enum TreeSort {
  /// Name ascending (default).
  nameAsc,

  /// Name descending.
  nameDesc,
}

/// The link format the editor's link button inserts.
enum LinkType {
  /// A wikilink `[[…]]` (the default).
  wikilink,

  /// A markdown link `[…](…)`.
  markdown,
}

/// Below this width the shell is single-pane (spec: phones are
/// full-screen tree or editor, the split lands at 600 dp and up).
const double splitBreakpoint = 600;

/// Whether the editor and the preview actually sit side by side.
///
/// The forced modes win; `auto` follows the width. It lives here rather
/// than in the shell because the settings screen asks the same question:
/// the split-ratio row means nothing when the panes never share a screen
/// (T-CL-05).
bool previewSplits(PreviewLayoutMode mode, {required bool narrow}) =>
    switch (mode) {
      PreviewLayoutMode.split => true,
      PreviewLayoutMode.fullScreen => false,
      PreviewLayoutMode.auto => !narrow,
    };

/// The default editor share of the split.
const double defaultSplitRatio = 0.55;

/// The default folder (library-relative) of the list notes (T-TK-06).
const String defaultListFolder = 'Lists';

/// The lower bound of the allowed split range.
const double minSplitRatio = 0.2;

/// The upper bound of the allowed split range.
const double maxSplitRatio = 0.8;

/// Global app settings, a single row (id 1).
final class AppSettingsRepo {
  /// Creates the repo over the given [AppDatabase].
  new(this._db);

  final AppDatabase _db;

  /// The last opened library root, or null.
  Future<String?> lastLibraryPath() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.libraryPath;
  }

  /// Persists `path` as the last opened library root.
  Future<void> setLastLibraryPath(String? path) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(libraryPath: Value(path)),
    );
  }

  /// Whether the debug log buffer records events (default true).
  Future<bool> debugLogsEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.debugLogsEnabled;
  }

  /// Persists the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(debugLogsEnabled: Value(enabled)),
    );
  }

  /// The preview layout mode (default [PreviewLayoutMode.auto]).
  Future<PreviewLayoutMode> previewMode() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isEmpty) return PreviewLayoutMode.auto;
    return switch (rows.first.previewMode) {
      'split' => PreviewLayoutMode.split,
      'switch' => PreviewLayoutMode.fullScreen,
      _ => PreviewLayoutMode.auto,
    };
  }

  /// Persists the preview layout mode.
  Future<void> setPreviewMode(PreviewLayoutMode mode) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(previewMode: Value(mode.name)),
    );
  }

  /// The editor|preview split ratio (0..1; default [defaultSplitRatio]).
  Future<double> splitRatio() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? defaultSplitRatio : rows.first.splitRatio;
  }

  /// Persists the split ratio (clamped to the allowed range).
  Future<void> setSplitRatio(double ratio) async {
    await _ensureRow();
    final clamped = ratio < minSplitRatio
        ? minSplitRatio
        : ratio > maxSplitRatio
        ? maxSplitRatio
        : ratio;
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(splitRatio: Value(clamped)),
    );
  }

  /// The stored UI language id (`system`, `en` or `it`).
  Future<AppLanguage> language() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppLanguage.system
        : AppLanguage.fromId(rows.first.language);
  }

  /// Persists the UI language.
  Future<void> setLanguage(AppLanguage language) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(language: Value(language.id)),
    );
  }

  Future<void> _ensureRow() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isNotEmpty) {
      return;
    }
    await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            libraryPath: const Value(null),
          ),
        );
  }
}
