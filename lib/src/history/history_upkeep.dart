/// The history's upkeep (#1148): what `git gc` does for a repository, done
/// off every save's path.
///
/// - **Packing.** A snapshot keeps its version whole: that is all a save
///   waits for. Packing then stores each older version as a delta against
///   the version after it — the newest stays whole, the way git packs —
///   and keeps a whole one every [maxDeltaChain] deltas, so a read of the
///   oldest applies a bounded chain.
/// - **Collecting.** Rotation and deletes write only the log; an object no
///   log names any more, directly or as a delta's base, is deleted once it
///   is older than the grace period — a snapshot writes its object before
///   its log line, and the grace keeps the collection from taking one in
///   between.
/// - **Moving the old history in**, for every note that still has one.
///
/// Synchronous and top-level: it runs on a background isolate.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:niman/src/history/history_generation.dart';
import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:path/path.dart' as p;

/// How long a pass waits for a move of logs to end before it lists again.
const Duration _movePause = Duration(milliseconds: 20);

/// How old an unnamed object must be before the collection takes it.
const Duration historyGarbageGrace = Duration(hours: 1);

/// What packing one note did: the versions now stored as deltas, and the
/// bytes that saved on disk.
typedef PackOutcome = ({int packed, int saved});

/// Stores the older versions of [rel] as deltas against the version after
/// each, where that is smaller and keeps every chain within
/// [maxDeltaChain].
PackOutcome packNoteHistory(String root, String rel) {
  final versions = readHistoryManifest(root, rel).versions;
  if (versions.isEmpty) return (packed: 0, saved: 0);
  final bases = {
    for (final v in versions) v.sha256: deltaBaseOf(root, v.sha256),
  };
  var packed = 0;
  var saved = 0;
  // Newest first: a version's successor is settled before the version is.
  Uint8List? successorContent;
  for (var i = versions.length - 2; i >= 0; i--) {
    final version = versions[i];
    final successor = versions[i + 1];
    final sha = version.sha256;
    final next = successor.sha256;
    if (sha == next || bases[sha] != null) {
      successorContent = null;
      continue;
    }
    // The deltas older than this one that already lead through it: each
    // would read one more step once it is a delta too.
    var behind = 0;
    for (var j = i - 1; j >= 0; j--) {
      if (bases[versions[j].sha256] != versions[j + 1].sha256) break;
      behind++;
    }
    final depth = chainDepth(root, next);
    if (depth == null || behind + 1 + depth > maxDeltaChain) {
      successorContent = null;
      continue;
    }
    final file = File(historyObjectPath(root, sha));
    final before = file.existsSync() ? file.lengthSync() : 0;
    final content = readObject(root, sha);
    if (content == null) {
      successorContent = null;
      continue;
    }
    if (storeAsDelta(
      root,
      sha,
      next,
      content: content,
      baseContent: successorContent,
    )) {
      bases[sha] = next;
      packed++;
      saved += before - file.lengthSync();
    }
    successorContent = content;
  }
  // The newest stays whole: compressed hard now that no save waits for it.
  // One a crash cut short — its header gone, or its stream — is written
  // again from the note when the note still holds it: a save that found
  // the note unchanged since this version left the check here.
  final newest = versions.last.sha256;
  if (chainDepth(root, newest) == null || isFastWhole(root, newest)) {
    final file = File(historyObjectPath(root, newest));
    final before = file.existsSync() ? file.lengthSync() : 0;
    final content =
        readObject(root, newest) ?? _repairFromNote(root, rel, newest);
    if (content != null && isFastWhole(root, newest)) {
      storeHard(root, newest, content);
      saved += before - file.lengthSync();
    }
  }
  return (packed: packed, saved: saved);
}

/// The note at [rel] as it is, written as object [sha] when it still holds
/// that content; null when it does not.
Uint8List? _repairFromNote(String root, String rel, String sha) {
  final note = File(p.join(root, rel));
  if (!note.existsSync()) return null;
  final bytes = note.readAsBytesSync();
  if (shaOf(bytes) != sha) return null;
  writeObject(root, sha, bytes);
  return readObject(root, sha);
}

