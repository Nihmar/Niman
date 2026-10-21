import 'dart:io';

import 'package:niman/src/core/files.dart';

/// Deletes the temp files a killed write left in the library under [root] —
/// the atomic writes' and the sync download's alike, and the folders a
/// book's conversion stages its notes in — and answers how many went
/// (#379, #1138).
///
/// A write goes to a hidden temp name in the target's own directory and is
/// renamed onto it ([atomicTempPath], and the sync's `.niman-tmp-sync-`);
/// the rename is the only thing that removes the temp, so a process killed
/// between the two leaves it for good. Nothing else notices: the index walk
/// skips hidden entries and the sync skips dot names, so the file sits in
/// the user's library, is never indexed or synced, and reads as content
/// when the folder is listed.
///
/// Only files older than [minimumAge] are taken, so a write still running
/// when the sweep passes is left for its rename. A symlink is neither
/// followed nor removed — only real directories are descended — so a link
/// cannot lead the sweep out of the library. The hidden folders are walked
/// too (that is where `.niman/` and `.history/` leave theirs); a `.git/` is
/// not, so a library that versions its notes is not walked whole.
///
/// Top-level and stateless, so it runs on the walk's own kind of background
/// isolate (every `listSync`/`statSync` is a FUSE round trip on Android).
int sweepStaleTempFiles(
  String root, {
  Duration minimumAge = staleTempMinimumAge,
}) {
  final cutoff = DateTime.now().subtract(minimumAge);
  var removed = 0;
  final pending = <Directory>[Directory(root)];
  while (pending.isNotEmpty) {
    final dir = pending.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      // Gone between its parent's listing and its own.
      continue;
    }
    for (final entry in entries) {
      if (entry is Directory) {
        final name = _baseName(entry.path);
        if (name == '.git') continue;
        // A whole folder staged for a write that never finished — a book's
        // conversion, written aside and renamed in (#1138) — goes whole.
        if (isTempFileName(name) &&
            entry.statSync().modified.isBefore(cutoff)) {
          try {
            entry.deleteSync(recursive: true);
            removed++;
          } on FileSystemException {
            // Renamed in, or gone, while the sweep walked.
          }
          continue;
        }
        pending.add(entry);
      } else if (entry is File &&
          isTempFileName(_baseName(entry.path)) &&
          _isStaleTemp(entry, cutoff)) {
        try {
          entry.deleteSync();
          removed++;
        } on FileSystemException {
          // Renamed onto its target, or otherwise gone, while the sweep
          // walked: nothing to remove.
        }
      }
    }
  }
  return removed;
}

/// Whether [file] was last touched before [cutoff] — the age guard that
/// keeps a running write's temp out of the sweep.
bool _isStaleTemp(File file, DateTime cutoff) {
  try {
    return file.statSync().modified.isBefore(cutoff);
  } on FileSystemException {
    return false;
  }
}

/// The last path segment of [path], cut by hand like [atomicTempPath]: the
/// sweep runs where `package:path`'s platform style would ask for a working
/// directory a rebuild may have taken (#319).
String _baseName(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final cut = slash > backslash ? slash : backslash;
  return cut < 0 ? path : path.substring(cut + 1);
}
