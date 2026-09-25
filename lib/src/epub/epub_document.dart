/// An EPUB, read into one Markdown text the read view draws, off the UI
/// isolate.
///
/// An EPUB is a zip: `META-INF/container.xml` names the package document
/// (the OPF), whose manifest lists the book's files and whose spine says
/// the order its chapters are read in; the table of contents is the EPUB 3
/// navigation document or the EPUB 2 NCX. Every chapter is converted
/// ([XhtmlMarkdown]) and the chapters are joined in spine order, a rule
/// between them. What the reader needs besides the text comes with it:
/// the table of contents and the book's own links, as lines of that text,
/// and the pictures, extracted to a folder of the app's cache.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:niman/src/epub/xhtml_markdown.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// One entry of a book's table of contents: its title, the line of the
/// book's text it opens on, and how deep it is nested (0 at the top).
typedef EpubContentsEntry = ({String title, int line, int depth});

/// Where a chapter of a book begins: its path in the archive, and the line
/// of the book's text it opens on.
typedef EpubChapter = ({String file, int line});

/// A book, ready to read.
final class EpubDocument {
  /// Wraps a read book.
  const new({
    required this.title,
    required this.markdown,
    required this.contents,
    required this.pictures,
    required this.links,
    required this.chapters,
  });

  /// The book's title, or its file name when it gives none.
  final String title;

  /// The whole book, as Markdown.
  final String markdown;

  /// Its table of contents, in the book's order.
  final List<EpubContentsEntry> contents;

  /// Where each picture the text names ([pictureScheme]) is on disk.
  final Map<String, String> pictures;

  /// The line each of the book's own links ([linkScheme]) goes to, by its
  /// number; null for a link into a file the book does not read.
  final List<int?> links;

  /// Its chapters with any text, in the order they are read.
  final List<EpubChapter> chapters;

  /// How the text names a picture: `epub-picture:3`.
  static const String pictureScheme = 'epub-picture';

  /// How the text names a link into the book: `epub-link:3`.
  static const String linkScheme = 'epub-link';

  /// The line [target] — a link's href in the text — goes to, or null
  /// when it is not a link into the book.
  int? lineOfLink(String target) {
    if (!target.startsWith('$linkScheme:')) return null;
    final index = int.tryParse(target.substring(linkScheme.length + 1));
    if (index == null || index < 0 || index >= links.length) return null;
    return links[index];
  }

  /// The index of the contents entry being read at [line]: the last one
  /// opening at or above it; -1 before the first.
  int entryAt(int line) =>
      contents.lastIndexWhere((entry) => entry.line <= line);

  /// The index of the chapter [name] names: its path in the archive, as
  /// the book spells it, else whatever its case (a Markdown link's
  /// fragment may come lowercased), else its file name alone (a link
  /// written by hand); -1 when none does.
  int _chapterNamed(String name) {
    final exact = chapters.indexWhere((c) => c.file == name);
    if (exact != -1) return exact;
    final lower = name.toLowerCase();
    final anyCase = chapters.indexWhere((c) => c.file.toLowerCase() == lower);
    if (anyCase != -1) return anyCase;
    return chapters.indexWhere((c) => c.file.toLowerCase().endsWith('/$lower'));
  }

  /// [line] of the book's text, [fraction] into it, as a place in its
  /// chapter; null for a book with no chapters.
  EpubLocation? locationAt(int line, double fraction) {
    final index = chapters.lastIndexWhere((c) => c.line <= line);
    if (index == -1) {
      return chapters.isEmpty
          ? null
          : EpubLocation(chapter: chapters.first.file, line: 0);
    }
    final chapter = chapters[index];
    return EpubLocation(
      chapter: chapter.file,
      line: line - chapter.line,
      fraction: fraction,
    );
  }

  /// The line of the book's text [location] names, kept within its
  /// chapter when the chapter has grown shorter; null when the book has
  /// no such chapter.
  int? lineOfLocation(EpubLocation location) {
    final index = _chapterNamed(location.chapter);
    if (index == -1) return null;
    final start = chapters[index].line;
    final end = index + 1 < chapters.length
        ? chapters[index + 1].line - 1
        : '\n'.allMatches(markdown).length - 1;
    return (start + location.line).clamp(start, end < start ? start : end);
  }
}

/// Reads the EPUB at [path] on an isolate, its pictures extracted to a
/// folder of [cacheDir] of that book's own ([pictureDirOf]).
///
/// Top-level for `Isolate.run`: it carries the two paths. The file is
/// stat'ed there too, not on the UI isolate.
Future<EpubDocument> openEpub(String path, String cacheDir) =>
    Isolate.run(() => readEpub(path, pictureDirOf(path, cacheDir)));

