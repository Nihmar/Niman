// What a reader sees of a block: which characters are syntax and which are
// text, and what the innermost construct covering each of them is. This is the
// mapping `read` mode renders from, so most of this file checks the *text*
// rather than the styles — a marker left in, or a character lost, is the bug
// that would show up on screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';

/// The visible view of the first block of [document].
VisibleText _visible(String document, {int index = 0}) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  final parsed = BlockParser().parse(scanner.index.blocks[index], buffer);
  return VisibleText.of(parsed);
}

/// The `kind:text` of each visible segment.
List<String> _segments(String document) {
  final visible = _visible(document);
  return <String>[
    for (final segment in visible.segments) _describe(visible, segment),
  ];
}

/// One segment as `kind:text`.
String _describe(VisibleText visible, VisibleSegment segment) {
  final text = visible.text.substring(segment.start, segment.end);
  return '${segment.kind.name}:$text';
}

void main() {
  group('the markers come out', () {
    test('plain text is all of it', () {
      expect(_visible('just words').plainText, 'just words');
    });

    test('strong and emphasis, both spellings', () {
      for (final source in <String>[
        'a **bold** b',
        'a __bold__ b',
        'a *it* b',
        'a _it_ b',
      ]) {
        expect(
          _visible(source).plainText,
          'a bold b'.replaceAll(
            'bold',
            source.contains('bold') ? 'bold' : 'it',
          ),
          reason: source,
        );
      }
    });

    test('strikethrough', () {
      expect(_visible('a ~~gone~~ b').plainText, 'a gone b');
    });

    test('a link keeps its text and drops its destination', () {
      final visible = _visible('see [the note](https://example.com) now');
      expect(visible.plainText, 'see the note now');
      final link = visible.segments.firstWhere(
        (segment) => segment.kind == StyleKind.link,
      );
      expect(visible.text.substring(link.start, link.end), 'the note');
      expect(link.href, 'https://example.com');
    });

    test('an image keeps its alt text, for the renderer to draw it', () {
      final visible = _visible('an ![alt](a.png) here');
      expect(visible.plainText, 'an alt here');
      final image = visible.segments.firstWhere(
        (segment) => segment.kind == StyleKind.image,
      );
      expect(visible.text.substring(image.start, image.end), 'alt');
      expect(image.href, 'a.png');
    });

    test('a heading keeps its text', () {
      expect(_visible('# A title').plainText, 'A title');
      expect(_visible('## Two').plainText, 'Two');
      expect(_visible('# Closed ###').plainText, 'Closed');
    });

    test('a code span is drawn, and is read as its own text', () {
      final visible = _visible('use `code` here');
      expect(visible.plainText, 'use code here');
      expect(visible.replaced.single.kind, ExtensionKind.codeSpan);
    });
  });

  group('the spans drawn rather than typed', () {
    test('math is drawn, and read as its tex', () {
      final visible = _visible(r'a $x_i$ b');
      expect(visible.replaced.single.kind, ExtensionKind.inlineMath);
      expect(visible.plainText, 'a x_i b');
    });

    test('a wikilink is drawn, with its marker out of the text', () {
      final visible = _visible('see [[Note|alias]] now');
      expect(visible.replaced.single.kind, ExtensionKind.wikilink);
      expect(visible.plainText, 'see Note|alias now');
    });

    test('a tag is drawn as its own text', () {
      final visible = _visible('a #prova here');
      expect(visible.plainText, 'a #prova here');
      expect(visible.replaced.single.kind, ExtensionKind.tag);
    });

    test('an embed is drawn', () {
      final visible = _visible('before ![[assets/a.png]] after');
      expect(visible.replaced.single.kind, ExtensionKind.embed);
      expect(visible.plainText, 'before assets/a.png after');
    });
  });

  group('nesting is the innermost construct', () {
    test('emphasis inside strong', () {
      expect(_segments('**a *b* c**'), <String>[
        'strong:a ',
        'emphasis:b',
        'strong: c',
      ]);
    });

    test('a link inside strong keeps its own kind', () {
      // The strong run's own text either side of the link is empty, so the only
      // visible segment is the link's.
      expect(_segments('**[see](u)**'), <String>['link:see']);
      expect(_visible('**[see](u)**').plainText, 'see');
      expect(_segments('**a [see](u) b**'), <String>[
        'strong:a ',
        'link:see',
        'strong: b',
      ]);
    });

    test('a code span inside strong is drawn', () {
      final visible = _visible('**a `x` b**');
      expect(visible.plainText, 'a x b');
      expect(visible.replaced.single.kind, ExtensionKind.codeSpan);
    });
  });

  group('the segments are sound', () {
    test('they are in order, inside the text, and never on a marker', () {
      const document = r'''
# A title with **bold** and `code`

A paragraph with *emphasis*, a [link](u), an ![image](i.png), a [[wikilink]],
inline math $x$ and a #tag.
''';
      final buffer = SourceBuffer.fromText(document);
      final scanner = BlockScanner(buffer);
      final parser = BlockParser();
      for (final block in scanner.index.blocks) {
        final parsed = parser.parse(block, buffer);
        final visible = VisibleText.of(parsed);
        var previous = 0;
        for (final segment in visible.segments) {
          expect(segment.start, greaterThanOrEqualTo(previous));
          expect(segment.end, greaterThan(segment.start));
          expect(segment.end, lessThanOrEqualTo(visible.text.length));
          previous = segment.end;
        }
        // Nothing visible is a marker character of its own construct: `*`, `#`
        // and backticks never appear in the plain text of this document.
        expect(visible.plainText, isNot(contains('*')));
        expect(visible.plainText, isNot(contains('`')));
      }
    });

    test('a malformed construct shows as written rather than losing text', () {
      // A link the parser did not close as a link, an emphasis with no pair.
      for (final source in <String>['a [half', 'a * b', 'a ** b']) {
        expect(_visible(source).plainText, source, reason: source);
      }
    });
  });
}
