// The link to a place in a PDF or a book (#282), as the library writes
// links, reads back as the same file and place.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/place_link.dart';
import 'package:niman/src/reading/book_location.dart';

void main() {
  const pdf = PdfLocation(page: 34);
  const epub = EpubLocation(chapter: 'OEBPS/ch 5.xhtml', line: 12);

  test('a wikilink, its label the alias', () {
    final link = placeLink(
      path: 'Books/My Book.pdf',
      place: pdf,
      label: 'My Book, p. 34',
      linkType: LinkType.wikilink,
    );
    expect(link, '[[Books/My Book.pdf#page=34|My Book, p. 34]]');
    final ref = parseWikiRef(link.substring(2, link.length - 2));
    expect(ref.target, 'Books/My Book.pdf');
    expect(BookLocation.fromFragment(ref.heading!), pdf);
  });

  test('a Markdown link, its path percent-encoded as Obsidian writes it', () {
    final link = placeLink(
      path: 'Books/My (1) Book.epub',
      place: epub,
      label: 'My Book, [Five]',
      linkType: LinkType.markdown,
    );
    const href =
        'Books/My%20%281%29%20Book.epub#chapter=OEBPS/ch%205.xhtml&line=12';
    expect(link, '[My Book, (Five)]($href)');
    final hash = href.indexOf('#');
    expect(percentDecoded(href.substring(0, hash)), 'Books/My (1) Book.epub');
    expect(BookLocation.fromFragment(href.substring(hash + 1)), epub);
  });

  test('a label cannot end the wikilink or split its alias', () {
    final link = placeLink(
      path: 'a.pdf',
      place: pdf,
      label: 'x|y]]',
      linkType: LinkType.wikilink,
    );
    expect(link, '[[a.pdf#page=34|x-y))]]');
  });
}
