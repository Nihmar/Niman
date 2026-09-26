/// Disk walk and probe primitives for the index (#51): the entries a scan
/// observes, the batched probes the watcher path needs, and the progress
/// value the first index reports. Stateless and isolate-safe — the walks
/// run on background isolates, where every `listSync`/`statSync` would
/// otherwise be a UI-isolate FUSE round trip.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:path/path.dart' as p;

/// A note file or folder observed on disk during a scan.
final class DiskEntry {
  /// Creates a disk entry for the entry at `rel`.
  const new({
    required this.rel,
    required this.name,
    required this.isDir,
    required this.size,
    required this.modified,
  });

  /// Library-relative slash-separated path.
  final String rel;

  /// Base name of the entry.
  final String name;

  /// Whether the entry is a directory.
  final bool isDir;

  /// Byte size (0 for directories).
  final int size;

  /// Last modification time.
  final DateTime modified;
}

/// One disk walk's result: the entries found, plus the log lines the walk
/// wanted to write.
///
/// The walk runs on a background isolate, where the app-wide log buffer
/// does not exist, so its lines travel back here and are replayed by the
/// caller instead.
final class ScanResult {
  /// Creates a walk result.
  const new({required this.entries, required this.logs});

  /// The entries found, directories and files, in traversal order.
  final List<DiskEntry> entries;

  /// Log lines produced during the walk, oldest first.
  final List<String> logs;
}

/// Walks [start] (the library root itself, or a directory inside [root])
/// depth-first, skipping hidden entries.
///
/// Top-level and fully synchronous so it can be handed to Isolate.run:
/// on Android every `listSync`/`statSync` is a FUSE round trip, and a
/// library of a few hundred entries costs the better part of a second —
/// long enough to be felt on the UI isolate, and to stack up into an ANR
/// together with the digests.
ScanResult scanTree(String root, String start) {
  final entries = <DiskEntry>[];
  final logs = <String>[];
  _walkDir(root, Directory(start), entries, logs);
  return ScanResult(entries: entries, logs: logs);
}

void _walkDir(
  String root,
  Directory dir,
  List<DiskEntry> out,
  List<String> logs,
) {
  final rel = relPath(dir.path, root);
  if (rel.isNotEmpty) {
    final st = dir.statSync();
    out.add(
      DiskEntry(
        rel: rel,
        name: p.basename(dir.path),
        isDir: true,
        size: 0,
        modified: st.modified,
      ),
    );
  }
  for (final ent in dir.listSync(followLinks: false)) {
    final name = p.basename(ent.path);
    if (name.startsWith('.')) {
      logs.add('walk: skip hidden entry "$name"');
      continue;
    }
    if (ent is Directory) {
      _walkDir(root, ent, out, logs);
    } else if (ent is File) {
      final st = ent.statSync();
      out.add(
        DiskEntry(
          rel: relPath(ent.path, root),
          name: name,
          isDir: false,
          size: st.size,
          modified: st.modified,
        ),
      );
    } else {
      logs.add('walk: skip non-file/dir entry "${ent.path}" ($ent)');
    }
  }
}

/// One directory's own listing in a streamed walk (#302).
///
/// The whole-tree [scanTree] returns every entry at once, which at a
/// million notes is a million [DiskEntry] in memory before the scan has
/// written anything. A streamed walk yields these one at a time instead:
/// the caller mirrors a directory, then asks for the next.
final class DirListing {
  /// Creates a directory listing.
  const new({
    required this.rel,
    required this.name,
    required this.modified,
    required this.entries,
    required this.logs,
    this.failed = false,
  });

  /// Library-relative slash-separated path; `''` for the library root.
  final String rel;

  /// Base name; `''` for the library root.
  final String name;

  /// The directory's own last-modification time.
  final DateTime modified;

  /// The direct children — files and folders — by name. Hidden entries are
  /// not here; the walk skips them and says so in [logs].
  final List<DiskEntry> entries;

