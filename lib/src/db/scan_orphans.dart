/// The scan-scoped tables that carry a rename across directories (#302).
library;

import 'package:drift/drift.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/scan_touches.dart';

/// The notes a scan found gone, kept until its end so a note that moved to
/// a directory the walk reaches later — or has already passed — keeps its
/// id.
///
/// `scan_orphans` holds the notes of every folder walked so far that are
/// gone from disk, and their rows stay in `notes` until the scan's end;
/// `scan_gone` holds the paths to prune when no pairing claimed them. Both
/// are SQLite's, not Dart's, so a mass delete costs disk, not heap.
final class ScanOrphans {
  /// Creates the tables' keeper over [_db], leaving out what [_touches]
  /// says a write outside the scan touched.
  new(this._db, this._dao, this._touches)
    : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final ScanTouches _touches;

  final AppLogger _log;

  /// How many gone paths the prune deletes per query, so a mass move never
  /// becomes a list in memory.
  static const _prunePage = 200;

  /// Highest row id before the walk: every row above it was inserted by
  /// this scan, which is how the second pairing pass finds the fresh rows
  /// a rename may have left behind.
  int get baseline => _baseline;
  int _baseline = 0;

  /// Whether these scan's orphan tables exist — the index had rows when it
  /// started. A library with none cannot have a note that moved away from
  /// it, so the pairing is skipped and its tables never made.
  bool _pairing = false;

  /// A content-preserving rename candidate among the notes an earlier
  /// directory of this scan found gone. Asked only when the listing itself
  /// has no candidate; the answer is consumed, so one row pairs once.
  ///
  /// None or several matches pair nothing, exactly as `IndexTree.applyDiff`
  /// treats its local candidates: two identical orphans and one new note
  /// make the move ambiguous, and guessing would repoint the wrong id.
  Future<Note?> lookup(DiskEntry e, String sha) async {
    if (!_pairing) return null;
    final path = await soleMatch(sha, e.size, e.modified);
    if (path == null) return null;
    if (_touches.shields(path)) return null;
    final row = await _dao.find(path);
    if (row == null) return null;
    await consume(path);
    _log.debug('pair: "$path" -> "${e.rel}" (content unchanged)');
    return row;
  }

  /// The path of the one orphan with this digest, size and time, or null
  /// when none or several have them.
  Future<String?> soleMatch(String sha, int size, DateTime modified) async {
    final rows = await _db
        .customSelect(
          'SELECT path FROM scan_orphans '
          'WHERE sha256 = ? AND size = ? AND modified = ?',
          variables: [
            Variable<String>(sha),
            Variable<int>(size),
            Variable<int>(_seconds(modified)),
          ],
        )
        .get();
    if (rows.length != 1) return null;
    return rows.single.read<String>('path');
  }

  /// Takes the orphan at [path] out of the candidates: it paired.
  Future<void> consume(String path) =>
      _db.customStatement('DELETE FROM scan_orphans WHERE path = ?', [path]);

  /// How many orphans no pairing has claimed yet.
  Future<int> count() async {
    final count = await _db
        .customSelect('SELECT count(*) AS c FROM scan_orphans')
        .getSingle();
    return count.read<int>('c');
  }

  /// Keeps the vanished entries of one listing for the rest of the scan.
  ///
  /// A gone note with a digest becomes a rename candidate; the notes under
  /// a gone folder become candidates too — moving a folder is a rename of
  /// each note in it — while the folder's own path goes to `scan_gone`, so
  /// whatever no pairing claimed is pruned at the end. The rows themselves
  /// stay in `notes` until then: pairing repoints them, it cannot resurrect
  /// a row whose FTS, tags and links were already wiped.
  Future<void> registerGone(Map<String, Note> old, Set<String> goneLeft) async {
    for (final rel in goneLeft) {
      final row = old[rel];
      if (row == null) continue;
      if (row.isDir) {
        final range = subtreePathRange(rel);
        await _db.customStatement(
          'INSERT OR IGNORE INTO scan_orphans '
          '(id, path, sha256, size, modified) '
          'SELECT id, path, sha256, size, modified FROM notes '
          'WHERE is_dir = 0 AND sha256 IS NOT NULL '
          'AND path >= ? AND path < ?',
          [range.from, range.to],
        );
      } else if (row.sha256 case final String sha) {
        await _db.customStatement(
          'INSERT OR IGNORE INTO scan_orphans '
          '(id, path, sha256, size, modified) VALUES (?, ?, ?, ?, ?)',
          [row.id, row.path, sha, row.size, _seconds(row.modified)],
        );
      }
      await _db.customStatement(
        'INSERT OR IGNORE INTO scan_gone (path) VALUES (?)',
        [rel],
      );
    }
  }

  /// Deletes every path the walk found gone and no pairing claimed, one
  /// page at a time, reporting the top-level ones. `scan_gone` holds only
  /// the entries of a present directory's listing, so no path here is
  /// inside another.
  Future<({bool wrote, Set<String> removed})> pruneGone() async {
    var wrote = false;
    final removed = <String>{};
    if (!_pairing) return (wrote: wrote, removed: removed);
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT path FROM scan_gone ORDER BY path LIMIT $_prunePage',
          )
          .get();
      if (rows.isEmpty) break;
      for (final row in rows) {
        final path = row.read<String>('path');
        // Made again, or written inside, since the scan saw it gone.
        final deleted = _touches.shields(path)
            ? 0
            : await _dao.deleteSubtree(path);
        await _db.customStatement('DELETE FROM scan_gone WHERE path = ?', [
          path,
        ]);
        if (deleted > 0) {
          wrote = true;
          removed.add(path);
        }
      }
    }
    return (wrote: wrote, removed: removed);
  }

  /// Creates the scan's temp tables, and captures the row id the walk
  /// starts from. A library with no rows has no orphans to pair: the tables
  /// stay away, and a fresh index of a million notes pays nothing for a
  /// pairing it cannot need.
  Future<void> open({required bool hadRows}) async {
    await close();
    _pairing = hadRows;
    if (!hadRows) return;
    _baseline = await _dao.maxId();
    await _db.customStatement(
      'CREATE TEMP TABLE scan_orphans '
      '(id INTEGER PRIMARY KEY, path TEXT UNIQUE NOT NULL, '
      'sha256 TEXT NOT NULL, size INTEGER NOT NULL, modified INTEGER NOT NULL)',
    );
    await _db.customStatement(
      'CREATE INDEX scan_orphans_key ON scan_orphans (sha256, size, modified)',
    );
    await _db.customStatement(
      'CREATE TEMP TABLE scan_gone (path TEXT PRIMARY KEY)',
    );
  }

  /// Drops the scan's temp tables.
  Future<void> close() async {
    _pairing = false;
    await _db.customStatement('DROP TABLE IF EXISTS scan_orphans');
    await _db.customStatement('DROP TABLE IF EXISTS scan_gone');
  }

  static int _seconds(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;
}