/// What a whole pass over a library's history did. `failed` counts the notes
/// and objects it could not do its work on and went on without, and
/// `failure` says why of the first.
typedef UpkeepOutcome = ({
  int notes,
  int migrated,
  int packed,
  int savedBytes,
  int collected,
  int collectedBytes,
  int failed,
  String? failure,
});

/// Moves every old history in, packs every note's, compacts the logs that
/// grew, and collects the objects no log names and older than [grace].
///
/// A note or an object that cannot be done — a lock held past its patience,
/// a path too long for Windows, an object another pass deleted first — is
/// counted and left, and the pass goes on: one note must not stop the
/// others' packing, nor the collection, at every open.
///
/// [beforeNote] runs before each note is done, and [beforeCollect] before
/// each unnamed object is looked at for collection: for a test to make
/// one fail, or to take the object away as another pass would.
UpkeepOutcome maintainHistory(
  String root, {
  Duration grace = historyGarbageGrace,
  DateTime? now,
  @visibleForTesting void Function(String rel)? beforeNote,
  @visibleForTesting void Function(File object)? beforeCollect,
}) {
  final history = Directory(p.join(root, historyFolderName));
  const empty = (
    notes: 0,
    migrated: 0,
    packed: 0,
    savedBytes: 0,
    collected: 0,
    collectedBytes: 0,
    failed: 0,
    failure: null,
  );
  if (!history.existsSync()) return empty;
  var failed = 0;
  String? failure;
  void fail(String what, Object error) {
    failed++;
    failure ??= '$what: $error';
  }

  var migrated = 0;
  if (!legacyIsDone(root)) {
    var moveFailed = false;
    for (final rel in legacyNotesUnder(root, history)) {
      try {
        migrated += withHistoryLock(root, [
          rel,
        ], () => importLegacyHistory(root, rel));
      } on Object catch (e) {
        moveFailed = true;
        fail('moving in "$rel"', e);
      }
    }
    // Looked at once more, and said so when nothing is left: the next open
    // lists no `.history/` for it.
    if (!moveFailed && legacyNotesUnder(root, history).isEmpty) {
      try {
        markLegacyDone(root);
      } on FileSystemException catch (e) {
        fail('recording the old history moved in', e);
      }
    }
  }
  final notes = _logged(root, history);
  var packed = 0;
  var saved = 0;
  for (final rel in notes) {
    try {
      beforeNote?.call(rel);
      // Compacted under the note's lock, from a read made under it: a line
      // a save or a pin appends meanwhile waits, and is in what is
      // rewritten.
      withHistoryLock(root, [rel], () {
        final log = readLog(root, rel);
        if (log != null && logWantsCompacting(log)) {
          writeLog(root, rel, log.manifest, highest: log.highest);
        }
      });
      final outcome = packNoteHistory(root, rel);
      packed += outcome.packed;
      saved += outcome.saved;
    } on Object catch (e) {
      fail('packing "$rel"', e);
    }
  }
  // What the logs name, read only now, right before the sweep: a pass that
  // packs a large library takes long enough for a note to move meanwhile.
  final named = namedObjects(root);
  var collected = 0;
  var collectedBytes = 0;
  final cutoff = (now ?? DateTime.now()).subtract(grace);
  // Nothing is collected from a listing that would not hold still.
  if (named != null) {
    for (final MapEntry(key: sha, value: file) in listObjects(root).entries) {
      if (named.contains(sha)) continue;
      beforeCollect?.call(file);
      // A stat of a file another pass just deleted answers an epoch, which
      // is before any cutoff: only a file that is there is old enough.
      final stat = file.statSync();
      if (stat.type != FileSystemEntityType.file) continue;
      if (!stat.modified.isBefore(cutoff)) continue;
      try {
        file.deleteSync();
        collected++;
        collectedBytes += stat.size;
      } on PathNotFoundException {
        // Collected by another pass between the stat and the delete.
      } on FileSystemException catch (e) {
        fail('collecting $sha', e);
      }
    }
  }
  _pruneEmptyFans(root);
  return (
    notes: notes.length,
    migrated: migrated,
    packed: packed,
    savedBytes: saved,
    collected: collected,
    collectedBytes: collectedBytes,
    failed: failed,
    failure: failure,
  );
}

