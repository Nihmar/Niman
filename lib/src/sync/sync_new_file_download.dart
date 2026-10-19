import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/transfers/direct_write.dart';
import 'package:path/path.dart' as p;

/// The download step for a path with no local file: the server's copy is
/// written straight to its final name, with no temp and no rename
/// (docs/records/sync.md, "How a new file is written").
///
/// A file that exists already is replaced the other way round — through a
/// temp, renamed over it — because there the version the user has must
/// stay whole until the new one is complete. For a new file there is no
/// such version, and a rename onto a name per file is what a ransomware
/// monitor looks for.
///
/// What this step owes in return is the file it leaves behind when a run
/// is killed mid-write: the path is marked in the sync store before the
/// first byte and the mark is cleared in the transaction that records the
/// item row, so the next run (`SyncDownloadRecovery`) finds a partial file
/// by the mark.
final class SyncNewFileDownload {
  /// The step for the library at [root].
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.sides,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: the new file reaches the index through them.
  final NoteOps ops;

  /// The sync state: the pending marks and the agreed rows.
  final SyncStore store;

  /// Reads, checks and records both sides of a path.
  final SyncSides sides;

  static const _log = AppLogger(name: 'sync');

  /// Downloads the file of [d], which has no local copy, and records the
  /// row both sides now agree on. A file that appears at the path before the
  /// download creates it — found by the check, or by the exclusive create —
  /// makes the step skip and is left as it is; the next run decides again.
  Future<SyncStepOutcome> run(SyncRunContext c, SyncDecision d) async {
    final path = d.path;
    // The scan saw no file: a file there now is not ours to write over.
    await sides.localStillAsPlanned(c, path);
    final pending = store.pendingDownloads;
    await pending.mark(root, path);
    final NewFileDownload got;
    try {
      got = await ops.syncCreate(path, () => sides.fetchNew(c, path));
    } on DirectWriteRefused {
      // A file came while the copy was on its way: somebody else's, left as
      // it is, with nothing of ours on the disk to look for. The same skip as
      // a file that changed under a temp download; the next run decides.
      await _unmark(path);
      return SyncStepOutcome.skipped;
    } on Object {
      // The transfer removes what it wrote when it fails; the mark stays
      // only if something is left that a later run has to look at.
      if (!await _fileThere(path)) await _unmark(path);
      rethrow;
    }
    final local = await sides.stat(path);
    if (local == null) {
      await _unmark(path);
      throw const SyncStepFailure('downloaded but not on disk');
    }
    await pending.recorded(
      await sides.row(
        c,
        path,
        sha: got.download.sha256,
        local: local,
        remote: sides.remoteFrom(c, path, got.download),
      ),
    );
    return SyncStepOutcome.done;
  }

  Future<bool> _fileThere(String path) async {
    final stat = await FileStat.stat(p.join(root, path));
    return stat.type != FileSystemEntityType.notFound;
  }

  /// Clears the mark of [path], without letting a failure to do so replace
  /// the one being reported.
  Future<void> _unmark(String path) async {
    try {
      await store.pendingDownloads.clear(root, path);
    } on Object catch (e) {
      _log.warning('pending: "$path" not unmarked: $e');
    }
  }
}
