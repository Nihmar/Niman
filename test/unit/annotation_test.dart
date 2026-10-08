// An annotation of a PDF or a book (#284) as its companion note holds it:
// a heading naming the place, the passage quoted with the link back to
// it, the comment. A highlight (#626): the quote and its link alone.
//
// A link is written in pieces, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/reading/book_location.dart';

void main() {
  const passage = PdfLocation(page: 34, chars: (start: 120, end: 180));

  test('a passage: its heading, its quote and link, the comment', () {
    const annotation = Annotation(
      path: 'Books/Dune.pdf',
      place: passage,
      label: 'Dune, p. 34',
      quote: 'The spice\n  must flow.',
      comment: 'Remember this.',
    );
    expect(
      annotation.toMarkdown(linkType: LinkType.wikilink),
      '## Dune, p. 34\n'
      '\n'
      '> The spice must flow.\n'
      '> — [[Books/Dune.pdf#page=34&chars=120-180|Dune, p. 34]]\n'
      '\n'
      'Remember this.\n',
    );
  });

  test('the quote is the words it is, never syntax', () {
    const annotation = Annotation(
      path: 'a.pdf',
      place: PdfLocation(page: 1),
      label: '# One',
      quote: r'A #tag, a [[link]], $5 and $6.',
    );
    final text = annotation.toMarkdown(linkType: LinkType.wikilink);
    expect(text, startsWith(r'## \# One'));
    expect(text, contains(r'> A \#tag, a \[\[link\]\], \$5 and \$6.'));
  });

  test('a place with nothing to quote has its link alone, no comment', () {
    const annotation = Annotation(
      path: 'Scan.pdf',
      place: PdfLocation(page: 2),
      label: 'Scan, p. 2',
    );
    expect(
      annotation.toMarkdown(linkType: LinkType.markdown),
      '## Scan, p. 2\n\n[Scan, p. 2](Scan.pdf#page=2)\n',
    );
  });

  test("a passage's characters ride on the link and read back", () {
    expect(passage.toFragment(), 'page=34&chars=120-180');
    expect(BookLocation.fromFragment(passage.toFragment()), passage);
    expect(
      BookLocation.fromFragment('page=3&chars=9-2'),
      const PdfLocation(page: 3),
    );
  });

  group('a highlight (#626)', () {
    const highlight = Annotation(
      path: 'Books/Dune.pdf',
      place: passage,
      label: 'Dune, p. 34',
      quote: 'The spice #must flow.',
      highlight: HighlightColour.green,
    );

    test('is its quote and link alone, the colour in the link', () {
      expect(
        highlight.toMarkdown(linkType: LinkType.wikilink),
        r'> The spice \#must flow.'
        '\n'
        '> — [[Books/Dune.pdf#page=34&chars=120-180&highlight=green'
        '|Dune, p. 34]]\n',
      );
      expect(
        highlight.toMarkdown(linkType: LinkType.markdown),
        endsWith(
          '> — [Dune, p. 34]'
          '(Books/Dune.pdf#page=34&chars=120-180&highlight=green)\n',
        ),
      );
    });

    test('the colour is a key a place passes over', () {
      expect(
        BookLocation.fromFragment('page=34&chars=120-180&highlight=green'),
        passage,
      );
    });

    test('annotated, it is an annotation with its heading', () {
      final annotated = highlight.withComment('Remember.');
      expect(annotated.highlight, isNull);
      expect(
        annotated.toMarkdown(linkType: LinkType.wikilink),
        startsWith('## Dune, p. 34\n'),
      );
      expect(
        highlight.withComment('').highlighted(HighlightColour.pink).highlight,
        HighlightColour.pink,
      );
    });
  });
}
