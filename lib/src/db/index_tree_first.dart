/// The first index of a library, the tree before the notes (#302).
library;

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_change.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/index_tree.dart';

/// Writes the walk's rows into an empty index without reading a note, a
/// directory at a time, so a first open waits for the tree and not for the
/// notes; the content is owed to the full scan that follows.
///
/// What [run] does and why is told at `IndexReconciler.treeFirst`, its
/// entry point.
final class IndexTreeFirst {
  /// Creates the pass over the shared index handles.
  new(this._db, this._dao, this._tree)
    : _log = const AppLogger(name: 'indexer');

  final IndexDatabase _db;

  final NoteDao _dao;

  final IndexTree _tree;

  final AppLogger _log;

  /// Mirrors the tree under [root] when the index has no rows. Answers
  /// whether it wrote; [onChanged] fires when it did.
  Future<bool> run(
    String root, {
    void Function(IndexChange change)? onChanged,
  }) async {
    if (await _dao.hasRows()) return false;
    var wrote = false;
    var entries = 0;
    final walk = await DirWalker.start(root);
    Object? failure;
    try {
      for (
        var listing = await walk.next();
        listing != null;
        listing = await walk.next()
      ) {
        listing.logs.forEach(_log.debug);
        if (listing.failed) continue;
        entries += listing.entries.length;
        final dirRel = listing.rel;
        final dirRow = dirRel.isEmpty ? null : await _dao.find(dirRel);
        final old = <String, Note>{dirRel: ?dirRow};
        final listingEntries = <DiskEntry>[
          if (dirRow != null)
            DiskEntry(
              rel: dirRel,
              name: listing.name,
              isDir: true,
              size: 0,
              modified: listing.modified,
              created: listing.created,
            ),
          ...listing.entries,
        ];
        await _db.transaction(() async {
          final result = await _tree.applyDiff(
            entries: listingEntries,
            old: old,
            shas: const <String, String>{},
            contents: const <String, NoteContent>{},
            scope: dirRel,
            scopeParentId: dirRow?.parent ?? 0,
          );
          wrote |= result.wrote;
        });
      }
    } catch (error) {
      failure = error;
      rethrow;
    } finally {
      await walk.close(error: failure);
    }
    if (entries == 0) return false;
    _log.info(
      'first index $root: the tree first, $entries entr(ies); '
      'the notes after it',
    );
    if (wrote) {
      final cb = onChanged;
      if (cb != null) cb(IndexChange.tree);
    }
    return wrote;
  }
}
