/// The `.history/` folder on disk (docs/dev/sync.md, "History").
///
/// Everything here is synchronous and top-level: it runs inside
/// `Isolate.run`, where the app's log buffer is not the main one, so the
/// functions return what happened (with log-ready notes) instead of
/// logging it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

/// The history folder's name inside the library root.
const String historyFolderName = '.history';

/// The file holding version [number] of the note at library-relative
/// [rel].
String historyVersionPath(String root, String rel, int number) =>
    p.join(root, historyFolderName, '$rel.v$number');

/// The manifest file of the note at library-relative [rel].
String historyManifestPath(String root, String rel) =>
    p.join(root, historyFolderName, '$rel.json');

final RegExp _versionSuffix = RegExp(r'\.v(\d+)$');

/// Reads the manifest of [rel], converging it with the version files on
/// disk: entries whose file is gone are dropped, and `.v<n>` files the
/// manifest does not describe (a torn write, a hand-copied folder) are
/// read back as [HistoryReason.unknown] versions.
HistoryManifest readHistoryManifest(String root, String rel) {
  final file = File(historyManifestPath(root, rel));
  final stored = file.existsSync()
      ? HistoryManifest.decode(file.readAsStringSync())
      : HistoryManifest();
  final onDisk = _versionFiles(root, rel);
  final kept = [
    for (final v in stored.versions)
      if (onDisk.containsKey(v.number)) v,
  ];
  final described = {for (final v in kept) v.number};
  for (final entry in onDisk.entries) {
    if (described.contains(entry.key)) continue;
    final stat = entry.value.statSync();
    kept.add(
      HistoryVersion(
        number: entry.key,
        savedAt: stat.modified,
        reason: HistoryReason.unknown,
        size: stat.size,
        sha256: '',
      ),
    );
  }
  return HistoryManifest(
    versions: kept,
    pins: {
      for (final e in stored.pins.entries)
        if (onDisk.containsKey(e.value)) e.key: e.value,
    },
  );
}

/// The `.v<n>` files of [rel], by number.
Map<int, File> _versionFiles(String root, String rel) {
  final manifest = File(historyManifestPath(root, rel));
  final dir = manifest.parent;
  if (!dir.existsSync()) return const {};
  final prefix = '${p.basename(rel)}.v';
  final out = <int, File>{};
  for (final entry in dir.listSync(followLinks: false)) {
    if (entry is! File) continue;
    final name = p.basename(entry.path);
    if (!name.startsWith(prefix)) continue;
    final match = _versionSuffix.firstMatch(name);
    if (match == null || match.start != prefix.length - 2) continue;
    final number = int.tryParse(match.group(1)!);
    if (number != null && number > 0) out[number] = entry;
  }
  return out;
}

/// Writes [manifest] for [rel] atomically; removes the file (and empty
/// folders up to `.history/`) when the manifest holds nothing.
void writeHistoryManifest(String root, String rel, HistoryManifest manifest) {
  final file = File(historyManifestPath(root, rel));
  if (manifest.versions.isEmpty) {
    if (file.existsSync()) file.deleteSync();
    _pruneEmptyFolders(root, file.parent);
    return;
  }
  file.parent.createSync(recursive: true);
  _writeAtomicallySync(file, utf8.encode(manifest.encode()));
}

/// What [snapshotBeforeWrite] did.
@immutable
final class SnapshotOutcome {
  /// Describes one snapshot attempt.
  const new({
    required this.decision,
    this.version,
    this.rotated = const [],
    this.elapsedMs = 0,
  });

  /// Whether a version was taken, and why.
  final SnapshotDecision decision;

  /// The version written, when one was.
  final HistoryVersion? version;

  /// The version numbers rotation deleted.
  final List<int> rotated;

  /// Time spent, in milliseconds.
  final int elapsedMs;

