// T-M2-04: the windowed preview — every Markdown extra renders, only
// visible blocks get laid out, and the CommonMark corpus parses+builds
// without errors.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/preview/code_highlight.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 600, child: child)),
);

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
  });
}
