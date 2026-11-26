/// The folder of the app's cache the books' pictures are extracted to
/// (#1311): one folder a book, kept within a size.
///
/// A book's folder is named by its path, size and modification time
/// (`pictureDirOf`), so a rename, a move or a sync touching the file makes
/// a new one and nothing would ever remove the old: on the desktops no
/// system clears the cache. A folder is marked as used each time its book
/// is read ([markEpubFolderUsed]), and after a book is read the folders
/// used least recently are deleted until the rest fit ([pruneEpubCache]).
///
/// Everything here is synchronous file work, for the isolate that reads
/// the book (`openEpub`).
library;

import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// The most bytes the pictures of all the books' folders may take.
const int epubCacheMaxBytes = 512 * 1024 * 1024;

/// The most folders (books) the cache keeps.
const int epubCacheMaxFolders = 200;

/// The file of a folder whose time says when it was last used: a folder's
/// own modification time moves only when a file is added or removed in it.
const String _usedMarker = '.used';

/// Writes [bytes] to [target], whole or not at all.
///
/// They go to a temp name of [target]'s own folder ([atomicTempPath]) and
/// the temp is renamed to [target]: whatever is under a picture's name is
/// a whole picture, and a crash in between leaves a temp file, which no
/// reader takes for one ([dropStaleTemps] removes it later).
void writePictureWhole(File target, List<int> bytes) {
  final temp = atomicTempPath(target, DateTime.now().microsecondsSinceEpoch);
  try {
    temp
      ..writeAsBytesSync(bytes, flush: true)
      ..renameSync(target.path);
  } on FileSystemException {
    // Another reader of the same book put the picture there first and
    // holds it open (Windows refuses to replace a file in use): theirs is
    // the whole picture. Anything else is the caller's to hear.
    if (!target.existsSync()) rethrow;
  } finally {
    if (temp.existsSync()) temp.deleteSync();
  }
}

/// Deletes the temp files of pictures a killed reader left in [dir], those
/// older than [staleTempMinimumAge]: a younger one may be a write still
/// running in another pane of the same book.
void dropStaleTemps(String dir) {
  final cutoff = DateTime.now().subtract(staleTempMinimumAge);
  try {
    for (final entry in Directory(dir).listSync(followLinks: false)) {
      if (entry is File &&
          isTempFileName(p.basename(entry.path)) &&
          entry.statSync().modified.isBefore(cutoff)) {
        entry.deleteSync();
      }
    }
  } on FileSystemException {
    // Gone, or taken by the write it belonged to, while it was listed.
  }
}

/// Marks the book folder [dir] as used now.
void markEpubFolderUsed(String dir) {
  final marker = File(p.join(dir, _usedMarker));
  if (marker.existsSync()) {
    marker.setLastModifiedSync(DateTime.now());
  } else {
    marker.writeAsBytesSync(const []);
  }
}

/// Deletes the least recently used book folders of [cacheDir] until the
/// rest take at most [maxBytes] and number at most [maxFolders]; the
/// folder [keep] is the book in use and stays whatever its size.
///
/// A folder's use is its marker's time ([markEpubFolderUsed]), its own
/// modification time for one that has none. A folder that cannot be
/// deleted (held open by a reader of another book on Windows) is left for
/// the next time; pruning never fails the book that asked for it.
void pruneEpubCache(
  String cacheDir, {
  required String keep,
  int maxBytes = epubCacheMaxBytes,
  int maxFolders = epubCacheMaxFolders,
}) {
  final root = Directory(cacheDir);
  if (!root.existsSync()) return;
  final folders = <_Folder>[];
  try {
    for (final entry in root.listSync(followLinks: false)) {
      if (entry is Directory) folders.add(_Folder.of(entry));
    }
  } on FileSystemException {
    return;
  }
  var bytes = folders.fold(0, (sum, folder) => sum + folder.bytes);
  var count = folders.length;
  // Oldest first, the folder in use never among the ones taken.
  folders.sort((a, b) => a.used.compareTo(b.used));
  for (final folder in folders) {
    if (bytes <= maxBytes && count <= maxFolders) break;
    if (p.equals(folder.path, keep)) continue;
    try {
      Directory(folder.path).deleteSync(recursive: true);
    } on FileSystemException {
      continue;
    }
    bytes -= folder.bytes;
    count--;
  }
}

/// A book folder of the cache, with what pruning asks of it.
final class _Folder {
  const new(this.path, this.bytes, this.used);

  factory of(Directory dir) {
    var bytes = 0;
    try {
      for (final entry in dir.listSync(followLinks: false)) {
        if (entry is File) bytes += entry.statSync().size;
      }
      final marker = File(p.join(dir.path, _usedMarker));
      final used = marker.existsSync()
          ? marker.statSync().modified
          : dir.statSync().modified;
      return _Folder(dir.path, bytes, used);
    } on FileSystemException {
      // Gone while the cache was walked: nothing of it to count.
      return _Folder(dir.path, 0, DateTime.fromMillisecondsSinceEpoch(0));
    }
  }

  final String path;
  final int bytes;
  final DateTime used;
}