  /// A log-ready summary.
  String describe(String rel) {
    final buffer = StringBuffer('snapshot "$rel": $decision');
    final v = version;
    if (v != null) buffer.write(' -> v${v.number} (${v.size} b)');
    if (rotated.isNotEmpty) {
      buffer.write(', rotated out ${rotated.map((n) => 'v$n').join(', ')}');
    }
    buffer.write(' in $elapsedMs ms');
    return buffer.toString();
  }
}

/// Keeps the current content of the note at [rel] as a version when
/// [request] says so, then rotates. Call it right before overwriting the
/// note.
SnapshotOutcome snapshotBeforeWrite(
  String root,
  String rel,
  SnapshotRequest request,
) {
  final clock = Stopwatch()..start();
  final note = File(p.join(root, rel));
  final exists = note.existsSync();
  final manifest = exists ? readHistoryManifest(root, rel) : HistoryManifest();
  // The manifest alone often decides: the note is read only when it can.
  final early = exists
      ? skipWithoutReading(manifest: manifest, request: request)
      : null;
  if (early != null) {
    return SnapshotOutcome(
      decision: early,
      elapsedMs: clock.elapsedMilliseconds,
    );
  }
  final bytes = exists ? note.readAsBytesSync() : null;
  final oldSha = bytes == null ? null : sha256.convert(bytes).toString();
  final decision = decideSnapshot(
    manifest: manifest,
    oldSha: oldSha,
    request: request,
  );
  if (!decision.take) {
    return SnapshotOutcome(
      decision: decision,
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
  final target = File(historyVersionPath(root, rel, version.number));
  target.parent.createSync(recursive: true);
  _writeAtomicallySync(target, bytes);
  var next = manifest.adding(version);
  final overflow = next.overflow(request.limit);
  final rotated = <int>[];
  for (final old in overflow) {
    final file = File(historyVersionPath(root, rel, old.number));
    if (file.existsSync()) file.deleteSync();
    rotated.add(old.number);
  }
  next = next.removing(rotated.toSet());
  writeHistoryManifest(root, rel, next);
  return SnapshotOutcome(
    decision: decision,
    version: version,
    rotated: rotated,
    elapsedMs: clock.elapsedMilliseconds,
  );
}

/// The text of version [number] of [rel], or null when it is gone.
List<int>? readHistoryVersion(String root, String rel, int number) {
  final file = File(historyVersionPath(root, rel, number));
  return file.existsSync() ? file.readAsBytesSync() : null;
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
  final manifest = readHistoryManifest(root, rel);
  if (number != null && manifest.version(number) == null) {
    throw StateError('"$rel" has no v$number to pin');
  }
  var next = manifest.pinning(pin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  for (final n in rotated) {
    final file = File(historyVersionPath(root, rel, n));
    if (file.existsSync()) file.deleteSync();
  }
  next = next.removing(rotated.toSet());
  writeHistoryManifest(root, rel, next);
  return rotated;
}

/// Pins, as the sync base of [rel], the version whose content hashes to
/// [sha] — the content both sides agreed on at a successful sync
/// (docs/dev/sync.md, "Rotation and the pinned base").
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
  var manifest = readHistoryManifest(root, rel);
  int? number;
  for (final version in manifest.versions.reversed) {
    if (version.sha256 == sha) {
      number = version.number;
      break;
    }
  }
  var wrote = false;
  if (number == null) {
    final note = File(p.join(root, rel));
    final bytes = note.existsSync() ? note.readAsBytesSync() : null;
    if (bytes != null && sha256.convert(bytes).toString() == sha) {
      final version = HistoryVersion(
        number: manifest.nextNumber,
        savedAt: now,
        reason: HistoryReason.sync,
        size: bytes.length,
        sha256: sha,
      );
      final target = File(historyVersionPath(root, rel, version.number));
      target.parent.createSync(recursive: true);
      _writeAtomicallySync(target, bytes);
      manifest = manifest.adding(version);
      number = version.number;
      wrote = true;
    }
  }
  if (number == null && manifest.pins[syncBasePin] == null) {
    return (pinned: null, wrote: false, rotated: const <int>[]);
  }
  var next = manifest.pinning(syncBasePin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  for (final n in rotated) {
    final file = File(historyVersionPath(root, rel, n));
    if (file.existsSync()) file.deleteSync();
  }
  next = next.removing(rotated.toSet());
  writeHistoryManifest(root, rel, next);
  return (pinned: number, wrote: wrote, rotated: rotated);
}

/// Moves the history of the note at [fromRel] to [toRel] (a rename or a
/// move of the note). When [toRel] already has history — left behind by
/// a note that used to live there — the moved versions are renumbered
/// after it and both are kept.
///
/// Returns how many versions moved.
int moveNoteHistory(String root, String fromRel, String toRel) {
  if (fromRel == toRel) return 0;
  final source = readHistoryManifest(root, fromRel);
  if (source.versions.isEmpty) {
    deleteNoteHistory(root, fromRel);
    return 0;
  }
  final target = readHistoryManifest(root, toRel);
  final offset = target.versions.isEmpty ? 0 : target.nextNumber - 1;
  final moved = <HistoryVersion>[];
  for (final v in source.versions) {
    final number = v.number + offset;
    final to = File(historyVersionPath(root, toRel, number));
    to.parent.createSync(recursive: true);
    File(historyVersionPath(root, fromRel, v.number)).renameSync(to.path);
    moved.add(
      HistoryVersion(
        number: number,
        savedAt: v.savedAt,
        reason: v.reason,
        size: v.size,
        sha256: v.sha256,
      ),
    );
  }
  writeHistoryManifest(
    root,
    toRel,
    HistoryManifest(
      versions: [...target.versions, ...moved],
      pins: {
        ...target.pins,
        for (final e in source.pins.entries) e.key: e.value + offset,
      },
    ),
  );
  deleteNoteHistory(root, fromRel);
  return moved.length;
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
    return _manifestCount(to);
  }
  // Something already lives at the target: merge note by note.
  var count = 0;
  for (final entry in from.listSync(recursive: true, followLinks: false)) {
    if (entry is! File || !entry.path.endsWith('.json')) continue;
    final inner = p.split(p.relative(entry.path, from: from.path)).join('/');
    final noteRel = inner.substring(0, inner.length - '.json'.length);
    moveNoteHistory(root, '$fromRel/$noteRel', '$toRel/$noteRel');
    count++;
  }
  if (from.existsSync()) from.deleteSync(recursive: true);
  return count;
}

int _manifestCount(Directory dir) => dir
    .listSync(recursive: true, followLinks: false)
    .where((e) => e is File && e.path.endsWith('.json'))
    .length;

/// Deletes the history of the note at [rel]. Returns the versions
/// removed.
int deleteNoteHistory(String root, String rel) {
  final files = _versionFiles(root, rel);
  for (final file in files.values) {
    file.deleteSync();
  }
  final manifest = File(historyManifestPath(root, rel));
  if (manifest.existsSync()) manifest.deleteSync();
  _pruneEmptyFolders(root, manifest.parent);
  return files.length;
}

/// Deletes the history of every note under the folder [rel]. Returns the
/// notes whose history was removed.
int deleteFolderHistory(String root, String rel) {
  final dir = Directory(p.join(root, historyFolderName, rel));
  if (!dir.existsSync()) return 0;
  final count = _manifestCount(dir);
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

/// A synchronous temp-file + rename write (the async one in `files.dart`
/// is for callers that can await; these functions run inside an isolate
/// that does its work in one synchronous pass).
void _writeAtomicallySync(File file, List<int> bytes) {
  final tmp = File(
    p.join(
      file.parent.path,
      '.${p.basename(file.path)}.niman-tmp-'
      '${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  try {
    final raf = tmp.openSync(mode: FileMode.writeOnly);
    try {
      raf
        ..writeFromSync(bytes)
        ..flushSync();
    } finally {
      raf.closeSync();
    }
    tmp.renameSync(file.path);
  } catch (_) {
    if (tmp.existsSync()) tmp.deleteSync();
    rethrow;
  }
}
