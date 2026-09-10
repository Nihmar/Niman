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

    test('offset → line walks the block heights', () {
      final map = ScrollMap()
        ..rebuild(List.generate(40, (i) => 'line $i').join('\n\n'));
      // No block measured yet: each spans 2 lines at the 22 px default, so
      // 500 px is block 11's middle — around line 22, not the 39 a pure
      // line fraction of the extent would say.
      expect(map.lineForPreviewOffset(500, maxExtent: 1000), 22);
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

    test('measured heights win over the line fraction (images, math)', () {
      // Three paragraphs; the middle one is ten times as tall as the
      // others (an image or a display-math block). The line fraction would
      // put the last paragraph at ~80% of the extent; the measured map
      // puts it right after the tall block.
      final map = ScrollMap()..rebuild('one\n\ntall\n\nthree');
      expect(map.blockStartLines.length, 3);
      map
        ..measure(0, 100)
        ..measure(1, 1000)
        ..measure(2, 100);

      // Content: 100 + 1000 before the last block = 1100 px. A pure line
      // fraction of the extent would say 1600.
      expect(map.previewOffsetForLine(4, maxExtent: 2000), 1100);
      // Inside the tall block, half its height is its second line.
      expect(
        map.lineForPreviewOffset(600, maxExtent: 2000),
        inInclusiveRange(2, 3),
      );
    });

    test('unmeasured blocks are estimated from the measured average', () {
      // Four blocks, spans 2/2/2/1 lines: the two measured ones give
      // (40 + 20) / 4 = 15 px per source line, so the third block (2 lines)
      // estimates at 30 px and the fourth at 15: line 6 starts 90 px in.
      final map = ScrollMap()
        ..rebuild('a\n\nb\n\nc\n\nd')
        ..measure(0, 40)
        ..measure(1, 20);
      expect(map.previewOffsetForLine(6, maxExtent: 1000), 90);
    });

    test('a re-parse keeps the heights of blocks that did not move', () {
      // Every typing pause re-parses and rebuilds the map: without carrying
      // the measurements over, the preview re-measured every block on
      // screen (T-PP-22).
      final map = ScrollMap()
        ..rebuild('a\n\nb')
        ..measure(0, 40)
        ..measure(1, 20);
      expect(map.isReady, isTrue);

      map.rebuild('a\n\nb');
      expect(map.isReady, isTrue, reason: 'no re-learn for identical starts');
      expect(map.blockHeights.take(2), [40, 20]);
    });

    test('a block whose start line moved is measured again', () {
      // The measurements come first, then the re-parse: a paragraph
      // inserted above b and c shifts their start lines, so only the
      // block that still starts on line 0 carries its height.
      final map = ScrollMap()
        ..rebuild('a\n\nb\n\nc')
        ..measure(0, 10)
        ..measure(1, 20)
        ..measure(2, 30)
        ..rebuild('a\n\nextra\n\nb\n\nc');
      expect(map.blockStartLines, [0, 2, 4, 6]);
      expect(map.blockHeights.first, 10);
      // The starts 0, 2 and 4 still exist, so their heights carry over —
      // including the one now holding the inserted paragraph, which the
      // next layout corrects. Only the block at line 6 is unmeasured.
      expect(map.blockHeights.where((height) => height > 0).length, 3);
      expect(map.isReady, isFalse);
    });

    test('a re-measure replaces the old height in the average', () {
      // Not 120: the block's second measurement is the one that counts.
      final map = ScrollMap()
        ..rebuild('a\n\nb')
        ..measure(0, 100)
        ..measure(0, 20);
      expect(map.previewOffsetForLine(2, maxExtent: 1000), 20);
    });
  });
}
