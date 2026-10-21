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

import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:path/path.dart' as p;

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

/// What a whole pass over a library's history did.
typedef UpkeepOutcome = ({
  int notes,
  int migrated,
  int packed,
  int savedBytes,
  int collected,
  int collectedBytes,
});

/// Moves every old history in, packs every note's, compacts the logs that
/// grew, and collects the objects no log names and older than [grace].
UpkeepOutcome maintainHistory(
  String root, {
  Duration grace = historyGarbageGrace,
  DateTime? now,
}) {
  final history = Directory(p.join(root, historyFolderName));
  const empty = (
    notes: 0,
    migrated: 0,
    packed: 0,
    savedBytes: 0,
    collected: 0,
    collectedBytes: 0,
  );
  if (!history.existsSync()) return empty;
  var migrated = 0;
  for (final rel in legacyNotesUnder(root, history)) {
    migrated += withHistoryLock(root, [
      rel,
    ], () => importLegacyHistory(root, rel));
  }
  final notes = _logged(root, history);
  var packed = 0;
  var saved = 0;
  for (final rel in notes) {
    // Compacted under the note's lock, from a read made under it: a line a
    // save or a pin appends meanwhile waits, and is in what is rewritten.
    withHistoryLock(root, [rel], () {
      final log = readLog(root, rel);
      if (log != null && logWantsCompacting(log)) {
        writeLog(root, rel, log.manifest, highest: log.highest);
      }
    });
    final outcome = packNoteHistory(root, rel);
    packed += outcome.packed;
    saved += outcome.saved;
  }
  final named = <String>{};
  for (final rel in notes) {
    for (final v
        in readLog(root, rel)?.manifest.versions ?? <HistoryVersion>[]) {
      named.add(v.sha256);
    }
  }
  final queue = [...named];
  while (queue.isNotEmpty) {
    final base = deltaBaseOf(root, queue.removeLast());
    if (base != null && named.add(base)) queue.add(base);
  }
  var collected = 0;
  var collectedBytes = 0;
  final cutoff = (now ?? DateTime.now()).subtract(grace);
  {
    for (final MapEntry(key: sha, value: file) in listObjects(root).entries) {
      if (named.contains(sha)) continue;
      final stat = file.statSync();
      if (!stat.modified.isBefore(cutoff)) continue;
      file.deleteSync();
      collected++;
      collectedBytes += stat.size;
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
  );
}

/// Every note with a log under [history], library-relative; the objects
/// folder is not walked.
List<String> _logged(String root, Directory history) {
  final out = <String>[];
  void walk(Directory dir) {
    for (final entry in dir.listSync(followLinks: false)) {
      if (entry is Directory) {
        if (p.equals(entry.path, historyObjectsPath(root))) continue;
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

void _pruneEmptyFans(String root) {
  final dir = Directory(historyObjectsPath(root));
  if (!dir.existsSync()) return;
  for (final fan in dir.listSync(followLinks: false)) {
    if (fan is Directory && fan.listSync().isEmpty) fan.deleteSync();
  }
}
