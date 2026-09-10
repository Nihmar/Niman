// T-M2-04: the windowed preview — every Markdown extra renders, only
// visible blocks get laid out, and the CommonMark corpus parses+builds
// without errors.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/preview/code_highlight.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 600, child: child)),
);

/// One box of each state.
const String _tasks = '''
- [ ] pending
- [x] done
''';

/// Short blocks with long line spans: a heading and a display formula each
/// followed by blank lines, so an estimate made from the line count is far
/// bigger than what either draws.
const String _sparse = r'''
# Heading




Prose between the two.

$$
x^2 + y^2 = z^2
$$




Tail.
''';

const String _extras = r'''
# Heading

Paragraph with **bold**, *italic*, ~~strike~~, `inline`, and a [link](https://example.com).

> A quote to end all quotes.

- plain item
- [x] task done
- [ ] task pending

1. ordered first
2. ordered second

| Col A | Col B |
| --- | --- |
| 1 | 2 |

```dart
void main() { print('hi'); }
```

Math stays plain text until T-M2-05: $x^2$ and $$y^2$$.

A footnote reference[^note].

[^note]: The footnote text.
''';

void main() {
  group('MarkdownPreview', () {
    testWidgets('renders the fixture with every extra', (tester) async {
      await tester.pumpWidget(
        _app(
          const MarkdownPreview(
            data: _extras,
            syntaxHighlighter: PreviewCodeHighlighter(
              language: 'dart',
              theme: atomOneLightTheme,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Heading', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Paragraph with bold', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('A quote to end all quotes', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('task done', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('ordered second', findRichText: true),
        findsOneWidget,
      );
      // The table: its "1" cell lands in a separate cell widget below the
      // heading text; the fixture's table must not throw and must render.
      expect(find.textContaining('Col B', findRichText: true), findsOneWidget);
      // Code fence: the highlighter produced a monospace RichText.
      expect(
        find.textContaining('void main()', findRichText: true),
        findsOneWidget,
      );
      // Footnote content renders once (ref + definition).
      expect(
        find.textContaining('The footnote text', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('only visible blocks are laid out (windowing)', (tester) async {
      final long = StringBuffer();
      for (var i = 0; i < 300; i++) {
        long.write('Paragraph number $i with some text to fill a line.\n\n');
      }
      await tester.pumpWidget(_app(MarkdownPreview(data: long.toString())));
      await tester.pump();
      expect(
        find.textContaining('Paragraph number 0', findRichText: true),
        findsOneWidget,
      );
      // Far blocks exist in the parsed widget list but are NOT laid out —
      // the SliverList builds lazily.
      expect(
        find.textContaining('Paragraph number 290', findRichText: true),
        findsNothing,
      );
      // Scrolling brings the far block into the viewport.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Paragraph number 290', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('rebuilds when the data changes', (tester) async {
      await tester.pumpWidget(_app(const MarkdownPreview(data: '# One')));
      await tester.pump();
      expect(find.text('One', findRichText: true), findsOneWidget);
      await tester.pumpWidget(_app(const MarkdownPreview(data: '# Two')));
      await tester.pump();
      expect(find.text('One', findRichText: true), findsNothing);
      expect(find.text('Two', findRichText: true), findsOneWidget);
    });

    testWidgets('the CommonMark corpus parses and builds without errors', (
      tester,
    ) async {
      final json = jsonDecode(
        File('test/spec.json').readAsStringSync(),
      ) as List<dynamic>;
      expect(json.length, 652);
      for (final example in json.cast<Map<String, dynamic>>()) {
        final markdown = example['markdown'] as String;
        await tester.pumpWidget(_app(MarkdownPreview(data: markdown)));
        final error = tester.takeException();
        expect(
          error,
          isNull,
          reason:
              'spec example ${example['example']} '
              '(${example['section']}) crashed: '
              '${markdown.length > 60 ? markdown.substring(0, 60) : markdown}',
        );
      }
    });

    // 2026-09-10 device report: on a note with eight lines of frontmatter
    // the preview sat eight lines ahead of the editor, the whole way down.
    // The frontmatter is not parsed and not drawn, but the editor beside
    // the pane still numbers its lines, so the map has to count them.
    testWidgets('the map answers in the note lines, frontmatter included', (
      tester,
    ) async {
      const note =
          '---\n'
          'id: 1\n'
          'title: Note\n'
          '---\n'
          '\n'
          '# Heading\n'
          '\n'
          'A paragraph.\n';
      final map = ScrollMap();
      await tester.pumpWidget(
        _app(MarkdownPreview(data: note, scrollMap: map)),
      );
      await tester.pump();
      await tester.pump();

      // Two blocks, at the note's own line 5 and line 7.
      expect(map.blockStartLines, [5, 7]);
      expect(map.lineCount, 8);
      expect(map.lineOffset, 4);
      // The heading's line maps above the paragraph's.
      final heading = map.previewOffsetForLine(5, maxExtent: 1000);
      final paragraph = map.previewOffsetForLine(7, maxExtent: 1000);
      expect(heading, isNotNull);
      expect(paragraph! > heading!, isTrue);
      // And back again.
      expect(map.lineForPreviewOffset(paragraph, maxExtent: 1000), 7);
    });

    // 2026-09-10 device report: "there is an enormous amount of padding
    // around the math blocks" — and around headings, and quotes. The
    // sliver forces every block into the extent the map estimated from its
    // line count, and the measuring box relaxed only the *maximum* of that
    // constraint: each block was stretched to its own estimate, reported
    // the stretched height back as its measurement, and kept it.
    testWidgets('a block is laid out at its own height, not its line count', (
      tester,
    ) async {
      final map = ScrollMap();
      await tester.pumpWidget(
        _app(MarkdownPreview(data: _sparse, scrollMap: map)),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Four blocks: heading, prose, formula, tail.
      expect(map.blockStartLines.length, 4);
      // The heading spans six source lines (five of them blank) and the
      // formula five: at the map's 22 px per line that is 132 and 110 px
      // of estimate against about 30 px of ink.
      expect(map.blockHeights[0], lessThan(60));
      expect(map.blockHeights[2], lessThan(60));
      for (var i = 0; i < map.blockHeights.length; i++) {
        expect(
          map.extentFor(i),
          moreOrLessEquals(map.blockHeights[i], epsilon: 0.5),
          reason: 'block $i is laid out at an extent it does not fill',
        );
      }
    });

    // 2026-09-10 device report: the task boxes were invisible in the
    // dark. They were rendered and laid out — painted in
    // `ThemeData.primaryColor`, which a dark theme sets to the surface
    // color, so every box was the color of the page behind it.
    testWidgets('the task boxes are visible against the page', (tester) async {
      for (final brightness in Brightness.values) {
        // A clean tree between the two: the preview builds its widgets
        // once per parse, so reusing the element would keep the styles of
        // the theme before it.
        await tester.pumpWidget(const SizedBox());
        final theme = ThemeData(
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCBA6F7),
            brightness: brightness,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SizedBox(
                height: 400,
                // Keyed per brightness: the preview keeps the widgets it
                // built for the last parse, so an unkeyed swap would show
                // the previous theme's boxes.
                child: MarkdownPreview(key: ValueKey(brightness), data: _tasks),
              ),
            ),
          ),
        );
        await tester.pump();

        final pending = tester.widget<Icon>(
          find.byIcon(Icons.check_box_outline_blank),
        );
        final done = tester.widget<Icon>(find.byIcon(Icons.check_box));
        for (final box in [pending, done]) {
          expect(
            box.color,
            theme.colorScheme.primary,
            reason: 'the box is not the accent in $brightness',
          );
          expect(
            box.color,
            isNot(theme.colorScheme.surface),
            reason: 'the box is the color of the page in $brightness',
          );
        }
      }
    });
  });
}
