/// An HTML page that is a book (#1294): a long page split into chapters —
/// a fanfiction downloaded from AO3, a novel saved from another site.
///
/// The model: what the conversion needs of a book — its title and metadata,
/// and its text as one HTML in which each chapter opens at a marker.
/// `readHtmlBook` (`html_book_reader.dart`) says whether a page is one, by the
/// profile that knows its shape (`html_book_ao3.dart`) or, for any other page,
/// by the rule of `html_book_headings.dart`.
///
/// Pure: a page in, a book out. The text is made Markdown by
/// `html_book_text.dart`, planned by `import/book/book_plan.dart` and written
/// by `html_book_render.dart`.
library;

import 'package:html/dom.dart';

/// The shape a book was recognized by.
enum HtmlBookProfile {
  /// An Archive of Our Own download: `div#preface`, `div#chapters`,
  /// `div#afterword`.
  ao3,

  /// Any page whose headings of one level repeat: see `html_book_headings`.
  headings,
}

/// One chapter of a book: the id of the marker its text opens at in
/// [HtmlBook.html], and its title as the book calls it (empty when it calls
/// it nothing).
typedef HtmlBookChapter = ({String marker, String title});

/// The marker element's id for chapter [index] (from 0).
String chapterMarker(int index) => 'niman-chapter-$index';

/// A marker: an empty block that the converter notes the line of, before the
/// chapter's heading — the heading's own `id`, which the book's links name,
/// is left as it is.
Element chapterMarkerElement(int index) =>
    Element.tag('div')..id = chapterMarker(index);

/// A page read as a book.
final class HtmlBook {
  /// A book read from a page.
  const new({
    required this.profile,
    required this.title,
    required this.authors,
    required this.fields,
    required this.html,
    required this.chapters,
    required this.headingLevel,
    this.introHtml = '',
  });

  /// What it was recognized by.
  final HtmlBookProfile profile;

  /// What it is called.
  final String title;

  /// Who wrote it.
  final List<String> authors;

  /// The frontmatter of its notes, in order, as `bookFrontmatter` writes
  /// them: a text, a number or a list; `imported` is not among them (see
  /// [fieldsImportedOn]).
  final List<(String, Object?)> fields;

  /// All its text as one HTML, a [chapterMarkerElement] before each
  /// chapter's heading.
  final String html;

  /// The chapters, in reading order.
  final List<HtmlBookChapter> chapters;

  /// The level of the chapters' headings in [html] (1 to 6); 0 when the
  /// chapters are not set off by one (a book of a single chapter).
  final int headingLevel;

  /// What comes before the chapters and is not one of them, as the index
  /// says it: an AO3 work's summary and notes. Empty for a book that has
  /// none.
  final String introHtml;

  /// [fields] with `imported: [day]` after the `source` — or, for a book that
  /// names none, at the end of what it says of itself.
  List<(String, Object?)> fieldsImportedOn(String day) {
    final at = fields.indexWhere((field) => field.$1 == 'source');
    final index = at < 0 ? fields.length : at + 1;
    return [...fields.take(index), ('imported', day), ...fields.skip(index)];
  }
}
