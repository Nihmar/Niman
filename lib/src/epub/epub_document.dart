/// An EPUB, read into one Markdown text the read view draws, off the UI
/// isolate.
///
/// An EPUB is a zip: `META-INF/container.xml` names the package document
/// (the OPF), whose manifest lists the book's files and whose spine says
/// the order its chapters are read in; the table of contents is the EPUB 3
/// navigation document or the EPUB 2 NCX. Every chapter is converted
/// (`HtmlMarkdown`) and the chapters are joined in spine order, a rule
/// between them. What the reader needs besides the text comes with it:
/// the table of contents and the book's own links, as lines of that text,
/// and the pictures, extracted to a folder of the app's cache.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:path/path.dart' as p;

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
    this.mathReport,
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

  /// An ad-hoc diagnostic (#303): what the chapters' math looked like to a
  /// plain scan — the SVG formulas, their first TeX, the MathML — for the
  /// pane to log. Null when the book shows none.
  final String? mathReport;

  /// How the text names a picture: `epub-picture:3`.
  static const String pictureScheme = epubPictureScheme;

  /// How the text names a link into the book: `epub-link:3`.
  static const String linkScheme = epubLinkScheme;

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
/// Throws a [FormatException] when the file is not an EPUB it can read: an
/// [EpubRefused] says why (not a book, protected, too large).
EpubDocument readEpub(String path, String pictureDir) {
  final input = InputFileStream(path);
  try {
    final book = parseEpub(EpubArchive.open(input));
    final text = StringBuffer();
    final chapterStart = <String, int>{};
    final anchors = <String, Map<String, int>>{};
    var line = 0;
    for (final chapter in book.chapters) {
      if (text.isNotEmpty) {
        // A rule between two chapters, a blank line on each side of it.
        text.write('\n\n---\n\n');
        line += 4;
      }
      chapterStart[chapter.file] = line;
      anchors[chapter.file] = {
        for (final entry in chapter.anchors.entries)
          entry.key: line + entry.value,
      };
      text.write(chapter.markdown);
      line += '\n'.allMatches(chapter.markdown).length;
    }
    text.write('\n');

    int? lineOf(String file, String fragment) {
      final start = chapterStart[file];
      if (start == null) return null;
      if (fragment.isEmpty) return start;
      return epubAnchorLine(anchors[file], fragment) ?? start;
    }

    return EpubDocument(
      title: book.info.title ?? p.basenameWithoutExtension(path),
      markdown: text.toString(),
      contents: [
        for (final entry in book.contents)
          if (lineOf(entry.file, entry.fragment) case final line?)
            (title: entry.title, line: line, depth: entry.depth),
      ],
      pictures: _extract(book, pictureDir),
      links: [
        for (final target in book.links) lineOf(target.file, target.fragment),
      ],
      chapters: [
        for (final MapEntry(key: file, value: line) in chapterStart.entries)
          (file: file, line: line),
      ],
      mathReport: _mathReport(book.formulaSvgs, book.firstTex, book.mathMl),
    );
  } finally {
    input.closeSync();
  }
}

/// The math a book's chapters showed, as one log line's worth (#303):
/// null when there was none.
String? _mathReport(int formulas, String? firstTex, int mathMl) {
  if (formulas == 0 && mathMl == 0) return null;
  final sample = firstTex == null ? '' : ' (first: "$firstTex")';
  final ml = mathMl == 0 ? '' : ', $mathMl mathml';
  return '$formulas svg formulas$sample$ml';
}

/// Writes the book's pictures under [dir], each once: a book opened again
/// finds its pictures where it left them.
Map<String, String> _extract(EpubBook book, String dir) {
  final out = <String, String>{};
  if (book.pictures.isEmpty) return out;
  Directory(dir).createSync(recursive: true);
  for (var index = 0; index < book.pictures.length; index++) {
    final target = File(
      p.join(dir, '$index${p.extension(book.pictures[index]).toLowerCase()}'),
    );
    if (!target.existsSync()) {
      final bytes = book.pictureBytes(index);
      if (bytes == null) continue;
      target.writeAsBytesSync(bytes, flush: true);
    }
    out['${EpubDocument.pictureScheme}:$index'] = target.path;
  }
  return out;
}
