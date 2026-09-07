// T-M3-01 AC: link parser — all wikilink forms + Markdown links, edge cases
// (empty, unicode, unclosed), fence/frontmatter skipping, absolute offsets.
import 'package:copist/src/links/parser.dart';
import 'package:flutter_test/flutter_test.dart';

WikiRef _wikiRef(String text, {int index = 0}) =>
    (parseLinks(text)[index] as WikiLink).ref;

MarkdownLink _mdLink(String text, {int index = 0}) =>
    parseLinks(text)[index] as MarkdownLink;

void main() {
  group('parseWikiRef', () {
    test('plain target', () {
      final ref = parseWikiRef('my note');
      expect(ref.target, 'my note');
      expect(ref.heading, isNull);
      expect(ref.alias, isNull);
    });

    test('target|alias', () {
      final ref = parseWikiRef('note|display');
      expect(ref.target, 'note');
      expect(ref.alias, 'display');
      expect(ref.heading, isNull);
    });

    test('target#heading', () {
      final ref = parseWikiRef('note#My Heading');
      expect(ref.target, 'note');
      expect(ref.heading, 'My Heading');
      expect(ref.alias, isNull);
    });

    test('target#heading|alias', () {
      final ref = parseWikiRef('note#My Heading|display');
      expect(ref.target, 'note');
      expect(ref.heading, 'My Heading');
      expect(ref.alias, 'display');
    });

    test('#heading (current note)', () {
      final ref = parseWikiRef('#My Heading');
      expect(ref.target, '');
      expect(ref.heading, 'My Heading');
      expect(ref.alias, isNull);
    });

    test('#heading|alias', () {
      final ref = parseWikiRef('#Heading|shown');
      expect(ref.target, '');
      expect(ref.heading, 'Heading');
      expect(ref.alias, 'shown');
    });

    test('|alias (empty target)', () {
      final ref = parseWikiRef('|alias');
      expect(ref.target, '');
      expect(ref.heading, isNull);
      expect(ref.alias, 'alias');
    });

    test(
      'parts are trimmed; a # that appears after the pipe is alias text',
      () {
        final ref = parseWikiRef(' note # Head | Display ');
        expect(ref.target, 'note');
        expect(ref.heading, 'Head');
        expect(ref.alias, 'Display');
      },
    );

    test('empty parts normalize to null', () {
      expect(parseWikiRef('note#').heading, isNull);
      expect(parseWikiRef('note|').alias, isNull);
      expect(parseWikiRef('#').heading, isNull);
      expect(parseWikiRef('|').alias, isNull);
      expect(parseWikiRef('note#|x').heading, isNull);
    });

    test('first pipe splits; rest stays in the alias', () {
      final ref = parseWikiRef('a|b|c');
      expect(ref.target, 'a');
      expect(ref.alias, 'b|c');
    });

    test('unicode target and heading', () {
      final ref = parseWikiRef('日本語#見出し|表示');
      expect(ref.target, '日本語');
      expect(ref.heading, '見出し');
      expect(ref.alias, '表示');
    });
  });

  group('parseLinks — wikilinks', () {
    test('all documented forms in one document, in order', () {
      const text =
          '[[wiki]] [[wiki|alias]] [[wiki#heading]] '
          '[[#heading]] [[|alias]] [[wiki#heading|alias]]';
      final links = parseLinks(text);
      expect(links, hasLength(6));
      expect(links[0], isA<WikiLink>());
      final targets = [
        (links[0] as WikiLink).ref.target,
        (links[1] as WikiLink).ref.target,
        (links[2] as WikiLink).ref.target,
        (links[3] as WikiLink).ref.target,
        (links[4] as WikiLink).ref.target,
        (links[5] as WikiLink).ref.target,
      ];
      expect(targets, ['wiki', 'wiki', 'wiki', '', '', 'wiki']);
      expect((links[4] as WikiLink).ref.alias, 'alias');
      expect((links[5] as WikiLink).ref.heading, 'heading');
      expect((links[5] as WikiLink).ref.alias, 'alias');
    });

    test('offsets are absolute across lines', () {
      const text = 'a [[one]] b\nc [two](three) d';
      final links = parseLinks(text);
      expect(links, hasLength(2));
      final wiki = links[0] as WikiLink;
      final md = links[1] as MarkdownLink;
      expect(wiki.start, 2);
      expect(wiki.end, 9);
      expect(text.substring(wiki.start, wiki.end), '[[one]]');
      expect(md.start, 14);
      expect(md.end, 26);
      expect(text.substring(md.start, md.end), '[two](three)');
    });

    test('whitespace inside brackets is trimmed', () {
      final ref = _wikiRef('[[ My Note ]]');
      expect(ref.target, 'My Note');
    });

    test('empty, unclosed and malformed forms', () {
      expect(parseLinks('[[]]'), isEmpty); // nothing to link
      expect(parseLinks('[[|]]'), isEmpty);
      expect(parseLinks('[[#]]'), isEmpty);
      expect(parseLinks('[[wiki'), isEmpty); // unclosed
      expect(parseLinks('[[a]'), isEmpty); // unclosed
      expect(parseLinks('[[a]]]'), hasLength(1)); // trailing ] ignored
      // Nested brackets: the tokenizer finds the first complete `[[…]]`,
      // so the inner `[[b]]` is the link (editor, preview, parser agree).
      final ref = _wikiRef('[[a[[b]]');
      expect(ref.target, 'b');
      expect(parseLinks('[[a[[b]]'), hasLength(1));
    });

    test('unicode forms', () {
      final ref = _wikiRef('[[日本語]]');
      expect(ref.target, '日本語');
    });
  });

  group('parseLinks — Markdown links', () {
    test('text + href', () {
      final link = _mdLink('[text](href)');
      expect(link.text, 'text');
      expect(link.href, 'href');
    });

    test('urls, anchors and relative paths are kept whole', () {
      expect(
        _mdLink('[x](https://example.com/a?b=1)').href,
        'https://example.com/a?b=1',
      );
      expect(_mdLink('[x](#Local Heading)').href, '#Local Heading');
      expect(_mdLink('[x](dir/note.md#Heading)').href, 'dir/note.md#Heading');
      expect(_mdLink('[x](note.md)').text, 'x');
    });

    test('empty text or href', () {
      final link = _mdLink('[](href)');
      expect(link.text, '');
      expect(link.href, 'href');
    });

    test('a bare [text] without parentheses is not a link', () {
      expect(parseLinks('[text]'), isEmpty);
    });

    test('images and embeds are not links', () {
      expect(parseLinks('![alt](img.png)'), isEmpty);
      expect(parseLinks('![[embed]]'), isEmpty);
      expect(parseLinks('text ![[embed]] and [[real]]'), hasLength(1));
    });
  });

  group('parseLinks — skipping non-note contexts', () {
    test('fenced code blocks', () {
      const text = '```\n[[not]] [x](y)\n```\n[[yes]]';
      final links = parseLinks(text);
      expect(links, hasLength(1));
      expect((links.single as WikiLink).ref.target, 'yes');
    });

    test('inline code', () {
      const text = '`[[not]]` and `[x](y)` then [[yes]]';
      final links = parseLinks(text);
      expect(links, hasLength(1));
      expect((links.single as WikiLink).ref.target, 'yes');
    });

    test('math blocks', () {
      const text = r'$$ [[not]] $$';
      expect(parseLinks(text), isEmpty);
      const text2 = '\$\$ [[not]] \$\$\n[[yes]]';
      final links = parseLinks(text2);
      expect(links, hasLength(1));
      expect((links.single as WikiLink).ref.target, 'yes');
    });

    test('leading frontmatter', () {
      const text = '---\ntags: [[not]]\nlinks:\n  - [x](y)\n---\n[[yes]]';
      final links = parseLinks(text);
      expect(links, hasLength(1));
      expect((links.single as WikiLink).ref.target, 'yes');
    });

    test('a link in a heading line is still parsed', () {
      final links = parseLinks('# See [[related]]');
      expect((links.single as WikiLink).ref.target, 'related');
    });

    test('multiple links per line keep order', () {
      final links = parseLinks('[[a]] [t](u) [[b|c]]');
      expect(links, hasLength(3));
      expect(links[1], isA<MarkdownLink>());
      expect((links[2] as WikiLink).ref.alias, 'c');
    });
  });
}
