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
}

/// What an export writes: `name` as `bytes`, typed `mimeType`.
typedef ExportPayload = ({String name, Uint8List bytes, String mimeType});

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
  required ExportFormat format,
  LinkSource? linkSource,
}) async {
  switch (format) {
    case ExportFormat.markdown:
      return (
        name: p.basename(path),
        bytes: Uint8List.fromList(utf8.encode(text)),
        mimeType: 'text/markdown',
      );
    case ExportFormat.html:
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
