// One block, drawn: the renderer's mapping from a block to a widget. The
// assertions are mostly about *text* — a marker left in, or a line lost, is
// what a reader would see — plus one per widget kind that has no text of its
// own (a rule, a code box, a table).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// The document drawn as a column of blocks, the way the read view will.
Widget _view(String document, MathCache cache) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  final parser = BlockParser();
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final theme = markdownThemeOf(context);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final block in scanner.index.blocks)
                  BlockView(
                    parsed: parser.of(block, buffer),
                    theme: theme,
                    mathCache: cache,
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// The text on screen, with the widgets' own text joined.
String _screenText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final widget in tester.allWidgets) {
    if (widget is Text) {
      final data = widget.data;
      if (data != null) buffer.write(data);
      final span = widget.textSpan;
      if (span != null) buffer.write(span.toPlainText());
    }
  }
  return buffer.toString();
}

void main() {
  testWidgets('the markers are not on screen', (tester) async {
    await tester.pumpWidget(
      _view(
        '# A title\n\nsome **bold** and *italic* and `code` text\n\n'
        'a [link](https://example.com) and ~~gone~~',
        _syncCache(),
      ),
    );
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('A title'));
    expect(screen, contains('bold'));
    expect(screen, contains('italic'));
    expect(screen, contains('link'));
    expect(screen, isNot(contains('**')));
    expect(screen, isNot(contains('~~')));
    expect(screen, isNot(contains('https://example.com')));
    // The code span's backticks are gone, its text is not.
    expect(screen, contains('code'));
    expect(screen, isNot(contains('`code`')));
  });

  testWidgets('a fence is drawn as code, without its fence', (tester) async {
    await tester.pumpWidget(
      _view('before\n\n```dart\nfinal x = 1;\n```\n\nafter', _syncCache()),
    );
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('final x = 1;'));
    expect(screen, isNot(contains('```')));
    expect(screen, contains('before'));
    expect(screen, contains('after'));
  });

  testWidgets('a rule is drawn as a line', (tester) async {
    await tester.pumpWidget(_view('a\n\n---\n\nb', _syncCache()));
    await tester.pump();
    expect(_screenText(tester), contains('a'));
    expect(_screenText(tester), contains('b'));
    // The break is a coloured box rather than text; `---` is nowhere on screen.
    expect(find.byType(ColoredBox), findsWidgets);
    expect(_screenText(tester), isNot(contains('---')));
  });

  testWidgets('a list keeps its marker and its text', (tester) async {
    await tester.pumpWidget(_view('- one\n- two\n\n1. three', _syncCache()));
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('-'));
    expect(screen, contains('one'));
    expect(screen, contains('two'));
    expect(screen, contains('three'));
  });

  testWidgets('a quote is drawn, with its bar', (tester) async {
    await tester.pumpWidget(_view('> quoted text', _syncCache()));
    await tester.pump();
    expect(_screenText(tester), contains('quoted text'));
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('a formula is typeset rather than shown', (tester) async {
    await tester.pumpWidget(_view(r'a $x^2$ b', _syncCache()));
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('a'));
    expect(screen, contains('b'));
    expect(screen, isNot(contains(r'$x^2$')));
  });

  testWidgets('a table is a table', (tester) async {
    await tester.pumpWidget(
      _view('| a | b |\n|---|---|\n| 1 | 2 |', _syncCache()),
    );
    await tester.pump();
    expect(find.byType(Table), findsOneWidget);
    final screen = _screenText(tester);
    expect(screen, contains('a'));
    expect(screen, contains('2'));
    expect(screen, isNot(contains('---')));
  });

  testWidgets('a table cell renders its own inline markup', (tester) async {
    await tester.pumpWidget(
      _view(
        '| **head** | `code` |\n|---|---|\n| a [link](u) | ~~gone~~ |',
        _syncCache(),
      ),
    );
    await tester.pump();
    final screen = _screenText(tester);
    // The cell's markup is rendered, not shown: the words are there, the
    // markers are not, and the link's destination is gone.
    expect(screen, contains('head'));
    expect(screen, contains('code'));
    expect(screen, contains('link'));
    expect(screen, contains('gone'));
    expect(screen, isNot(contains('**')));
    expect(screen, isNot(contains('~~')));
    expect(screen, isNot(contains('](u)')));
  });

  testWidgets('the frontmatter is metadata, not prose', (tester) async {
    await tester.pumpWidget(
      _view('---\ntitle: A note\n---\n\nbody text', _syncCache()),
    );
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('body text'));
    expect(screen, isNot(contains('title: A note')));
  });

  testWidgets('a wikilink shows its alias, not its brackets', (tester) async {
    await tester.pumpWidget(_view('see [[Note|the alias]] now', _syncCache()));
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('the alias'));
    expect(screen, isNot(contains('[[')));
    expect(screen, isNot(contains(']]')));
  });
}
