/// An EPUB read into its parts (#1138): its metadata, its chapters as
/// Markdown in reading order, its table of contents, and the pictures and
/// links its chapters name. The reader joins the chapters into one text
/// (`epub_document.dart`); the conversion writes them as notes
/// (`epub_convert.dart`). One parse for both, so the notes say what the
/// reader shows.
///
/// An EPUB is a zip: `META-INF/container.xml` names the package document
/// (the OPF), whose manifest lists the book's files and whose spine says
/// the order its chapters are read in; the table of contents is the EPUB 3
/// navigation document or the EPUB 2 NCX. Every chapter is converted
/// ([HtmlMarkdown]); a picture it shows is written `epub-picture:<n>` and a
/// link into the book `epub-link:<n>`, numbers into [EpubBook.pictures] and
/// [EpubBook.links], for whoever reads the parts to resolve.
library;

import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_info.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// How a chapter's text names a picture: `epub-picture:3`.
const String epubPictureScheme = 'epub-picture';

/// How a chapter's text names a link into the book: `epub-link:3`.
const String epubLinkScheme = 'epub-link';

/// A place in the book: a file of the zip, and an anchor in it ('' for its
/// start).
typedef EpubTarget = ({String file, String fragment});

/// One entry of the table of contents: what it is called, where it points,
/// and how deep it is nested (0 at the top).
typedef EpubTocEntry = ({
  String title,
  String file,
  String fragment,
  int depth,
});

/// One chapter with text: its file in the zip, its Markdown, and the line of
/// that Markdown each of its anchors (`id`s) is on.
typedef EpubChapterText = ({
  String file,
  String markdown,
  Map<String, int> anchors,
});

/// The line of [fragment] among a chapter's [anchors] (its `id`s), or null
/// when it names none.
///
/// A fragment is a URL's: `Cap%C3%ADtulo` names the `id="Capítulo"`. It is
/// read decoded; the text as written still answers where an `id` really
/// spells a `%`.
int? epubAnchorLine(Map<String, int>? anchors, String fragment) {
  if (anchors == null || fragment.isEmpty) return null;
  return anchors[percentDecoded(fragment)] ?? anchors[fragment];
}

/// A book, read into its parts.
final class EpubBook {
  /// The parts of a read book.
  const new({
    required this.info,
    required this.spine,
    required this.chapters,
    required this.contents,
    required this.pictures,
    required this.links,
    required this._archive,
    this.formulaSvgs = 0,
    this.firstTex,
    this.mathMl = 0,
  });

  /// What the book says about itself.
  final EpubInfo info;

  /// Every file of the spine, in reading order, with text or not: where a
  /// contents entry pointing at a page with none (a part's title page)
  /// opens — the next chapter that has some.
  final List<String> spine;

  /// Its chapters with any text, in reading order.
  final List<EpubChapterText> chapters;

  /// Its table of contents, in the book's order.
  final List<EpubTocEntry> contents;

  /// The pictures the chapters show, by the number their text names them
  /// by: their paths in the zip.
  final List<String> pictures;

  /// The book's own links, by the number their text names them by.
  final List<EpubTarget> links;

  /// What the chapters' math looked like to a plain scan (#303): the
  /// formula SVGs, the first one's TeX, and the MathML elements.
  final int formulaSvgs;

  /// See [formulaSvgs].
  final String? firstTex;

  /// See [formulaSvgs].
  final int mathMl;

  final EpubArchive _archive;

  /// The bytes of picture [index], or null when the zip does not hold it.
  Uint8List? pictureBytes(int index) => _archive.bytes(pictures[index]);
}

/// Reads [archive] into a book.
///
/// Throws [EpubRefused]: not a book, or one whose chapters are encrypted.
EpubBook parseEpub(EpubArchive archive) {
  EpubBook? book;
  for (final step in _readSteps(archive)) {
    book = step;
  }
  return book!;
}

/// [parseEpub] that gives the event loop a turn, and [between] a call,
/// before each of the spine's chapters.
///
/// Converting a chapter is the parse's expensive part, so on a big book it
/// is what a stop would otherwise wait for: [between] is where a cancel
/// throws. Whatever it throws ends the read there. It is the same read as
/// [parseEpub] — one parser, driven a chapter at a time.
Future<EpubBook> parseEpubStepped(
  EpubArchive archive, {
  Future<void> Function()? between,
}) async {
  final steps = _readSteps(archive).iterator;
  while (steps.moveNext()) {
    if (steps.current case final book?) return book;
    await Future<void>.delayed(Duration.zero);
    await between?.call();
  }
  throw StateError('the read ended without a book');
}

