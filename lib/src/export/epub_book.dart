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
import 'package:flutter/foundation.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/frontmatter/parser.dart';
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

/// The metadata a book's frontmatter may carry (#303).
///
/// A single note's own frontmatter is the book's; a folder's or the
/// library's is its first chapter's, because a folder has no frontmatter of
/// its own. The keys are the typical ones, so a note that already reads as
/// an ebook elsewhere reads the same here.
@immutable
final class EpubMetadata {
  /// Creates a book's metadata.
  const new({
    this.title,
    this.authors = const <String>[],
    this.language,
    this.description,
    this.publisher,
    this.date,
    this.subjects = const <String>[],
    this.series,
    this.seriesIndex,
    this.rights,
    this.identifier,
    this.cover,
  });

  /// `title:` — the book's own name, where the export does not know better.
  final String? title;

  /// `author:` (or `authors:`), one `dc:creator` each.
  final List<String> authors;

  /// `language:` or `lang:` — a BCP 47 code, overriding the app's.
  final String? language;

  /// `description:`.
  final String? description;

  /// `publisher:`.
  final String? publisher;

  /// `date:`.
  final String? date;

  /// `tags:`, one `dc:subject` each.
  final List<String> subjects;

  /// `series:`.
  final String? series;

  /// `series_index:`.
  final String? seriesIndex;

  /// `rights:`.
  final String? rights;

  /// `identifier:` or `isbn:`.
  final String? identifier;

  /// `cover:` — the target of the cover picture, as the note writes it.
  final String? cover;
}

/// The book metadata [text]'s frontmatter carries.
EpubMetadata epubMetadataOf(String text) {
  final front = parseFrontmatter(text);
  if (front == null) return const EpubMetadata();
  String? first(String key) {
    final values = front.fields[key];
    if (values == null || values.isEmpty) return null;
    final value = values.first.trim();
    return value.isEmpty ? null : value;
  }

  return EpubMetadata(
    title: front.title,
    authors: front.fields['author'] ?? front.fields['authors'] ?? const [],
    language: first('language') ?? first('lang'),
    description: first('description'),
    publisher: first('publisher'),
    date: first('date'),
    subjects: front.tags,
    series: first('series'),
    seriesIndex: first('series_index'),
    rights: first('rights'),
    identifier: first('identifier') ?? first('isbn'),
    cover: first('cover'),
  );
}

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
  new _(this._title, this._language, this._metadata);

  final String _title;
  final String _language;
  final EpubMetadata _metadata;

  late final ZipFileEncoder _encoder = ZipFileEncoder();
  final List<EpubChapterEntry> _chapters = <EpubChapterEntry>[];
  final Map<String, _EpubPicture> _pictures = <String, _EpubPicture>{};
  final List<_EpubPicture> _picturesInOrder = <_EpubPicture>[];
  String? _fonts;
  bool _closed = false;
  _EpubPicture? _cover;

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
    final type = epubPictureType(p.extension(absolutePath).toLowerCase());
    if (type == null) return;
    final extension = p.extension(absolutePath).toLowerCase();
    final href = '$_imageDir/cover$extension';
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
    if (_cover != null) {
      _encoder.addArchiveFile(
        ArchiveFile.string('$_opfDir/cover.xhtml', _coverXhtml()),
      );
    }
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/nav.xhtml', _navXhtml()),
    );
    _encoder.addArchiveFile(
      ArchiveFile.string('$_opfDir/content.opf', _contentOpf()),
    );
    await _encoder.close();
  }

  /// The page that shows the cover: a spine item in front of the chapters,
  /// so a reader opens on the picture, not on the first chapter.
  String _coverXhtml() {
    final cover = _cover!;
    final src = p.posix.relative(cover.href, from: _opfDir);
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!DOCTYPE html>\n'
        '<html xmlns="http://www.w3.org/1999/xhtml" '
        'xml:lang="${escapeAttribute(_language)}" '
        'lang="${escapeAttribute(_language)}">\n'
        '<head>\n'
        '  <meta charset="utf-8" />\n'
        '  <title>${escapeHtml(_title)}</title>\n'
        '  <style>html, body { margin: 0; padding: 0; height: 100%; } '
        'img { display: block; margin: 0 auto; max-width: 100%; '
        'max-height: 100%; }</style>\n'
        '</head>\n'
        '<body>\n'
        '<div><img src="${escapeAttribute(src)}" '
        'alt="${escapeAttribute(_title)}" /></div>\n'
        '</body>\n'
        '</html>\n';
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
    if (_cover != null) {
      manifest.write(
        '    <item id="cover-page" href="cover.xhtml" '
        'media-type="application/xhtml+xml" />\n',
      );
      final href = p.posix.relative(_cover!.href, from: _opfDir);
      final type = epubPictureType(p.extension(_cover!.path).toLowerCase());
      manifest.write(
        '    <item id="cover-image" href="${escapeAttribute(href)}" '
        'media-type="$type" properties="cover-image" />\n',
      );
    }
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
    if (_cover != null) {
      spine.write('    <itemref idref="cover-page" />\n');
    }
    for (final chapter in _chapters) {
      spine.write('    <itemref idref="${chapter.id}" />\n');
    }
    final modified = DateTime.now().toUtc().toIso8601String().split('.').first;
    final metadata = StringBuffer()
      ..write(
        '    <dc:identifier id="pub-id">urn:uuid:${_uuidV4()}</dc:identifier>\n',
      )
      ..write('    <dc:title>${escapeHtml(_title)}</dc:title>\n')
      ..write('    <dc:language>${escapeAttribute(_language)}</dc:language>\n');
    for (final author in _metadata.authors) {
      if (author.trim().isEmpty) continue;
      metadata.write('    <dc:creator>${escapeHtml(author)}</dc:creator>\n');
    }
    if (_metadata.description != null) {
      metadata.write(
        '    <dc:description>${escapeHtml(_metadata.description!)}'
        '</dc:description>\n',
      );
    }
    if (_metadata.publisher != null) {
      metadata.write(
        '    <dc:publisher>${escapeHtml(_metadata.publisher!)}</dc:publisher>\n',
      );
    }
    if (_metadata.date != null) {
      metadata.write('    <dc:date>${escapeHtml(_metadata.date!)}</dc:date>\n');
    }
    for (final subject in _metadata.subjects) {
      if (subject.trim().isEmpty) continue;
      metadata.write('    <dc:subject>${escapeHtml(subject)}</dc:subject>\n');
    }
    if (_metadata.rights != null) {
      metadata.write(
        '    <dc:rights>${escapeHtml(_metadata.rights!)}</dc:rights>\n',
      );
    }
    if (_metadata.identifier != null) {
      metadata.write(
        '    <dc:identifier>${escapeHtml(_metadata.identifier!)}'
        '</dc:identifier>\n',
      );
    }
    if (_metadata.series != null) {
      metadata.write(
        '    <meta property="belongs-to-collection" id="series">'
        '${escapeHtml(_metadata.series!)}</meta>\n'
        '    <meta refines="#series" property="collection-type">series</meta>\n',
      );
      if (_metadata.seriesIndex != null) {
        metadata.write(
          '    <meta refines="#series" property="group-position">'
          '${escapeHtml(_metadata.seriesIndex!)}</meta>\n',
        );
      }
    }
    if (_cover != null) {
      metadata.write('    <meta name="cover" content="cover-image" />\n');
    }
    metadata.write(
      '    <meta property="dcterms:modified">${modified}Z</meta>\n',
    );
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" '
        'unique-identifier="pub-id" '
        'xml:lang="${escapeAttribute(_language)}">\n'
        '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">\n'
        '$metadata'
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
