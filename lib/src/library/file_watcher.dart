import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// A batch of filesystem changes delivered by a [FileWatcher].
final class WatchBatch {
  /// Creates a batch of changed paths.
  const WatchBatch({required this.paths, required this.resyncDirs});

  /// Changed absolute paths; for renames this is the OLD path (the new
  /// path is unknown to the OS event).
  final List<String> paths;

  /// Directories to resync fully, as absolute paths: parents of rename
  /// events, whose new path is not part of the event stream.
  final List<String> resyncDirs;
}

/// Recursively watches [root] for changes, coalescing raw events into
/// [WatchBatch]es after [debounce] of quiet.
///
/// On Linux the recursive watch is inotify-backed; on Android the same
/// mechanism applies. When the OS cannot deliver every event (FUSE, inotify
/// limits), the periodic full rescan in the library controller is the
/// safety net (see the M1 plan risks).
final class FileWatcher {
  /// Creates a watcher for [root] with the given [debounce] window.
  FileWatcher(this.root, {this.debounce = defaultDebounce});

  /// The debounce window between the last event and the batch emission.
  static const defaultDebounce = Duration(milliseconds: 250);

  final AppLogger _log = const AppLogger(name: 'watcher');

  /// The watched root directory (absolute path).
  final String root;

  /// How long after the last event before a batch is emitted.
  final Duration debounce;

  final StreamController<WatchBatch> _controller =
      StreamController<WatchBatch>.broadcast();
  final Set<String> _paths = <String>{};
  final Set<String> _resyncDirs = <String>{};
  /// Cancelled in [stop]; the lint cannot see the cross-method lifecycle.
  // ignore: cancel_subscriptions
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _timer;
  bool _started = false;
  bool _closed = false;

  /// Batches of changed paths, coalesced by the debounce window.
  Stream<WatchBatch> get events => _controller.stream;

  /// Begins watching. Each emitted [FileSystemEvent] is coalesced; move
  /// events additionally resync their parent directory, since the destination
  /// may be unknown to the OS event.
  Future<void> start() async {
    if (_started || _closed) {
      throw StateError('Watcher is already started or closed');
    }
    _started = true;
    _log.info('watcher start: "$root" (recursive)');
    final stream = Directory(root).watch(recursive: true);
    _listen(stream);
  }

  void _listen(Stream<FileSystemEvent> stream) {
    _subscription = stream.listen(
      _onEvent,
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

  void _onEvent(FileSystemEvent event) {
    if (_closed) return;
    if (event is FileSystemMoveEvent) {
      // The destination may be unknown to the OS; resync the parent either
      // way, and index the destination when it is known.
      _log.debug(
        'watcher event: move "${event.path}" -> '
        '${event.destination ?? 'unknown'}',
      );
      _resyncDirs.add(p.dirname(event.path));
      _paths.add(event.path);
      final destination = event.destination;
      if (destination != null) {
        _paths.add(destination);
      }
    } else {
      _log.debug('watcher event: ${_typeName(event)} "${event.path}"');
      _paths.add(event.path);
    }
    _timer ??= Timer(debounce, _flush);
  }

  String _typeName(FileSystemEvent event) {
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
