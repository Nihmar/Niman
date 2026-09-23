// One block, drawn: the renderer's mapping from a block to a widget. The
// assertions are mostly about *text* — a marker left in, or a line lost, is
// what a reader would see — plus one per widget kind that has no text of its
// own (a rule, a code box, a table).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:path/path.dart' as p;

import '../fakes/item_mark_finder.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// The document drawn as a column of blocks, the way the read view will.
Widget _view(
  String document,
  MathCache cache, {
  Future<String?> Function(String target)? resolve,
  double scale = 1,
}) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  final parser = BlockParser();
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        // The note's size, as the note view sets it around the read view.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Builder(
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
                        embedResolver: resolve,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
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

/// The style [text] is drawn in, as the paragraph resolves it: each span's
/// own style over the ones above it.
TextStyle _styleOf(WidgetTester tester, String text) {
  for (final widget in tester.allWidgets) {
    if (widget is! Text || widget.textSpan == null) continue;
    TextStyle? found;
    void visit(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is TextSpan) {
        if (found == null && (span.text ?? '').contains(text)) found = style;
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      }
    }

    visit(widget.textSpan!, widget.style ?? const TextStyle());
    if (found != null) return found!;
  }
  throw StateError('"$text" is not on screen');
}

void main() {
  testWidgets("a heading's words are drawn at the heading's size", (
    tester,
  ) async {
    await tester.pumpWidget(
      _view('# A title with *stress*\n\nbody text', _syncCache()),
    );
    await tester.pump();
    final context = tester.element(find.byType(Scaffold));
    final theme = markdownThemeOf(context);
    final title = _styleOf(tester, 'A title');
    expect(title.fontSize, theme.heading1.fontSize);
    expect(title.fontWeight, theme.heading1.fontWeight);
    final stress = _styleOf(tester, 'stress');
    expect(stress.fontSize, theme.heading1.fontSize);
    expect(stress.fontStyle, FontStyle.italic);
    expect(_styleOf(tester, 'body text').fontSize, theme.body.fontSize);
  });

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
    // The marker is drawn as `live` draws it: a painted bullet whatever the
    // note wrote, and an ordered item keeps its number.
    expect(findBullet(), findsNWidgets(2));
    expect(screen, contains('1.'));
    expect(screen, contains('one'));
    expect(screen, contains('two'));
    expect(screen, contains('three'));
  });

  testWidgets("an item's next line is its text, and its marker is not", (
    tester,
  ) async {
    // A second line indented to the item's text left the parse guessing:
    // the item was drawn as `- one` with its next line's spaces kept.
    await tester.pumpWidget(
      _view('- one\n  two\n- [ ] three\n  four', _syncCache()),
    );
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('one\ntwo'));
    expect(screen, contains('three\nfour'));
    expect(screen, isNot(contains('- ')));
    expect(screen, isNot(contains('[ ]')));
  });

  testWidgets("a task's box and a number's gap grow with the note's text", (
    tester,
  ) async {
    // The note's size is a scaler, which scales the text as it is laid out
    // and nothing else: the box and the gap stayed at 100% beside text twice
    // as big, and so did the column they sit in.
    Future<(double, double, double)> drawn(double scale) async {
      await tester.pumpWidget(
        _view('- [ ] task\n\n1. one', _syncCache(), scale: scale),
      );
      await tester.pump();
      final box = itemMarkOf(tester.widget(findCheckbox(ticked: false)))!.em;
      final number = tester.getRect(find.text('1.'));
      final text = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText() == 'one');
      final gap = text.localToGlobal(Offset.zero).dx - number.right;
      final column = text.localToGlobal(Offset.zero).dx;
      return (box, gap, column);
    }

    final (box, gap, column) = await drawn(1);
    final (bigBox, bigGap, bigColumn) = await drawn(2);
    expect(bigBox, closeTo(box * 2, 0.01));
    expect(bigGap, closeTo(gap * 2, 0.01));
    expect(bigColumn, closeTo(column * 2, 0.01));
  });

  testWidgets("a bullet and a box sit mid-column, on their text's first row", (
    tester,
  ) async {
    // Where `live` puts them: centred in the column that ends where the
    // item's text begins, on the row of its first line — a glyph and an
    // icon stood at the column's left, each at its own baseline.
    await tester.pumpWidget(_view('- one\n- [x] two', _syncCache()));
    await tester.pump();
    for (final (mark, text) in [
      (findBullet(), 'one'),
      (findCheckbox(ticked: true), 'two'),
    ]) {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText() == text);
      final left = paragraph.localToGlobal(Offset.zero).dx;
      final column = tester.getRect(mark);
      expect(column.right, closeTo(left, 0.01), reason: text);
      expect(
        itemMarkOf(tester.widget(mark))!.row,
        closeTo(
          paragraph.getFullHeightForCaret(const TextPosition(offset: 0)),
          0.01,
        ),
        reason: text,
      );
    }
  });

  testWidgets("a list's numbers end at one edge, clear of the text", (
    tester,
  ) async {
    // A `10.` is wider than the marker column: it wrapped to two rows, and
    // the numbers of a long list did not line up.
    final items = [for (var at = 1; at <= 10; at++) '$at. item $at'];
    await tester.pumpWidget(_view(items.join('\n'), _syncCache()));
    await tester.pump();

    /// Where [text] is drawn: from its first character to past its last,
    /// as tall as its paragraph.
    Rect paragraphOf(String text) {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText() == text);
      Offset at(int offset) => paragraph.localToGlobal(
        paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero),
      );
      final start = at(0);
      return Rect.fromLTRB(
        start.dx,
        start.dy,
        at(text.length).dx,
        start.dy + paragraph.size.height,
      );
    }

    final nine = paragraphOf('9.');
    final ten = paragraphOf('10.');
    final tenText = paragraphOf('item 10');
    expect(ten.height, closeTo(nine.height, 0.5), reason: 'one row');
    expect(ten.right, closeTo(nine.right, 0.5), reason: 'numbers align');
    expect(ten.right, lessThan(tenText.left), reason: 'clear of the text');
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

  testWidgets('an embed is a picture when it resolves', (tester) async {
    // Synchronous on purpose: a widget test's clock is fake, so a real
    // `await` on file IO never completes inside the test body.
    final directory = Directory.systemTemp.createTempSync('niman_embed');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File(p.join(directory.path, 'pixel.png'))
      ..writeAsBytesSync(_onePixelPng);

    await tester.pumpWidget(
      _view(
        'before ![[pixel.png]] after',
        _syncCache(),
        resolve: (target) async => target == 'pixel.png' ? file.path : null,
      ),
    );
    await tester.pump();
    await tester.pump();
    // Resolved and drawn: the image is in the tree, and the note's own words
    // are not standing in for it.
    expect(find.byType(Image), findsWidgets);
    expect(_screenText(tester), isNot(contains('![[pixel.png]]')));
  });

  testWidgets("an embed that resolves to nothing keeps the note's words", (
    tester,
  ) async {
    await tester.pumpWidget(
      _view(
        'before ![[missing.png]] after',
        _syncCache(),
        resolve: (target) async => null,
      ),
    );
    await tester.pump();
    final screen = _screenText(tester);
    expect(screen, contains('![[missing.png]]'));
    // The rest of the paragraph is still there: an unresolvable embed is not
    // a reason to lose the line.
    expect(screen, contains('before'));
    expect(screen, contains('after'));
  });

  testWidgets('an embed of a note is not a broken image', (tester) async {
    await tester.pumpWidget(
      _view(
        'see ![[another-note.md]] here',
        _syncCache(),
        resolve: (target) async => '/nowhere/another-note.md',
      ),
    );
    await tester.pump();
    expect(_screenText(tester), contains('![[another-note.md]]'));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a Markdown image is a picture when it resolves', (tester) async {
    final directory = Directory.systemTemp.createTempSync('niman_image');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File(p.join(directory.path, 'pixel.png'))
      ..writeAsBytesSync(_onePixelPng);

    await tester.pumpWidget(
      _view(
        'before ![the alt](pixel.png) after',
        _syncCache(),
        resolve: (target) async => target == 'pixel.png' ? file.path : null,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    // The alt text stands in for a picture only when there is no picture.
    expect(_screenText(tester), isNot(contains('the alt')));
    expect(_screenText(tester), contains('before'));
  });

  testWidgets("a Markdown image with nothing to draw keeps the note's words", (
    tester,
  ) async {
    await tester.pumpWidget(
      _view(
        'before ![the alt](missing.png) after',
        _syncCache(),
        resolve: (target) async => null,
      ),
    );
    await tester.pump();
    // `![alt](src)` as it was written, not `![[alt]]`: a Markdown image shows
    // the spelling the note used.
    expect(_screenText(tester), contains('![the alt](missing.png)'));
    expect(_screenText(tester), contains('after'));
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

/// A one-pixel PNG, so an embed test needs no fixture on disk.
final List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];
