/// Everything an exported page needs from the disk (#24), gathered before
/// the page is built: the pictures the note shows, as `data:` URIs.
///
/// Building a page reads nothing ([NoteHtmlSource]), so this is where the
/// reading happens. A picture that cannot be resolved, read or typed stays
/// as the note wrote it, and the skip is logged.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/links/embed_path.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

const AppLogger _log = AppLogger(name: 'export');

/// The note's own sources, read for its page.
abstract final class ExportSources {
  /// A whole note's page source: its [text], its [title], and every picture
  /// it shows as a `data:` URI, by the target as the note writes it.
  static Future<NoteHtmlSource> forNote({
    required String text,
    required String title,
    required String notePath,
    required String root,
    LinkSource? linkSource,
  }) async => NoteHtmlSource(
    text: text,
    title: title,
    images: await images(
      text: text,
      notePath: notePath,
      root: root,
      linkSource: linkSource,
    ),
  );

  /// The pictures [text] shows, resolved and read: `data:` URIs by the
  /// target as written — an embed's wiki target, a Markdown image's `src`.
  static Future<Map<String, String>> images({
    required String text,
    required String notePath,
    required String root,
    LinkSource? linkSource,
  }) async {
    final images = <String, String>{};
    for (final target in pictureTargets(text)) {
      final path = await _picturePath(target, notePath, root, linkSource);
      if (path == null) {
        _log.warning('picture not found: "$target" in $notePath');
        continue;
      }
      final uri = await pictureDataUri(path);
      if (uri == null) continue;
      images[target] = uri;
    }
    return images;
  }

  /// The whole page for [source], built off the UI isolate (#24): the
  /// parse, the code highlighting and the formulas' SVG are a tenth of a
  /// second on a large note, and a tenth of a second is a visible hang.
  static Future<String> page(
    NoteHtmlSource source, {
    required String language,
  }) => Isolate.run(() {
    final html = NoteHtml(source);
    return htmlPage(
      title: source.title,
      body: html.body(),
      fontFaces: html.fontFaces,
      language: language,
    );
  });

  /// The picture targets [text] names, as written: an embed's
  /// (`![[photo.png]]`) and a Markdown image's (the parser's `img src`).
  ///
  /// Only an embed with an image extension counts: `![[notes.md]]` is a
  /// link to a file that happens to be an embed, the same rule the read
  /// view draws by.
  static List<String> pictureTargets(String text) {
    final out = <String>{};
    for (final target in _embeds(text)) {
      if (EmbedView.imageExtensions.hasMatch(target)) out.add(target);
    }
    out.addAll(NoteHtml(NoteHtmlSource(text: text, title: '')).imageTargets());
    return out.toList();
  }

  /// The embed targets of [text], through the read view's own masker: a
  /// `![[…]]` in code, math, raw HTML or the frontmatter is not one.
  static List<String> _embeds(String text) {
    const masker = ExtensionMasker();
    final buffer = SourceBuffer.fromText(text);
    final out = <String>[];
    for (final block in BlockScanner(buffer).index.blocks) {
      if (!_carriesEmbeds(block.kind)) continue;
      final blockText = [
        for (var line = block.startLine; line < block.endLine; line++)
          buffer.lineAt(line),
      ].join('\n');
      for (final span in masker.mask(blockText).spans) {
        if (span.kind != ExtensionKind.embed) continue;
        final target = parseWikiRef(span.inner).target;
        if (target.isNotEmpty) out.add(target);
      }
    }
    return out;
  }

  /// Whether a block's text is read as constructs at all.
  static bool _carriesEmbeds(BlockKind kind) => switch (kind) {
    BlockKind.frontmatter ||
    BlockKind.fencedCode ||
    BlockKind.indentedCode ||
    BlockKind.math ||
    BlockKind.html => false,
    _ => true,
  };

  /// Resolves [target], then its percent-decoded form — a Markdown image is
  /// written the way a URL is, where the path is not.
  static Future<String?> _picturePath(
    String target,
    String notePath,
    String root,
    LinkSource? linkSource,
  ) async {
    final path = await resolveEmbedPath(target, notePath, root, linkSource);
    if (path != null) return path;
    try {
      final decoded = Uri.decodeFull(target);
      if (decoded == target) return null;
      return await resolveEmbedPath(decoded, notePath, root, linkSource);
    } on FormatException {
      return null;
    }
  }

  /// The picture at [path] as a `data:` URI, read off the UI isolate; null
  /// when its extension has no image type or the file cannot be read, and
  /// the skip is logged here — not in the isolate, whose own log would be
  /// thrown away with it.
  static Future<String?> pictureDataUri(String path) async {
    final result = await Isolate.run(() {
      final mime = _imageMime(p.extension(path).toLowerCase());
      if (mime == null) return (uri: null, skip: 'not an image type');
      try {
        final bytes = File(path).readAsBytesSync();
        return (uri: 'data:$mime;base64,${base64Encode(bytes)}', skip: null);
      } on FileSystemException catch (error) {
        return (uri: null, skip: '$error');
      }
    });
    if (result.uri == null) {
      _log.warning('picture skipped ($path): ${result.skip}');
    }
    return result.uri;
  }

  static String? _imageMime(String extension) => switch (extension) {
    '.png' => 'image/png',
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.webp' => 'image/webp',
    '.bmp' => 'image/bmp',
    _ => null,
  };
}
