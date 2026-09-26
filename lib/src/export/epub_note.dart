/// One note as an EPUB (#303): a book of one chapter, its pictures inside
/// the container.
///
/// The page is the exported page the other formats use — `NoteHtml` for
/// the body, `MathSvg` for the formulas — wrapped in the XHTML an EPUB
/// chapter must be and packaged with [EpubBook]. A link out has nothing
/// to point at, exactly as on a page exported on its own.
library;

import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

const AppLogger _log = AppLogger(name: 'export');

/// Where the book's one chapter sits in the container.
const String _chapterHref = 'OEBPS/text/note.xhtml';

/// The user stopped a note's EPUB export: no file is written.
final class EpubExportCancelled implements Exception {
  /// Creates the cancellation.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'EPUB export cancelled';
}

/// The note at [path] (relative to [root]) as an EPUB payload.
///
/// [scratch] is where the container is built, a temp directory of its own
/// when null. [isCancelled] is asked at the stages a stop can land between —
/// before the book, between its pictures, after the page is built — and
/// answers with [EpubExportCancelled] rather than a file; the typesetting
/// inside [ExportSources.xhtml] is one isolate pass and runs to its end.
Future<ExportPayload> exportNoteEpub({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  LinkSource? linkSource,
  Directory? scratch,
  bool Function()? isCancelled,
}) async {
  if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
  final dir = scratch ?? await Directory.systemTemp.createTemp('niman-epub-');
  try {
    final file = p.join(dir.path, '${p.basenameWithoutExtension(path)}.epub');
    final metadata = epubMetadataOf(text);
    final coverTarget = metadata.cover;
    final cover = coverTarget == null
        ? null
        : await ExportSources.picturePath(
            target: coverTarget,
            notePath: p.join(root, path),
            root: root,
            linkSource: linkSource,
          );
    if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
    final book = await EpubBook.start(
      path: file,
      title: title,
      language: language,
      metadata: metadata,
      cover: cover,
    );
    try {
      final paths = await ExportSources.imagePaths(
        text: text,
        notePath: p.join(root, path),
        root: root,
        linkSource: linkSource,
      );
      final images = <String, String>{};
      for (final entry in paths.entries) {
        if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
        final href = await book.imageHref(
          p.posix.dirname(_chapterHref),
          entry.value,
        );
        if (href != null) images[entry.key] = href;
      }
      final source = NoteHtmlSource(text: text, title: title, images: images);
      final chapter = await ExportSources.xhtml(source);
      if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
      // A diagnostic for a formula that never shows (#303): what the chapter
      // written into the container carries.
      _log.info(
        'epub "$title": ${_count(chapter.body, '<svg')} formulas drawn, '
        '${_count(chapter.body, 'class="math-source"')} left as source',
      );
      book.addChapter(
        href: _chapterHref,
        title: title,
        body: chapter.body,
        fontFaces: chapter.fontFaces,
        hasSvg: chapter.hasSvg,
      );
    } finally {
      await book.close();
    }
    if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
    return (
      name: '${p.basenameWithoutExtension(path)}.epub',
      bytes: await File(file).readAsBytes(),
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

/// How many times [needle] appears in [text]; a diagnostic count, not a
/// parser.
int _count(String text, String needle) {
  var count = 0;
  var at = 0;
  while (true) {
    final found = text.indexOf(needle, at);
    if (found < 0) return count;
    count++;
    at = found + needle.length;
  }
}
