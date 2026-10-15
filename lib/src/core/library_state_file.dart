/// A keyed JSON file of the library's `.niman/` folder (#951): the shape
/// `ReadingPositions` (`reading.json`) and `ReviewStore` (`review.json`)
/// share. One object, one entry per library-relative path, rewritten whole
/// on every change and merged entry by entry by the sync.
///
/// Nothing is cached: a read opens the file afresh, so a copy the sync just
/// brought is what the next read sees. The updates of one file run one after
/// the other, each reading it again, so two panes never lose each other's
/// entry. Reading, changing and writing all run on a background isolate: the
/// file is the whole library's, and a decode or an encode of it on the UI
/// isolate is a frame lost on every grade or step of a reader (AGENTS.md).
/// The on-disk format is an object keyed by path, so an older build reads it
/// unchanged.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// Changes the entries of a state file in place; says whether it did. It runs
/// on a background isolate, so it captures plain values only.
typedef StateChange = bool Function(Map<String, Object?> entries);

/// The keyed JSON file [filePath], library-relative, of the library at
/// [root].
final class LibraryStateFile {
  /// The file [filePath] of the library whose absolute path is [root].
  const new(this.root, this.filePath);

  /// The library's absolute path.
  final String root;

  /// The file, library-relative: one of the sync's library state files.
  final String filePath;

  static const AppLogger _log = AppLogger(name: 'library-state');

  /// The updates still running, by file: each waits for the one before.
  static final Map<String, Future<void>> _queues = {};

  /// The entries under [keys], on a background isolate; the others never
  /// reach the UI isolate. A key with no entry is absent, as is every key of
  /// a file that is missing or does not read.
  Future<Map<String, Object?>> read(Iterable<String> keys) async {
    final library = root;
    final path = filePath;
    final wanted = keys.toList(growable: false);
    final (:entries, :problem) = await Isolate.run(() {
      final (:entries, :problem) = readBlocking(library, path);
      return (
        entries: {
          for (final key in wanted)
            if (entries.containsKey(key)) key: entries[key],
        },
        problem: problem,
      );
    });
    if (problem != null) _log.warning('$filePath does not read: $problem');
    return entries;
  }

  /// Every entry, on a background isolate.
  Future<Map<String, Object?>> readAll() async {
    final library = root;
    final path = filePath;
    final (:entries, :problem) = await Isolate.run(
      () => readBlocking(library, path),
    );
    if (problem != null) _log.warning('$filePath does not read: $problem');
    return entries;
  }

  /// The entries of the file [filePath] of the library at [root], read and
  /// decoded here and now: for code already on a background isolate. None
  /// when the file is missing or is not a JSON object; the record says why a
  /// file that is there did not read.
  static ({Map<String, Object?> entries, String? problem}) readBlocking(
    String root,
    String filePath,
  ) {
    try {
      final decoded = jsonDecode(
        File(p.join(root, filePath)).readAsStringSync(),
      );
      if (decoded is Map) {
        return (
          entries: {
            for (final entry in decoded.entries)
              entry.key.toString(): entry.value,
          },
          problem: null,
        );
      }
    } on FileSystemException {
      // No file yet: nothing was recorded in this library.
    } on FormatException catch (error) {
      return (entries: <String, Object?>{}, problem: error.toString());
    }
    return (entries: <String, Object?>{}, problem: null);
  }

  /// Runs [change] over the entries, after every earlier update of this
  /// file, and writes them back when it says it changed them. Says whether
  /// it wrote.
  ///
  /// The read, [change] and the write are one job on a background isolate,
  /// so [change] captures plain values only. A file that does not read is
  /// written over; a write that fails is logged, not thrown, and says false.
  Future<bool> update(StateChange change) async {
    final library = root;
    final path = filePath;
    final key = p.join(library, path);
    final before = _queues[key];
    final done = Completer<void>();
    _queues[key] = done.future;
    try {
      if (before != null) await before;
      final (:wrote, :problem) = await Isolate.run(
        () => _updateBlocking(library, path, change),
      );
      if (problem != null) _log.warning('$path does not read: $problem');
      return wrote;
    } on Object catch (error) {
      _log.warning('could not write $path: $error');
      return false;
    } finally {
      done.complete();
      if (identical(_queues[key], done.future)) unawaited(_queues.remove(key));
    }
  }

  /// Carries the entries of [from] to [to], both library-relative: a file
  /// renamed or moved, or a folder and every file under it. Says whether
  /// anything moved.
  Future<bool> moved(String from, String to) =>
      update((entries) => _carry(entries, from, to));

  /// Drops the entries of [paths], library-relative, and of the files under
  /// them: the files the library saw leave. Says whether anything went.
  ///
  /// Only a deletion the library observed comes through here. An update does
  /// not drop an absent file on its own: on this device that can be an entry
  /// the sync brought for a file that has not arrived yet, and dropping it
  /// would delete the other device's entry at the next sync.
  Future<bool> removed(Iterable<String> paths) {
    final gone = paths.toList(growable: false);
    if (gone.isEmpty) return Future<bool>.value(false);
    return update((entries) => _drop(entries, gone));
  }
}

bool _carry(Map<String, Object?> entries, String from, String to) {
  final carried = {
    for (final key in entries.keys)
      if (key == from || isUnder(from, key))
        key: to + key.substring(from.length),
  };
  if (carried.isEmpty) return false;
  for (final MapEntry(key: old, value: moved) in carried.entries) {
    entries[moved] = entries.remove(old);
  }
  return true;
}

bool _drop(Map<String, Object?> entries, List<String> gone) {
  final leaving =
      entries.keys
          .where((key) => gone.any((path) => key == path || isUnder(path, key)))
          .toList(growable: false)
        ..forEach(entries.remove);
  return leaving.isNotEmpty;
}

/// The job of [LibraryStateFile.update], top level so the closure of
/// `Isolate.run` carries only the paths and the change.
Future<({bool wrote, String? problem})> _updateBlocking(
  String root,
  String filePath,
  StateChange change,
) async {
  final (:entries, :problem) = LibraryStateFile.readBlocking(root, filePath);
  if (!change(entries)) return (wrote: false, problem: problem);
  final file = File(p.join(root, filePath));
  await file.parent.create(recursive: true);
  final text = const JsonEncoder.withIndent('  ').convert(entries);
  await writeFileAtomically(file, utf8.encode('$text\n'));
  return (wrote: true, problem: problem);
}