/// The folder of [cacheDir] the pictures of the EPUB at [path] go to: named
/// by the book's path, size and modification time, so a book opened again
/// finds its pictures and a book changed on disk gets new ones.
String pictureDirOf(String path, String cacheDir) {
  final stat = File(path).statSync();
  final key = '$path\n${stat.size}\n${stat.modified.microsecondsSinceEpoch}';
  return p.join(cacheDir, sha1.convert(utf8.encode(key)).toString());
}

/// Reads the EPUB at [path], here; see [openEpub].
///
/// Throws a [FormatException] when the file is not an EPUB it can read.
EpubDocument readEpub(String path, String pictureDir) {
  final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
  final book = _Book(archive);
  final opfPath = book.packagePath();
  final opf = book.xml(opfPath);
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
  if (spine.isEmpty) throw const FormatException('the book has no chapters');

  final pictures = <String>[];
  final targets = <({String file, String fragment})>[];
  final chapterStart = <String, int>{};
  final anchors = <String, Map<String, int>>{};
  final text = StringBuffer();
  var line = 0;
  for (final chapter in spine) {
    final file = book.file(chapter);
    if (file == null) continue;
    final dir = p.posix.dirname(chapter);
    final converted = XhtmlMarkdown(
      picture: (src) {
        final resolved = _resolve(dir, src);
        if (book.file(resolved) == null) return null;
        var index = pictures.indexOf(resolved);
        if (index < 0) {
          index = pictures.length;
          pictures.add(resolved);
        }
        return '${EpubDocument.pictureScheme}:$index';
      },
      link: (href) {
        if (_scheme.hasMatch(href)) return href;
        final hash = href.indexOf('#');
        final target = hash < 0 ? href : href.substring(0, hash);
        final fragment = hash < 0 ? '' : href.substring(hash + 1);
        targets.add((
          file: target.isEmpty ? chapter : _resolve(dir, target),
          fragment: fragment,
        ));
        return '${EpubDocument.linkScheme}:${targets.length - 1}';
      },
    ).convert(book.text(file));
    if (converted.markdown.trim().isEmpty) continue;
    if (text.isNotEmpty) {
      // A rule between two chapters, a blank line on each side of it.
      text.write('\n\n---\n\n');
      line += 4;
    }
    chapterStart[chapter] = line;
    anchors[chapter] = {
      for (final entry in converted.anchors.entries)
        entry.key: line + entry.value,
    };
    text.write(converted.markdown);
    line += '\n'.allMatches(converted.markdown).length;
  }
  text.write('\n');

  int? lineOf(String file, String fragment) {
    final start = chapterStart[file];
    if (start == null) return null;
    if (fragment.isEmpty) return start;
    return anchors[file]?[fragment] ?? start;
  }

  return EpubDocument(
    title: _title(opf) ?? p.basenameWithoutExtension(path),
    markdown: text.toString(),
    contents: [
      for (final entry in book.contents(opf, manifest))
        if (lineOf(entry.file, entry.fragment) case final line?)
          (title: entry.title, line: line, depth: entry.depth),
    ],
    pictures: _extract(book, pictures, pictureDir),
    links: [for (final target in targets) lineOf(target.file, target.fragment)],
    chapters: [
      for (final MapEntry(key: file, value: line) in chapterStart.entries)
        (file: file, line: line),
    ],
  );
}

/// A file of the book's manifest.
typedef _Item = ({String path, String type, String properties});

/// Where a table of contents entry points.
typedef _Entry = ({String title, String file, String fragment, int depth});

/// An `http:`, `mailto:`… href, which leaves the book.
final RegExp _scheme = RegExp('^[A-Za-z][A-Za-z0-9+.-]*:');

/// [href], as written in a file of folder [dir], as a path in the zip.
String _resolve(String dir, String href) {
  final hash = href.indexOf('#');
  final bare = hash < 0 ? href : href.substring(0, hash);
  // Percent-decoded where the escapes are well formed; a stray `%` is a
  // character of the name.
  final decoded = _badEscape.hasMatch(bare) ? bare : Uri.decodeComponent(bare);
  final joined = dir.isEmpty || dir == '.'
      ? decoded
      : p.posix.join(dir, decoded);
  return p.posix.normalize(joined);
}

/// A `%` that does not open a two-digit escape.
final RegExp _badEscape = RegExp('%(?![0-9A-Fa-f]{2})');

