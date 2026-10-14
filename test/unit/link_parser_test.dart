// T-M3-01 AC: link parser — all wikilink forms + Markdown links, edge cases
// (empty, unicode, unclosed), fence/frontmatter skipping, absolute offsets.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/parser.dart';

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

  group('parseWikiRef — block links (#844)', () {
    test('#^id is a block, not a heading', () {
      final ref = parseWikiRef('Note#^37066d');
      expect(ref.target, 'Note');
      expect(ref.block, '37066d');
      expect(ref.heading, isNull, reason: 'a fragment is one or the other');
      expect(ref.fragment, '^37066d');
    });

    test('a heading is still a heading', () {
      final ref = parseWikiRef('Note#Heading');
      expect(ref.heading, 'Heading');
      expect(ref.block, isNull);
      expect(ref.fragment, 'Heading');
    });

    test('an id keeps its letters, digits and dashes verbatim', () {
      expect(parseWikiRef('Note#^a-b').block, 'a-b');
      expect(parseWikiRef('Note#^Quote-2').block, 'Quote-2');
      expect(parseWikiRef('#^only-here').block, 'only-here');
      expect(parseWikiRef('#^only-here').target, '');
    });

    test('a caret that is not an id stays a heading', () {
      expect(parseWikiRef('Note#^').heading, '^');
      expect(parseWikiRef('Note#^two words').heading, '^two words');
      expect(parseWikiRef('Note#^ünï').heading, '^ünï');
      expect(parseWikiRef('Note#^two words').block, isNull);
    });

    test('the alias rides along and the display text drops the fragment', () {
      final ref = parseWikiRef('Note#^id1|the idea');
      expect(ref.block, 'id1');
      expect(ref.alias, 'the idea');
      expect(wikiDisplayText('Note#^id1'), 'Note');
      expect(wikiDisplayText('Note#Heading'), 'Note');
      expect(wikiDisplayText('Note#^id1|the idea'), 'the idea');
    });

    test('a block link is a link of its own in a document', () {
      final link = parseLinks('See [[Note#^37066d]] now').single as WikiLink;
      expect(link.ref.block, '37066d');
      expect(parseLinks('[[#^37066d]]'), hasLength(1));
    });
  });

  group('parseWikiRef — heading paths (#845)', () {
    test('every # after the first is a level of the path', () {
      final ref = parseWikiRef('Note#H1#H2');
      expect(ref.target, 'Note');
      expect(ref.heading, 'H1#H2', reason: 'kept whole, as it was written');
      expect(ref.headingPath, ['H1', 'H2']);
      expect(ref.fragment, 'H1#H2');
    });

    test('the same note, nested: [[#A#B]]', () {
      final ref = parseWikiRef('#A#B');
      expect(ref.target, '');
      expect(ref.headingPath, ['A', 'B']);
    });

    test('levels are trimmed and an empty one dropped', () {
      expect(parseWikiRef('Note# A # B ').headingPath, ['A', 'B']);
      expect(parseWikiRef('Note#A##B').headingPath, ['A', 'B']);
      expect(parseWikiRef('Note#A#').headingPath, ['A']);
      expect(parseWikiRef('Note').headingPath, isEmpty);
    });

    test('a single heading is a path of one', () {
      expect(parseWikiRef('Note#Heading').headingPath, ['Heading']);
    });

    test('the alias is cut before the path', () {
      final ref = parseWikiRef('Note#A#B|shown');
      expect(ref.headingPath, ['A', 'B']);
      expect(ref.alias, 'shown');
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

    test('embeds are skipped unless asked for, and marked when kept', () {
      const text = 'a [[note]] ![[pic.png]] ![alt](pic.png) [x](a.md)';
      expect(parseLinks(text), hasLength(2)); // the wikilink and [x](a.md)
      final kept = parseLinks(text, includeEmbeds: true);
      expect(kept, hasLength(4));
      final embed = kept[1] as WikiLink;
      expect(embed.embed, isTrue);
      expect(text.substring(embed.start, embed.end), '![[pic.png]]');
      final image = kept[2] as MarkdownLink;
      expect(image.embed, isTrue);
      expect(image.text, 'alt');
      expect(image.href, 'pic.png');
      expect(text.substring(image.start, image.end), '![alt](pic.png)');
      expect((kept[0] as WikiLink).embed, isFalse);
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

    test('a title is not part of the href, whatever its quoting (#917)', () {
      for (final title in ['"A title"', "'A title'", '(A title)']) {
        final link = _mdLink('[x](docs/a.md $title)');
        expect(link.href, 'docs/a.md', reason: title);
        expect(link.title, title, reason: title);
        expect(link.angled, isFalse);
      }
      final angled = _mdLink('[x](<docs/a b.md> "T")');
      expect(angled.href, 'docs/a b.md');
      expect(angled.angled, isTrue);
      expect(angled.title, '"T"');
      expect(_mdLink('[x](a.md)').title, isNull);
    });

    test('an image keeps its title apart from its href (#917)', () {
      final image = parseLinks('![p](pic.png "T")', includeEmbeds: true).single;
      expect((image as MarkdownLink).href, 'pic.png');
      expect(image.title, '"T"');
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

  // What the read view and the export both show for a wikilink.
  test('a wikilink shows its alias, else its target, else what is written', () {
    expect(wikiDisplayText('Note|Shown'), 'Shown');
    expect(wikiDisplayText('Note#Part|Shown'), 'Shown');
    expect(wikiDisplayText('Note#Part'), 'Note');
    expect(wikiDisplayText(' Note '), 'Note');
    expect(wikiDisplayText('Note| '), 'Note');
    expect(wikiDisplayText('#Part'), '#Part');
  });
}
