// The app's own inline constructs as our parser reads them (`AppSyntax`,
// `docs/dev/block-tree.md` phase 4): the forms of a formula, a wikilink, an
// embed and a tag the notes use, and a code span reading first, holding
// what looks like one. They were the masker's tests.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';

/// The app's constructs and the code spans [text] holds, in order, at any
/// depth, as spans of the text.
List<ExtensionSpan> _spans(String text) {
  final out = <ExtensionSpan>[];
  void walk(List<InlineNode> nodes) {
    for (final node in nodes) {
      final kind = switch (node) {
        MathNode(:final display) =>
          display ? ExtensionKind.displayMath : ExtensionKind.inlineMath,
        WikiLinkNode(:final embed) =>
          embed ? ExtensionKind.embed : ExtensionKind.wikilink,
        TagNode() => ExtensionKind.tag,
        CodeNode() => ExtensionKind.codeSpan,
        _ => null,
      };
      if (kind != null) {
        out.add(
          ExtensionSpan(
            kind: kind,
            start: node.start,
            end: node.end,
            text: text.substring(node.start, node.end),
          ),
        );
      }
      if (node is InlineContainer) walk(node.children);
    }
  }

  walk(InlineParser(text).parse());
  return out;
}

void main() {
  group('inline math', () {
    test('the forms the notes actually use', () {
      for (final text in <String>[
        r'$x$',
        r'$ x $',
        r'$1$',
        r'$2 \times 2$',
        r'$a_{i}$',
        r'$\frac{1}{2}$',
      ]) {
        final spans = _spans(text);
        expect(spans, hasLength(1), reason: text);
        expect(spans.first.kind, ExtensionKind.inlineMath);
        expect(spans.first.text, text);
      }
    });

    test('an escaped dollar is not math', () {
      final spans = _spans(r'costs \$5 and \$10');
      expect(spans, isEmpty);
    });

    test('a dollar as a currency sign is not math', () {
      // A `$` right after a digit opens nothing, and one right before a
      // digit closes nothing: a price either side of its number. Measured
      // on a 945 KB note of 13 004 formulas: none breaks either rule.
      for (final text in <String>[
        r'20$ + 0,10$/Kg x day',
        r'costs $5 and $10',
        r'5$ or 10$',
      ]) {
        expect(_spans(text), isEmpty, reason: text);
      }
      // A formula with digits at its edges is still one.
      expect(_spans(r'so $x = 1$ and $2y$'), hasLength(2));
    });

    test('an unterminated dollar is not math', () {
      expect(_spans(r'a $ and no close'), isEmpty);
    });

    test('two spans in one block', () {
      final spans = _spans(r'$a$ and $b$');
      expect(spans, hasLength(2));
      expect(spans.first.text, r'$a$');
      expect(spans.last.text, r'$b$');
    });

    test('a display pair is not two inline spans', () {
      final spans = _spans(r'$$a = b$$');
      expect(spans, hasLength(1));
      expect(spans.first.kind, ExtensionKind.displayMath);
      expect(spans.first.text, r'$$a = b$$');
    });
  });

  group('wikilinks', () {
    test('every form the app resolves', () {
      final cases = <String, String>{
        '[[Note]]': 'Note',
        '[[Note|alias]]': 'Note|alias',
        '[[Note#Heading]]': 'Note#Heading',
        '[[Note#Heading|alias]]': 'Note#Heading|alias',
        '[[#Heading]]': '#Heading',
        '[[|alias]]': '|alias',
      };
      for (final entry in cases.entries) {
        final spans = _spans(entry.key);
        expect(spans, hasLength(1), reason: entry.key);
        expect(spans.first.kind, ExtensionKind.wikilink);
        expect(spans.first.inner, entry.value);
      }
    });

    test('an embed is an embed, not a link', () {
      final spans = _spans('![[assets/a.png]]');
      expect(spans, hasLength(1));
      expect(spans.first.kind, ExtensionKind.embed);
      expect(spans.first.inner, 'assets/a.png');
    });

    test('an empty reference is not a link', () {
      for (final text in <String>['[[]]', '[[|]]', '[[#]]']) {
        expect(_spans(text), isEmpty, reason: text);
      }
    });

    test('brackets do not nest', () {
      expect(_spans('[[a [b]]]'), isEmpty);
      expect(_spans('[[a\nb]]'), isEmpty);
    });

    test('a wikilink in the middle of prose is found', () {
      final spans = _spans('see [[Note]] for more');
      expect(spans, hasLength(1));
      expect(spans.first.start, 4);
      expect(spans.first.end, 12);
    });
  });

  group('tags', () {
    test('a tag is a tag', () {
      final spans = _spans('a #prova here');
      expect(spans, hasLength(1));
      expect(spans.first.kind, ExtensionKind.tag);
      expect(spans.first.text, '#prova');
    });

    test('a slash and a dash are part of it', () {
      expect(_spans('#a/b-c').first.text, '#a/b-c');
    });

    test('a hash inside a word is not a tag', () {
      expect(_spans('a#b'), isEmpty);
      expect(_spans('issue #42').first.text, '#42');
    });

    test('a heading marker is not a tag', () {
      // A bare `# ` is not a tag: the tag rule needs a word character.
      expect(_spans('# not a tag'), isEmpty);
    });
  });

  group('code spans come first', () {
    test('math inside backticks is not math', () {
      final spans = _spans(r'use `$x$` for that');
      expect(spans, hasLength(1));
      expect(spans.first.kind, ExtensionKind.codeSpan);
      expect(spans.first.text, r'`$x$`');
    });

    test('a wikilink inside backticks is not a link', () {
      final spans = _spans('use `[[Note]]` for that');
      expect(spans.single.kind, ExtensionKind.codeSpan);
    });

    test('a tag inside backticks is not a tag', () {
      expect(_spans('`#notatag`').single.kind, ExtensionKind.codeSpan);
    });

    test('a run of backticks closes at the same run', () {
      final spans = _spans('`` ` `` and `x`');
      expect(spans, hasLength(2));
      expect(spans.first.text, '`` ` ``');
      expect(spans.last.text, '`x`');
    });

    test('an unclosed backtick holds nothing', () {
      expect(_spans('a ` b'), isEmpty);
    });
  });

  test('random text: the spans are in order, and are the text', () {
    final random = Random(20260921);
    const alphabet = <String>[
      'a',
      ' ',
      r'$',
      '[',
      ']',
      '#',
      '`',
      '|',
      '!',
      '\n',
      r'\',
      '_',
      '/',
    ];
    for (var round = 0; round < 400; round++) {
      final length = random.nextInt(40);
      final buffer = StringBuffer();
      for (var i = 0; i < length; i++) {
        buffer.write(alphabet[random.nextInt(alphabet.length)]);
      }
      final text = buffer.toString();
      var previous = 0;
      for (final span in _spans(text)) {
        expect(span.start, greaterThanOrEqualTo(previous), reason: text);
        expect(span.text, text.substring(span.start, span.end), reason: text);
        previous = span.end;
      }
    }
  });
}
