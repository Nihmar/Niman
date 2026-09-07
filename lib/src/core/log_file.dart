/// Disk mirror of the in-memory log buffer, so an export survives the
/// process.
///
/// The in-memory buffer dies with the app, which is exactly what happens
/// in the cases worth diagnosing: a reminder that fired (or did not) with
/// the app closed, an OEM battery killer, a crash, a reboot. Lines are
/// appended to a file under the app's private support directory, batched
/// so a burst of logging is one write, and capped by a single rotation.
library;

import 'dart:async';
import 'dart:io';

/// An append-only, size-capped log file with one rotation.
///
/// Writes are batched: [add] only buffers, and a flush runs on a timer,
/// on [flush] (the shell calls it when the app backgrounds, so a swipe
/// away keeps its tail) and whenever the pending buffer gets large.
final class LogFile {
  /// Creates a log file at [path], rotating past [maxBytes].
  LogFile({
    required this.path,
    this.maxBytes = 512 * 1024,
    this.flushInterval = const Duration(seconds: 3),
  });

  /// The current file; the previous generation is `<path>.1`.
  final String path;

  /// Size at which the current file rotates.
  final int maxBytes;

  /// How long buffered lines wait before being written.
  final Duration flushInterval;

  /// Flush early rather than hold an unbounded burst in memory.
  static const int _maxPending = 200;

  final List<String> _pending = <String>[];
  Timer? _timer;
  Future<void>? _writing;

  /// Buffers [line] for the next flush.
  void add(String line) {
    _pending.add(line);
    if (_pending.length >= _maxPending) {
      unawaited(flush());
      return;
    }
    _timer ??= Timer(flushInterval, () => unawaited(flush()));
  }

  /// Writes everything buffered, rotating first when the file is full.
  ///
  /// Serialized: a flush already running is awaited, then the newly
  /// buffered lines go out, so lines never interleave or get lost.
  Future<void> flush() async {
    final running = _writing;
    if (running != null) {
      await running;
    }
    if (_pending.isEmpty) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    final batch = _pending.join('\n');
    _pending.clear();
    final write = _write('$batch\n');
    _writing = write;
    try {
      await write;
    } finally {
      _writing = null;
    }
  }

  /// The persisted lines, oldest first (previous generation included).
  Future<String> read() async {
    await flush();
    final parts = <String>[];
    for (final file in <File>[File('$path.1'), File(path)]) {
      try {
        if (file.existsSync()) {
          parts.add(await file.readAsString());
        }
      } on Object {
        // A missing or unreadable generation is not worth failing an
        // export over: the other one plus the memory buffer still help.
      }
    }
    return parts.join();
  }

  /// Deletes both generations.
  Future<void> clear() async {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
    for (final file in <File>[File('$path.1'), File(path)]) {
      try {
        if (file.existsSync()) {
          await file.delete();
        }
      } on Object {
        // Nothing to do; the next write recreates it.
      }
    }
  }

  Future<void> _write(String chunk) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      if (file.existsSync() && await file.length() >= maxBytes) {
        // One rotation: the previous generation is overwritten, so disk
        // use stays under 2 * maxBytes no matter how long the app runs.
        await file.rename('$path.1');
      }
      await file.writeAsString(chunk, mode: FileMode.append, flush: true);
    } on Object {
      // Logging must never take the app down, and there is nowhere to
      // report a failure of the log itself.
    }
  }
}
