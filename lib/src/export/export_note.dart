/// One note as an exported file (#24): what it is called and the bytes it
/// holds.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// What a note is exported as.
enum ExportFormat {
  /// The note's own Markdown, as it is on disk.
  markdown,

  /// The note as one self-contained HTML page.
  html,

  /// The note as a PDF (#63), printed or drawn.
  pdf,

  /// The note as a one-chapter EPUB (#303), its pictures inside it.
  epub,
}

/// What an export writes: `name` as `bytes`, typed `mimeType`.
typedef ExportPayload = ({String name, Uint8List bytes, String mimeType});

/// What [exportNote] writes.
///
/// [ExportFormat.pdf] is not here: a PDF needs a printer to run and a theme
/// to draw with, and a builder over text and bytes has neither. Asking for
/// one is a compile-time error instead of a runtime one, and `exportNotePdf`
/// owns that format.
enum ExportFileFormat {
  /// The note's own Markdown, as it is on disk.
  markdown,

  /// The note as one self-contained HTML page.
  html,
}

/// The Markdown file for the note at [path]: its bytes as they are on
/// disk.
///
/// The export reads the file's bytes rather than reading the note and
/// writing the text back: `readNote` decodes leniently and drops a BOM, so
/// re-encoding its answer is not the file the user has.
ExportPayload exportMarkdown({
  required String path,
  required Uint8List bytes,
}) => (name: p.basename(path), bytes: bytes, mimeType: 'text/markdown');

/// The file one note's export makes.
///
/// `text` is the note as it stands — the caller saves the editor first —
/// `title` is what its page is called (`displayNameOf`), `path` its
/// library-relative path (its name becomes the file's), and `root` the
/// library's absolute root.
Future<ExportPayload> exportNote({
  required String text,
  required String title,
  required String path,
  required String root,
  required String language,
  required ExportFileFormat format,
  LinkSource? linkSource,
}) async {
  switch (format) {
    case ExportFileFormat.markdown:
      return exportMarkdown(
        path: path,
        bytes: Uint8List.fromList(utf8.encode(text)),
      );
    case ExportFileFormat.html:
      final source = await ExportSources.forNote(
        text: text,
        title: title,
        notePath: p.join(root, path),
        root: root,
        linkSource: linkSource,
      );
      final page = await ExportSources.page(source, language: language);
      return (
        name: '${p.basenameWithoutExtension(path)}.html',
        bytes: Uint8List.fromList(utf8.encode(page)),
        mimeType: 'text/html',
      );
  }
}
