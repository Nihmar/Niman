/// Where each book and PDF of a library was left (#281), in
/// `<library>/.niman/reading.json`: one entry per file, by its
/// library-relative path, holding its [BookLocation] and when it was
/// read there.
///
/// It is the library's, not the device's, and it syncs: a book left on
/// the phone opens on the desktop where the phone stopped. Two devices
/// reading two books never conflict, the sync merging the file entry by
/// entry, and the same book read on both keeps the later reading
/// (`mergeReadingJson`).
///
/// Nothing is cached: a pane reads the file when it opens a document and
/// writes it back as the reader moves, so a copy the sync just brought is
/// what the next open reads. The writes of one library run one after the
/// other, each reading the file afresh, so two panes never lose each
/// other's entry.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:path/path.dart' as p;

/// The reading positions of the library at [root].
final class ReadingPositions {
  /// The positions of the library whose absolute path is [root].
  const new(this.root);

  /// The library's absolute path.
  final String root;

  /// The file, library-relative: one of the sync's library state files.
  static const String filePath = '.niman/reading.json';

  /// The key an entry's time is kept under, beside its location's fields.
  static const String atKey = 'at';

  static const AppLogger _log = AppLogger(name: 'reading');

  /// The writes still running, by file: each waits for the one before.
  static final Map<String, Future<void>> _queues = {};

  File get _file => File(p.join(root, filePath));

  /// The library-relative key of [path], an absolute path; null when it
  /// is not inside the library.
  String? keyOf(String path) =>
      p.isWithin(root, path) ? relPath(path, root) : null;

  /// Where the file at [path], library-relative, was left; null when it
  /// never was, or the entry does not read.
  Future<BookLocation?> read(String path) async =>
      BookLocation.fromJson((await _load())[path]);

  /// Records that the file at [path], library-relative, was left at
  /// [location], now or [at].
  Future<void> write(String path, BookLocation location, {DateTime? at}) =>
      _update((entries) {
        entries[path] = {
          ...location.toJson(),
          atKey: (at ?? DateTime.now()).toUtc().toIso8601String(),
        };
        return true;
      });

  /// Carries the entries of [from] to [to], both library-relative: a file
  /// renamed or moved, or a folder and every file under it.
  Future<void> moved(String from, String to) => _update((entries) {
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
  });

  /// Runs [change] over the entries, after every earlier write of this
  /// library, and writes them back when it says it changed them.
  Future<void> _update(
    bool Function(Map<String, Object?> entries) change,
  ) async {
    final key = _file.path;
    final before = _queues[key];
    final done = Completer<void>();
    _queues[key] = done.future;
    try {
      if (before != null) await before;
      final entries = await _load();
      if (!change(entries)) return;
      await _file.parent.create(recursive: true);
      final text = const JsonEncoder.withIndent('  ').convert(entries);
      await writeFileAtomically(_file, utf8.encode('$text\n'));
    } on Object catch (error) {
      _log.warning('could not write $filePath: $error');
    } finally {
      done.complete();
      if (identical(_queues[key], done.future)) unawaited(_queues.remove(key));
    }
  }

  /// The entries on disk: none when the file is missing or is not a JSON
  /// object.
  Future<Map<String, Object?>> _load() async {
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value,
        };
      }
    } on FileSystemException {
      // No file yet: nothing was read in this library.
    } on FormatException catch (error) {
      _log.warning('$filePath does not read: $error');
    }
    return {};
  }
}