/// The read of [archive], one step at a time: null before each chapter of
/// the spine, then the book, last. Lazy — nothing is read until the
/// iteration asks.
Iterable<EpubBook?> _readSteps(EpubArchive archive) sync* {
  final opfPath = archive.packagePath();
  final opf = archive.xml(opfPath);
  final opfDir = p.posix.dirname(opfPath);

  final manifest = <String, _Item>{};
  for (final item in _named(opf, 'item')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id == null || href == null) continue;
    manifest[id] = (
      path: _resolve(opfDir, href),
      type: item.getAttribute('media-type') ?? '',
      properties: item.getAttribute('properties') ?? '',
    );
  }
  final spine = [
    for (final ref in _named(opf, 'itemref'))
      if (manifest[ref.getAttribute('idref')] case final item?) item.path,
  ];
  if (spine.isEmpty) {
    throw const EpubRefused(EpubRefusal.notABook, 'the book has no chapters');
  }
  // DRM encrypts the chapters; a font obfuscated against copying is listed
  // in the same file and leaves the text alone.
  final encrypted = archive.encrypted();
  if (spine.any(encrypted.contains)) {
    throw const EpubRefused(
      EpubRefusal.protected,
      'the chapters are encrypted',
    );
  }

  final pictures = <String>[];
  final pictureIndex = <String, int>{};
  final links = <EpubTarget>[];
  final chapters = <EpubChapterText>[];
  var formulaSvgs = 0;
  var mathMl = 0;
  String? firstTex;
  for (final chapter in spine) {
    yield null;
    final text = archive.text(chapter);
    if (text == null) continue;
    final dir = p.posix.dirname(chapter);
    for (final match in _svgFormula.allMatches(text)) {
      formulaSvgs++;
      firstTex ??= match.group(1);
    }
    mathMl += _mathMl.allMatches(text).length;
    final converted = HtmlMarkdown(
      picture: (src) {
        final resolved = _resolve(dir, src);
        if (!archive.has(resolved)) return null;
        final index = pictureIndex.putIfAbsent(resolved, () {
          pictures.add(resolved);
          return pictures.length - 1;
        });
        return '$epubPictureScheme:$index';
      },
      link: (href) {
        if (_scheme.hasMatch(href)) return href;
        final hash = href.indexOf('#');
        final target = hash < 0 ? href : href.substring(0, hash);
        final fragment = hash < 0 ? '' : href.substring(hash + 1);
        links.add((
          file: target.isEmpty ? chapter : _resolve(dir, target),
          fragment: fragment,
        ));
        return '$epubLinkScheme:${links.length - 1}';
      },
    ).convert(text);
    if (converted.markdown.trim().isEmpty) continue;
    chapters.add((
      file: chapter,
      markdown: converted.markdown,
      anchors: converted.anchors,
    ));
  }
  // A spine that resolved to no readable text is as unreadable as an
  // empty one: the reader is told rather than shown a blank pane (#377).
  if (chapters.isEmpty) {
    throw const EpubRefused(EpubRefusal.notABook, 'the book has no chapters');
  }
  yield EpubBook(
    info: epubInfoOf(opf, (id) => manifest[id]?.path),
    spine: spine,
    chapters: chapters,
    contents: _contents(archive, opf, manifest),
    pictures: pictures,
    links: links,
    archive: archive,
    formulaSvgs: formulaSvgs,
    firstTex: firstTex,
    mathMl: mathMl,
  );
}

/// A formula SVG's TeX, in its `aria-label`; an ad-hoc diagnostic (#303).
final RegExp _svgFormula = RegExp(
  '<svg[^>]*aria-label="([^"]*)"',
  caseSensitive: false,
);

/// A MathML element; an ad-hoc diagnostic (#303).
final RegExp _mathMl = RegExp(r'<math[\s>]', caseSensitive: false);

/// A file of the book's manifest.
typedef _Item = ({String path, String type, String properties});

/// An `http:`, `mailto:`… href, which leaves the book.
final RegExp _scheme = RegExp('^[A-Za-z][A-Za-z0-9+.-]*:');

/// [href], as written in a file of folder [dir], as a path in the zip.
String _resolve(String dir, String href) {
  final hash = href.indexOf('#');
  final bare = hash < 0 ? href : href.substring(0, hash);
  // A book spells a name either way — `cit%C3%A9.xhtml`, or the raw UTF-8
  // `cité.xhtml` that most books with accents or CJK names write — and a
  // stray `%` is a character of it: [percentDecoded] reads all three.
  final decoded = percentDecoded(bare);
  final joined = dir.isEmpty || dir == '.'
      ? decoded
      : p.posix.join(dir, decoded);
  return p.posix.normalize(joined);
}