/// The elements under [node] named [local], whatever their prefix: an OPF
/// may write `<item>` or `<opf:item>`.
Iterable<XmlElement> _named(XmlNode node, String local) =>
    node.descendantElements.where((element) => element.localName == local);

/// The first child of [element] named [local], whatever its prefix.
XmlElement? _child(XmlElement element, String local) => element.childElements
    .where((child) => child.localName == local)
    .firstOrNull;

String? _title(XmlDocument opf) {
  for (final element in opf.descendantElements) {
    if (element.localName == 'title' && element.innerText.trim().isNotEmpty) {
      return element.innerText.trim();
    }
  }
  return null;
}

/// Writes [pictures] under [dir], each once: a book opened again finds its
/// pictures where it left them.
Map<String, String> _extract(_Book book, List<String> pictures, String dir) {
  final out = <String, String>{};
  if (pictures.isEmpty) return out;
  Directory(dir).createSync(recursive: true);
  for (var index = 0; index < pictures.length; index++) {
    final file = book.file(pictures[index]);
    if (file == null) continue;
    final target = File(
      p.join(dir, '$index${p.extension(pictures[index]).toLowerCase()}'),
    );
    if (!target.existsSync()) {
      final bytes = file.readBytes();
      if (bytes == null) continue;
      target.writeAsBytesSync(bytes, flush: true);
    }
    out['${EpubDocument.pictureScheme}:$index'] = target.path;
  }
  return out;
}

/// The zip, read as a book.
final class _Book {
  new(this._archive);

  final Archive _archive;

  ArchiveFile? file(String path) => _archive.findFile(path);

  String text(ArchiveFile file) =>
      utf8.decode(file.readBytes() ?? const <int>[], allowMalformed: true);

  XmlDocument xml(String path) {
    final entry = file(path);
    if (entry == null) throw FormatException('"$path" is not in the book');
    return XmlDocument.parse(text(entry));
  }

  /// The package document's path, from `META-INF/container.xml`.
  String packagePath() {
    final container = xml('META-INF/container.xml');
    final rootfile = _named(container, 'rootfile').firstOrNull;
    final path = rootfile?.getAttribute('full-path');
    if (path == null) throw const FormatException('no package document');
    return path;
  }

  /// The table of contents: the EPUB 3 navigation document when there is
  /// one, the EPUB 2 NCX otherwise.
  List<_Entry> contents(XmlDocument opf, Map<String, _Item> manifest) {
    final nav = manifest.values
        .where((item) => item.properties.split(' ').contains('nav'))
        .firstOrNull;
    if (nav != null) {
      final entries = _navContents(nav.path);
      if (entries.isNotEmpty) return entries;
    }
    final spine = _named(opf, 'spine').firstOrNull;
    final ncx =
        manifest[spine?.getAttribute('toc')] ??
        manifest.values
            .where((item) => item.type == 'application/x-dtbncx+xml')
            .firstOrNull;
    return ncx == null ? const [] : _ncxContents(ncx.path);
  }

  List<_Entry> _navContents(String path) {
    final entry = file(path);
    if (entry == null) return const [];
    final document = html.parse(text(entry));
    final navs = document.getElementsByTagName('nav');
    final toc =
        navs
            .where((nav) => (nav.attributes['epub:type'] ?? '') == 'toc')
            .firstOrNull ??
        navs.firstOrNull;
    final list = toc?.querySelector('ol');
    if (list == null) return const [];
    final dir = p.posix.dirname(path);
    final out = <_Entry>[];
    void walk(dom.Element ol, int depth) {
      for (final li in ol.children) {
        if (li.localName != 'li') continue;
        final a = li.querySelector('a');
        final href = a?.attributes['href'];
        if (a != null && href != null) {
          final title = a.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (title.isNotEmpty) out.add(_entry(dir, href, title, depth));
        }
        for (final nested in li.children) {
          if (nested.localName == 'ol') walk(nested, depth + 1);
        }
      }
    }

    walk(list, 0);
    return out;
  }

  List<_Entry> _ncxContents(String path) {
    final ncx = xml(path);
    final map = _named(ncx, 'navMap').firstOrNull;
    if (map == null) return const [];
    final dir = p.posix.dirname(path);
    final out = <_Entry>[];
    void walk(XmlElement parent, int depth) {
      for (final point in parent.childElements) {
        if (point.localName != 'navPoint') continue;
        final title = _child(
          point,
          'navLabel',
        )?.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
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

  static _Entry _entry(String dir, String href, String title, int depth) {
    final hash = href.indexOf('#');
    return (
      title: title,
      file: _resolve(dir, href),
      fragment: hash < 0 ? '' : href.substring(hash + 1),
      depth: depth,
    );
  }
}
