// Our inline parser stays linear on `cmark`'s pathological inputs
// (`test/pathological_tests.py`): each runs at two sizes, four times apart,
// and the larger may take a bounded multiple of the smaller's time — a
// quadratic parse takes sixteen times as long, a linear one four.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';

/// The inputs, by name, each made from a size: `cmark`'s, scaled down.
final Map<String, String Function(int n)> _cases = {
  'nested strong emphasis': (n) => '${'*a **a ' * n}b${' a** a*' * n}',
  'emphasis closers with no openers': (n) => 'a_ ' * n,
  'emphasis openers with no closers': (n) => '_a ' * n,
  'openers of three': (n) => 'a***' * n,
  'link closers with no openers': (n) => 'a]' * n,
  'link openers with no closers': (n) => '[a' * n,
  'mismatched openers and closers': (n) => '*a_ ' * n,
  'openers and closers multiple of 3': (n) => 'a**b${'c* ' * n}',
  'link openers and emphasis closers': (n) => '[ a_' * n,
  'pattern [ (](': (n) => '[ (](' * n,
  'pattern ![[]()': (n) => '![[]()' * n,
  'nested brackets': (n) => '${'[' * n}a${']' * n}',
  // Runs of every length up to m: m²/2 characters, so m grows as √n.
  'backticks': (n) =>
      [for (var i = 1; i < sqrt(n * 8).round(); i++) 'e${'`' * i}'].join(),
  'unclosed links A': (n) => '[a](<b' * n,
  'unclosed links B': (n) => '[a](b' * n,
  'unclosed comments': (n) => '<!--' * n,
  'unclosed processing instruction': (n) => '<?${'a' * n}',
  'unclosed processing instructions, spaced': (n) => '<? ' * n,
  'unclosed processing instructions, with words': (n) => '<? ${'ab ' * n}',
  'unclosed processing instruction openers': (n) => '<?' * n,
  'unclosed CDATA': (n) => '<![CDATA[${'a ' * n}',
  'unclosed CDATA openers': (n) => '<![CDATA[ ' * n,
  'CDATA closed past a NUL': (n) => '${'<![CDATA[ ' * n}\x00]]>',
  'many links in unclosed brackets': (n) => '${'[' * n}${'[a](b) ' * n}',
  'a run of closing parentheses': (n) => 'http://a.b/${')' * n}',
  // The app's own syntax (docs/records/block-tree.md, phase 4).
  'dollars no closing one answers': (n) => r'$1 ' * n,
  'unclosed display math': (n) => r'$$a ' * n,
  'unclosed wikilinks': (n) => '[[a ' * n,
  'tags': (n) => '#a ' * n,
  'highlight openers with no closers': (n) => '==a ' * n,
  'underlines with no closing tag': (n) => '<u>a ' * n,
  'math between emphasis': (n) => r'*a $b_c$ ' * n,
};

/// The fastest of three parses of [text], in microseconds.
int _time(String text) {
  var best = 1 << 62;
  for (var round = 0; round < 3; round++) {
    final watch = Stopwatch()..start();
    InlineParser(text).parse();
    final elapsed = watch.elapsedMicroseconds;
    if (elapsed < best) best = elapsed;
  }
  return best;
}

void main() {
  for (final MapEntry(key: name, value: make) in _cases.entries) {
    test('$name is linear', () {
      // Warm the parser up, so the first size does not pay for it.
      InlineParser(make(500)).parse();
      final small = _time(make(2000));
      final large = _time(make(8000));
      // Four times the input; linear is about four times the time. Eight
      // leaves room for the noise of a shared machine, and is still half
      // what a quadratic parse would take.
      expect(
        large,
        lessThan(small * 8 + 2000),
        reason: '$name: ${small}us at n, ${large}us at 4n',
      );
    });
  }

  test(
    'an unclosed processing instruction or CDATA does not freeze a parse',
    () {
      // The pattern for them took 45 s on `<![CDATA[` and forty characters.
      for (final text in [
        '<![CDATA[${'a' * 60}',
        '<![CDATA[${'a ' * 30}',
        'In XML a <![CDATA[ section holds raw text, and no end',
        'PHP opens with <?php echo \$x; and nothing closes it ${'ab ' * 20}',
      ]) {
        final watch = Stopwatch()..start();
        InlineParser(text).parse();
        expect(watch.elapsedMilliseconds, lessThan(500), reason: text);
      }
    },
  );

  test('a processing instruction and a CDATA section end at their first '
      'closer', () {
    String html(String md) => TreeHtml(md).render();
    expect(html('a <?php echo 1; ?> b'), '<p>a <?php echo 1; ?> b</p>\n');
    // The pattern read `??>` as a body of `?` + `?` + `>` and found no end.
    expect(html('a <?x??> b'), '<p>a <?x??> b</p>\n');
    expect(
      html('a <![CDATA[ x ]] y ]]> b'),
      '<p>a <![CDATA[ x ]] y ]]> b</p>\n',
    );
    expect(html('a <?x'), '<p>a &lt;?x</p>\n');
    expect(html('a <![CDATA[x ]]'), '<p>a &lt;![CDATA[x ]]</p>\n');
    // A second opener after a first that found no closer.
    expect(html('x <?a <?b'), '<p>x &lt;?a &lt;?b</p>\n');
    expect(html('a <?b ?> <?c'), '<p>a <?b ?> &lt;?c</p>\n');
  });

  test('emphasis nested thousands deep is parsed and written', () {
    // Without recursion, in the parser and in the HTML: a recursive walk
    // overflowed the stack.
    const n = 20000;
    final html = TreeHtml('${'*a **a ' * n}b${' a** a*' * n}').render();
    expect(html, startsWith('<p><em>a <strong>a <em>a'));
  });
}
