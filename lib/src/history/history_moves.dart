/// A note's history following the note (docs/records/sync.md, "Following
/// the note"): moved with a rename or a move, deleted with the note. The
/// objects stay where they are — only logs move — and the ones no log names
/// any more go with the upkeep's collection (`history_upkeep.dart`).
library;

import 'dart:io';

import 'package:niman/src/history/history_access.dart';
import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// Moves the history of the note at [fromRel] to [toRel] (a rename or a
/// move of the note). When [toRel] already has history — left behind by
/// a note that used to live there — the moved versions are renumbered
/// after it and both are kept.
///
/// Returns how many versions moved.
int moveNoteHistory(String root, String fromRel, String toRel) {
  if (fromRel == toRel) return 0;
  return withHistoryLock(root, [fromRel, toRel], () {
    final source = presentVersions(root, loadHistoryLog(root, fromRel));
    if (source.versions.isEmpty) {
      _deleteNote(root, fromRel);
      return 0;
    }
    final targetLog = loadHistoryLog(root, toRel);
    final target = presentVersions(root, targetLog);
    if (target.versions.isEmpty) {
      final to = File(historyLogPath(root, toRel));
      to.parent.createSync(recursive: true);
      File(historyLogPath(root, fromRel)).renameSync(to.path);
      pruneHistoryFolders(root, File(historyLogPath(root, fromRel)).parent);
      return source.versions.length;
    }
    final offset = nextVersionNumber(targetLog, target) - 1;
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
    deleteHistoryLog(root, fromRel);
    return source.versions.length;
  });
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
int deleteNoteHistory(String root, String rel) =>
    withHistoryLock(root, [rel], () => _deleteNote(root, rel));

int _deleteNote(String root, String rel) {
  // An old history is deleted as it lies: moving it in first would write
  // objects only for the collection to take them.
  final logged = readLog(root, rel)?.manifest.versions.length;
  final legacy = deleteLegacyHistory(root, rel);
  deleteHistoryLog(root, rel);
  return logged ?? legacy;
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
  pruneHistoryFolders(root, dir.parent);
  return count;
}