/// Every object a log names, directly or as a delta's base, however far
/// down its chain; null when the logs would not hold still.
///
/// A log listed and gone when it is read was moved meanwhile — a note
/// renamed while the upkeep ran — and its versions are under a name the
/// listing did not have: the logs are listed again, up to [attempts] times.
/// Missing a moved log's objects would collect a history that is still
/// there.
///
/// A log can also be moved from a folder the walk had not reached into one
/// it had left, and then it is in neither listing and no read fails. A move
/// of logs changes the store's generation (`history_generation.dart`): one
/// running when the pass began or ended, or finished meanwhile, makes the
/// pass start again.
///
/// [afterFolder] lets a test move a log once a folder is listed, and
/// [afterListing] once the whole walk is.
Set<String>? namedObjects(
  String root, {
  int attempts = 5,
  @visibleForTesting void Function(Directory folder)? afterFolder,
  @visibleForTesting void Function()? afterListing,
}) {
  final history = Directory(p.join(root, historyFolderName));
  for (var attempt = 0; attempt < attempts; attempt++) {
    final generation = historyGeneration(root);
    if (generation == null) {
      sleep(_movePause * (attempt + 1)); // a move is running: let it end
      continue;
    }
    final notes = history.existsSync()
        ? _logged(root, history, afterFolder)
        : <String>[];
    afterListing?.call();
    final named = <String>{};
    var steady = true;
    for (final rel in notes) {
      final FoldedLog? log;
      try {
        log = readLog(root, rel);
      } on FileSystemException {
        return null; // a log that cannot be read names what it names
      }
      if (log == null) {
        steady = false;
        break;
      }
      for (final v in log.manifest.versions) {
        named.add(v.sha256);
      }
    }
    if (!steady) continue;
    if (historyGeneration(root) != generation) continue;
    // A delta's base is named too, however far down its chain.
    final queue = [...named];
    while (queue.isNotEmpty) {
      final base = deltaBaseOf(root, queue.removeLast());
      if (base != null && named.add(base)) queue.add(base);
    }
    return named;
  }
  return null;
}

/// Every note with a log under [history], library-relative; the objects
/// and locks folders are not walked.
List<String> _logged(
  String root,
  Directory history, [
  void Function(Directory folder)? afterFolder,
]) {
  final out = <String>[];
  void walk(Directory dir) {
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      return; // moved or deleted while the walk ran: the generation says
    }
    afterFolder?.call(dir);
    for (final entry in entries) {
      if (entry is Directory) {
        if (p.equals(entry.path, historyObjectsPath(root)) ||
            p.equals(entry.path, historyLocksPath(root))) {
          continue;
        }
        walk(entry);
      } else if (entry is File && entry.path.endsWith('.log')) {
        final rel = p
            .split(p.relative(entry.path, from: history.path))
            .join('/');
        out.add(rel.substring(0, rel.length - '.log'.length));
      }
    }
  }

  walk(history);
  return out..sort();
}

/// Removes the objects folders left empty: each deleted outright, and a
/// folder that holds an object refuses.
void _pruneEmptyFans(String root) {
  final dir = Directory(historyObjectsPath(root));
  if (!dir.existsSync()) return;
  for (final fan in dir.listSync(followLinks: false)) {
    if (fan is! Directory) continue;
    try {
      fan.deleteSync();
    } on FileSystemException {
      // Not empty, or filled again meanwhile.
    }
  }
}
