/// The `.history/` folder on disk (docs/records/history-store.md).
///
/// A note's versions are objects named by their content, kept once
/// (`history_objects.dart`), and listed by the note's append-only log
/// (`history_log.dart`); a history kept the old way is moved in the first
/// time it is touched (`history_legacy.dart`).
///
/// Everything here is synchronous and top-level: it runs inside
/// `Isolate.run`, where the app's log buffer is not the main one, so the
/// functions return what happened (with log-ready notes) instead of
/// logging it.
library;

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/history/external_write_check.dart';
import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/history/history_objects.dart' show historyFolderName;

/// The log of [rel] folded, the old history moved in first when it has one.
///
/// The log is read again after the move whatever it answered: a move that
/// lost the race to another (`history_legacy.dart`) writes nothing, and the
/// log is the other's.
FoldedLog _load(String root, String rel) {
  final log = readLog(root, rel);
  if (log != null) return log;
  importLegacyHistory(root, rel);
  return readLog(root, rel) ?? (manifest: HistoryManifest(), lines: 0);
}

/// [log]'s history without the versions whose object is gone, and the pins
/// on them: what a reader can actually have.
HistoryManifest _present(String root, FoldedLog log) {
  final manifest = log.manifest;
  final kept = [
    for (final v in manifest.versions)
      if (hasObject(root, v.sha256)) v,
  ];
  if (kept.length == manifest.versions.length) return manifest;
  final numbers = {for (final v in kept) v.number};
  return HistoryManifest(
    versions: kept,
    pins: {
      for (final e in manifest.pins.entries)
        if (numbers.contains(e.value)) e.key: e.value,
    },
  );
}

/// The versions kept for [rel] (oldest first) and its pins. A version whose
/// object is gone is not listed.
HistoryManifest readHistoryManifest(String root, String rel) =>
    _present(root, _load(root, rel));

/// Records [lines] in the log of [rel], whose history is now [next]:
/// appended, or the log rewritten when it has grown well past [next].
void _record(
  String root,
  String rel,
  FoldedLog before,
  HistoryManifest next,
  List<String> lines,
) {
  final after = (manifest: next, lines: before.lines + lines.length);
  if (logWantsCompacting(after)) {
    writeLog(root, rel, next);
  } else {
    appendLog(root, rel, lines);
  }
}

/// What [snapshotBeforeWrite] did.
@immutable
final class SnapshotOutcome {
  /// Describes one snapshot attempt.
  const new({
    required this.decision,
    this.version,
    this.rotated = const [],
    this.external,
    this.elapsedMs = 0,
    this.keepMs = 0,
    this.manifestMs = 0,
  });

  /// Whether a version was taken, and why.
  final SnapshotDecision decision;

  /// The version written, when one was.
  final HistoryVersion? version;

  /// The version numbers rotation deleted.
  final List<int> rotated;

  /// How the external check was settled when the stamps alone could not
  /// ([ExternalWriteCheck.note]): the stamps compared and what the bytes
  /// said. Null when they agreed or nothing was expected.
  final String? external;

  /// Time spent, in milliseconds.
  final int elapsedMs;

  /// Of [elapsedMs], the version's object and the log's line, when a
  /// version was taken. Before #1148 they were a whole copy and a whole
  /// manifest, each written, flushed and renamed: 85 ms at the median on a
  /// tablet, as long for 10 KB as for 1.5 MB (device log, 2026-10-20).
  final int keepMs;

  /// See [keepMs].
  final int manifestMs;

  /// A log-ready summary.
  String describe(String rel) {
    final buffer = StringBuffer('snapshot "$rel": $decision');
    final v = version;
    if (v != null) buffer.write(' -> v${v.number} (${v.size} b)');
    if (rotated.isNotEmpty) {
      buffer.write(', rotated out ${rotated.map((n) => 'v$n').join(', ')}');
    }
    final checked = external;
    if (checked != null) buffer.write(' [external check: $checked]');
    buffer.write(' in $elapsedMs ms');
    if (v != null) buffer.write(' (object $keepMs, log $manifestMs)');
    return buffer.toString();
  }
}

