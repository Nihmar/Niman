/// One writer at a time on a note's history (#1148 review).
///
/// A note's log is read, decided on and written by isolates that do not
/// share memory: a save's snapshot, a sync's pin of its base, the upkeep's
/// compaction, a move. Two of them at once could each read the log, each
/// pick the same next version number, or one compact the log from what it
/// read while the other appended a line the compaction then dropped. So
/// every read-decide-write of a log runs holding the note's lock.
///
/// The lock is a file, `.history/<path>.log.lock`, created exclusively — an
/// operation the file system answers once, whichever isolate or process
/// asks — and deleted when the work is done. A lock older than [_stale] was
/// left by a crash and is broken; one held longer than [_patience] is a
/// stall, and the work gives up rather than wait for ever.
///
/// Synchronous, like the store: it runs on background isolates, where a
/// short sleep blocks nothing a user waits on.
library;

import 'dart:io';

import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// How old a lock must be to be taken for a crash's leftover.
const Duration _stale = Duration(seconds: 30);

/// How long a writer waits for a lock before it gives up.
const Duration _patience = Duration(seconds: 10);

/// The lock of the note at [rel]'s history.
String historyLockPath(String root, String rel) =>
    p.join(root, historyFolderName, '$rel.log.lock');

/// A history lock not had in time.
final class HistoryLockTimeout implements Exception {
  /// The lock of [rel] was not had.
  const new(this.rel);

  /// The note whose history was locked.
  final String rel;

  @override
  String toString() => 'HistoryLockTimeout: "$rel" stayed locked';
}

/// The locks this isolate holds, by path: taking one again from inside the
/// work that holds it (a snapshot moving an old history in) goes on
/// without waiting on itself.
final Set<String> _heldHere = {};

/// Runs [body] holding the locks of [rels], taken in path order so two
/// writers asking for the same two never wait on each other.
///
/// Throws [HistoryLockTimeout] when a lock is held past the patience.
T withHistoryLock<T>(String root, Iterable<String> rels, T Function() body) {
  final ordered = [
    for (final rel in {...rels}.toList()..sort())
      if (!_heldHere.contains(historyLockPath(root, rel))) rel,
  ];
  final held = <File>[];
  try {
    for (final rel in ordered) {
      held.add(_acquire(root, rel));
      _heldHere.add(held.last.path);
    }
    return body();
  } finally {
    for (final lock in held.reversed) {
      _heldHere.remove(lock.path);
      try {
        lock.deleteSync();
      } on FileSystemException {
        // Broken as stale by another writer: nothing left to release.
      }
      // A delete or a move inside could not prune the folder while the
      // lock was in it: an emptied one goes now.
      _prune(root, lock.parent);
    }
  }
}

/// Removes [dir] and its empty parents, stopping at `.history/` itself.
void _prune(String root, Directory dir) {
  final stop = p.normalize(p.join(root, historyFolderName));
  var current = dir;
  try {
    while (p.isWithin(stop, current.path) && current.listSync().isEmpty) {
      current.deleteSync();
      current = current.parent;
    }
  } on FileSystemException {
    // Gone already, or filled again by another writer: nothing to prune.
  }
}

File _acquire(String root, String rel) {
  final lock = File(historyLockPath(root, rel));
  final clock = Stopwatch()..start();
  var pause = 1;
  while (true) {
    try {
      lock.parent.createSync(recursive: true);
      lock.createSync(exclusive: true);
      return lock;
    } on FileSystemException {
      // Held, or the folder raced away: look at the lock, then wait.
    }
    try {
      final age = DateTime.now().difference(lock.statSync().modified);
      if (lock.existsSync() && age > _stale) {
        lock.deleteSync();
        continue;
      }
    } on FileSystemException {
      // Released between the attempt and the look: try again.
      continue;
    }
    if (clock.elapsed > _patience) throw HistoryLockTimeout(rel);
    sleep(Duration(milliseconds: pause));
    pause = pause < 32 ? pause * 2 : 32;
  }
}
