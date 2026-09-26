/// The EPUB package (#303): the metadata a book may carry, and the XHTML,
/// nav and OPF a container holds — the strings the writer zips.
///
/// Split from `epub_book.dart` so the container's writing and the
/// container's text are read apart: nothing here touches a zip, and
/// nothing there spells a tag.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/picture_mime.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:path/path.dart' as p;

/// Where the container's pieces live.
const String epubOpfDir = 'OEBPS';

/// Where the pictures live, inside the package directory.
const String epubImageDir = '$epubOpfDir/images';

/// One chapter, as it was added.
typedef EpubChapterEntry = ({String id, String href, String title, bool svg});

/// One picture, as it was copied in.
typedef EpubPictureEntry = ({String id, String href, String path});

/// The metadata a book's frontmatter may carry (#303).
///
/// A single note's own frontmatter is the book's; a folder's or the
/// library's is its `index.md`. The keys are the typical ones, so a note
/// that already reads as an ebook elsewhere reads the same here.
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

  /// `published:` — the book's publication date.
  ///
  /// Not `date:`, which is the note's own: a journal entry that begins a
  /// book must not date the book the day it was written.
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
    date: first('published'),
    subjects: front.tags,
    series: first('series'),
    seriesIndex: first('series_index'),
    rights: first('rights'),
    identifier: first('identifier') ?? first('isbn'),
    cover: first('cover'),
  );
}

/// [href], a container-relative path, as the IRI a package or a nav may
/// name: one path segment at a time, because a space or a `#` in a note's
/// name is not a URL character. The zip entries keep the note's own name;
/// only the references to them are escaped (E5).
String _iri(String href) => href.split('/').map(Uri.encodeComponent).join('/');

/// The page that shows the cover: a spine item in front of the chapters,
/// so a reader opens on the picture, not on the first chapter.
String epubCoverXhtml({
  required String coverHref,
  required String title,
  required String language,
}) {
  final src = _iri(p.posix.relative(coverHref, from: epubOpfDir));
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!DOCTYPE html>\n'
      '<html xmlns="http://www.w3.org/1999/xhtml" '
      'xml:lang="${escapeAttribute(language)}" '
      'lang="${escapeAttribute(language)}">\n'
      '<head>\n'
      '  <meta charset="utf-8" />\n'
      '  <title>${escapeHtml(title)}</title>\n'
      '  <style>html, body { margin: 0; padding: 0; height: 100%; } '
      'img { display: block; margin: 0 auto; max-width: 100%; '
      'max-height: 100%; }</style>\n'
      '</head>\n'
      '<body>\n'
      '<div><img src="${escapeAttribute(src)}" '
      'alt="${escapeAttribute(title)}" /></div>\n'
      '</body>\n'
      '</html>\n';
}

/// The chapter's own XHTML: its title, its body, and the two style sheets
/// at whatever depth the chapter sits.
String epubChapterXhtml({
  required String href,
  required String title,
  required String body,
  required String language,
}) {
  final dir = p.posix.dirname(href);
  String at(String target) => p.posix.relative(target, from: dir);
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!DOCTYPE html>\n'
      '<html xmlns="http://www.w3.org/1999/xhtml" '
      'xml:lang="${escapeAttribute(language)}" '
      'lang="${escapeAttribute(language)}">\n'
      '<head>\n'
      '  <meta charset="utf-8" />\n'
      '  <title>${escapeHtml(title)}</title>\n'
      '  <link rel="stylesheet" type="text/css" '
      'href="${escapeAttribute(at('$epubOpfDir/style.css'))}" />\n'
      '  <link rel="stylesheet" type="text/css" '
      'href="${escapeAttribute(at('$epubOpfDir/fonts.css'))}" />\n'
      '</head>\n'
      '<body>\n'
      '<article class="note">\n$body</article>\n'
      '</body>\n'
      '</html>\n';
}

/// The navigation document, one entry per chapter in spine order.
String epubNavXhtml({
  required List<EpubChapterEntry> chapters,
  required String title,
  required String language,
}) {
  final entries = StringBuffer();
  for (final chapter in chapters) {
    final href = _iri(p.posix.relative(chapter.href, from: epubOpfDir));
    entries.write(
      '      <li><a href="${escapeAttribute(href)}">'
      '${escapeHtml(chapter.title)}</a></li>\n',
    );
  }
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!DOCTYPE html>\n'
      '<html xmlns="http://www.w3.org/1999/xhtml" '
      'xmlns:epub="http://www.idpf.org/2007/ops" '
      'xml:lang="${escapeAttribute(language)}" '
      'lang="${escapeAttribute(language)}">\n'
      '<head>\n'
      '  <meta charset="utf-8" />\n'
      '  <title>${escapeHtml(title)}</title>\n'
      '</head>\n'
      '<body>\n'
      '  <nav epub:type="toc" id="toc">\n'
      '    <h1>${escapeHtml(title)}</h1>\n'
      '    <ol>\n$entries'
      '    </ol>\n'
      '  </nav>\n'
      '</body>\n'
      '</html>\n';
}

