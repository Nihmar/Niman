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
/// other's entry. The entries of books the library saw leave are dropped
/// (#367), on the deletion rather than on the next write: a write does not
/// stat the library, so a position the sync brought for a book whose file
/// has not arrived yet is not mistaken for a deleted one (#492).
library;

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/library_state_file.dart';
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

  LibraryStateFile get _state => LibraryStateFile(root, filePath);

  /// The library-relative key of [path], an absolute path; null when it
  /// is not inside the library.
  String? keyOf(String path) =>
      p.isWithin(root, path) ? relPath(path, root) : null;

  /// Where the file at [path], library-relative, was left; null when it
  /// never was, or the entry does not read.
  Future<BookLocation?> read(String path) async =>
      BookLocation.fromJson((await _state.read([path]))[path]);

  /// Records that the file at [path], library-relative, was left at
  /// [location], now or [at].
  Future<void> write(String path, BookLocation location, {DateTime? at}) {
    final entry = {
      ...location.toJson(),
      atKey: (at ?? DateTime.now()).toUtc().toIso8601String(),
    };
    return _state.update((entries) {
      entries[path] = entry;
      return true;
    });
  }

  /// Carries the entries of [from] to [to], both library-relative: a file
  /// renamed or moved, or a folder and every file under it.
  Future<void> moved(String from, String to) => _state.moved(from, to);

  /// Drops the entries of [paths], library-relative, and of the books under
  /// them: the files the library saw leave (#492). See
  /// [LibraryStateFile.removed] for why only an observed deletion drops an
  /// entry.
  Future<void> removed(Iterable<String> paths) => _state.removed(paths);
}
