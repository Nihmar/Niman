/// One writer at a time on a note's history (#1148 review).
///
/// A note's log is read, decided on and written by isolates that do not
/// share memory: a save's snapshot, a sync's pin of its base, the upkeep's
/// compaction, a move. Two of them at once could each read the log, each
/// pick the same next version number, or one compact the log from what it
/// read while the other appended a line the compaction then dropped. So
/// every read-decide-write of a log runs holding the note's lock.
///
/// The locks live apart from the notes' folders, flat, in
/// `.history/.locks/`, one file a note named by the hash of its path folded
/// to lower case — so a case-only rename, whose two names are one file on
/// Windows and Android, asks for one lock and not two, and a release has no
/// folder of the note's to tidy (listing a folder of 30k logs on every save
/// would be a round trip each on Android). Folding over-locks two notes
/// whose names differ by case on Linux, which only makes them take turns.
/// How a lock file is taken, broken and released is `history_lock_file.dart`.
///
/// Synchronous, like the store: it runs on background isolates, where a
/// short sleep blocks nothing a user waits on.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:niman/src/history/history_folders.dart';
import 'package:niman/src/history/history_lock_file.dart';
import 'package:path/path.dart' as p;

/// The file name of the store-wide lock the packer holds around a delta's
/// loop check and write; not a hash, so no note's lock is it.
const String _packLockName = 'pack';

/// The file name of the store-wide lock a move of logs holds: what tells the
/// upkeep a log may be moving.
const String _moveLockName = 'move';

/// The folder holding the locks of the library at [root].
String historyLocksPath(String root) =>
    p.join(root, historyFolderName, historyLocksFolderName);

/// The store-wide lock a move of logs holds while it runs
/// (`history_generation.dart`).
String historyMoveLockPath(String root) =>
    p.join(historyLocksPath(root), '$_moveLockName.lock');

/// The lock of the note at [rel]'s history.
String historyLockPath(String root, String rel) => p.join(
  historyLocksPath(root),
  '${sha256.convert(utf8.encode(rel.toLowerCase()))}.lock',
);

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
/// writers asking for the same two never wait on each other. Names that
/// are one lock — differing by case — are taken once.
///
/// Throws [HistoryLockTimeout] when a lock is held past the patience, and a
/// [FileSystemException] when the store cannot hold a lock at all.
T withHistoryLock<T>(
  String root,
  Iterable<String> rels,
  T Function() body, {
  Duration stale = historyLockStale,
}) => _withLocks(
  root,
  {for (final rel in rels) historyLockPath(root, rel): rel},
  body,
  stale,
);

/// Runs [body] holding the store-wide pack lock: what makes the packer's
/// check that a delta leads to no loop, and the write of that delta, one
/// step across the isolates that pack at once.
T withHistoryPackLock<T>(String root, T Function() body) => _withLocks(
  root,
  {p.join(historyLocksPath(root), '$_packLockName.lock'): _packLockName},
  body,
  historyLockStale,
);

/// Runs [body] holding the store-wide move lock, which says a log is being
/// moved while it runs.
T withHistoryMoveLock<T>(String root, T Function() body) => _withLocks(
  root,
  {historyMoveLockPath(root): _moveLockName},
  body,
  historyLockStale,
);

T _withLocks<T>(
  String root,
  Map<String, String> named,
  T Function() body,
  Duration stale,
) {
  final ordered = [
    for (final path in named.keys.toList()..sort())
      if (!_heldHere.contains(path)) path,
  ];
  final held = <(File, String)>[];
  try {
    for (final path in ordered) {
      final lock = File(path);
      final token = acquireLockFile(lock, stale: stale);
      if (token == null) throw HistoryLockTimeout(named[path]!);
      held.add((lock, token));
      _heldHere.add(path);
    }
    return body();
  } finally {
    for (final (lock, token) in held.reversed) {
      _heldHere.remove(lock.path);
      releaseLockFile(lock, token);
    }
  }
}