/// The package: metadata, manifest and spine.
String epubContentOpf({
  required String title,
  required String language,
  required EpubMetadata metadata,
  required List<EpubChapterEntry> chapters,
  required List<EpubPictureEntry> pictures,
  required EpubPictureEntry? cover,
}) {
  final manifest = StringBuffer()
    ..write(
      '    <item id="nav" href="nav.xhtml" '
      'media-type="application/xhtml+xml" properties="nav" />\n'
      '    <item id="css" href="style.css" media-type="text/css" />\n'
      '    <item id="fonts" href="fonts.css" media-type="text/css" />\n',
    );
  if (cover != null) {
    manifest.write(
      '    <item id="cover-page" href="cover.xhtml" '
      'media-type="application/xhtml+xml" />\n',
    );
    final href = _iri(p.posix.relative(cover.href, from: epubOpfDir));
    final type = pictureMime(p.extension(cover.path).toLowerCase());
    manifest.write(
      '    <item id="cover-image" href="${escapeAttribute(href)}" '
      'media-type="$type" properties="cover-image" />\n',
    );
  }
  for (final chapter in chapters) {
    final href = _iri(p.posix.relative(chapter.href, from: epubOpfDir));
    manifest.write(
      '    <item id="${chapter.id}" href="${escapeAttribute(href)}" '
      'media-type="application/xhtml+xml"'
      '${chapter.svg ? ' properties="svg"' : ''} />\n',
    );
  }
  for (final picture in pictures) {
    final href = _iri(p.posix.relative(picture.href, from: epubOpfDir));
    final type = pictureMime(p.extension(picture.path).toLowerCase());
    manifest.write(
      '    <item id="${picture.id}" href="${escapeAttribute(href)}" '
      'media-type="$type" />\n',
    );
  }
  final spine = StringBuffer();
  if (cover != null) {
    spine.write('    <itemref idref="cover-page" />\n');
  }
  for (final chapter in chapters) {
    spine.write('    <itemref idref="${chapter.id}" />\n');
  }
  final modified = DateTime.now().toUtc().toIso8601String().split('.').first;
  final dc = StringBuffer()
    ..write(
      '    <dc:identifier id="pub-id">urn:uuid:${_uuidV4()}</dc:identifier>\n',
    )
    ..write('    <dc:title>${escapeHtml(title)}</dc:title>\n')
    ..write('    <dc:language>${escapeAttribute(language)}</dc:language>\n');
  for (final author in metadata.authors) {
    if (author.trim().isEmpty) continue;
    dc.write('    <dc:creator>${escapeHtml(author)}</dc:creator>\n');
  }
  if (metadata.description != null) {
    dc.write(
      '    <dc:description>${escapeHtml(metadata.description!)}'
      '</dc:description>\n',
    );
  }
  if (metadata.publisher != null) {
    dc.write(
      '    <dc:publisher>${escapeHtml(metadata.publisher!)}</dc:publisher>\n',
    );
  }
  if (metadata.date != null) {
    dc.write('    <dc:date>${escapeHtml(metadata.date!)}</dc:date>\n');
  }
  for (final subject in metadata.subjects) {
    if (subject.trim().isEmpty) continue;
    dc.write('    <dc:subject>${escapeHtml(subject)}</dc:subject>\n');
  }
  if (metadata.rights != null) {
    dc.write('    <dc:rights>${escapeHtml(metadata.rights!)}</dc:rights>\n');
  }
  if (metadata.identifier != null) {
    dc.write(
      '    <dc:identifier>${escapeHtml(metadata.identifier!)}'
      '</dc:identifier>\n',
    );
  }
  if (metadata.series != null) {
    dc.write(
      '    <meta property="belongs-to-collection" id="series">'
      '${escapeHtml(metadata.series!)}</meta>\n'
      '    <meta refines="#series" property="collection-type">series</meta>\n',
    );
    if (metadata.seriesIndex != null) {
      dc.write(
        '    <meta refines="#series" property="group-position">'
        '${escapeHtml(metadata.seriesIndex!)}</meta>\n',
      );
    }
  }
  if (cover != null) {
    dc.write('    <meta name="cover" content="cover-image" />\n');
  }
  dc.write('    <meta property="dcterms:modified">${modified}Z</meta>\n');
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" '
      'unique-identifier="pub-id" '
      'xml:lang="${escapeAttribute(language)}">\n'
      '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">\n'
      '$dc'
      '  </metadata>\n'
      '  <manifest>\n$manifest'
      '  </manifest>\n'
      '  <spine>\n$spine'
      '  </spine>\n'
      '</package>\n';
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
