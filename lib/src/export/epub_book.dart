/// An EPUB 3 book being written (#303): chapters and pictures streamed into
/// the container, the package and the nav written when the last one is in.
///
/// The container is a zip with one rule that matters — `mimetype` is its
/// first entry and is not compressed — and one more the OPF carries: every
/// chapter is well-formed XHTML, so a book opens in Calibre, Apple Books,
/// KOReader and Niman's own pane alike.
///
/// A book is written one chapter at a time for the same reason the folder
/// export streams: a library can be a novel, and the book must not be held
/// whole. Pictures are copied in once, whatever a chapter's own path is,
/// and the OPF and nav are written last, when the manifest is complete.
///
/// The strings it writes are `epub_package.dart`'s; this file is the zip.
library;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:niman/src/export/epub_package.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/picture_mime.dart';
import 'package:path/path.dart' as p;

// A caller that built a book's metadata reads it back from the same import
// (`EpubBook` and `EpubMetadata` are one feature), whatever file each lives
// in.
export 'package:niman/src/export/epub_package.dart'
    show EpubMetadata, epubMetadataOf;

/// The container's entry point, the same file for every EPUB.
const String _containerXml =
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<container version="1.0" '
    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n'
    '  <rootfiles>\n'
    '    <rootfile full-path="$epubOpfDir/content.opf" '
    'media-type="application/oebps-package+xml" />\n'
    '  </rootfiles>\n'
    '</container>\n';

/// An EPUB 3 book taking shape.
final class EpubBook {
  new _(this._title, this._language, this._metadata);

  final String _title;
  final String _language;
  final EpubMetadata _metadata;

  late final ZipFileEncoder _encoder = ZipFileEncoder();
  final List<EpubChapterEntry> _chapters = <EpubChapterEntry>[];
  final Map<String, EpubPictureEntry> _pictures = <String, EpubPictureEntry>{};
  final List<EpubPictureEntry> _picturesInOrder = <EpubPictureEntry>[];
  String? _fonts;
  bool _closed = false;
  EpubPictureEntry? _cover;

  /// Starts a book at [path], titled [title], in [language] (a BCP 47 code).
  ///
  /// [metadata] is the frontmatter's own metadata (#303): its title and
  /// language override [title] and [language] when they name one. [cover]
  /// is the picture the metadata's `cover:` resolved to, or null. The
  /// `mimetype` entry and the container are written here, first — every
  /// other entry follows in whatever order the chapters are ready.
  static Future<EpubBook> start({
    required String path,
    required String title,
    required String language,
    EpubMetadata metadata = const EpubMetadata(),
    String? cover,
  }) async {
    final book = EpubBook._(
      metadata.title ?? title,
      metadata.language ?? language,
      metadata,
    );
    book._encoder.create(path);
    final mimetype = ArchiveFile.string('mimetype', 'application/epub+zip')
      ..compression = CompressionType.none;
    book._encoder.addArchiveFile(mimetype);
    book._encoder.addArchiveFile(
      ArchiveFile.string('META-INF/container.xml', _containerXml),
    );
    if (cover != null) await book._addCover(cover);
    return book;
  }

  /// Copies the cover in and names it in the package.
  ///
  /// A type an EPUB cannot carry is no cover, not a failed book.
  Future<void> _addCover(String absolutePath) async {
    final type = pictureMime(p.extension(absolutePath).toLowerCase());
    if (type == null) return;
    final extension = p.extension(absolutePath).toLowerCase();
    final href = '$epubImageDir/cover$extension';
    await _encoder.addFile(File(absolutePath), href);
    _cover = (id: 'cover-image', href: href, path: absolutePath);
  }

  /// Copies [absolutePath] into the book once, and answers the URL to use
  /// for it from a chapter in [fromDir] (both container-relative).
  ///
  /// Answers null — the picture stays out — when its type is not one an
  /// EPUB carries.
  Future<String?> imageHref(String fromDir, String absolutePath) async {
    final existing = _pictures[absolutePath];
    if (existing != null) {
      return p.posix.relative(existing.href, from: fromDir);
    }
    final type = pictureMime(p.extension(absolutePath).toLowerCase());
    if (type == null) return null;
    final at = _picturesInOrder.length + 1;
    final extension = p.extension(absolutePath).toLowerCase();
    final href = '$epubImageDir/img-$at$extension';
    final picture = (id: 'img-$at', href: href, path: absolutePath);
    _pictures[absolutePath] = picture;
    _picturesInOrder.add(picture);
    await _encoder.addFile(File(absolutePath), href);
    return p.posix.relative(href, from: fromDir);
  }

  /// Adds one chapter, in spine order. [href] is container-relative (its
  /// folder, normally `text/`, mirrors the tree, so the links between
  /// chapters resolve as they do in the HTML zip).
  ///
  /// [fontFaces] are the maths fonts the chapter's formulas need, declared
  /// once for the whole book; [hasSvg] says the chapter embeds inline SVG
  /// (a formula), which the package must declare.
  void addChapter({
    required String href,
    required String title,
    required String body,
    String? fontFaces,
    bool hasSvg = false,
  }) {
    _fonts ??= fontFaces;
    final id = 'ch${_chapters.length + 1}';
    final xhtml = epubChapterXhtml(
      href: href,
      title: title,
      body: body,
      language: _language,
    );
    _encoder.addArchiveFile(ArchiveFile.string(href, xhtml));
    _chapters.add((id: id, href: href, title: title, svg: hasSvg));
  }

  /// Writes the styles, the nav, the package, and closes the container.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _encoder.addArchiveFile(
      ArchiveFile.string('$epubOpfDir/style.css', pageStyle),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string('$epubOpfDir/fonts.css', _fonts ?? ''),
    );
    if (_cover != null) {
      _encoder.addArchiveFile(
        ArchiveFile.string(
          '$epubOpfDir/cover.xhtml',
          epubCoverXhtml(
            coverHref: _cover!.href,
            title: _title,
            language: _language,
          ),
        ),
      );
    }
    _encoder.addArchiveFile(
      ArchiveFile.string(
        '$epubOpfDir/nav.xhtml',
        epubNavXhtml(chapters: _chapters, title: _title, language: _language),
      ),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string(
        '$epubOpfDir/content.opf',
        epubContentOpf(
          title: _title,
          language: _language,
          metadata: _metadata,
          chapters: _chapters,
          pictures: _picturesInOrder,
          cover: _cover,
        ),
      ),
    );
    await _encoder.close();
  }
}
