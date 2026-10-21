/// Reading and writing a note's history log, for the store's operations
/// (`history_store.dart`, `history_pins.dart`, `history_moves.dart`).
///
/// Every function here expects the note's lock (`history_lock.dart`) held
/// by its caller when it writes; reading alone takes none.
library;

import 'dart:io';
import 'dart:math';

import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// An empty history.
FoldedLog get emptyHistoryLog =>
    (manifest: HistoryManifest(), lines: 0, highest: 0);

/// The log of [rel] folded, its old history moved in first when it has
/// one — under the note's lock, since the move writes.
///
/// The log is read again after the move whatever it answered: a move that
/// lost the race to another (`history_legacy.dart`) writes nothing, and
/// the log is the other's.
FoldedLog loadHistoryLog(String root, String rel) {
  final log = readLog(root, rel);
  if (log != null) return log;
  withHistoryLock(root, [rel], () => importLegacyHistory(root, rel));
  return readLog(root, rel) ?? emptyHistoryLog;
}

/// [log]'s history without the versions whose object is gone, and the pins
/// on them: what a reader can actually have. A stat a version: for a list
/// a user asked for, not for a save's path ([withoutMissingNewest]).
HistoryManifest presentVersions(String root, FoldedLog log) {
  final manifest = log.manifest;
  final kept = [
    for (final v in manifest.versions)
      if (hasObject(root, v.sha256)) v,
  ];
  if (kept.length == manifest.versions.length) return manifest;
  return _keeping(manifest, kept);
}

/// [log]'s history without the newest versions whose object is gone:
/// what a snapshot decides on. One stat, as a rule — the newest is there —
/// rather than one a version; an older version gone is only an older
/// version gone, and rotation takes it in turn.
HistoryManifest withoutMissingNewest(String root, FoldedLog log) {
  final versions = [...log.manifest.versions];
  while (versions.isNotEmpty && !hasObject(root, versions.last.sha256)) {
    versions.removeLast();
  }
  if (versions.length == log.manifest.versions.length) return log.manifest;
  return _keeping(log.manifest, versions);
}

HistoryManifest _keeping(HistoryManifest manifest, List<HistoryVersion> kept) {
  final numbers = {for (final v in kept) v.number};
  return HistoryManifest(
    versions: kept,
    pins: {
      for (final e in manifest.pins.entries)
        if (numbers.contains(e.value)) e.key: e.value,
    },
  );
}

/// The number the next version of [log] takes: past every number the log
/// ever named. A version whose object went missing keeps its number, so a
/// pin still naming it in the log is never handed new content.
int nextVersionNumber(FoldedLog log, [HistoryManifest? decidedOn]) =>
    max(log.highest + 1, (decidedOn ?? log.manifest).nextNumber);

/// Records [lines] in the log of [rel], whose history is now [next]:
/// appended, or the log rewritten when it has grown well past [next].
void recordHistory(
  String root,
  String rel,
  FoldedLog before,
  HistoryManifest next,
  List<String> lines,
) {
  final after = (
    manifest: next,
    lines: before.lines + lines.length,
    highest: before.highest,
  );
  if (logWantsCompacting(after)) {
    writeLog(root, rel, next, highest: before.highest);
  } else {
    appendLog(root, rel, lines);
  }
}

/// Deletes the log of [rel] and the folders it leaves empty.
void deleteHistoryLog(String root, String rel) {
  final log = File(historyLogPath(root, rel));
  if (log.existsSync()) log.deleteSync();
  pruneHistoryFolders(root, log.parent);
}

/// Removes [dir] and its empty parents, stopping at `.history/` itself.
void pruneHistoryFolders(String root, Directory dir) {
  final stop = p.normalize(p.join(root, historyFolderName));
  var current = dir;
  while (p.isWithin(stop, current.path) && current.existsSync()) {
    if (current.listSync().isNotEmpty) return;
    current.deleteSync();
    current = current.parent;
  }
}
