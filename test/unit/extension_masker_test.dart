// The extension masker: what a block's own constructs are, that the masked text
// is the same length as the source, and that the spans put it back byte for
// byte. The last two are the properties the parser bridge depends on.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/masked_block.dart';

const ExtensionMasker _masker = ExtensionMasker();

/// Puts [masked] back together from the spans, to prove nothing was lost.
String _restore(MaskedBlock masked) {
  final buffer = StringBuffer();
  var at = 0;
  for (final span in masked.spans) {
    buffer
      ..write(masked.text.substring(at, span.start))
      ..write(span.text);
    at = span.end;
  }
  return buffer.toString() + masked.text.substring(at);
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
        final masked = _masker.mask(text);
        expect(masked.spans, hasLength(1), reason: text);
        expect(masked.spans.first.kind, ExtensionKind.inlineMath);
        expect(masked.spans.first.text, text);
      }
    });

    test('an escaped dollar is not math', () {
      final masked = _masker.mask(r'costs \$5 and \$10');
      expect(masked.spans, isEmpty);
    });

    test('an unterminated dollar is not math', () {
      expect(_masker.mask(r'a $ and no close').spans, isEmpty);
    });

    test('two spans in one block', () {
      final masked = _masker.mask(r'$a$ and $b$');
      expect(masked.spans, hasLength(2));
      expect(masked.spans.first.text, r'$a$');
      expect(masked.spans.last.text, r'$b$');
    });

    test('a display pair is not two inline spans', () {
      final masked = _masker.mask(r'$$a = b$$');
      expect(masked.spans, hasLength(1));
      expect(masked.spans.first.kind, ExtensionKind.displayMath);
      expect(masked.spans.first.text, r'$$a = b$$');
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
        final masked = _masker.mask(entry.key);
        expect(masked.spans, hasLength(1), reason: entry.key);
        expect(masked.spans.first.kind, ExtensionKind.wikilink);
        expect(masked.spans.first.inner, entry.value);
      }
    });

    test('an embed is an embed, not a link', () {
      final masked = _masker.mask('![[assets/a.png]]');
      expect(masked.spans, hasLength(1));
      expect(masked.spans.first.kind, ExtensionKind.embed);
      expect(masked.spans.first.inner, 'assets/a.png');
    });

    test('an empty reference is not a link', () {
      for (final text in <String>['[[]]', '[[|]]', '[[#]]']) {
        expect(_masker.mask(text).spans, isEmpty, reason: text);
      }
    });

    test('brackets do not nest', () {
      expect(_masker.mask('[[a [b]]]').spans, isEmpty);
      expect(_masker.mask('[[a\nb]]').spans, isEmpty);
    });

    test('a wikilink in the middle of prose is found', () {
      final masked = _masker.mask('see [[Note]] for more');
      expect(masked.spans, hasLength(1));
      expect(masked.spans.first.start, 4);
      expect(masked.spans.first.end, 12);
    });
  });

  group('tags', () {
    test('a tag is a tag', () {
      final masked = _masker.mask('a #prova here');
      expect(masked.spans, hasLength(1));
      expect(masked.spans.first.kind, ExtensionKind.tag);
      expect(masked.spans.first.text, '#prova');
    });

    test('a slash and a dash are part of it', () {
      expect(_masker.mask('#a/b-c').spans.first.text, '#a/b-c');
    });

    test('a hash inside a word is not a tag', () {
      expect(_masker.mask('a#b').spans, isEmpty);
      expect(_masker.mask('issue #42').spans.first.text, '#42');
    });

    test('a heading marker is not a tag', () {
      // The bridge strips heading markers before masking; a bare `# ` is not a
      // tag either way, because the tag rule needs a word character.
      expect(_masker.mask('# not a tag').spans, isEmpty);
    });
  });

  group('code spans come first', () {
    test('math inside backticks is not math', () {
      final masked = _masker.mask(r'use `$x$` for that');
      expect(masked.spans, hasLength(1));
      expect(masked.spans.first.kind, ExtensionKind.codeSpan);
      expect(masked.spans.first.text, r'`$x$`');
    });

    test('a wikilink inside backticks is not a link', () {
      final masked = _masker.mask('use `[[Note]]` for that');
      expect(masked.spans.single.kind, ExtensionKind.codeSpan);
    });

    test('a tag inside backticks is not a tag', () {
      expect(
        _masker.mask('`#notatag`').spans.single.kind,
        ExtensionKind.codeSpan,
      );
    });

    test('a run of backticks closes at the same run', () {
      final masked = _masker.mask('`` ` `` and `x`');
      expect(masked.spans, hasLength(2));
      expect(masked.spans.first.text, '`` ` ``');
      expect(masked.spans.last.text, '`x`');
    });

    test('an unclosed backtick masks nothing', () {
      expect(_masker.mask('a ` b').spans, isEmpty);
    });
  });

  group('the masking keeps every offset', () {
    test('the masked text is the same length', () {
      for (final text in <String>[
        r'a $x$ b',
        'see [[Note]] and #tag',
        r'`$x$` and $y$',
        'nothing at all',
        '',
      ]) {
        final masked = _masker.mask(text);
        expect(masked.text.length, text.length, reason: text);
      }
    });

    test('the unmasked characters are untouched', () {
      const text = r'a $x$ b [[N]] c #t d';
      final masked = _masker.mask(text);
      for (var at = 0; at < text.length; at++) {
        if (masked.spanAt(at) != null) continue;
        if (at > 0 && masked.spanAt(at - 1) != null) continue;
        expect(masked.text[at], text[at], reason: 'at $at');
      }
    });

    test('the spans are in order and do not overlap', () {
      const text = r'$a$ [[N]] #t `c` $d$';
      final masked = _masker.mask(text);
      var previous = 0;
      for (final span in masked.spans) {
        expect(span.start, greaterThanOrEqualTo(previous));
        expect(span.end, greaterThan(span.start));
        previous = span.end;
      }
    });

    test('spanAt finds each span and nothing between them', () {
      const text = r'a $x$ b [[N]] c';
      final masked = _masker.mask(text);
      expect(masked.spanAt(0), isNull);
      expect(masked.spanAt(2)?.kind, ExtensionKind.inlineMath);
      expect(masked.spanAt(4)?.kind, ExtensionKind.inlineMath);
      expect(masked.spanAt(5), isNull);
      expect(masked.spanAt(8)?.kind, ExtensionKind.wikilink);
      expect(masked.spanAt(text.length - 1), isNull);
    });

    test('the source comes back from the spans', () {
      for (final text in <String>[
        r'a $x$ b',
        'see [[Note|alias]] and ![[img.png]] and #tag',
        r'`$x$` $y$ **bold** _i_',
        'plain',
        '',
        r'$$\frac{1}{2}$$',
      ]) {
        expect(_restore(_masker.mask(text)), text, reason: text);
      }
    });
  });

  test('random text keeps both properties', () {
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
      final masked = _masker.mask(text);
      expect(masked.text.length, text.length, reason: 'length on $text');
      expect(_restore(masked), text, reason: 'restore on $text');
      var previous = 0;
      for (final span in masked.spans) {
        expect(span.start, greaterThanOrEqualTo(previous), reason: text);
        previous = span.end;
      }
    }
  });
}
