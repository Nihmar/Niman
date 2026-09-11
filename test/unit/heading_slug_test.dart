// T-M3-01 AC: heading slug — the shared implementation the parser, the
// editor/outline and the preview all use for `#heading` anchors.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/slug.dart';

void main() {
  group('headingSlug', () {
    test('basic: lowercase, spaces to dashes', () {
      expect(headingSlug('My Heading'), 'my-heading');
      expect(headingSlug('A  B   C'), 'a-b-c');
      expect(headingSlug('Some Heading!'), 'some-heading');
    });

    test('punctuation runs collapse to one dash', () {
      expect(headingSlug('My! Heading, 2024'), 'my-heading-2024');
      expect(headingSlug('a - b'), 'a-b');
      expect(headingSlug('a -- b'), 'a-b');
      expect(headingSlug('**Bold** Heading'), 'bold-heading');
      expect(headingSlug('foo (bar) / baz'), 'foo-bar-baz');
    });

    test('case is normalized', () {
      expect(headingSlug('ABC def'), 'abc-def');
      expect(headingSlug('ABC def'), headingSlug('abc DEF'));
    });

    test('unicode letters and digits are kept', () {
      expect(headingSlug('日本語'), '日本語');
      expect(headingSlug('Привет Как'), 'привет-как');
      expect(headingSlug('Naïve Café 2'), 'naïve-café-2');
      expect(headingSlug('日本語 見出し'), '日本語-見出し');
    });

    test('underscores are kept (no hyphen collision with spaces)', () {
      expect(headingSlug('foo_bar'), 'foo_bar');
      expect(headingSlug('foo bar'), 'foo-bar');
      expect(headingSlug('_x_'), '_x_');
    });

    test('no leading or trailing dashes', () {
      expect(headingSlug('!!Hello!!'), 'hello');
      expect(headingSlug('  spaced  '), 'spaced');
      expect(headingSlug('--x--'), 'x');
    });

    test('empty or punctuation-only headings produce an empty slug', () {
      expect(headingSlug(''), '');
      expect(headingSlug('!!!'), '');
      expect(headingSlug('   '), '');
    });
  });

  group('slug agreement (parser = editor/outline = preview)', () {
    test('a [[#…]] anchor in a doc slugs to its own heading', () {
      const doc = '## My Heading\n\nbody [[#My Heading]] more';
      final links = parseLinks(doc);
      expect(links, hasLength(1));
      final wiki = links.single as WikiLink;
      expect(wiki.ref.target, '');
      expect(wiki.ref.heading, 'My Heading');
      expect(headingSlug(wiki.ref.heading!), 'my-heading');

      final outline = outlineOf(HighlightDocument.fromText(doc).lines);
      expect(outline, hasLength(1));
      expect(headingSlug(outline.single.text), headingSlug(wiki.ref.heading!));
    });

    test('markdown emphasis inside a heading still matches the anchor', () {
      const doc = '## **Bold** Heading\n\n[[x#Bold Heading]]';
      final link = parseLinks(doc).single as WikiLink;
      expect(headingSlug(link.ref.heading!), 'bold-heading');
      final entry = outlineOf(HighlightDocument.fromText(doc).lines).single;
      expect(headingSlug(entry.text), 'bold-heading');
      expect(headingSlug(entry.text), headingSlug(link.ref.heading!));
    });
  });
}
