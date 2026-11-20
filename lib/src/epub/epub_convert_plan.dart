/// Where a book's text goes when it is converted to notes (#1138): which
/// notes, in which folders, holding which lines.
///
/// The planning itself — an entry a note, a part a folder, the numbering,
/// the split depth — is `import/book/book_plan.dart`'s, shared with the HTML
/// book (#1294). This is what an EPUB adds: its chapters joined into the
/// reader's text, its table of contents as the entries, and a note a chapter
/// file, each named by its first heading, for a book with no usable
/// contents.
library;

import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_book_text.dart';
import 'package:niman/src/import/book/book_plan.dart';

export 'package:niman/src/import/book/book_plan.dart' show noteFolderOf;

/// One note of a converted book: see [BookPlannedNote].
typedef EpubPlannedNote = BookPlannedNote;

/// One entry of the book's contents as `index.md` lists it.
typedef EpubPlannedEntry = BookPlannedEntry;

/// The words a conversion writes in the user's language, handed in: the
/// isolate that writes has no locale.
typedef EpubConvertWords = BookWords;

/// Where an EPUB's text goes.
final class EpubPlan extends BookPlan {
  /// Plans [book]: a note a contents entry, or [oneNote] for one note of it
  /// all, named [title].
  factory of(
    EpubBook book, {
    required String title,
    required EpubConvertWords words,
    bool oneNote = false,
  }) {
    final text = epubBookText(book);
    if (oneNote) {
      final single = BookPlan.single(title: title, lines: text.lines);
      return EpubPlan._(
        book: book,
        title: title,
        lines: text.lines,
        notes: single.notes,
        contents: [
          for (final entry in book.contents)
            if (text.lineOf(entry.file, entry.fragment) case final line?)
              (title: entry.title, depth: entry.depth, line: line),
        ],
        lineOf: text.lineOf,
      );
    }
    final entries = _entries(book, text, words);
    return EpubPlan._(
      book: book,
      title: title,
      lines: text.lines,
      notes: planNotes(
        lines: text.lines,
        entries: entries,
        words: words,
        opensFile: text.opensFile,
      ),
      contents: entries,
      lineOf: text.lineOf,
    );
  }

  new _({
    required this.book,
    required super.title,
    required super.lines,
    required super.notes,
    required super.contents,
    required this._lineOf,
  });

  /// The book planned.
  final EpubBook book;

  final int? Function(String file, String fragment) _lineOf;

  /// The line of the book [target] opens on, or null when it is not in it.
  int? lineOfTarget(EpubTarget target) => _lineOf(target.file, target.fragment);
}

/// The contents entries that open somewhere in the text, their depths made
/// a tree's (no entry more than one level under the one before it); or a
/// chapter file an entry when the book has no usable contents.
List<BookPlannedEntry> _entries(
  EpubBook book,
  EpubBookText text,
  EpubConvertWords words,
) {
  final out = bookEntries([
    for (final entry in book.contents)
      if (text.lineOf(entry.file, entry.fragment) case final line?)
        (title: entry.title, depth: entry.depth, line: line),
  ]);
  if (out.isNotEmpty) return out;
  return [
    for (final (index, chapter) in book.chapters.indexed)
      (
        title:
            _firstHeading(chapter.markdown) ??
            words.chapter.replaceAll('{n}', '${index + 1}'),
        depth: 0,
        line: text.lineOf(chapter.file, '')!,
      ),
  ];
}

String? _firstHeading(String markdown) {
  for (final line in markdown.split('\n')) {
    final match = _heading.firstMatch(line);
    if (match != null) return match.group(1)!.trim();
  }
  return null;
}

final RegExp _heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$');
