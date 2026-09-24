// Builds small EPUBs in a test: the zip, its container, its package
// document and its chapters, written the way real books write them.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:archive/archive.dart';

/// One chapter of a test book: its path in the zip and its XHTML body.
typedef TestChapter = ({String path, String body});

/// An EPUB of [chapters] (read in that order), written to [path].
///
/// The package document is `OEBPS/content.opf`; chapter paths are relative
/// to it. [nav] is an EPUB 3 navigation document's `<ol>` (paths relative
/// to `OEBPS/nav.xhtml`), [ncx] an EPUB 2 NCX's `<navMap>` content;
/// [files] are other files of the zip, by their full path, listed in the
/// manifest when under `OEBPS/`. [prefix] writes the OPF's elements as
/// `<opf:item>`, as some books do. [omit] names chapters listed in the
/// manifest and spine but left out of the zip.
File writeTestEpub(
  String path, {
  required List<TestChapter> chapters,
  String title = 'A Test Book',
  String? nav,
  String? ncx,
  Map<String, List<int>> files = const {},
  bool prefix = false,
  Set<String> omit = const {},
}) {
  final o = prefix ? 'opf:' : '';
  final manifest = StringBuffer();
  final spine = StringBuffer();
  for (final (index, chapter) in chapters.indexed) {
    manifest.write(
      '<${o}item id="c$index" href="${chapter.path}" '
      'media-type="application/xhtml+xml"/>',
    );
    spine.write('<${o}itemref idref="c$index"/>');
  }
  if (nav != null) {
    manifest.write(
      '<${o}item id="nav" href="nav.xhtml" properties="nav" '
      'media-type="application/xhtml+xml"/>',
    );
  }
  if (ncx != null) {
    manifest.write(
      '<${o}item id="ncx" href="toc.ncx" '
      'media-type="application/x-dtbncx+xml"/>',
    );
  }
  for (final (index, name) in files.keys.indexed) {
    if (!name.startsWith('OEBPS/')) continue;
    manifest.write(
      '<${o}item id="f$index" href="${name.substring(6)}" '
      'media-type="image/png"/>',
    );
  }
  final ns = prefix
      ? 'xmlns:opf="http://www.idpf.org/2007/opf"'
      : 'xmlns="http://www.idpf.org/2007/opf"';
  final opf =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<${o}package $ns version="3.0" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/">'
      '<${o}metadata><dc:title>$title</dc:title></${o}metadata>'
      '<${o}manifest>$manifest</${o}manifest>'
      '<${o}spine${ncx != null ? ' toc="ncx"' : ''}>$spine</${o}spine>'
      '</${o}package>';

  final archive = Archive()
    ..add(ArchiveFile.string('mimetype', 'application/epub+zip'))
    ..add(
      ArchiveFile.string(
        'META-INF/container.xml',
        '<?xml version="1.0"?>'
            '<container version="1.0" '
            'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
            '<rootfiles><rootfile full-path="OEBPS/content.opf" '
            'media-type="application/oebps-package+xml"/></rootfiles>'
            '</container>',
      ),
    )
    ..add(ArchiveFile.string('OEBPS/content.opf', opf));
  for (final chapter in chapters) {
    if (omit.contains(chapter.path)) continue;
    archive.add(
      ArchiveFile.string('OEBPS/${chapter.path}', _xhtml(chapter.body)),
    );
  }
  if (nav != null) {
    archive.add(
      ArchiveFile.string(
        'OEBPS/nav.xhtml',
        _xhtml('<nav epub:type="toc"><h1>Contents</h1>$nav</nav>'),
      ),
    );
  }
  if (ncx != null) {
    archive.add(
      ArchiveFile.string(
        'OEBPS/toc.ncx',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">'
            '<navMap>$ncx</navMap></ncx>',
      ),
    );
  }
  for (final entry in files.entries) {
    archive.add(ArchiveFile.bytes(entry.key, entry.value));
  }
  return File(path)..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
}

/// An NCX `navPoint` titled [title] pointing at [src], around [inner].
String ncxPoint(String title, String src, [String inner = '']) =>
    '<navPoint><navLabel><text>$title</text></navLabel>'
    '<content src="$src"/>$inner</navPoint>';

String _xhtml(String body) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<html xmlns="http://www.w3.org/1999/xhtml" '
    'xmlns:epub="http://www.idpf.org/2007/ops">'
    '<head><title>x</title></head><body>$body</body></html>';