/// The elements under [node] named [local], whatever their prefix: an OPF
/// may write `<item>` or `<opf:item>`.
Iterable<XmlElement> _named(XmlNode node, String local) =>
    node.descendantElements.where((element) => element.localName == local);

/// The first child of [element] named [local], whatever its prefix.
XmlElement? _child(XmlElement element, String local) => element.childElements
    .where((child) => child.localName == local)
    .firstOrNull;

final RegExp _space = RegExp(r'\s+');

/// The table of contents: the EPUB 3 navigation document when there is
/// one, the EPUB 2 NCX otherwise.
List<EpubTocEntry> _contents(
  EpubArchive archive,
  XmlDocument opf,
  Map<String, _Item> manifest,
) {
  final nav = manifest.values
      .where((item) => item.properties.split(' ').contains('nav'))
      .firstOrNull;
  if (nav != null) {
    final entries = _navContents(archive, nav.path);
    if (entries.isNotEmpty) return entries;
  }
  final spine = _named(opf, 'spine').firstOrNull;
  final ncx =
      manifest[spine?.getAttribute('toc')] ??
      manifest.values
          .where((item) => item.type == 'application/x-dtbncx+xml')
          .firstOrNull;
  return ncx == null ? const [] : _ncxContents(archive, ncx.path);
}

List<EpubTocEntry> _navContents(EpubArchive archive, String path) {
  final text = archive.text(path);
  if (text == null) return const [];
  final document = html.parse(text);
  final navs = document.getElementsByTagName('nav');
  final toc =
      navs
          .where((nav) => (nav.attributes['epub:type'] ?? '') == 'toc')
          .firstOrNull ??
      navs.firstOrNull;
  final list = toc?.querySelector('ol');
  if (list == null) return const [];
  final dir = p.posix.dirname(path);
  final out = <EpubTocEntry>[];
  void walk(dom.Element ol, int depth) {
    for (final li in ol.children) {
      if (li.localName != 'li') continue;
      // The entry's own link or label: a part may be a `<span>` with no
      // link of its own, its chapters nested under it.
      final head =
          li.children
              .where(
                (child) => child.localName == 'a' || child.localName == 'span',
              )
              .firstOrNull ??
          // A link wrapped in another element, outside the nested list.
          li
              .querySelectorAll('a')
              .where((a) => !_insideList(a, li))
              .firstOrNull;
      final href = head?.localName == 'a' ? head?.attributes['href'] : null;
      final title = (head?.text ?? '').replaceAll(_space, ' ').trim();
      if (title.isNotEmpty && href != null) {
        out.add(_entry(dir, href, title, depth));
      } else if (title.isNotEmpty) {
        // No link of its own: it opens where its first chapter does.
        final first = li.querySelector('ol a[href]')?.attributes['href'];
        if (first != null) out.add(_entry(dir, first, title, depth));
      }
      for (final nested in li.children) {
        if (nested.localName == 'ol') walk(nested, depth + 1);
      }
    }
  }

  walk(list, 0);
  return out;
}

List<EpubTocEntry> _ncxContents(EpubArchive archive, String path) {
  final XmlDocument ncx;
  try {
    ncx = archive.xml(path);
  } on EpubRefused {
    return const [];
  }
  final map = _named(ncx, 'navMap').firstOrNull;
  if (map == null) return const [];
  final dir = p.posix.dirname(path);
  final out = <EpubTocEntry>[];
  void walk(XmlElement parent, int depth) {
    for (final point in parent.childElements) {
      if (point.localName != 'navPoint') continue;
      final title = _child(
        point,
        'navLabel',
      )?.innerText.replaceAll(_space, ' ').trim();
      final src = _child(point, 'content')?.getAttribute('src');
      if (title != null && title.isNotEmpty && src != null) {
        out.add(_entry(dir, src, title, depth));
      }
      walk(point, depth + 1);
    }
  }

  walk(map, 0);
  return out;
}

/// Whether [element] sits in an `<ol>` nested inside [item].
bool _insideList(dom.Element element, dom.Element item) {
  for (var at = element.parent; at != null && at != item; at = at.parent) {
    if (at.localName == 'ol') return true;
  }
  return false;
}

EpubTocEntry _entry(String dir, String href, String title, int depth) {
  final hash = href.indexOf('#');
  return (
    title: title,
    file: _resolve(dir, href),
    fragment: hash < 0 ? '' : href.substring(hash + 1),
    depth: depth,
  );
}
