// T-M2-06 M-06-1/2: BlockLocator matches the parser's top-level blocks, and
// ScrollMap answers the line↔offset queries.
import 'dart:convert';

import 'package:copist/src/preview/math_syntax.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

List<String> _lines(String text) => const LineSplitter().convert(text);

List<md.Node> _astBlocks(String source) {
  final document = md.Document(
    blockSyntaxes: [
      const MathBlockSyntax(),
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    ],
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  return document.parseLines(_lines(stripFrontmatter(source)));
}

const String _coverage = r'''
# Heading

A paragraph with a bit of text.

- one
- two

1. ordered
2. next

> quoted text
> still quoted

```dart
void main() {}
```

| A | B |
| --- | --- |
| 1 | 2 |

$$
x^2
$$

Single-line $$y^2$$.

---

Last paragraph.
''';

void main() {
  group('BlockLocator', () {
    test('matches the parser block count over the coverage fixture', () {
      final locator = BlockLocator().locate(_lines(_coverage));
      final ast = _astBlocks(_coverage);
      expect(locator.length, ast.length);
    });

    test('the sources mapped by line stay consistent', () {
      final map = ScrollMap()..rebuild(_coverage);
      final ast = _astBlocks(_coverage);
      expect(map.blockStartLines.length, ast.length);
      // First block at line 0, blocks strictly increasing, all in range.
      expect(map.blockStartLines.first, 0);
      for (var i = 1; i < map.blockStartLines.length; i++) {
        expect(map.blockStartLines[i], greaterThan(map.blockStartLines[i - 1]));
      }
      expect(map.blockStartLines.last, lessThan(_lines(_coverage).length));
    });

    test('display math and fences are one block each', () {
      final starts = BlockLocator().locate(
        _lines('before\n\n\$\$\nx\n\$\$\nafter'),
      );
      final ast = _astBlocks('before\n\n\$\$\nx\n\$\$\nafter');
      expect(starts.length, ast.length);
    });

    test('inline math never creates a block', () {
      const source = r'just $x$ here';
      final starts = BlockLocator().locate(_lines(source));
      final ast = _astBlocks(source);
      expect(starts.length, ast.length);
    });
  });

  group('ScrollMap', () {
    test('line → block and proportional offsets', () {
      final map = ScrollMap()
        ..rebuild(List.generate(40, (i) => 'line $i').join('\n\n'));
      expect(map.blockStartLines.length, 40);
      expect(map.blockForLine(0), 0);
      final offset = map.previewOffsetForLine(20, maxExtent: 1000);
      expect(offset, greaterThan(0));
    });

    test('offset → line round-trips approximately', () {
      final map = ScrollMap()
        ..rebuild(List.generate(40, (i) => 'line $i').join('\n\n'));
      // 79 lines (40 paragraphs, 39 separators); half of the content = the
      // middle line, blank separators count as lines.
      final line = map.lineForPreviewOffset(500, maxExtent: 1000);
      expect(line, 39);
    });

    test('ready only once every block is measured', () {
      final map = ScrollMap()..rebuild('a\n\nb\n\nc');
      expect(map.isReady, isFalse);
      for (var i = 0; i < map.blockStartLines.length; i++) {
        map.measure(i, 20);
      }
      expect(map.isReady, isTrue);
    });

    test('is ready for a single-paragraph source with measurement', () {
      final map = ScrollMap()
        ..rebuild('only paragraph')
        ..measure(0, 12);
      expect(map.isReady, isTrue);
      expect(map.previewOffsetForLine(0, maxExtent: 100), 0);
    });
  });
}
