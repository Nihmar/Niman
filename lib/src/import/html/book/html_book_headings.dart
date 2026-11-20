/// A page that is a book by its headings alone (#1294): a novel saved from
/// a site that has no profile of its own, a text set in chapters.
///
/// **The rule.** A page is a book when its headings say so:
///
/// - the chapters' heading level is the **shallowest level that occurs at
///   least [minimumChapters] times** (`h2` for a page with one `h1`, its
///   title, and chapters under it) — headings of a `nav`, an `aside` or a
///   footer do not count;
/// - the page has at least [minimumBookCharacters] characters of text: a
///   short page with three sections is an article;
/// - the chapters are long: the **median** of the text between two of those
///   headings is at least [minimumChapterCharacters]. A reference page whose
///   sections are a paragraph each, with a few long ones among them, is not
///   a book; a novel's chapters are.
///
/// The chapters are the headings of that level, flat: whatever is deeper
/// stays a heading inside its chapter, whatever is shallower (the book's
/// title) stays where it is — in the text before the first chapter, which is
/// the book's front matter.
///
/// What the page says of itself — its title, its author, its language, the
/// address it was saved from — is the book's metadata.
library;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/import/html/book/html_book.dart';
import 'package:niman/src/import/html/html_page.dart';

/// How many headings of a level make it the chapters'.
const int minimumChapters = 3;

/// How much text a page has to be a book.
const int minimumBookCharacters = 20000;

/// How long, at the median, a chapter has to be.
const int minimumChapterCharacters = 2000;

const Set<String> _headings = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

/// Elements whose text is not the book's.
const Set<String> _skipped = {
  'script',
  'style',
  'noscript',
  'template',
  'nav',
  'aside',
  'footer',
};

/// [page] as a book by its headings, or null when it is not one.
HtmlBook? readHeadingsBook(HtmlPage page) {
  // Cheap, before a page too short to be a book is parsed for it.
  if (page.html.length < minimumBookCharacters) return null;
  final document = html.parse(page.html);
  final body = document.body;
  if (body == null) return null;
  final found = <({Element heading, int level, int offset})>[];
  var characters = 0;
  void walk(Node node) {
    if (node is Text) {
      characters += node.data.trim().length;
    } else if (node is Element) {
      final name = node.localName ?? '';
      if (_skipped.contains(name)) return;
      if (_headings.contains(name) && node.text.trim().isNotEmpty) {
        found.add((
          heading: node,
          level: int.parse(name.substring(1)),
          offset: characters,
        ));
      }
      node.nodes.forEach(walk);
    }
  }

  walk(body);
  if (characters < minimumBookCharacters) return null;
  final counts = <int, int>{};
  for (final entry in found) {
    counts[entry.level] = (counts[entry.level] ?? 0) + 1;
  }
  final level = [
    for (final entry in counts.entries)
      if (entry.value >= minimumChapters) entry.key,
  ].fold<int?>(null, (best, at) => best == null || at < best ? at : best);
  if (level == null) return null;
  final chapters = [
    for (final entry in found)
      if (entry.level == level) entry,
  ];
  // The text between a chapter's heading and the next, the last one's to the
  // page's end.
  final lengths = [
    for (var i = 0; i < chapters.length; i++)
      (i + 1 < chapters.length ? chapters[i + 1].offset : characters) -
          chapters[i].offset,
  ]..sort();
  if (lengths[lengths.length ~/ 2] < minimumChapterCharacters) return null;

  final titles = <HtmlBookChapter>[];
  for (final (index, chapter) in chapters.indexed) {
    chapter.heading.parent!.insertBefore(
      chapterMarkerElement(index),
      chapter.heading,
    );
    titles.add((
      marker: chapterMarker(index),
      title: chapter.heading.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ));
  }
  final author = page.author;
  return HtmlBook(
    profile: HtmlBookProfile.headings,
    title: page.title,
    authors: author == null ? const [] : [author],
    fields: [
      ('title', page.title),
      ('author', author == null ? null : [author]),
      ('language', page.language),
      ('source', page.source),
    ],
    html: body.innerHtml,
    chapters: titles,
    headingLevel: level,
  );
}
