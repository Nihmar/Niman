import 'dart:async';
import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// A batch of filesystem changes delivered by a [FileWatcher].
final class WatchBatch {
  /// Creates a batch of changed paths.
  const new({required this.paths, required this.resyncDirs});

  /// Changed absolute paths; for renames this is the OLD path (the new
  /// path is unknown to the OS event).
  final List<String> paths;

  /// Directories to resync fully, as absolute paths: parents of rename
  /// events, whose new path is not part of the event stream.
  final List<String> resyncDirs;
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
final class FileWatcher {
  /// Creates a watcher for [root] with the given [debounce] window;
  /// [source] replaces the OS watch and is injected in tests.
  new(this.root, {this.debounce = defaultDebounce, WatchSource? source})
    : _source = source ?? _watchFileSystem;

  /// How long a batching window stays open, by default.
  static const defaultDebounce = Duration(milliseconds: 250);

  static const AppLogger _log = AppLogger(name: 'watcher');

  /// The watched root directory (absolute path).
  final String root;

  /// How long the batching window stays open after the change that
  /// opened it. Later changes do not extend it.
  final Duration debounce;

  final WatchSource _source;
  final StreamController<WatchBatch> _controller =
      StreamController<WatchBatch>.broadcast();
  final Set<String> _paths = <String>{};
  final Set<String> _resyncDirs = <String>{};

  /// Cancelled in [stop]; the lint cannot see the cross-method lifecycle.
  // ignore: cancel_subscriptions
  StreamSubscription<WatchChange>? _subscription;
  Timer? _timer;
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
      _onChange,
      onError: (Object error) {
        // Transient FS errors are recoverable via the periodic rescan, but
        // they are exactly what this log is meant to surface.
        _log.warning('watcher stream error: $error');
      },
      onDone: () {
        _log.warning('watcher stream closed before stop()');
        _subscription = null;
      },
    );
  }

  void _onChange(WatchChange change) {
    if (_closed) return;
    if (change.isMove) {
      _resyncDirs.add(p.dirname(change.path));
    }
    _paths.add(change.path);
    final destination = change.destination;
    if (destination != null) {
      _paths.add(destination);
    }
    _timer ??= Timer(debounce, _flush);
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
    _timer = null;
    if (_closed) return;
    final batch = WatchBatch(
      paths: _paths.toList(),
      resyncDirs: _resyncDirs.toList(),
    );
    _paths.clear();
    _resyncDirs.clear();
    _controller.add(batch);
  }

  /// Stops watching and closes the [events] stream.
  Future<void> stop() async {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _timer = null;
    final sub = _subscription;
    _subscription = null;
    _paths.clear();
    _resyncDirs.clear();
    await sub?.cancel();
    await _controller.close();
  }
}