  /// The lines the walk wanted to log for this listing.
  final List<String> logs;

  /// Whether the directory could not be read: it vanished between its
  /// parent's listing and its own. [entries] is empty then.
  final bool failed;

  /// The subfolders of this listing, by name.
  Iterable<DiskEntry> get dirs => entries.where((e) => e.isDir);
}

/// The streamed walk's isolate entry point (#302).
///
/// Sends its request port to the caller first, then answers every request
/// with the next [DirListing] in depth-first order — a directory before its
/// children — or with `null` once the tree is walked.
///
/// One request per directory is the backpressure: the isolate waits for the
/// caller to finish a directory before it lists the next, so neither side
/// holds more than one listing, and a whole-library scan costs one isolate
/// rather than one per folder. A short-lived `Isolate.run` per directory
/// would be a spawn per folder, and the FUSE `listSync`/`statSync` behind
/// every listing cannot run on the UI isolate.
Future<void> walkDirectories((String, SendPort) args) async {
  final (root, out) = args;
  final requests = ReceivePort();
  out.send(requests.sendPort);
  final pending = <String>[root];
  await for (final _ in requests) {
    if (pending.isEmpty) {
      out.send(null);
      break;
    }
    out.send(_listOne(root, pending.removeLast(), pending));
  }
  requests.close();
}

/// Lists one directory: its own state plus its direct children, and queues
/// its subfolders for the walk to visit next.
DirListing _listOne(String root, String abs, List<String> pending) {
  final rel = relPath(abs, root);
  final name = p.basename(abs);
  final logs = <String>[];
  final entries = <DiskEntry>[];
  final subdirs = <DiskEntry>[];
  try {
    final modified = Directory(abs).statSync().modified;
    final children = Directory(abs).listSync(followLinks: false)
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    for (final ent in children) {
      final childName = p.basename(ent.path);
      if (childName.startsWith('.')) {
        logs.add('walk: skip hidden entry "$childName"');
        continue;
      }
      if (ent is Directory) {
        final st = ent.statSync();
        final entry = DiskEntry(
          rel: relPath(ent.path, root),
          name: childName,
          isDir: true,
          size: 0,
          modified: st.modified,
        );
        entries.add(entry);
        subdirs.add(entry);
      } else if (ent is File) {
        final st = ent.statSync();
        entries.add(
          DiskEntry(
            rel: relPath(ent.path, root),
            name: childName,
            isDir: false,
            size: st.size,
            modified: st.modified,
          ),
        );
      } else {
        logs.add('walk: skip non-file/dir entry "${ent.path}" ($ent)');
      }
    }
    // Pushed in reverse so the first child is popped first: the walk is
    // depth-first and in name order.
    for (final dir in subdirs.reversed) {
      pending.add(p.join(root, dir.rel));
    }
    return DirListing(
      rel: rel,
      name: name,
      modified: modified,
      entries: entries,
      logs: logs,
    );
  } on FileSystemException catch (error) {
    logs.add('walk: "$rel" could not be read ($error)');
    return DirListing(
      rel: rel,
      name: name,
      modified: DateTime.fromMillisecondsSinceEpoch(0),
      entries: const [],
      logs: logs,
      failed: true,
    );
  }
}

/// Drives a [walkDirectories] isolate one directory at a time (#302).
///
/// [start] spawns the isolate and waits for its request port; [next] pulls
/// one listing; [close] stops the isolate. A scan owns one of these for its
/// whole run and closes it in a `finally`, so an exception in the middle of
/// a reconciliation cannot leave the isolate walking behind it.
final class DirWalker {
  new _(this._messages, this._events, this._isolate, this._root, this._ticket);

  final ReceivePort _messages;
  final StreamIterator<Object?> _events;
  final Isolate _isolate;
  final String _root;
  final int _ticket;

  SendPort? _requests;
  bool _finished = false;
  bool _portsClosed = false;

