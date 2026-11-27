// A bare URL is one link with its whole address: the app's tags and formulas
// are not read inside it (#1325). The GFM autolink pass runs after the
// parse, so a `#top` or a `$` the parser cut out of the text cut the link.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';

/// The links of [text], as their destination.
List<String> _hrefs(String text) {
  final out = <String>[];
  void walk(List<InlineNode> nodes) {
    for (final node in nodes) {
      if (node is LinkNode) out.add(node.destination);
      if (node is InlineContainer) walk(node.children);
    }
  }

  walk(InlineParser(text).parse());
  return out;
}

bool _holds<T extends InlineNode>(String text) {
  var found = false;
  void walk(List<InlineNode> nodes) {
    for (final node in nodes) {
      if (node is T) found = true;
      if (node is InlineContainer) walk(node.children);
    }
  }

  walk(InlineParser(text).parse());
  return found;
}

void main() {
  group('one link, with the whole address', () {
    for (final (text, href) in [
      ('https://x.com/#top', 'https://x.com/#top'),
      ('see https://x.com/#top now', 'https://x.com/#top'),
      ('www.x.com/#top', 'http://www.x.com/#top'),
      ('https://x/#/route', 'https://x/#/route'),
      ('https://app/#/route?a=1#b', 'https://app/#/route?a=1#b'),
      (r'https://x/$a/$b', r'https://x/$a/$b'),
      ('https://x.com/page#top', 'https://x.com/page#top'),
      ('(https://x.com/#top)', 'https://x.com/#top'),
      ('ftp://x.com/#top', 'ftp://x.com/#top'),
    ]) {
      test(text, () {
        expect(_hrefs(text), [href]);
        expect(_holds<TagNode>(text), isFalse);
        expect(_holds<MathNode>(text), isFalse);
      });
    }

    test('exported as one anchor', () {
      expect(
        TreeHtml('https://x.com/#top').render(),
        '<p><a href="https://x.com/#top">https://x.com/#top</a></p>\n',
      );
    });
  });

  group('the app syntax stays where no address is', () {
    test('a tag after a space is a tag', () {
      expect(_holds<TagNode>('https://x.com/ #top'), isTrue);
      expect(_holds<TagNode>('#top https://x.com/'), isTrue);
      expect(_hrefs('https://x.com/ #top'), ['https://x.com/']);
    });

    test('a tag after a comma-less word, and a formula, are read', () {
      expect(_holds<TagNode>('see #top'), isTrue);
      expect(_holds<MathNode>(r'a $x$ b'), isTrue);
      expect(_holds<MathNode>(r'https://x.com/ $x$'), isTrue);
    });

    test('a word that only looks like an address is prose', () {
      // No scheme boundary: a letter before it.
      expect(_holds<TagNode>('xhttps://a.b/#top'), isTrue);
    });
  });

  test('a long address with many hashes and dollars stays linear', () {
    String make(int n) => 'https://x.com/${r'/#a$b'.padRight(4) * n}';
    int time(String text) {
      final watch = Stopwatch()..start();
      InlineParser(text).parse();
      return watch.elapsedMicroseconds;
    }

    time(make(500));
    var small = 1 << 62;
    var large = 1 << 62;
    for (var round = 0; round < 3; round++) {
      final a = time(make(2000));
      final b = time(make(8000));
      if (a < small) small = a;
      if (b < large) large = b;
    }
    expect(large, lessThan(small * 8 + 2000), reason: '${small}us, ${large}us');
  });
}
