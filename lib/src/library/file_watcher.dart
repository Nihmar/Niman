import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// A batch of filesystem changes delivered by a [FileWatcher].
final class WatchBatch {
  /// Creates a batch of changed paths.
  const new({
    required this.paths,
    required this.resyncDirs,
    this.missedChanges = false,
  });

  /// Changed absolute paths; for renames this is the OLD path (the new
  /// path is unknown to the OS event).
  final List<String> paths;

  /// Directories to resync fully, as absolute paths: parents of rename
  /// events, whose new path is not part of the event stream.
  final List<String> resyncDirs;

  /// Whether the watch was down for a while — its source stream ended and
  /// was resubscribed to — so changes made meanwhile left no event, and
  /// only a walk of the whole library finds them.
  final bool missedChanges;
}

/// One raw change, as [FileWatcher]'s coalescing sees it.
///
/// `dart:io` seals [FileSystemEvent] and its subclasses, so nothing
/// outside the SDK can build one. The OS stream is mapped to this on the
/// way in, which is what lets a test drive the coalescing from a stream
/// it owns rather than from real filesystem notifications, whose arrival
/// time is the machine's to decide.
final class WatchChange {
  /// A change to [path].
  const new(this.path) : destination = null, isMove = false;

  /// A rename away from [path], to [destination] when the OS reports one.
  const new move(this.path, {this.destination}) : isMove = true;

  /// The changed absolute path; for a move, the OLD path.
  final String path;

  /// Where a move landed, when the OS knows; null otherwise.
  final String? destination;

  /// Whether this is a move, whose parent directory needs a full resync.
  final bool isMove;
}

/// Where a [FileWatcher] gets its raw changes: the OS watch on the root,
/// or, in tests, a stream the test feeds itself.
typedef WatchSource = Stream<WatchChange> Function(String root);

/// Recursively watches [root] for changes, coalescing raw events into
/// [WatchBatch]es: the first change opens a window of [debounce], and
/// everything arriving while it is open ships as one batch.
///
/// The window is not extended by later changes, so a burst longer than
/// [debounce] arrives as several batches instead of holding the index
/// back until the burst ends.
///
/// On Linux the recursive watch is inotify-backed; on Android the same
/// mechanism applies. When the OS cannot deliver every event (FUSE, inotify
/// limits), the periodic full rescan in the library controller is the
/// safety net (see the M1 plan risks).
///
/// A source stream that *ends* — an inotify limit, a FUSE hiccup, the
/// directory going away — is resubscribed to, with a backoff, so the watch
/// outlives one stream, and a batch flagged [WatchBatch.missedChanges]
/// ships as soon as the new one is in place; a burst larger than the pending
/// caps ships as
/// several batches instead of growing one unbounded list.
final class FileWatcher {
  /// Creates a watcher for [root] with the given [debounce] window;
  /// [source] replaces the OS watch and is injected in tests.
  new(
    this.root, {
    this.debounce = defaultDebounce,
    this.restartBackoff = defaultRestartBackoff,
    WatchSource? source,
  }) : _source = source ?? _watchFileSystem;

  /// How long a batching window stays open, by default.
  static const defaultDebounce = Duration(milliseconds: 250);

  /// How long the first resubscribe waits after the source stream ended;
  /// later attempts double it, up to [maxRestartBackoff].
  static const defaultRestartBackoff = Duration(seconds: 1);

  /// The longest wait between resubscribe attempts.
  static const maxRestartBackoff = Duration(seconds: 30);

  /// How many distinct paths one pending batch lists before it ships.
  /// Past it the batch is sent as it stands and a fresh window opens: a
  /// burst arrives as several bounded batches, never as one unbounded
  /// list, and no change is dropped. The count is of distinct paths — the
  /// batch is a coalesced set — so no arrival rate can fill it.
  static const maxPendingPaths = 4096;

  /// How many directories one pending batch asks to resync before it
  /// ships. Each resync walks a whole subtree, so this sits well below
  /// [maxPendingPaths]; it bounds [WatchBatch.resyncDirs] the same way.
  static const maxPendingResyncDirs = 256;

  static const AppLogger _log = AppLogger(name: 'watcher');

  /// The watched root directory (absolute path).
  final String root;

  /// How long the batching window stays open after the change that
  /// opened it. Later changes do not extend it.
  final Duration debounce;

  /// How long the first resubscribe waits after the source stream ended;
  /// later attempts double it, up to [maxRestartBackoff].
  final Duration restartBackoff;

  final WatchSource _source;
  final StreamController<WatchBatch> _controller =
      StreamController<WatchBatch>.broadcast();
  final Set<String> _paths = <String>{};
  final Set<String> _resyncDirs = <String>{};

  /// Whether the pending batch reports a gap in the watch
  /// ([WatchBatch.missedChanges]).
  bool _missedChanges = false;

  /// Cancelled in [stop]; the lint cannot see the cross-method lifecycle.
  // ignore: cancel_subscriptions
  StreamSubscription<WatchChange>? _subscription;
  Timer? _timer;

  /// The pending resubscribe, armed when the source stream ends; cancelled
  /// in [stop].
  Timer? _restartTimer;
  int _restartAttempts = 0;
  bool _started = false;
  bool _closed = false;

  /// Batches of changed paths, coalesced by the debounce window.
  Stream<WatchBatch> get events => _controller.stream;