  /// Spawns the walk isolate for [root] and waits for it to be ready.
  static Future<DirWalker> start(String root) async {
    final messages = ReceivePort();
    final isolate = await Isolate.spawn<(String, SendPort)>(
      walkDirectories,
      (root, messages.sendPort),
      onError: messages.sendPort,
      debugName: 'niman-walk',
    );
    final walker = DirWalker._(
      messages,
      StreamIterator<Object?>(messages),
      isolate,
      root,
      IsolateGauge.begin('walk "$root"'),
    );
    try {
      walker._requests = await walker._ready();
    } on Object {
      await walker.close();
      rethrow;
    }
    return walker;
  }

  Future<SendPort> _ready() async {
    if (!await _events.moveNext()) {
      throw StateError('the walk isolate for "$_root" ended before it started');
    }
    final event = _events.current;
    if (event is SendPort) return event;
    throw StateError(
      'the walk isolate for "$_root" failed: ${_failure(event)}',
    );
  }

  /// The next directory of the walk, or null when the tree is walked.
  Future<DirListing?> next() async {
    final requests = _requests;
    if (_finished || requests == null) return null;
    requests.send(null);
    while (await _events.moveNext()) {
      final event = _events.current;
      if (event == null) {
        _finished = true;
        return null;
      }
      if (event is DirListing) return event;
      throw StateError(
        'the walk isolate for "$_root" failed: ${_failure(event)}',
      );
    }
    _finished = true;
    return null;
  }

  /// Stops the walk and its isolate. Safe to call more than once, and after
  /// a walk that reached its end on its own.
  Future<void> close({Object? error}) async {
    if (!_finished) {
      _finished = true;
      _isolate.kill(priority: Isolate.immediate);
    }
    if (!_portsClosed) {
      _portsClosed = true;
      await _events.cancel();
      _messages.close();
    }
    IsolateGauge.finishJob(_ticket, error: error);
  }

  static String _failure(Object? event) =>
      event is List && event.isNotEmpty ? '${event.first}' : '$event';
}

/// The on-disk state of one path, as probed by [probePaths].
final class DiskProbe {
  /// Creates a probe result.
  const new({
    required this.exists,
    required this.isDir,
    required this.modified,
    this.size = 0,
  });

  /// Whether the path exists (file or directory).
  final bool exists;

  /// Whether it is a directory.
  final bool isDir;

  /// The byte size (0 unless a file).
  final int size;

  /// The last-modification time.
  final DateTime modified;
}

/// Probes [paths] (exists? directory? size? mtime?) — top-level so it can
/// run on a background isolate via Isolate.run: on Android every stat is
/// a FUSE round trip, and a cold FUSE takes seconds, so the watcher-event
/// path must not stat on the UI isolate (a save behind an open editor is
/// what froze the app, M2a on-device round 2).
List<DiskProbe> probePaths(List<String> paths) => [
  for (final path in paths) _probePath(path),
];

DiskProbe _probePath(String path) {
  final st = File(path).statSync();
  final type = st.type;
  // A symlink probes through to its target, as the old existsSync calls did.
  final isDir =
      type == FileSystemEntityType.directory ||
      (type == FileSystemEntityType.link && Directory(path).existsSync());
  return DiskProbe(
    exists: type != FileSystemEntityType.notFound,
    isDir: isDir,
    size: type == FileSystemEntityType.file ? st.size : 0,
    modified: st.modified,
  );
}

/// Whether [name] is a note file, the only kind the index digests.
bool isNoteFile(String name) => p.extension(name).toLowerCase() == '.md';

/// How far a scan has got, and on which note.
///
/// It exists for the first index of a library, which is the one long
/// enough to watch: the alternative is a progress bar with nothing behind
/// it while the app reads a few thousand files.
@immutable
final class IndexProgress {
  /// Creates a progress report.
  const new({required this.file, required this.done, required this.of});

  /// The library-relative path being read.
  final String file;

  /// Notes reached so far, including this one.
  final int done;

  /// Notes this pass will read in total.
  final int of;
}
