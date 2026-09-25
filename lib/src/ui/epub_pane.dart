/// An EPUB, read in the note pane (#280).
///
/// The book is read into Markdown off the UI isolate ([openEpub]) and drawn
/// by the note's own read view, in the note column, with a look of its own:
/// the library's theme, brightness, face and text size for its books
/// ([EpubLooks]), set from the Aa button on the row below. Its pictures
/// come from the app's cache, its own links jump within it, and its table
/// of contents is a button on that row too. It opens where it was left
/// ([ReadingPositions]), or where the link it was opened by points
/// ([BookLocation.fromFragment]). Its paragraphs are annotated in a
/// companion note (#284), and marked where they were (#285).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/epub_pane_state.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:niman/src/ui/epub_pane_state.dart' show EpubPaneState;

/// The folder of the app's cache the books' pictures go under.
Future<String> _epubCacheDir() async =>
    p.join((await getApplicationCacheDirectory()).path, 'epub');

/// The EPUB at [path], an absolute path, read in the note pane.
final class EpubPane extends StatefulWidget {
  /// Reads the book at [path].
  const new({
    required this.path,
    this.launcher = const OsLauncher(),
    this.column = NoteColumn.off,
    this.cacheDir = _epubCacheDir,
    this.onEditLook,
    this.positions,
    this.anchor,
    this.reloadToken = 0,
    this.linkType = LinkType.wikilink,
    this.onAnnotate,
    this.marks,
    super.key,
  });

  /// The book's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// The shell's note column, which the book is set in like a note.
  final NoteColumn column;

  /// Where the books' pictures are extracted: the app's cache, or a test's
  /// own folder.
  final Future<String> Function() cacheDir;

  /// Opens the sheet that sets how the books look; null leaves its button
  /// on the row, disabled.
  final VoidCallback? onEditLook;

  /// Where the library keeps its reading positions; null keeps none, and
  /// the book opens at its start.
  final ReadingPositions? positions;

  /// The fragment of the link the book was opened by (#282), naming a place
  /// in it: `chapter=OEBPS/ch5.xhtml&line=12`. It wins over where the book
  /// was left.
  final String? anchor;

  /// Bumped when the same link is followed again, so the book goes back to
  /// its place.
  final int reloadToken;

  /// How the library writes links, for the one to the place being read.
  final LinkType linkType;

  /// Annotates a paragraph of the book in its companion note (#284); null
  /// offers no annotating.
  final void Function(Annotation annotation)? onAnnotate;

  /// Where the library's files were annotated (#285): the paragraphs a
  /// companion note points at are marked, and a tap opens the note. Null
  /// marks nothing.
  final AnnotationMarkSource? marks;

  @override
  State<EpubPane> createState() => EpubPaneState();
}
