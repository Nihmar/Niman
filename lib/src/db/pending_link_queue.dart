/// The link edges a scan defers to its end (#302).
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/dangling_link_store.dart';
import 'package:niman/src/db/index_content_store.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/resolver.dart';

/// Queues the link edges a scan parses and writes them once the whole tree
/// is mirrored.
///
/// A target may live in a directory the walk has not reached, or move into
/// one it has already passed, so the edges go to the durable
/// `pending_links` table as they are parsed and resolve at the end, against
/// the final tree.
final class PendingLinkQueue {
  /// Creates the queue over [_db], keeping dead links in [_store]'s
  /// dangling-link store.
  new(this._db, this._store);

  final IndexDatabase _db;

  final IndexContentStore _store;

  /// How many deferred link edges resolve and write per query.
  static const _linkPage = 500;

  /// Queues [links] for [writePending], which resolves them once the
  /// whole tree is mirrored. Durable, so a scan that never reaches its end
  /// leaves them for the next one instead of losing them.
  Future<void> defer(Iterable<QueuedLink> links) async {
    final batch = links.toList(growable: false);
    if (batch.isEmpty) return;
    await _db.batch((b) {
      for (final link in batch) {
        b.insert(
          _db.pendingLinks,
          PendingLinksCompanion.insert(
            noteId: link.fromNote,
            target: link.target,
            kind: link.kind,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Resolves and writes every link edge the walk queued, against the tree
  /// as it stands after the pairing and the prune: a link to a note a later
  /// directory introduced, or to one that moved, finds its row. Edges a
  /// killed scan left queued are resolved here too.
  ///
  /// One page of pending links at a time — the distinct targets of a page
  /// resolve in one batch, and the page is deleted with the edges it wrote
  /// — so a first index of a million notes never holds the library's edges
  /// in memory.
  Future<void> writePending() async {
    while (true) {
      final rows = await _db
          .customSelect(
            'SELECT l.rowid AS rowid, l.note_id AS note_id, '
            'l.target AS target, l.kind AS kind, n.path AS path '
            'FROM pending_links AS l LEFT JOIN notes AS n ON n.id = l.note_id '
            'ORDER BY l.rowid LIMIT $_linkPage',
          )
          .get();
      if (rows.isEmpty) break;
      // A link resolves from the note it is written in: a `..` walks from
      // that note's folder (#491).
      LinkQuery queryOf(QueryRow row) => (
        target: row.read<String>('target'),
        from: row.readNullable<String>('path'),
        markdown: row.read<String>('kind') == 'md',
      );
      final resolved = await LinkResolver(_db)
          .resolveQueries({for (final row in rows) queryOf(row)});
      final last = rows.last.read<int>('rowid');
      final waiting = <WaitingLink>[];
      await _db.transaction(() async {
        for (final row in rows) {
          final fromNote = row.read<int>('note_id');
          final outcome = resolved[queryOf(row)];
          // A note deleted since it queued the link has no row to wait for.
          if (outcome is UnresolvedNote &&
              row.readNullable<String>('path') != null) {
            waiting.add((
              noteId: fromNote,
              query: queryOf(row),
              kind: row.read<String>('kind'),
            ));
          }
          if (outcome is! ResolvedNote || outcome.note.id == fromNote) {
            continue;
          }
          await _db.customInsert(
            'INSERT OR IGNORE INTO note_links (from_note, to_note, kind) '
            'VALUES (?, ?, ?)',
            variables: [
              Variable<int>(fromNote),
              Variable<int>(outcome.note.id),
              Variable<String>(row.read<String>('kind')),
            ],
          );
        }
        await _db.customStatement(
          'DELETE FROM pending_links WHERE rowid <= ?',
          [last],
        );
        // Dead links are kept for the note that answers them later (#974).
        await _store.dangling.keep(waiting);
      });
    }
  }
}
