import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:niman/src/library/session_events.dart';
import 'package:niman/src/sync/sync_service.dart';

/// Applies the watcher's batches of the open library to its index, its
/// open editors and its sync queue (#1055, #1062).
///
/// Reads the session's current state through the getters it is given: a
/// batch that lands while no library is ready is dropped.
final class WatchBatchApplier {
  /// An applier over the session's [indexer], [root] and [sync], which
  /// runs only while [ready]; [walkWhole] walks the library after the watch
  /// missed changes, and [events] carries the paths to the open editors.
  new({
    required this.indexer,
    required this.root,
    required this.ready,
    required this.walkWhole,
    required this.events,
    required this.sync,
  });

  /// The open library's indexer, or null while none is open.
  final Indexer? Function() indexer;

  /// The open library's root, or null while none is open.
  final String? Function() root;

  /// Whether the library is open and ready.
  final bool Function() ready;

  /// Walks the library at the given root whole, the rescan's failures
  /// handled.
  final Future<void> Function(String root) walkWhole;

  /// Where the watcher's paths are announced ([SessionEvents.externalChanges]).
  final SessionEvents events;

  /// The open library's sync, or null while none is open.
  final LibrarySyncService? Function() sync;

  final AppLogger _log = const AppLogger(name: 'session');

  /// Applies [batch].
  Future<void> apply(WatchBatch batch) async {
    _log.debug(
      'watch batch: ${batch.paths.length} path(s), '
      '${batch.resyncDirs.length} resync dir(s)',
    );
    final indexer = this.indexer();
    final root = this.root();
    if (indexer == null || root == null || !ready()) {
      return;
    }
    if (batch.missedChanges) {
      // The watch was down for a while: what changed meanwhile left no
      // event, and waiting for the periodic rescan leaves a note saved
      // then out of the index for minutes. The root itself cannot be
      // resynced (`Indexer.resync` passes over it), so it is walked whole.
      _log.info('watch batch: the watch restarted, walking the library');
      await walkWhole(root);
      if (!ready()) return;
    }
    try {
      for (final dir in batch.resyncDirs) {
        await indexer.resync(root, dir);
      }
      if (batch.paths.isNotEmpty) {
        await indexer.applyEvents(root, batch.paths);
      }
      // The editors that hold those notes open (#1055), before the sync's
      // probe below: they have no reason to wait for it.
      if (batch.paths.isNotEmpty) {
        events.externalChanged(batch.paths.toSet());
      }
      // What changed behind the ops' back (another app, a background
      // isolate, a hand edit) reaches the sync queue this way. Awaited, so
      // the batch queue runs the probes one batch at a time: left to race,
      // an older batch's answer could be queued after a newer one's.
      await sync()?.watched(batch.paths, batch.resyncDirs);
    } on Object catch (error) {
      // Transient watcher errors are covered by the periodic rescan.
      _log.warning('watch batch failed: $error');
    }
  }
}
