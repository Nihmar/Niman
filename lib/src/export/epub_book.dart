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
library;

import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:path/path.dart' as p;

/// The media type of the picture at [extension] (lower case, with the dot),
/// or null when it is not one an EPUB may carry. SVG is here where the
/// page's own embed list is not: a container stores the file itself, and
/// every reader draws SVG.
String? epubPictureType(String extension) => switch (extension) {
  '.png' => 'image/png',
  '.jpg' || '.jpeg' => 'image/jpeg',
  '.gif' => 'image/gif',
  '.webp' => 'image/webp',
  '.bmp' => 'image/bmp',
  '.svg' => 'image/svg+xml',
  _ => null,
};

/// Where the container's pieces live.
const String _opfDir = 'OEBPS';
const String _imageDir = '$_opfDir/images';

/// One chapter, as it was added.
typedef EpubChapterEntry = ({String id, String href, String title});

/// One picture, as it was copied in.
typedef _EpubPicture = ({String id, String href, String path});

/// The container's entry point, the same file for every EPUB.
const String _containerXml =
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<container version="1.0" '
    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n'
    '  <rootfiles>\n'
    '    <rootfile full-path="$_opfDir/content.opf" '
    'media-type="application/oebps-package+xml" />\n'
    '  </rootfiles>\n'
    '</container>\n';

/// An EPUB 3 book taking shape.
final class EpubBook {
  new _(this._title, this._language);

  final String _title;
  final String _language;

  late final ZipFileEncoder _encoder = ZipFileEncoder();
  final List<EpubChapterEntry> _chapters = <EpubChapterEntry>[];
  final Map<String, _EpubPicture> _pictures = <String, _EpubPicture>{};
  final List<_EpubPicture> _picturesInOrder = <_EpubPicture>[];
  String? _fonts;
  bool _closed = false;

  /// Starts a book at [path], titled [title], in [language] (a BCP 47 code).
  ///
  /// The `mimetype` entry and the container are written here, first: every
  /// other entry follows in whatever order the chapters are ready.
  static Future<EpubBook> start({
    required String path,
    required String title,
    required String language,
  }) async {
    final book = EpubBook._(title, language);
    book._encoder.create(path);
    final mimetype = ArchiveFile.string('mimetype', 'application/epub+zip')
      ..compression = CompressionType.none;
    book._encoder.addArchiveFile(mimetype);
    book._encoder.addArchiveFile(
      ArchiveFile.string('META-INF/container.xml', _containerXml),
    );
    return book;
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
    final type = epubPictureType(p.extension(absolutePath).toLowerCase());
    if (type == null) return null;
    final at = _picturesInOrder.length + 1;
    final extension = p.extension(absolutePath).toLowerCase();
    final href = '$_imageDir/img-$at$extension';
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
  /// once for the whole book.
  void addChapter({
    required String href,
    required String title,
    required String body,
    String? fontFaces,
  }) {
    _fonts ??= fontFaces;
    final id = 'ch${_chapters.length + 1}';
    final xhtml = _chapterXhtml(href: href, title: title, body: body);
    _encoder.addArchiveFile(ArchiveFile.string(href, xhtml));
    _chapters.add((id: id, href: href, title: title));
  }

  /// Writes the styles, the nav, the package, and closes the container.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/style.css', pageStyle),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/fonts.css', _fonts ?? ''),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/nav.xhtml', _navXhtml()),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/content.opf', _contentOpf()),
    );
    await _encoder.close();
  }

  /// The chapter's own XHTML: its title, its body, and the two style sheets
  /// at whatever depth the chapter sits.
  String _chapterXhtml({
    required String href,
    required String title,
    required String body,
  }) {
    final dir = p.posix.dirname(href);
    String at(String target) => p.posix.relative(target, from: dir);
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!DOCTYPE html>\n'
        '<html xmlns="http://www.w3.org/1999/xhtml" '
        'xml:lang="${escapeAttribute(_language)}" '
        'lang="${escapeAttribute(_language)}">\n'
        '<head>\n'
        '  <meta charset="utf-8" />\n'
        '  <title>${escapeHtml(title)}</title>\n'
        '  <link rel="stylesheet" type="text/css" '
        'href="${escapeAttribute(at('$_opfDir/style.css'))}" />\n'
        '  <link rel="stylesheet" type="text/css" '
        'href="${escapeAttribute(at('$_opfDir/fonts.css'))}" />\n'
        '</head>\n'
        '<body>\n'
        '<article class="note">\n$body</article>\n'
        '</body>\n'
        '</html>\n';
  }

  /// The navigation document, one entry per chapter in spine order.
  String _navXhtml() {
    final entries = StringBuffer();
    for (final chapter in _chapters) {
      final href = p.posix.relative(chapter.href, from: _opfDir);
      entries.write(
        '      <li><a href="${escapeAttribute(href)}">'
        '${escapeHtml(chapter.title)}</a></li>\n',
      );
    }
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!DOCTYPE html>\n'
        '<html xmlns="http://www.w3.org/1999/xhtml" '
        'xmlns:epub="http://www.idpf.org/2007/ops" '
        'xml:lang="${escapeAttribute(_language)}" '
        'lang="${escapeAttribute(_language)}">\n'
        '<head>\n'
        '  <meta charset="utf-8" />\n'
        '  <title>${escapeHtml(_title)}</title>\n'
        '</head>\n'
        '<body>\n'
        '  <nav epub:type="toc" id="toc">\n'
        '    <h1>${escapeHtml(_title)}</h1>\n'
        '    <ol>\n$entries'
        '    </ol>\n'
        '  </nav>\n'
        '</body>\n'
        '</html>\n';
  }

  /// The package: metadata, manifest and spine.
  String _contentOpf() {
    final manifest = StringBuffer()
      ..write(
        '    <item id="nav" href="nav.xhtml" '
        'media-type="application/xhtml+xml" properties="nav" />\n'
        '    <item id="css" href="style.css" media-type="text/css" />\n'
        '    <item id="fonts" href="fonts.css" media-type="text/css" />\n',
      );
    for (final chapter in _chapters) {
      final href = p.posix.relative(chapter.href, from: _opfDir);
      manifest.write(
        '    <item id="${chapter.id}" href="${escapeAttribute(href)}" '
        'media-type="application/xhtml+xml" />\n',
      );
    }
    for (final picture in _picturesInOrder) {
      final href = p.posix.relative(picture.href, from: _opfDir);
      final type = epubPictureType(p.extension(picture.path).toLowerCase());
      manifest.write(
        '    <item id="${picture.id}" href="${escapeAttribute(href)}" '
        'media-type="$type" />\n',
      );
    }
    final spine = StringBuffer();
    for (final chapter in _chapters) {
      spine.write('    <itemref idref="${chapter.id}" />\n');
    }
    final modified = DateTime.now().toUtc().toIso8601String().split('.').first;
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" '
        'unique-identifier="pub-id" '
        'xml:lang="${escapeAttribute(_language)}">\n'
        '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">\n'
        '    <dc:identifier id="pub-id">urn:uuid:${_uuidV4()}</dc:identifier>\n'
        '    <dc:title>${escapeHtml(_title)}</dc:title>\n'
        '    <dc:language>${escapeAttribute(_language)}</dc:language>\n'
        '    <meta property="dcterms:modified">${modified}Z</meta>\n'
        '  </metadata>\n'
        '  <manifest>\n$manifest'
        '  </manifest>\n'
        '  <spine>\n$spine'
        '  </spine>\n'
        '</package>\n';
  }
}

/// A version-4 UUID for the book's identifier.
String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int at) => bytes[at].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
