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
import 'package:niman/src/epub/epub_book_text.dart';
import 'package:niman/src/epub/epub_progress.dart';
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
  new({
    required this.title,
    required this.markdown,
    required this.lineCount,
    required this.contents,
    required this.pictures,
    required this.links,
    required this.chapters,
    required this.counts,
    this.language,
  });

  /// The book's title, or its file name when it gives none.
  final String title;

  /// The whole book, as Markdown.
  final String markdown;

  /// How many lines the book's text has, counted once as it is read (off
  /// the UI isolate): the end the last chapter's places are kept within
  /// (#1306), not a count of [markdown]'s line breaks asked for every mark.
  final int lineCount;

  /// Its table of contents, in the book's order.
  final List<EpubContentsEntry> contents;

  /// Where each picture the text names ([pictureScheme]) is on disk.
  final Map<String, String> pictures;

  /// The line each of the book's own links ([linkScheme]) goes to, by its
  /// number; null for a link into a file the book does not read.
  final List<int?> links;

  /// Its chapters with any text, in the order they are read.
  final List<EpubChapter> chapters;

  /// Its text's characters and words, counted as it is read, off the UI
  /// isolate, for the progress line (#1275).
  final EpubCounts counts;

  /// The book's language (`dc:language`, a BCP 47 tag), when it names one:
  /// the voice it is read aloud in (#1276).
  final String? language;

  /// The progress through the book, its chapters' starts the measure.
  EpubProgress progress() =>
      EpubProgress(counts, [for (final chapter in chapters) chapter.line]);

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
  int _chapterNamed(String name) =>
      _byName[name] ??
      _byLowerName[name.toLowerCase()] ??
      _bySuffix[name.toLowerCase()] ??
      -1;

  // The chapters by name, built once the first time a place is asked for
  // (#1306): a book's marks each used to walk the chapters, and the last
  // chapter's walked the text. The first chapter of a name wins in each.
  late final Map<String, int> _byName = {
    for (var i = chapters.length - 1; i >= 0; i--) chapters[i].file: i,
  };
  late final Map<String, int> _byLowerName = {
    for (var i = chapters.length - 1; i >= 0; i--)
      chapters[i].file.toLowerCase(): i,
  };

  /// Every tail of a chapter's path that starts after a `/`, lowercased:
  /// the file name alone, or the path from any folder down.
  late final Map<String, int> _bySuffix = {
    for (var i = chapters.length - 1; i >= 0; i--)
      for (final tail in _tails(chapters[i].file.toLowerCase())) tail: i,
  };

  static Iterable<String> _tails(String path) sync* {
    for (
      var slash = path.indexOf('/');
      slash != -1;
      slash = path.indexOf('/', slash + 1)
    ) {
      yield path.substring(slash + 1);
    }
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
        : lineCount - 1;
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
    // The one join of the chapters, the conversion's own: a contents entry
    // or a link on a page with no text opens at the next chapter's line.
    final text = epubBookText(book);
    final markdown = text.markdown;
    return EpubDocument(
      title: book.info.title ?? p.basenameWithoutExtension(path),
      markdown: markdown,
      lineCount: text.lines.length,
      contents: [
        for (final entry in book.contents)
          if (text.lineOf(entry.file, entry.fragment) case final line?)
            (title: entry.title, line: line, depth: entry.depth),
      ],
      pictures: _extract(book, pictureDir),
      links: [
        for (final target in book.links)
          text.lineOf(target.file, target.fragment),
      ],
      chapters: [
        for (final MapEntry(key: file, value: line) in text.starts.entries)
          (file: file, line: line),
      ],
      counts: EpubCounts.of(markdown),
      language: switch (book.info.language?.trim()) {
        final tag? when tag.isNotEmpty => tag,
        _ => null,
      },
    );
  } finally {
    input.closeSync();
  }
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