/// Keeps the current content of the note at [rel] as a version when
/// the request says so, then rotates. Call it right before overwriting the
/// note.
SnapshotOutcome snapshotBeforeWrite(
  String root,
  String rel,
  SnapshotRequest asked,
) {
  final clock = Stopwatch()..start();
  final note = File(p.join(root, rel));
  final exists = note.existsSync();
  // A file that is not the one the editor last saw, nor the one the app last
  // wrote, was written by somebody else, and the save about to replace it is
  // the last chance to keep what they wrote (#1055). A reason already forced
  // (a restore, a sync) stands.
  final check = exists ? ExternalWriteCheck.of(note, asked) : null;
  final foreign = check?.foreign ?? false;
  final request = foreign
      ? SnapshotRequest(
          limit: asked.limit,
          interval: asked.interval,
          now: asked.now,
          sessionStart: asked.sessionStart,
          forced: asked.forced ?? HistoryReason.external,
        )
      : asked;
  final log = exists ? _load(root, rel) : null;
  final manifest = log == null ? HistoryManifest() : _present(root, log);
  // The manifest alone often decides: the note is read only when it can.
  final early = exists
      ? skipWithoutReading(manifest: manifest, request: request)
      : null;
  if (early != null) {
    return SnapshotOutcome(
      decision: early,
      external: check?.note,
      elapsedMs: clock.elapsedMilliseconds,
    );
  }
  final bytes = exists ? check?.bytes ?? note.readAsBytesSync() : null;
  final oldSha = bytes == null ? null : shaOf(bytes);
  final decision = decideSnapshot(
    manifest: manifest,
    oldSha: oldSha,
    request: request,
  );
  if (!decision.take) {
    // Unchanged since the newest version: the note holds that version's
    // content, so an object of it a crash cut short is whole again here.
    if (oldSha != null && oldSha == manifest.newest?.sha256) {
      writeObject(root, oldSha, bytes!);
    }
    return SnapshotOutcome(
      decision: decision,
      external: check?.note,
      elapsedMs: clock.elapsedMilliseconds,
    );
  }
  final version = HistoryVersion(
    number: manifest.nextNumber,
    savedAt: request.now,
    reason: decision.reason!,
    size: bytes!.length,
    sha256: oldSha!,
  );
  final keepAt = clock.elapsedMilliseconds;
  writeObject(root, version.sha256, bytes);
  final logAt = clock.elapsedMilliseconds;
  var next = manifest.adding(version);
  final rotated = [for (final old in next.overflow(request.limit)) old.number];
  next = next.removing(rotated.toSet());
  _record(root, rel, log!, next, [
    keptLine(version),
    if (rotated.isNotEmpty) dropLine(rotated),
  ]);
  return SnapshotOutcome(
    decision: decision,
    version: version,
    rotated: rotated,
    external: check?.note,
    elapsedMs: clock.elapsedMilliseconds,
    keepMs: logAt - keepAt,
    manifestMs: clock.elapsedMilliseconds - logAt,
  );
}

/// The bytes of version [number] of [rel], or null when it is gone — or
/// when what its object rebuilds no longer hashes to the sha256 the log
/// records (a write a crash cut short, an edit by hand).
///
/// A drifted version is never handed back as the content its hash claims:
/// it is treated the way a missing one is, so a caller that would use it as
/// a merge base gets no base and the path becomes a conflict instead (see
/// #378).
List<int>? readHistoryVersion(String root, String rel, int number) {
  final version = _load(root, rel).manifest.version(number);
  if (version == null) return null;
  return readObject(root, version.sha256);
}

