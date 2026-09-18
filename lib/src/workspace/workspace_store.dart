import 'dart:convert';

import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// Where each library's [Workspace] is kept on this device (issue #23):
/// the app database's `workspaces` table, one row per library.
final class WorkspaceStore {
  /// A store over [_db].
  new(this._db);

  final AppDatabase _db;

  /// What was left open in [libraryPath]; nothing open when no row, or an
  /// unreadable one, is there.
  Future<Workspace> load(String libraryPath) async {
    final row =
        await (_db.select(_db.workspaces)
              ..where((t) => t.libraryPath.equals(p.normalize(libraryPath))))
            .getSingleOrNull();
    if (row == null) return Workspace.empty;
    try {
      return Workspace.fromJson(jsonDecode(row.state));
    } on FormatException {
      return Workspace.empty;
    }
  }

  /// Keeps [workspace] as what is open in [libraryPath].
  Future<void> save(String libraryPath, Workspace workspace) async {
    await _db
        .into(_db.workspaces)
        .insertOnConflictUpdate(
          WorkspacesCompanion.insert(
            libraryPath: p.normalize(libraryPath),
            state: jsonEncode(workspace.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Forgets [libraryPath]'s workspace (the library itself was forgotten).
  Future<void> remove(String libraryPath) async {
    await (_db.delete(
      _db.workspaces,
    )..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))).go();
  }
}
