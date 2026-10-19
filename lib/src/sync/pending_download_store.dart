import 'package:drift/drift.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

/// The downloads a sync is writing straight to their final names, kept so
/// a run that was killed half way finds them again (docs/records/sync.md,
/// "How a new file is written").
///
/// A path is marked before the first byte is written and cleared when the
/// agreed item row is recorded, in the same transaction. A mark found at the
/// start of a run means a download did not finish: whatever file is at that
/// path may be a part of the server's.
final class PendingDownloadStore {
  /// A store over [_db]; [now] is the clock for the marks (tests).
  new(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  /// Marks [path] of the library at [libraryPath] as being written.
  Future<void> mark(String libraryPath, String path) async {
    await _db
        .into(_db.syncPendingDownloads)
        .insertOnConflictUpdate(
          SyncPendingDownloadsCompanion.insert(
            libraryPath: p.normalize(libraryPath),
            path: path,
            startedAtMs: _now().millisecondsSinceEpoch,
          ),
        );
  }

  /// Clears the mark of [path].
  Future<void> clear(String libraryPath, String path) async {
    await (_db.delete(_db.syncPendingDownloads)..where(
          (t) =>
              t.libraryPath.equals(p.normalize(libraryPath)) &
              t.path.equals(path),
        ))
        .go();
  }

  /// Records [item], the row both sides now agree on for a file written
  /// straight to its final name, and clears its mark: both or neither.
  Future<void> recorded(SyncItem item) => _db.transaction(() async {
    final root = p.normalize(item.libraryPath);
    await _db
        .into(_db.syncItems)
        .insertOnConflictUpdate(item.copyWith(libraryPath: root));
    await clear(root, item.path);
  });

  /// The marked paths of the library at [libraryPath], oldest first.
  Future<List<String>> pending(String libraryPath) async {
    final rows =
        await (_db.select(_db.syncPendingDownloads)
              ..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))
              ..orderBy([(t) => OrderingTerm.asc(t.startedAtMs)]))
            .get();
    return [for (final row in rows) row.path];
  }

  /// Forgets every mark of the library at [libraryPath].
  Future<int> clearAll(String libraryPath) async {
    final removed = await (_db.delete(
      _db.syncPendingDownloads,
    )..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))).go();
    if (removed > 0) _log.info('pending: dropped $removed marks');
    return removed;
  }
}
