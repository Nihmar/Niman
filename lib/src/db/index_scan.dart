/// Disk walk and probe primitives for the index (#51): the entries a scan
/// observes, the batched probes the watcher path needs, and the progress
/// value the first index reports. Stateless and isolate-safe — the walks
/// run on background isolates, where every `listSync`/`statSync` would
/// otherwise be a UI-isolate FUSE round trip.
library;

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
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
