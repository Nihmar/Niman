/// A text file opened on its own, outside any library (#77).
///
/// Nothing a library does happens to it: it is not indexed, has no
/// history and no sync, its links are shown and not resolved, and its
/// frontmatter is text. It is read from where it is and written back
/// there, as it is — the editor is the same one, the file is simply not
/// a note.
///
/// The file's bytes are the editor's business, as a library note's are: it is
/// read and written by the same code (`loadNote`, the framing a note keeps,
/// the stamp of the file), so a byte order mark, line endings and an
/// encoding round-trip as they do there, and a change made outside is seen
/// by its stamp (#1334). This class only says where the file is and listens
/// for it.
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The files opened on their own: the ones a Markdown editor opens —
/// Markdown and plain text. What a library calls a note is narrower:
/// `isMarkdownNote` alone, so a `.txt` is never indexed, imported or
/// exported as one (#233).
const Set<String> editorOnlyExtensions = {'md', 'markdown', 'txt'};

/// One file opened outside the library.
base class EditorOnlyDocument {
  /// The file at [filePath], an absolute path.
  new(this.filePath);

  /// The absolute path to the file on disk. Fixed for as long as it is
  /// open: Niman does not rename it.
  final String filePath;

  /// The file's name, as its tab shows it.
  String get name => p.basename(filePath);

  /// The folder it sits in, as the bar shows it.
  String get folder => p.dirname(filePath);

  /// Fires when something else changes the file on disk, so an open
  /// editor can take the change in (and keep its own unsaved edits when
  /// it has some).
  ///
  /// The folder is watched rather than the file: an editor saving by
  /// rename — Niman's own write included — replaces the file, and a watch
  /// on the old one would go quiet. Where the platform watches nothing
  /// (iOS), [Directory.watch] throws, and the file is simply not followed:
  /// the editor opens it as it is.
  Stream<void> changes() async* {
    final dir = Directory(folder);
    if (!FileSystemEntity.isWatchSupported || !await dir.exists()) return;
    yield* dir
        .watch()
        .where((event) => p.equals(event.path, filePath))
        .map((_) {});
  }
}
