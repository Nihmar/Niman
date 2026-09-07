import 'package:copist/src/db/database.dart';
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

/// The default editor share of the split.
const double defaultSplitRatio = 0.55;

/// The lower bound of the allowed split range.
const double minSplitRatio = 0.2;

/// The upper bound of the allowed split range.
const double maxSplitRatio = 0.8;

/// Per-library local settings, keyed by the absolute library path.
///
/// Defaults: trash enabled, 10 history versions.
final class LibrarySettingsRepo {
  /// Creates the repo over the given [CopistDatabase].
  LibrarySettingsRepo(this._db);

  final CopistDatabase _db;

  /// Whether deletes move notes into `.trash/` (default true).
  Future<bool> isTrashEnabled(String libraryPath) async {
    final rows = await (
      _db.select(_db.librarySettings)
        ..where((t) => t.path.equals(libraryPath))
    ).get();
    return rows.isEmpty || rows.first.trashEnabled;
  }

  /// Sets the trash toggle for `libraryPath`.
  Future<void> setTrashEnabled(
    String libraryPath, {
    required bool enabled,
  }) async {
    await _ensureRow(libraryPath);
    await (_db.update(_db.librarySettings)
          ..where((t) => t.path.equals(libraryPath)))
        .write(LibrarySettingsCompanion(trashEnabled: Value(enabled)));
  }

  /// The user-chosen quick note (library-relative path), or null when the
  /// default `Quick note.md` at the library root is used.
  Future<String?> quickNotePath(String libraryPath) async {
    final rows = await (
      _db.select(_db.librarySettings)
        ..where((t) => t.path.equals(libraryPath))
    ).get();
    return rows.isEmpty ? null : rows.first.quickNotePath;
  }

  /// Sets (or clears, with null) the user-chosen quick note.
  Future<void> setQuickNotePath(
    String libraryPath, {
    required String? path,
  }) async {
    await _ensureRow(libraryPath);
    await (_db.update(_db.librarySettings)
          ..where((t) => t.path.equals(libraryPath)))
        .write(LibrarySettingsCompanion(quickNotePath: Value(path)));
  }

  /// Ensures a settings row exists for `libraryPath`.
  Future<void> _ensureRow(String libraryPath) async {
    final rows = await (
      _db.select(_db.librarySettings)
        ..where((t) => t.path.equals(libraryPath))
    ).get();
    if (rows.isNotEmpty) {
      return;
    }
    await _db.into(_db.librarySettings).insert(
      LibrarySettingsCompanion.insert(
        path: libraryPath,
        trashEnabled: true,
        historyVersions: 10,
      ),
    );
  }
}

/// Global app settings, a single row (id 1).
final class AppSettingsRepo {
  /// Creates the repo over the given [CopistDatabase].
  AppSettingsRepo(this._db);

  final CopistDatabase _db;

  /// The last opened library root, or null.
  Future<String?> lastLibraryPath() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.libraryPath;
  }

  /// Persists `path` as the last opened library root.
  Future<void> setLastLibraryPath(String? path) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(libraryPath: Value(path)));
  }

  /// Whether the debug log buffer records events (default true).
  Future<bool> debugLogsEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.debugLogsEnabled;
  }

  /// Persists the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(debugLogsEnabled: Value(enabled)));
  }

  /// Whether the note editor shows the row-number column (default true).
  Future<bool> lineNumbersEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.lineNumbers;
  }

  /// Persists the line-numbers toggle.
  Future<void> setLineNumbersEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(lineNumbers: Value(enabled)));
  }

  /// Whether the note editor focuses (shows the keyboard) on note open
  /// (default false).
  Future<bool> editorAutofocusEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isNotEmpty && rows.first.editorAutofocus;
  }

  /// Persists the keyboard-on-open toggle.
  Future<void> setEditorAutofocusEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(editorAutofocus: Value(enabled)));
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
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(previewMode: Value(mode.name)));
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
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(splitRatio: Value(clamped)));
  }

  /// The library tree sort order (default [TreeSort.nameAsc]).
  Future<TreeSort> treeSort() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isEmpty) return TreeSort.nameAsc;
    return switch (rows.first.treeSort) {
      'nameDesc' => TreeSort.nameDesc,
      _ => TreeSort.nameAsc,
    };
  }

  /// Persists the library tree sort order.
  Future<void> setTreeSort(TreeSort sort) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .write(AppSettingsCompanion(treeSort: Value(sort.name)));
  }

  Future<void> _ensureRow() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isNotEmpty) {
      return;
    }
    await _db.into(_db.appSettings).insert(
      AppSettingsCompanion.insert(
        id: const Value(1),
        libraryPath: const Value(null),
      ),
    );
  }
}
