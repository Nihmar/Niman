import 'dart:io';

import 'package:drift/native.dart';
// A connection on its own isolate reports what failed over there wrapped in
// DriftRemoteException; the sqlite error behind it is how a damaged index is
// told apart from a transient failure (#368).
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';

/// Opens, repairs and deletes the index file of a library (T-ML-03, #368).
///
/// The session's own connection to each library's index goes through here:
/// [open] warms it and rebuilds a file sqlite reports as damaged, [delete]
/// removes one for a rebuild or a forgotten library, and [ensureDerived]
/// builds what a file from before an index feature lacks.
final class LibraryIndexFiles {
  /// Index files opened with [openDb] and located, for [delete], with
  /// [locate].
  ///
  /// A null [locate] leaves a file behind, which costs disk space and
  /// nothing else — the index is derived data.
  new({required this.openDb, this.locate});

  /// Builds the index database of the library at the given absolute path.
  final Future<IndexDatabase> Function(String libraryPath) openDb;

  /// Locates a library's index file, so [delete] can remove it.
  final Future<File> Function(String libraryPath)? locate;

  final AppLogger _log = const AppLogger(name: 'session');

  /// Opens the index of the library at [libraryPath] and reads it once,
  /// rebuilding the file in place when sqlite reports it damaged (#368).
  ///
  /// The index is derived data and the documented way to repair it is to
  /// delete the file and re-index (`AGENTS.md`, `IndexDatabase`), but the
  /// only code that deleted one was `forgetLibrary`, which also drops the
  /// registry row, the workspace, the device settings and the sync
  /// destination — so a disk that filled or a killed migration left a
  /// library that would not open and no way out but losing its entry. A
  /// file sqlite answers with `SQLITE_CORRUPT` or `SQLITE_NOTADB` is
  /// deleted and opened again — empty, at its schema — and the caller's
  /// scan refills it from the notes on disk.
  ///
  /// The first query is also the connection's warm-up (#315): it is what
  /// opens the file, so the tree's first flatten is never the query that
  /// pays for the sqlite open, the schema and its FTS table.
  Future<IndexDatabase> open(String libraryPath) async {
    final db = await openDb(libraryPath);
    try {
      await _warmIndex(db);
      return db;
    } on Object catch (error) {
      final damaged = _sqliteCause(error);
      if (damaged == null || !_isDamagedIndex(damaged)) {
        await _closeIndex(db);
        rethrow;
      }
      _log.warning('index of $libraryPath is damaged; rebuilding: $damaged');
      await _closeIndex(db);
      await delete(libraryPath);
      final fresh = await openDb(libraryPath);
      try {
        await _warmIndex(fresh);
      } on Object {
        await _closeIndex(fresh);
        rethrow;
      }
      return fresh;
    }
  }

  /// Deletes the index file of a library, if it can be found.
  ///
  /// The file and the write-ahead log beside it go together: a rebuilt index
  /// must not open on a stale journal. Best effort — a failure here costs
  /// disk space, not correctness, and must not turn "forget this library" or
  /// "rebuild its index" into an error.
  Future<void> delete(String libraryPath) async {
    try {
      final locate = this.locate;
      if (locate == null) return;
      final file = await locate(libraryPath);
      for (final sidecar in const ['', '-wal', '-shm']) {
        final part = File('${file.path}$sidecar');
        if (await part.exists()) {
          await part.delete();
        }
      }
    } on Object catch (error) {
      _log.warning('index file not removed ($error)');
    }
  }

  /// [IndexDatabase.ensureRecentIndex], [IndexDatabase.ensurePinnedIndex],
  /// [IndexDatabase.ensureTagCounts] and
  /// [IndexDatabase.ensureStemTrigrams],
  /// logged rather than thrown: their readers answer without them, only
  /// slower.
  Future<void> ensureDerived(IndexDatabase db) async {
    final clock = Stopwatch()..start();
    try {
      await db.ensureRecentIndex();
      await db.ensurePinnedIndex();
      await db.ensureTagCounts();
      await db.ensureStemTrigrams();
      _log.debug(
        'notes_recent, tag counts and name trigrams ready in '
        '${clock.elapsedMilliseconds} ms',
      );
    } on Object catch (error) {
      _log.warning(
        'notes_recent, tag counts or name trigrams not built: $error',
      );
    }
  }

  /// The sqlite error behind [error], or null when it holds none.
  ///
  /// A connection on its own isolate (`defaultIndexDatabase`) reports what
  /// failed over there as drift's remote exception, with the sqlite error
  /// itself as its cause.
  static SqliteException? _sqliteCause(Object error) => switch (error) {
    final SqliteException sqlite => sqlite,
    final DriftRemoteException remote
        when remote.remoteCause is SqliteException =>
      remote.remoteCause as SqliteException,
    _ => null,
  };

  /// Whether [error] says the file is unreadable: sqlite's `SQLITE_CORRUPT`
  /// and `SQLITE_NOTADB` (sqlite.org/rescode.html).
  ///
  /// What a disk that ran out of room or a killed migration leaves behind,
  /// as against a transient I/O error, which is waited out by the rescan
  /// instead of costing a full re-index.
  static bool _isDamagedIndex(SqliteException error) =>
      error.resultCode == 11 || error.resultCode == 26;

  /// Closes a connection whose open failed, so the file behind it can be
  /// deleted (Windows will not delete an open file).
  Future<void> _closeIndex(IndexDatabase db) async {
    try {
      await db.close();
    } on Object catch (error) {
      _log.debug('damaged index connection not closed cleanly ($error)');
    }
  }

  /// Reads the index connection's file once, opening it (#315): the
  /// isolate's boot, the sqlite open, the schema and the FTS table.
  ///
  /// Throws when the file cannot be read; [open] takes that as the signal
  /// that the index is damaged and rebuilds it (#368). A connection that
  /// failed this way rethrows to every reader after, so the throw is the
  /// answer, not an accident.
  Future<void> _warmIndex(IndexDatabase db) async {
    final clock = Stopwatch()..start();
    await db.customSelect('SELECT 1').get();
    _log.debug('index warm-up: ${clock.elapsedMilliseconds} ms');
  }
}
