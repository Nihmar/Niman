/// One note as an EPUB (#303): a book of its chapters — one, or as many as
/// its headings say (`epub_note_chapters.dart`) — its pictures inside the
/// container.
///
/// The page is the exported page the other formats use — `NoteHtml` for
/// the body, `MathSvg` for the formulas — wrapped in the XHTML an EPUB
/// chapter must be and packaged with [EpubBook]. A link out has nothing
/// to point at, exactly as on a page exported on its own.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/epub_note_writer.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/export/epub_note_writer.dart'
    show EpubExportCancelled, EpubExportFailed;

const AppLogger _log = AppLogger(name: 'export');

/// The note at [path] (relative to [root]) as an EPUB payload.
///
/// What only the UI isolate can do happens here — resolving the cover and
/// the pictures against the link index ([linkSource]) — and the container is
/// written on a background isolate (#1305): the pictures are read and
/// stored, the page typeset and cut into chapters, and the book read back
/// there, never here.
///
/// [scratch] is where the container is built, a temp directory of its own
/// when null. [isCancelled] is asked before the pictures are resolved and
/// again while the container is written, at the stages a stop can land
/// between — before the book, between its pictures, after the page is
/// built — and answers with [EpubExportCancelled] rather than a file.
/// [todoBlocks] are the lists the note's `todo` fences are at this moment
/// (#1152). [writerProbe] is told, by a test, which isolate writes.
Future<ExportPayload> exportNoteEpub({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  LinkSource? linkSource,
  Directory? scratch,
  bool Function()? isCancelled,
  PrintedTodoBlocks todoBlocks = const <String, PrintedTodoBlock>{},
  bool kanban = false,
  @visibleForTesting SendPort? writerProbe,
}) async {
  if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
  final dir = scratch ?? await Directory.systemTemp.createTemp('niman-epub-');
  try {
    final file = p.join(dir.path, '${p.basenameWithoutExtension(path)}.epub');
    final coverTarget = epubMetadataOf(text).cover;
    final cover = coverTarget == null
        ? null
        : await ExportSources.picturePath(
            target: coverTarget,
            notePath: p.join(root, path),
            root: root,
            linkSource: linkSource,
          );
    if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
    final pictures = await ExportSources.imagePaths(
      text: text,
      notePath: p.join(root, path),
      root: root,
      linkSource: linkSource,
    );
    final written = await writeNoteEpubInBackground(
      (
        file: file,
        text: text,
        title: title,
        libraryPath: path,
        language: language,
        cover: cover,
        pictures: pictures,
        todoBlocks: todoBlocks,
        kanban: kanban,
      ),
      isCancelled: isCancelled,
      probe: writerProbe,
    );
    // A diagnostic for a formula that never shows (#303): what the chapter
    // written into the container carries.
    _log.info(
      'epub "$title": ${written.formulas} formulas drawn, '
      '${written.sources} left as source',
    );
    if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
    return (
      name: '${p.basenameWithoutExtension(path)}.epub',
      bytes: written.bytes.materialize().asUint8List(),
      mimeType: 'application/epub+zip',
    );
  } finally {
    if (scratch == null) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // The scratch is a temp directory: a failed sweep is not the
        // export's failure.
      }
    }
  }
}
