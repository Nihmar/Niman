/// The history as it was kept before #1148: `.history/<path>.v<n>`, a whole
/// copy a version, and `.history/<path>.json`, a manifest rewritten on every
/// snapshot. Read only to be moved into the objects and the log.
///
/// The move is safe to cut short anywhere. The objects go first, then the
/// log — written whole and flushed — and the old files only once the log is
/// there; a log on disk therefore means the move finished, and old files
/// beside one are leftovers to delete.
///
/// Two isolates can move the same history at once — the upkeep at a
/// library's first open after the update, and a save of that very note.
/// The one that finds a version file gone, or the log already written, has
/// lost the race: the other wrote the whole log before deleting a file, so
/// this one writes nothing, and its caller reads what the other wrote. Left
/// to carry on, it would have written a log without the versions it could
/// no longer read, over the whole one. A version whose file no longer hashes
/// to what its manifest recorded stays out, as it always read as missing
/// (#378); a file the manifest did not describe comes in as an `unknown`
/// version, as it always read.
library;

import 'dart:io';

import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// The old manifest file of the note at [rel].
String legacyManifestPath(String root, String rel) =>
    p.join(root, historyFolderName, '$rel.json');

final RegExp _versionSuffix = RegExp(r'\.v(\d+)$');

/// Moves the old history of [rel], if it has one, into the objects and a
/// log; answers how many versions came in. Does nothing where a log is
/// already there but delete what an earlier move left.
int importLegacyHistory(String root, String rel) {
  final files = _versionFiles(root, rel);
  final manifestFile = File(legacyManifestPath(root, rel));
  final hasManifest = manifestFile.existsSync();
  if (files.isEmpty && !hasManifest) return 0;
  if (File(historyLogPath(root, rel)).existsSync()) {
    _deleteLegacy(files, manifestFile);
    return 0;
  }
  final stored = hasManifest
      ? HistoryManifest.decode(manifestFile.readAsStringSync())
      : HistoryManifest();
  final kept = <HistoryVersion>[];
  for (final MapEntry(key: number, value: file) in files.entries) {
    final described = stored.version(number);
    final List<int> bytes;
    try {
      bytes = file.readAsBytesSync();
    } on PathNotFoundException {
      return 0; // another move finished it: its log is there
    } on FileSystemException {
      continue; // unreadable: it never read as a version either
    }
    final sha = shaOf(bytes);
    if (described != null &&
        described.sha256.isNotEmpty &&
        described.sha256 != sha) {
      continue; // drifted: it never read as the content it claims
    }
    writeObject(root, sha, bytes);
    kept.add(
      HistoryVersion(
        number: number,
        savedAt: described?.savedAt ?? file.statSync().modified,
        reason: described?.reason ?? HistoryReason.unknown,
        size: bytes.length,
        sha256: sha,
      ),
    );
  }
  if (File(historyLogPath(root, rel)).existsSync()) return 0;
  final numbers = {for (final v in kept) v.number};
  writeLog(
    root,
    rel,
    HistoryManifest(
      versions: kept,
      pins: {
        for (final e in stored.pins.entries)
          if (numbers.contains(e.value)) e.key: e.value,
      },
    ),
  );
  _deleteLegacy(files, manifestFile);
  return kept.length;
}

/// Deletes the old history of [rel] without moving it in; answers how many
/// versions it held.
int deleteLegacyHistory(String root, String rel) {
  final files = _versionFiles(root, rel);
  _deleteLegacy(files, File(legacyManifestPath(root, rel)));
  return files.length;
}

/// Every note under [dir] (`.history/` or a folder in it) that still has
/// old history, as library-relative paths: what a library-wide pass moves.
List<String> legacyNotesUnder(String root, Directory dir) {
  if (!dir.existsSync()) return const [];
  final history = p.join(root, historyFolderName);
  final notes = <String>{};
  for (final entry in dir.listSync(recursive: true, followLinks: false)) {
    if (entry is! File) continue;
    final rel = p.split(p.relative(entry.path, from: history)).join('/');
    if (rel.startsWith('$historyObjectsFolderName/')) continue;
    if (rel.endsWith('.json')) {
      notes.add(rel.substring(0, rel.length - '.json'.length));
      continue;
    }
    final match = _versionSuffix.firstMatch(rel);
    if (match != null) notes.add(rel.substring(0, match.start));
  }
  return notes.toList()..sort();
}

/// The old `.v<n>` files of [rel], by number.
Map<int, File> _versionFiles(String root, String rel) {
  final dir = File(legacyManifestPath(root, rel)).parent;
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
    // Made from its path rather than taken from the listing: a listing's
    // files skip `IOOverrides`, which the race's test reads them through.
    if (number != null && number > 0) out[number] = File(entry.path);
  }
  return out;
}

void _deleteLegacy(Map<int, File> files, File manifest) {
  for (final file in files.values) {
    if (file.existsSync()) file.deleteSync();
  }
  if (manifest.existsSync()) manifest.deleteSync();
}
