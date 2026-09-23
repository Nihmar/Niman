// `live` and the read view are one page: the same note, drawn the same, one
// of them editable. What is held here is what the reader sees move when the
// pane flips — a glyph that is not where it was.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A note whose second paragraph wraps in any pane this file uses.
final String _note =
    'caret\n\nplain words\n\n${List.filled(40, 'wrapping').join(' ')}\n';

/// Pumps [_note] in `live`, or in the read view when [read].
Future<void> _pump(
  WidgetTester tester, {
  required bool read,
  required bool numbers,
  required NoteColumn column,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => read
              ? MarkdownReadView(
                  buffer: SourceBuffer.fromText(_note),
                  parser: BlockParser(),
                  mathCache: MathCache(),
                  column: column,
                  lineNumbers: numbers,
                )
              : MarkdownSurface(
                  buffer: SourceBuffer.fromText(_note),
                  mode: MarkdownSurfaceMode.live,
                  theme: markdownThemeOf(context),
                  selection: const SelectionModel.at(0),
                  showLineNumbers: numbers,
                  column: column,
                ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Where the glyph at [offset] of the paragraph that starts with [start] is
/// drawn, globally.
Offset _glyph(WidgetTester tester, String start, int offset) {
  final paragraph = tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .firstWhere((p) => p.text.toPlainText().startsWith(start));
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )
      .first;
  return paragraph.localToGlobal(Offset(box.left, box.top));
}

/// Pumps [note] in `live`, the caret on its first line, or in the read view
/// when [read]; no numbers, no column.
Future<void> _pumpNote(
  WidgetTester tester,
  String note, {
  required bool read,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => read
              ? MarkdownReadView(
                  buffer: SourceBuffer.fromText(note),
                  parser: BlockParser(),
                  mathCache: MathCache(),
                )
              : MarkdownSurface(
                  buffer: SourceBuffer.fromText(note),
                  mode: MarkdownSurfaceMode.live,
                  theme: markdownThemeOf(context),
                  selection: const SelectionModel.at(0),
                  showLineNumbers: false,
                  mathCache: MathCache(),
                ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Where the first glyph of [word] is drawn, in whichever paragraph has it.
Offset _glyphOf(WidgetTester tester, String word) {
  for (final paragraph in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    final at = paragraph.text.toPlainText().indexOf(word);
    if (at < 0) continue;
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: at, extentOffset: at + 1),
        )
        .first;
    return paragraph.localToGlobal(Offset(box.left, box.top));
  }
  throw StateError('"$word" is not on screen');
}

/// The first offset of the paragraph starting with [start] that is drawn on
/// its second row.
int _wrap(WidgetTester tester, String start) {
  final first = _glyph(tester, start, 0).dy;
  var at = 1;
  while (_glyph(tester, start, at).dy <= first) {
    at++;
  }
  return at;
}

void main() {
  for (final numbers in [false, true]) {
    for (final (name, column) in [
      ('full width', NoteColumn.off),
      ('a column', const NoteColumn(width: 500)),
    ]) {
      testWidgets('the text starts and wraps where it does in live '
          '(${numbers ? 'numbers' : 'no numbers'}, $name)', (tester) async {
        // The read view set its text 16 px in from each side; `live`, with
        // no column, 5 px — past the numbers when they were on — and 5 px
        // from the right: the text moved and wrapped elsewhere each time
        // the pane flipped.
        tester.view.physicalSize = const Size(900, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(tester, read: false, numbers: numbers, column: column);
        final live = _glyph(tester, 'plain', 0).dx;
        final liveWrap = _wrap(tester, 'wrapping');
        await _pump(tester, read: true, numbers: numbers, column: column);
        expect(_glyph(tester, 'plain', 0).dx, closeTo(live, 0.01));
        expect(_wrap(tester, 'wrapping'), liveWrap);
      });
    }
  }

  testWidgets("each construct's text starts where it does in live", (
    tester,
  ) async {
    // A heading's hidden `#` left its space behind, 6 px of the heading's
    // size before the title in `live`; and a list's text stood a tenth of a
    // pixel short of the read view's, which sets a paragraph's first glyph
    // half an ambient letter spacing in; and a quote's text stood its bar's
    // width further in, in the read view, than past the bar in `live`; and
    // a code block's code stood a padding further in, in its box, than on
    // `live`'s page, which drew no box; and an indented block's code stood
    // its four spaces further in, in `live`, which drew them.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note =
        'caret\n\n# Heading one\n\n## Heading two\n\n- bullet\n- [ ] task\n'
        '  - nested\n\n1. numbered\n\n> quoted\n>\n> > deeper\n\n'
        '```dart\nfenced();\n```\n\n    indented();\n      deeper();\n';
    const words = [
      'Heading one',
      'Heading two',
      'bullet',
      'task',
      'nested',
      'quoted',
      'deeper',
      'fenced',
      'indented',
      'deeper()',
    ];
    Future<List<double>> lefts({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      return [for (final word in words) _glyphOf(tester, word).dx];
    }

    final live = await lefts(read: false);
    final read = await lefts(read: true);
    for (var at = 0; at < words.length; at++) {
      expect(read[at], closeTo(live[at], 0.01), reason: words[at]);
    }
  });

  testWidgets("each construct's text stands as far down as it does in live", (
    tester,
  ) async {
    // The read view gave a blank line 1 em and left a spacing of 1 em under
    // every block, where `live` draws a blank line as one of its rows, 1.5 em,
    // and leaves nothing under a block: every construct past the first stood
    // higher or lower than it did a pane flip before, and further off the
    // further down the note it was. A rule, one pixel in the read view, is a
    // row in `live` with the rule across its middle. A code block's box had
    // a padding of 0.6 em above and below its code, where `live` has a
    // fence's row.
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note =
        'caret\n\n# Heading one\n\n## Heading two\npara under\n\n\n'
        'after two\n\n- bullet\n- [ ] task\n  - nested\n\n- loose\n\n'
        '1. numbered\n\n---\n\nruled\n\n> quoted\n>\n> > deeper\n\n'
        '```dart\nfenced();\nsecond();\n```\nafter code\n\n```\n```\n'
        'after empty\n\n```\nnever closed\n```\n\n\$\$\nx^2\n\$\$\n\n'
        'after math\n';
    const words = [
      'Heading one',
      'Heading two',
      'para under',
      'after two',
      'bullet',
      'task',
      'nested',
      'loose',
      'numbered',
      'ruled',
      'quoted',
      'deeper',
      'fenced',
      'second',
      'after code',
      'after empty',
      'never closed',
      'after math',
    ];
    Future<List<double>> tops({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      final origin = _glyphOf(tester, 'caret').dy;
      return [for (final word in words) _glyphOf(tester, word).dy - origin];
    }

    final live = await tops(read: false);
    final read = await tops(read: true);
    for (var at = 0; at < words.length; at++) {
      expect(read[at], closeTo(live[at], 0.01), reason: words[at]);
    }
  });

  testWidgets('a row whose text is all hidden is a row, in live', (
    tester,
  ) async {
    // A rule's row and a quote's empty line are all marks, hidden: the row
    // was laid out as nothing while the list gave it its room, so the rule
    // was drawn at the top of its row, not across its middle where the read
    // view draws it, and the quote's bar broke off at the empty line.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note = 'caret\n\n---\n\n> quoted\n>\n> more\n';
    await _pumpNote(tester, note, read: false);
    final theme = markdownThemeOf(tester.element(find.byType(Scaffold)));
    final row = theme.lineHeight;
    final origin = _glyphOf(tester, 'caret').dy;
    final rows = [
      for (final element in find.byType(CustomPaint).evaluate())
        if ((element.widget as CustomPaint).painter
            case final LiveDecorationPainter painter)
          (painter.shape, tester.getRect(find.byWidget(element.widget))),
    ];
    for (final (_, rect) in rows) {
      expect(rect.height, closeTo(row, 0.01));
    }
    final rule = rows.firstWhere((row) => row.$1.rule).$2.center.dy - origin;

    await _pumpNote(tester, note, read: true);
    final drawn = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == theme.rule,
      ),
    );
    expect(drawn.center.dy - _glyphOf(tester, 'caret').dy, closeTo(rule, 0.01));
  });
  testWidgets("a code block's box stands where it does in live", (
    tester,
  ) async {
    // `live` drew a code block's rows on the page, where the read view drew a
    // box with a padding of 0.6 em above and below its code: the box is now
    // `live`'s rows, its fences' rows its top and bottom, in both modes.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note = 'caret\n\n```dart\nfenced();\n```\n\nlast\n';
    Future<Rect> box({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      final background = markdownThemeOf(tester.element(find.byType(Scaffold)))
          .codeBackground;
      final origin = _glyphOf(tester, 'caret');
      if (read) {
        return tester
            .getRect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).color == background,
              ),
            )
            .shift(-origin);
      }
      final rows = [
        for (final element in find.byType(CustomPaint).evaluate())
          if ((element.widget as CustomPaint).painter
              case final LiveDecorationPainter painter
              when painter.shape.code != null)
            tester.getRect(find.byWidget(element.widget)),
      ];
      return Rect.fromLTRB(
        rows.first.left,
        rows.first.top,
        rows.last.right,
        rows.last.bottom,
      ).shift(-origin);
    }

    final live = await box(read: false);
    final read = await box(read: true);
    expect(read.top, closeTo(live.top, 0.01), reason: 'the top');
    expect(read.bottom, closeTo(live.bottom, 0.01), reason: 'the bottom');
    expect(read.right, closeTo(live.right, 0.01), reason: 'the right edge');
  });

  testWidgets("a code block's code is coloured as it is in live", (
    tester,
  ) async {
    // `live` drew every row of code in one muted colour, where the read view
    // highlights the block by the language its fence names: a pane flip
    // recoloured the code. A comment over two rows is coloured on both, the
    // block being highlighted whole in both modes.
    const lines = ['var name = "text"; // note', '/* one', 'two */ var x;'];
    final note = 'caret\n\n```dart\n${lines.join('\n')}\n```\n';
    Future<List<Color?>> colours({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      final out = <Color?>[];
      for (final line in lines) {
        final paragraph = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .firstWhere((p) => p.text.toPlainText().contains(line));
        final at = paragraph.text.toPlainText().indexOf(line);
        for (var offset = at; offset < at + line.length; offset++) {
          out.add(_colourAt(paragraph.text, offset));
        }
      }
      return out;
    }

    final live = await colours(read: false);
    final read = await colours(read: true);
    expect(live.toSet().length, greaterThan(2), reason: 'coloured at all');
    expect(live, read);
  });

  testWidgets("a quote's content stands where it does in live", (tester) async {
    // `live` saw a quote as one block and drew its every line as quoted
    // prose, where the read view reads the content again as blocks: a
    // heading inside a quote was set small, a list's next line stood on
    // the quote's column rather than under its item's text, and a code block
    // had no box, its fences drawn and its code in the quote's font.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note =
        'caret\n\n> # Quoted heading\n>\n> - item one\n>   continued line\n'
        '> - item two\n>\n> ```dart\n> var x = 1;\n> ```\n>\n'
        '>     indented in quote\n\nafter\n';
    const words = [
      'Quoted heading',
      'item one',
      'continued',
      'item two',
      'var x',
      'indented in',
      'after',
    ];
    Future<List<Offset>> places({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      final origin = _glyphOf(tester, 'caret');
      return [for (final word in words) _glyphOf(tester, word) - origin];
    }

    final live = await places(read: false);
    final read = await places(read: true);
    for (var at = 0; at < words.length; at++) {
      expect(read[at].dx, closeTo(live[at].dx, 0.01), reason: words[at]);
      expect(read[at].dy, closeTo(live[at].dy, 0.01), reason: words[at]);
    }
  });

  testWidgets('an HTML block stands where it does in live', (tester) async {
    // The read view drew an HTML block's source in a box with a padding all
    // round, its lines four spaces short; `live` drew the source as rows on
    // the page. Both draw it in a code block's box now, a row per line.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note =
        'caret\n\n<div>\n    <span>inner</span>\n</div>\n\nafter html\n';
    const words = ['<div>', 'inner', '</div>', 'after html'];
    Future<List<Offset>> places({required bool read}) async {
      await _pumpNote(tester, note, read: read);
      final origin = _glyphOf(tester, 'caret');
      return [for (final word in words) _glyphOf(tester, word) - origin];
    }

    final live = await places(read: false);
    final read = await places(read: true);
    for (var at = 0; at < words.length; at++) {
      expect(read[at].dx, closeTo(live[at].dx, 0.01), reason: words[at]);
      expect(read[at].dy, closeTo(live[at].dy, 0.01), reason: words[at]);
    }
  });
}

/// The colour the character at [offset] of [root]'s text is drawn in, the
/// styles above it inherited.
Color? _colourAt(InlineSpan root, int offset) {
  var seen = 0;
  Color? found;
  bool walk(InlineSpan span, Color? inherited) {
    if (span is! TextSpan) {
      seen++;
      return false;
    }
    final colour = span.style?.color ?? inherited;
    final text = span.text;
    if (text != null) {
      if (offset < seen + text.length) {
        found = colour;
        return true;
      }
      seen += text.length;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      if (walk(child, colour)) return true;
    }
    return false;
  }

  walk(root, null);
  return found;
}
