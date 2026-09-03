import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart';

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
