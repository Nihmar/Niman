import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/temp_sweep_blocking.dart'
    show sweepStaleTempFiles;
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/library/trash_cleaner.dart' as trash;

/// The upkeep an open library gets behind its ready bump: each one best
/// effort, since the library is open and usable whatever they run into.
final class LibraryOpenChores {
  /// The chores, logged as the session's.
  const new();

  static const _log = AppLogger(name: 'session');

  /// Prepares the tree's first query off the critical path: the root's
  /// first page in the library's order, through [NoteDao.warmUpTree], which
  /// runs the very read the first flatten does (its `LIMIT` is bound).
  ///
  /// Not the root's every row, which is what it read until the tree began
  /// to page (#1064) and went on reading after: 850 ms for a root of 200 000
  /// notes, each row of it sent to this isolate to warm a statement nothing
  /// ran (#1135).
  Future<void> warmUpTree(NoteDao dao, TreeSort sort) async {
    try {
      await dao.warmUpTree(sort: sort);
    } on Object catch (error) {
      _log.debug('tree warm-up failed ($error)');
    }
  }

  /// Runs the automatic trash empty for a library that asked for one,
  /// and swallows whatever it runs into: the library is open and usable
  /// either way, and a trash that could not be emptied is not a reason to
  /// fail the open behind the user's back.
  Future<void> autoEmptyTrash(NoteOperations ops, int days) async {
    if (days <= 0) return;
    try {
      await trash.autoEmptyTrash(ops, maxAgeDays: days);
    } on Object catch (error) {
      _log.error('auto-empty failed: $error');
    }
  }

  /// Sweeps the stray `.niman-tmp-*` files a killed write left in the open
  /// library (issue #379).
  ///
  /// Runs once per open, on a background isolate like the index walk: the
  /// rename onto a target is the only thing that removes a write's temp, so
  /// a process killed between the two leaves the temp behind, and nothing
  /// else notices it — the walk and the sync both skip dot names. The age
  /// guard in [sweepStaleTempFiles] keeps a write still in flight safe.
  /// Whatever it runs into is logged and swallowed: the library is open and
  /// usable either way.
  Future<void> sweepStaleTemps(String abs) async {
    try {
      final removed = await IsolateGauge.run(
        () => sweepStaleTempFiles(abs),
        'sweep temps "$abs"',
      );
      if (removed > 0) {
        _log.info('swept $removed stale temp file(s) in $abs');
      }
    } on Object catch (error) {
      _log.warning('temp sweep failed for $abs: $error');
    }
  }
}
