/// One note as an EPUB (#303): a book of one chapter, its pictures inside
/// the container.
///
/// The page is the exported page the other formats use — `NoteHtml` for
/// the body, `MathSvg` for the formulas — wrapped in the XHTML an EPUB
/// chapter must be and packaged with [EpubBook]. A link out has nothing
/// to point at, exactly as on a page exported on its own.
library;

import 'dart:io';

import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// Where the book's one chapter sits in the container.
const String _chapterHref = 'OEBPS/text/note.xhtml';

/// The note at [path] (relative to [root]) as an EPUB payload.
///
/// [scratch] is where the container is built, a temp directory of its own
/// when null.
Future<ExportPayload> exportNoteEpub({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  LinkSource? linkSource,
  Directory? scratch,
}) async {
  final dir = scratch ?? await Directory.systemTemp.createTemp('niman-epub-');
  try {
    final file = p.join(dir.path, '${p.basenameWithoutExtension(path)}.epub');
    final book = await EpubBook.start(
      path: file,
      title: title,
      language: language,
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
        final href = await book.imageHref(
          p.posix.dirname(_chapterHref),
          entry.value,
        );
        if (href != null) images[entry.key] = href;
      }
      final source = NoteHtmlSource(text: text, title: title, images: images);
      final chapter = await ExportSources.xhtml(source);
      book.addChapter(
        href: _chapterHref,
        title: title,
        body: chapter.body,
        fontFaces: chapter.fontFaces,
      );
    } finally {
      await book.close();
    }
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