/// Pins version [number] of [rel] under [pin] (null unpins), then rotates
/// the version the pin released when it no longer fits [limit].
///
/// Returns the version numbers rotated out.
List<int> pinHistoryVersion(
  String root,
  String rel,
  String pin,
  int? number, {
  required int limit,
}) {
  final log = _load(root, rel);
  final manifest = _present(root, log);
  if (number != null && manifest.version(number) == null) {
    throw StateError('"$rel" has no v$number to pin');
  }
  var next = manifest.pinning(pin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  next = next.removing(rotated.toSet());
  _record(root, rel, log, next, [
    pinLine(pin, number),
    if (rotated.isNotEmpty) dropLine(rotated),
  ]);
  return rotated;
}

/// Pins, as the sync base of [rel], the version whose content hashes to
/// [sha] — the content both sides agreed on at a successful sync
/// (docs/records/sync.md, "Rotation and the pinned base").
///
/// The newest version with that content is pinned. When there is none and
/// the note on disk still holds that content, it is kept as a new version
/// (reason `sync`) first. When neither holds it — the note was edited
/// again before the pin — nothing is pinned and the old pin is released.
/// Rotation then runs against [limit]; the pin never rotates out.
///
/// Returns the pinned version number (null when none), whether a version
/// was written, and the numbers rotated out.
({int? pinned, bool wrote, List<int> rotated}) pinSyncBaseVersion(
  String root,
  String rel,
  String sha, {
  required int limit,
  required DateTime now,
}) {
  final log = _load(root, rel);
  var manifest = _present(root, log);
  final lines = <String>[];
  int? number;
  for (final version in manifest.versions.reversed) {
    if (version.sha256 != sha) continue;
    // An object that no longer rebuilds its content is never pinned as the
    // base (#378): the same content may still be read through another
    // version, so the search goes on.
    if (readObject(root, version.sha256) == null) continue;
    number = version.number;
    break;
  }
  var wrote = false;
  if (number == null) {
    final note = File(p.join(root, rel));
    final bytes = note.existsSync() ? note.readAsBytesSync() : null;
    if (bytes != null && shaOf(bytes) == sha) {
      final version = HistoryVersion(
        number: manifest.nextNumber,
        savedAt: now,
        reason: HistoryReason.sync,
        size: bytes.length,
        sha256: sha,
      );
      writeObject(root, sha, bytes);
      manifest = manifest.adding(version);
      lines.add(keptLine(version));
      number = version.number;
      wrote = true;
    }
  }
  if (number == null && manifest.pins[syncBasePin] == null) {
    return (pinned: null, wrote: false, rotated: const <int>[]);
  }
  var next = manifest.pinning(syncBasePin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  next = next.removing(rotated.toSet());
  _record(root, rel, log, next, [
    ...lines,
    pinLine(syncBasePin, number),
    if (rotated.isNotEmpty) dropLine(rotated),
  ]);
  return (pinned: number, wrote: wrote, rotated: rotated);
}

/// Moves the history of the note at [fromRel] to [toRel] (a rename or a
/// move of the note). When [toRel] already has history — left behind by
/// a note that used to live there — the moved versions are renumbered
/// after it and both are kept. The objects stay where they are: only the
/// log moves.
///
/// Returns how many versions moved.
int moveNoteHistory(String root, String fromRel, String toRel) {
  if (fromRel == toRel) return 0;
  final source = _present(root, _load(root, fromRel));
  if (source.versions.isEmpty) {
    deleteNoteHistory(root, fromRel);
    return 0;
  }
  final target = _present(root, _load(root, toRel));
  if (target.versions.isEmpty) {
    final to = File(historyLogPath(root, toRel));
    to.parent.createSync(recursive: true);
    File(historyLogPath(root, fromRel)).renameSync(to.path);
    _pruneEmptyFolders(root, File(historyLogPath(root, fromRel)).parent);
    return source.versions.length;
  }
  final offset = target.nextNumber - 1;
  writeLog(
    root,
    toRel,
    HistoryManifest(
      versions: [
        ...target.versions,
        for (final v in source.versions)
          HistoryVersion(
            number: v.number + offset,
            savedAt: v.savedAt,
            reason: v.reason,
            size: v.size,
            sha256: v.sha256,
          ),
      ],
      pins: {
        ...target.pins,
        for (final e in source.pins.entries) e.key: e.value + offset,
      },
    ),
  );
  _deleteLog(root, fromRel);
  return source.versions.length;
}

/// Moves the history of every note under the folder [fromRel] to [toRel]
/// (a folder rename or move). Returns how many notes' histories moved.
int moveFolderHistory(String root, String fromRel, String toRel) {
  if (fromRel == toRel) return 0;
  final from = Directory(p.join(root, historyFolderName, fromRel));
  if (!from.existsSync()) return 0;
  final to = Directory(p.join(root, historyFolderName, toRel));
  if (!to.existsSync()) {
    to.parent.createSync(recursive: true);
    from.renameSync(to.path);
    return _notesUnder(root, to).length;
  }
  // Something already lives at the target: merge note by note.
  final notes = _notesUnder(root, from);
  final prefix = '$fromRel/';
  for (final rel in notes) {
    final inner = rel.substring(prefix.length);
    moveNoteHistory(root, rel, '$toRel/$inner');
  }
  if (from.existsSync()) from.deleteSync(recursive: true);
  return notes.length;
}

/// The notes under [dir] (in `.history/`) that have history, old or new,
/// as library-relative paths.
List<String> _notesUnder(String root, Directory dir) {
  final history = p.join(root, historyFolderName);
  final notes = {...legacyNotesUnder(root, dir)};
  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    if (entry is! File || !entry.path.endsWith('.log')) continue;
    final rel = p.split(p.relative(entry.path, from: history)).join('/');
    notes.add(rel.substring(0, rel.length - '.log'.length));
  }
  return notes.toList()..sort();
}

/// Deletes the history of the note at [rel]. Returns the versions
/// removed. Their objects go with the next collection, unless another
/// version still names them.
int deleteNoteHistory(String root, String rel) {
  // An old history is deleted as it lies: moving it in first would write
  // objects only for the collection to take them.
  final logged = readLog(root, rel)?.manifest.versions.length;
  final legacy = deleteLegacyHistory(root, rel);
  _deleteLog(root, rel);
  return logged ?? legacy;
}

void _deleteLog(String root, String rel) {
  final log = File(historyLogPath(root, rel));
  if (log.existsSync()) log.deleteSync();
  _pruneEmptyFolders(root, log.parent);
}

/// Deletes the history of every note under the folder [rel]. Returns the
/// notes whose history was removed.
int deleteFolderHistory(String root, String rel) {
  final dir = Directory(p.join(root, historyFolderName, rel));
  if (!dir.existsSync() || p.equals(dir.path, historyObjectsPath(root))) {
    return 0;
  }
  final count = _notesUnder(root, dir).length;
  dir.deleteSync(recursive: true);
  _pruneEmptyFolders(root, dir.parent);
  return count;
}

/// Removes [dir] and its empty parents, stopping at `.history/` itself.
void _pruneEmptyFolders(String root, Directory dir) {
  final stop = p.normalize(p.join(root, historyFolderName));
  var current = dir;
  while (p.isWithin(stop, current.path) && current.existsSync()) {
    if (current.listSync().isNotEmpty) return;
    current.deleteSync();
    current = current.parent;
  }
}