  /// Begins watching. Each change is coalesced; move events additionally
  /// resync their parent directory, since the destination may be unknown
  /// to the OS event.
  Future<void> start() async {
    if (_started || _closed) {
      throw StateError('Watcher is already started or closed');
    }
    _started = true;
    _log.info('watcher start: "$root" (recursive)');
    _listen(_source(root));
  }

  static Stream<WatchChange> _watchFileSystem(String root) =>
      Directory(root).watch(recursive: true).map(_toChange);

  static WatchChange _toChange(FileSystemEvent event) {
    if (event is FileSystemMoveEvent) {
      // The destination may be unknown to the OS; the parent is resynced
      // either way, and the destination indexed when it is known.
      _log.debug(
        'watcher event: move "${event.path}" -> '
        '${event.destination ?? 'unknown'}',
      );
      return WatchChange.move(event.path, destination: event.destination);
    }
    _log.debug('watcher event: ${_typeName(event)} "${event.path}"');
    return WatchChange(event.path);
  }

  void _listen(Stream<WatchChange> stream) {
    _subscription = stream.listen(
      _onEvent,
      onError: (Object error) {
        // Transient FS errors are recoverable via the periodic rescan, but
        // they are exactly what this log is meant to surface.
        _log.warning('watcher stream error: $error');
      },
      onDone: _onStreamDone,
    );
  }

  void _onEvent(WatchChange change) {
    // A delivered change proves this watch works, so a later end starts
    // over from the first, short wait instead of the long one.
    _restartAttempts = 0;
    _onChange(change);
  }

  /// The source stream ended on its own (an inotify limit, a FUSE hiccup,
  /// the directory going away). The watch does not come back by itself,
  /// and the periodic rescan alone is a long delay for the user's own
  /// edits, so resubscribe — with [restartBackoff] doubling up to
  /// [maxRestartBackoff], the shape `syncBackoff` uses, so a source that
  /// keeps ending immediately is not hammered.
  void _onStreamDone() {
    _subscription = null;
    if (_closed) return;
    _scheduleRestart('stream ended before stop()');
  }

  void _scheduleRestart(String reason) {
    final wait = _nextRestartWait();
    _restartAttempts++;
    _log.warning('watcher $reason; resubscribing in ${wait.inMilliseconds} ms');
    _restartTimer = Timer(wait, _restart);
  }

  Duration _nextRestartWait() {
    // 2^8 · the first wait already passes the cap; the clamp keeps the
    // shift small.
    final factor = 1 << math.min(_restartAttempts, 8);
    final wait = restartBackoff * factor;
    return wait > maxRestartBackoff ? maxRestartBackoff : wait;
  }

  void _restart() {
    _restartTimer = null;
    if (_closed) return;
    final Stream<WatchChange> stream;
    try {
      stream = _source(root);
    } on Object catch (error) {
      // The same failure that ended the stream (the root gone, a watch
      // limit) can also refuse a new one; keep trying, on the backoff.
      _log.warning('watcher resubscribe failed: $error');
      _scheduleRestart('resubscribe failed');
      return;
    }
    _listen(stream);
    // Nothing watched between the end and this subscription, so a change
    // made then left no event. Said now, once the new watch is in place:
    // whatever the walk this asks for misses, the new watch sees.
    _missedChanges = true;
    _flush();
  }

  void _onChange(WatchChange change) {
    if (_closed) return;
    if (change.isMove) {
      _addResyncDir(p.dirname(change.path));
    }
    _addPath(change.path);
    final destination = change.destination;
    if (destination != null) {
      _addPath(destination);
    }
    _timer ??= Timer(debounce, _flush);
  }

  /// Adds one changed path, unless that would push the pending batch past
  /// [maxPendingPaths]: then the batch ships as it stands and this path
  /// opens the next one. Nothing is dropped — a storm is delivered as
  /// several batches instead of one list that grows with the burst.
  void _addPath(String path) {
    if (!_paths.contains(path) && _paths.length >= maxPendingPaths) {
      _flush();
    }
    _paths.add(path);
  }

  /// Adds one directory to resync, bounded like [_addPath] by
  /// [maxPendingResyncDirs] (a resync walks a subtree, so far fewer of
  /// them are pending at once).
  void _addResyncDir(String dir) {
    if (!_resyncDirs.contains(dir) &&
        _resyncDirs.length >= maxPendingResyncDirs) {
      _flush();
    }
    _resyncDirs.add(dir);
  }

  static String _typeName(FileSystemEvent event) {
    return switch (event) {
      FileSystemCreateEvent() => 'create',
      FileSystemModifyEvent() => 'modify',
      FileSystemDeleteEvent() => 'delete',
      _ => 'type=${event.type}',
    };
  }

  void _flush() {
    // Cancelling, not just dropping the handle: a full pending set flushes
    // before its window closed, and the armed timer must not fire a second,
    // empty batch afterwards.
    _timer?.cancel();
    _timer = null;
    if (_closed) return;
    final batch = WatchBatch(
      paths: _paths.toList(),
      resyncDirs: _resyncDirs.toList(),
      missedChanges: _missedChanges,
    );
    _paths.clear();
    _resyncDirs.clear();
    _missedChanges = false;
    _controller.add(batch);
  }

  /// Stops watching and closes the [events] stream.
  Future<void> stop() async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _timer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    final sub = _subscription;
    _subscription = null;
    _paths.clear();
    _resyncDirs.clear();
    await sub?.cancel();
    await _controller.close();
  }
}
