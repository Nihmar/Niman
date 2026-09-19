/// A Markdown file opened on its own, outside any library (#77).
///
/// Nothing a library does happens to it: it is not indexed, has no
/// history and no sync, its links are shown and not resolved, and its
/// frontmatter is text. It is read from where it is and written back
/// there, as it is — the editor is the same one, the file is simply not
/// a note.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// The files opened on their own: the ones Markdown editors open.
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

  /// Its text.
  Future<String> read() => File(filePath).readAsString();

  /// Writes [content] back, whole or not at all.
  Future<void> write(String content) =>
      writeFileAtomically(File(filePath), utf8.encode(content));

  /// Whether the file is still there.
  bool get exists => File(filePath).existsSync();

  /// Fires when something else changes the file on disk, so an open
  /// editor can take the change in (and keep its own unsaved edits when
  /// it has some).
  ///
  /// The folder is watched rather than the file: an editor saving by
  /// rename — Niman's own write included — replaces the file, and a watch
  /// on the old one would go quiet.
  Stream<void> changes() {
    final dir = Directory(folder);
    if (!dir.existsSync()) return const Stream.empty();
    return dir
        .watch()
        .where((event) => p.equals(event.path, filePath))
        .map((_) {});
  }
}
