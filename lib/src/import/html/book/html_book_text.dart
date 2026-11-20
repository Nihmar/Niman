/// A book's text as Markdown lines (#1294), and where each chapter opens in
/// them: what the plan splits into notes.
///
/// - **Converted once**, whole, with each `<br>`-cut line a paragraph (an AO3
///   download writes a paragraph so). A picture is written under a
///   placeholder ([pictureScheme]) and a link into the page under the one
///   `html_anchor_links.dart` knows: the pictures are kept and the notes
///   named afterwards, and each placeholder is then made what it points at.
/// - **Headings shifted** so that the chapters' own are `#` when each is a
///   note of its own, `##` under the one note's `#` title: a chapter's note
///   starts with its heading, at the top level, and the sections of a chapter
///   keep their depth under it.
/// - **The book's title**, when the text before the first chapter opens with
///   it as a heading, is left out of that text: it is the note's own.
library;

import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/html/book/html_book.dart';
import 'package:niman/src/import/html/html_anchor_links.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_unlinked.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// How a picture's placeholder starts in the converted text: followed by the
/// number of its `src` in the text's `pictureSrcs`.
const String pictureScheme = 'niman-picture';

/// A book's text, converted.
typedef HtmlBookText = ({
  /// The text, a line an item.
  List<String> lines,

  /// Where each element with an `id` begins, as a line of [lines].
  Map<String, int> anchors,

  /// Where each chapter opens, by title.
  List<BookPlannedEntry> entries,

  /// The `src` of each picture the text names, in the order it names them.
  List<String> pictureSrcs,

  /// The book's intro (see [HtmlBook.introHtml]), converted; empty when it
  /// has none.
  String intro,
});

/// [book] converted: its chapters' headings at the top level, or — with
/// [oneNote] — under a title. [words] names a chapter the book calls
/// nothing; [base] is what its pictures' relative `src`s are relative to.
HtmlBookText convertBookText(
  HtmlBook book, {
  required Uri base,
  required bool oneNote,
  required BookWords words,
}) {
  final srcs = <String>[];
  final index = <String, int>{};
  String? placeholder(String src) {
    if (PictureSource.parse(src, base) == null) return null;
    final number = index.putIfAbsent(src, () {
      srcs.add(src);
      return srcs.length - 1;
    });
    return '$pictureScheme:$number';
  }

  final converter = HtmlMarkdown(
    picture: placeholder,
    link: (href) => isUnlinked(href)
        ? null
        : href.startsWith('#') && href.length > 1
        ? anchorTarget(href.substring(1))
        : href,
    breaksAsParagraphs: true,
  );
  final converted = converter.convert(book.html);
  // A book that sets no chapter off by a heading has no level to move.
  final by = book.headingLevel == 0 ? 0 : (oneNote ? 2 : 1) - book.headingLevel;
  final lines = shiftHeadings(converted.markdown.split('\n'), by);
  final entries = <BookPlannedEntry>[];
  for (final (number, chapter) in book.chapters.indexed) {
    final line = converted.anchors[chapter.marker];
    if (line == null) continue;
    entries.add((
      title: chapter.title.isEmpty
          ? words.chapter.replaceAll('{n}', '${number + 1}')
          : chapter.title,
      depth: 0,
      line: line,
    ));
  }
  _withoutTitle(
    lines,
    entries.isEmpty ? lines.length : entries.first.line,
    book,
  );
  return (
    lines: lines,
    anchors: converted.anchors,
    entries: entries,
    pictureSrcs: srcs,
    intro: book.introHtml.isEmpty
        ? ''
        : converter.convert(book.introHtml).markdown,
  );
}

/// [lines] with every heading [by] levels deeper (higher up when negative),
/// never past `######` nor above `#`; the lines of a code fence are not
/// headings.
List<String> shiftHeadings(List<String> lines, int by) {
  if (by == 0) return lines;
  final out = <String>[];
  var fenced = false;
  for (final line in lines) {
    if (_fence.hasMatch(line)) fenced = !fenced;
    final match = fenced ? null : _heading.firstMatch(line);
    if (match == null) {
      out.add(line);
      continue;
    }
    final level = (match[1]!.length + by).clamp(1, 6);
    out.add('${'#' * level}${match[2]}');
  }
  return out;
}

/// Blanks the book's own title, as a heading in [lines] before line [end] —
/// the text before the first chapter — so that it is not said twice.
void _withoutTitle(List<String> lines, int end, HtmlBook book) {
  final title = escapeMarkdownText(book.title).trim();
  for (var i = 0; i < end; i++) {
    final match = _heading.firstMatch(lines[i]);
    if (match == null) continue;
    if (match[2]!.trim() == title) lines[i] = '';
    return;
  }
}

/// The name a chapter's note is given: its heading without the number that
/// starts it — `Chapter 3: The Storm` is `The Storm` — when it has a title
/// of its own after one, else the heading whole (`Chapter 3`).
///
/// A number is a word, digits or a Roman numeral, then a colon, a full stop
/// or a dash.
String chapterFileTitle(String heading) {
  final match = _numbered.firstMatch(heading.trim());
  return match == null ? heading : match[1]!.trim();
}

final RegExp _numbered = RegExp(
  r'^\S+\s+(?:\d+|[IVXLCDM]+)\s*[:.–—-]\s*(\S.*)$',
);
final RegExp _heading = RegExp(r'^(#{1,6})([ \t]+.*)$');
final RegExp _fence = RegExp(r'^\s*(```|~~~)');
