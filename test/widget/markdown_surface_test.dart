// The one surface in its two modes (#245, #246), and the property that makes
// them
// one widget: the same note, the same offsets, one flag between them.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show boxSizePx;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_inline_math.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// [_theme] with a list column as wide, for the test font, as a text face's
/// is: every glyph of the test font is as wide as it is tall, so a `- ` is
/// 28 px of it and a third of that in a text face.
const MarkdownTheme _wideColumns = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 80,
  // A `> ` in the test font is 28 wide: 16 leaves it 12 to hang into the
  // numbers' gap, which is 14 and all the room there is past the numbers.
  quoteIndentPerLevel: 16,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// The shape of a `- [ ] …` line.
const LineShape _task = LineShape(marker: 0, box: 2, task: false);

void main() {
  Future<MarkdownSourceViewState> pumpMode(
    WidgetTester tester,
    MarkdownSurfaceMode mode, {
    int? caret = 3,
    String text = '# Titolo\n\ntesto\n',
    MarkdownTheme theme = _theme,
    bool lineNumbers = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: SourceBuffer.fromText(text),
            mode: mode,
            theme: theme,
            // A caret the caller holds, or `null` for a surface that owns its
            // own — the two contracts a caller can have, and the reveal has to
            // hold for both.
            selection: caret == null ? null : SelectionModel.at(caret),
            showLineNumbers: lineNumbers,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
  }

  testWidgets('both modes are the same surface', (tester) async {
    for (final mode in MarkdownSurfaceMode.values) {
      await pumpMode(tester, mode);
      expect(
        find.byType(MarkdownSourceView),
        findsOneWidget,
        reason: '$mode is the source surface underneath',
      );
      expect(find.byType(MarkdownSurface), findsOneWidget);
    }
  });

  testWidgets("live shows a code block's code, and hides its fences", (
    tester,
  ) async {
    // A fence's content lines were tokens of the fence, and the fence is a
    // marker: `live` hid the code itself, a blank where the block was, until
    // the caret went into it.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n```dart\ncode line\n```\n\n    indented code\n',
    );
    final spans = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;
    for (final code in ['code line', 'indented code']) {
      final drawn = spans.where((span) => span.text!.contains(code));
      expect(drawn, isNotEmpty, reason: code);
      expect(drawn.any(hidden), isFalse, reason: '$code is the note');
    }
    final fences = spans.where((span) => span.text!.startsWith('```'));
    expect(fences, isNotEmpty);
    expect(fences.every(hidden), isTrue, reason: 'the fences are syntax');
  });

  testWidgets('live hides the marker, source shows it', (tester) async {
    // The caret is *off* the heading's line: the markers are hidden
    // everywhere except where the writer is, which is the policy
    // (`docs/dev/unified-surface.md` §8.6.2) and is tested by the reveal test
    // below.
    Future<List<TextSpan>> spansAfter(MarkdownSurfaceMode mode) async {
      await pumpMode(tester, mode, caret: 10);
      final spans = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        widget.text.visitChildren((span) {
          if (span is TextSpan) spans.add(span);
          return true;
        });
      }
      return spans;
    }

    final shown = await spansAfter(MarkdownSurfaceMode.source);
    final hidden = await spansAfter(MarkdownSurfaceMode.live);
    expect(
      shown.any((span) => span.text == '#' && span.style?.fontSize != 0.01),
      isTrue,
      reason: 'source draws the hash at its own size, as the note was written',
    );
    expect(
      // With the space after it: a heading's prefix is hidden whole.
      hidden.any((span) => span.text == '# ' && span.style?.fontSize == 0.01),
      isTrue,
      reason: 'live draws it invisible and taking no room',
    );
  });

  testWidgets('live hides the inline markers, and keeps what they mark', (
    tester,
  ) async {
    Future<List<TextSpan>> spansOf(MarkdownSurfaceMode mode) async {
      await pumpMode(
        tester,
        mode,
        caret: 30,
        text: 'a **bold** and [a link](u)\n\nsecond line\n',
      );
      final spans = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        widget.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
      }
      return spans;
    }

    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;
    final live = await spansOf(MarkdownSurfaceMode.live);
    for (final marker in ['**', '[', '](u)']) {
      final drawn = live.where((span) => span.text == marker);
      expect(drawn, isNotEmpty, reason: '"$marker" is drawn');
      expect(
        drawn.every(hidden),
        isTrue,
        reason: '"$marker" is syntax, and live hides it',
      );
    }
    for (final text in ['bold', 'a link']) {
      expect(
        live.any((span) => span.text == text && !hidden(span)),
        isTrue,
        reason: '"$text" is what the syntax marks, and stays',
      );
    }
    final source = await spansOf(MarkdownSurfaceMode.source);
    expect(source.where((span) => span.text == '**').any(hidden), isFalse);
  });

  testWidgets('==highlight== is marked, its markers hidden in live (#279)', (
    tester,
  ) async {
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\na ==marked== word\n',
    );
    final spans = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;
    final markers = spans.where((span) => span.text == '==');
    expect(markers, hasLength(2));
    expect(markers.every(hidden), isTrue, reason: 'live hides the markers');
    final marked = spans.singleWhere((span) => span.text == 'marked');
    expect(hidden(marked), isFalse);
    expect(marked.style?.backgroundColor, isNotNull, reason: 'it is marked');
  });

  testWidgets("a callout's mark is hidden in live, shown under the caret", (
    tester,
  ) async {
    const text = 'caret\n\n> [!tip] Title\n> body\n';
    Future<List<TextSpan>> spansWith(int caret) async {
      await pumpMode(
        tester,
        MarkdownSurfaceMode.live,
        caret: caret,
        text: text,
      );
      final spans = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        widget.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
      }
      return spans;
    }

    bool hidden(TextSpan span) => (span.style?.fontSize ?? 14) < 1;
    final away = await spansWith(0);
    // Drawn as room, a glyph of no size a character: the icon stands there.
    final mark = away.where((span) => span.text == 'x' * '[!tip] '.length);
    expect(mark, hasLength(1));
    expect(mark.single.style?.fontSize, 0.01);
    expect(mark.single.style?.letterSpacing, greaterThan(0));
    expect(away.any((span) => span.text!.contains('[!tip]')), isFalse);
    expect(
      away.any((span) => span.text!.contains('Title') && !hidden(span)),
      isTrue,
    );
    final on = await spansWith(text.indexOf('Title') + 1);
    expect(
      on.any((span) => span.text!.contains('[!tip]') && !hidden(span)),
      isTrue,
      reason: 'the caret on the title line shows the mark as written',
    );
  });

  testWidgets('live hides the tags the toolbar writes, and draws them', (
    tester,
  ) async {
    // `<u>` and `<sup>` are what the underline and superscript buttons
    // write; `live` showed them as the tags they are.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\na <u>under</u> and x<sup>2</sup>\n',
    );
    final spans = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;
    for (final tag in ['<u>', '</u>', '<sup>', '</sup>']) {
      expect(
        spans.where((span) => span.text == tag).every(hidden),
        isTrue,
        reason: '"$tag" is syntax',
      );
    }
    final under = spans.singleWhere((span) => span.text == 'under');
    expect(under.style?.decoration, TextDecoration.underline);
    expect(hidden(under), isFalse);
  });

  // 2026-09-24 report: from source to live and back the caret kept the
  // place and the height it had, over a line drawn another way.
  testWidgets('a mode switch measures the caret again', (tester) async {
    const text = '# Hello\n\nSome text.\n';
    final buffer = SourceBuffer.fromText(text);
    const caret = 5; // # Hel|lo
    Future<MarkdownSourceViewState> pump(MarkdownSurfaceMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: buffer,
              mode: mode,
              theme: _theme,
              selection: const SelectionModel.at(caret),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      );
    }

    /// Where the caret belongs on the line as it is drawn now.
    Rect expected() {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().contains('Hello'));
      const position = TextPosition(offset: caret);
      final at = paragraph.getOffsetForCaret(position, Rect.zero);
      return Rect.fromLTWH(
        at.dx,
        at.dy,
        0,
        paragraph.getFullHeightForCaret(position),
      ).shift(paragraph.localToGlobal(Offset.zero));
    }

    final first = await pump(MarkdownSurfaceMode.live);
    for (final mode in [MarkdownSurfaceMode.source, MarkdownSurfaceMode.live]) {
      final state = await pump(mode);
      expect(identical(state, first), isTrue, reason: 'the same surface');
      final want = expected();
      final got = state.caretRect!;
      expect(got.left, closeTo(want.left, 0.5), reason: '$mode: its place');
      expect(got.height, closeTo(want.height, 0.5), reason: '$mode: height');
    }
  });

  testWidgets(
    'the caret is drawn where its character is, on an indented line',
    (tester) async {
      // `live` indents a list item and a quote; the caret was measured in the
      // paragraph and drawn over the box around it, an indent to the left.
      // The task's marks are wider than its column, and hang left of it.
      for (final (note, caret, wide) in [
        ('caret\n\n- item\n', 11, false),
        ('caret\n\n> quoted\n', 12, false),
        ('caret\n\n- [ ] task\n', 15, true),
      ]) {
        final state = await pumpMode(
          tester,
          MarkdownSurfaceMode.live,
          caret: caret,
          text: note,
          theme: wide ? _wideColumns : _theme,
          lineNumbers: wide,
        );
        await tester.pump();
        final box = tester
            .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
            .singleWhere(
              (paint) =>
                  paint.foregroundPainter.runtimeType.toString() ==
                  '_CaretPainter',
            );
        final at = state.caretRect!;
        final expected = Rect.fromPoints(
          box.globalToLocal(at.topLeft),
          box.globalToLocal(at.bottomRight),
        );
        // A quote's bar is painted too: the caret is the rect at the caret.
        expect(
          box,
          paints..something((method, arguments) {
            if (method != #drawRect) return false;
            final drawn = arguments.first as Rect;
            return (drawn.left - expected.left).abs() < 0.5 &&
                (drawn.top - expected.top).abs() < 0.5 &&
                (drawn.height - expected.height).abs() < 0.5;
          }),
          reason: note,
        );
      }
    },
  );

  testWidgets("a line's text stays put when the caret reveals its marks", (
    tester,
  ) async {
    // The revealed marks are set into the indent where the bullet and the
    // gap past the bar were: the text jumped right by their width every time
    // the caret came onto the line (device screenshot 2026-09-23). Marks
    // wider than their column — a task's `- [ ] `, a `10. `, and in the test
    // font, whose glyphs are as wide as they are tall, even a `- ` — hang
    // out into the margin left of the text instead.
    /// Where the glyph after [prefix] is drawn on the line starting with it,
    /// and where the line's first glyph is.
    Future<(double, double)> textLeft(
      String note,
      int caret,
      String prefix,
    ) async {
      await pumpMode(
        tester,
        MarkdownSurfaceMode.live,
        caret: caret,
        text: note,
        // The numbers' gutter keeps the fold arrows' gap empty: the margin
        // marks wider than their column hang into.
        theme: _wideColumns,
        lineNumbers: true,
      );
      await tester.pump();
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
      double glyph(int offset) => paragraph
          .localToGlobal(
            Offset(
              paragraph
                  .getBoxesForSelection(
                    TextSelection(baseOffset: offset, extentOffset: offset + 1),
                  )
                  .first
                  .left,
              0,
            ),
          )
          .dx;
      return (glyph(prefix.length), glyph(0));
    }

    for (final (note, prefix) in [
      ('caret\n\n- item\n', '- '),
      ('caret\n\n- [ ] task\n', '- [ ] '),
      ('caret\n\n10. ten\n', '10. '),
      ('caret\n\n- item\n  - [ ] deep\n', '  - [ ] '),
      ('caret\n\n> quoted\n', '> '),
    ]) {
      final line = note.indexOf(prefix, 7);
      final (away, _) = await textLeft(note, 0, prefix);
      final (on, first) = await textLeft(
        note,
        line + prefix.length + 1,
        prefix,
      );
      expect(on, closeTo(away, 0.01), reason: note);
      final surface = tester.getRect(find.byType(MarkdownSurface));
      expect(first, greaterThanOrEqualTo(surface.left), reason: note);
    }
    // Wider than the margin too: the text moves by what is left over, and
    // the marks stay on the surface.
    const note = 'caret\n\n1000000. far\n';
    final (away, _) = await textLeft(note, 0, '1000000. ');
    final (on, first) = await textLeft(note, 18, '1000000. ');
    expect(on, greaterThan(away));
    expect(
      first,
      greaterThanOrEqualTo(tester.getRect(find.byType(MarkdownSurface)).left),
    );
  });
  testWidgets("a bullet sits on its text's row, not on the hidden marker", (
    tester,
  ) async {
    // The marker is set in a hundredth of a size, and the row read off it
    // stood on the baseline with no height: bullets and numbers were drawn
    // below the text they belong to.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- item\n1. first\n',
    );
    for (final prefix in ['- ', '1. ']) {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
      final slot = liveItemSlot(paragraph, const LineShape(marker: 0), _theme);
      final text = TextPosition(offset: prefix.length);
      final top = paragraph.getOffsetForCaret(text, Rect.zero).dy;
      final height = paragraph.getFullHeightForCaret(text);
      expect(slot.top, closeTo(top, 0.5), reason: prefix);
      expect(slot.height, closeTo(height, 0.5), reason: prefix);
    }
  });

  testWidgets("a task's box and text line up with a bullet's", (tester) async {
    // A task item has one more visible space than a bullet one, and its
    // text stood that much to the right (device screenshot 2026-09-23).
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- item\n- [ ] task\n',
    );
    RenderParagraph line(String prefix) => tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
    double textLeft(RenderParagraph p, int offset) => p
        .localToGlobal(
          p.getOffsetForCaret(TextPosition(offset: offset), Rect.zero),
        )
        .dx;
    final bullet = line('- item');
    final task = line('- [ ]');
    // To the pixel: a hidden mark still advances by a sliver, and the box's
    // three of them held the text half a pixel off.
    expect(textLeft(task, 6), closeTo(textLeft(bullet, 2), 0.01));
    final bulletSlot = liveItemSlot(bullet, const LineShape(marker: 0), _theme);
    final taskSlot = liveItemSlot(task, _task, _theme);
    expect(
      task.localToGlobal(taskSlot.topLeft).dx,
      closeTo(bullet.localToGlobal(bulletSlot.topLeft).dx, 0.01),
      reason: 'the box sits where the bullet does',
    );
  });

  testWidgets('a nested item is one column in per level, as read draws it', (
    tester,
  ) async {
    // Live nested by the spaces the note was written with, so a sublist sat
    // a few pixels in rather than under its parent's text.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- one\n  - two\n    - [ ] three\n',
    );
    RenderParagraph line(String prefix) => tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
    double textLeft(String prefix) {
      final p = line(prefix);
      return p
          .localToGlobal(
            p.getOffsetForCaret(TextPosition(offset: prefix.length), Rect.zero),
          )
          .dx;
    }

    final one = textLeft('- ');
    final two = textLeft('  - ');
    final three = textLeft('    - [ ] ');
    expect(two - one, closeTo(_theme.listIndentPerLevel, 0.1));
    expect(three - two, closeTo(_theme.listIndentPerLevel, 0.1));
  });

  testWidgets("an item's next line starts under its text", (tester) async {
    // A line the note wrote under an item — indented to its text, or lazy
    // — was drawn at the margin with its spaces, left of the item's text.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- one\n  two\n  - [ ] three\n    four\nlazy\n',
    );
    // Where the glyph at [offset] is drawn: its box, not a caret — a caret
    // mid-line stands at the glyph before, a hidden one with no spacing,
    // and at a paragraph's start at the glyph's own box.
    double textLeft(String line, int offset) {
      final p = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText() == line);
      final box = p
          .getBoxesForSelection(
            TextSelection(baseOffset: offset, extentOffset: offset + 1),
          )
          .first;
      return p.localToGlobal(Offset(box.left, 0)).dx;
    }

    final one = textLeft('- one', 2);
    expect(textLeft('  two', 2), closeTo(one, 0.01));
    final three = textLeft('  - [ ] three', 8);
    expect(textLeft('    four', 4), closeTo(three, 0.01));
    expect(textLeft('lazy', 0), closeTo(three, 0.01), reason: 'lazy: the item');
  });

  testWidgets("a wrapped item's next row starts under its text", (
    tester,
  ) async {
    // The paragraph's rows start where it does, and its first row had the
    // hidden prefix — the written indent, the marker, the box, the spaces —
    // before the text: the second row hung out to the left by all of it.
    const prefix = '  - [ ] ';
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- parent\n$prefix${'word ' * 30}\n',
    );
    final paragraph = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
    Offset at(int offset) =>
        paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero);
    final first = at(prefix.length);
    var next = prefix.length;
    while (at(next).dy <= first.dy) {
      next++;
    }
    // A hidden mark keeps a hundredth of its advance: eight of them are
    // under a tenth of a pixel.
    expect(at(next).dx, closeTo(first.dx, 0.1));
  });

  testWidgets("live's box and number grow with the note's text", (
    tester,
  ) async {
    // The note's size is a scaler, which the text is laid out at: the box
    // stayed 12 px and the number unscaled beside text twice as big.
    /// The side of the drawn box and the height of the drawn number, at
    /// text [scale].
    Future<(double, double)> drawn(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: MarkdownSurface(
                  buffer: SourceBuffer.fromText(
                    'caret\n\n- [ ] task\n\n1. one\n',
                  ),
                  mode: MarkdownSurfaceMode.live,
                  theme: _theme,
                  selection: const SelectionModel.at(0),
                  showLineNumbers: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      var box = 0.0;
      var number = 0.0;
      final item = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().startsWith('1. '));
      final middle = liveItemSlot(
        item,
        const LineShape(marker: 0),
        _theme,
      ).center.dy;
      for (final paint in tester.renderObjectList<RenderCustomPaint>(
        find.byType(CustomPaint),
      )) {
        final painter = paint.painter;
        if (painter is! LiveDecorationPainter) continue;
        final numbered = painter.shape.ordinal != null;
        expect(
          paint,
          paints..everything((method, arguments) {
            if (method == #drawRRect) {
              box = (arguments.first as RRect).width;
            }
            // The number is centred on its row, and its paragraph is gone
            // once painted: its height is read off where it was drawn. It is
            // painted first, behind the line's own paragraph.
            if (method == #drawParagraph && numbered && number == 0) {
              number = 2 * (middle - (arguments[1] as Offset).dy);
            }
            return true;
          }),
        );
      }
      return (box, number);
    }

    final (box, number) = await drawn(1);
    final (bigBox, bigNumber) = await drawn(2);
    expect(box, greaterThan(0));
    expect(number, greaterThan(0));
    expect(bigBox, closeTo(box * 2, 0.01));
    expect(bigNumber, closeTo(number * 2, 0.5));
  });

  group('a task box in live', () {
    const note = 'caret\n\n- [ ] da fare\n- [x] fatto\n';

    /// Where the box of the line starting [prefix] is drawn, globally.
    Offset boxOf(WidgetTester tester, String prefix) {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().startsWith(prefix));
      final slot = liveItemSlot(paragraph, _task, _theme);
      return paragraph.localToGlobal(slot.center);
    }

    for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
      testWidgets('ticks and unticks where it is drawn (${kind.name})', (
        tester,
      ) async {
        final state = await pumpMode(
          tester,
          MarkdownSurfaceMode.live,
          caret: 0,
          text: note,
        );
        final buffer = state.widget.buffer;
        await tester.tapAt(boxOf(tester, '- [ ] da'), kind: kind);
        await tester.pump();
        expect(buffer.text, 'caret\n\n- [x] da fare\n- [x] fatto\n');
        expect(state.selection.extent, 0, reason: 'the caret stays put');
        // Past the double-click window, or the second tap counts as one.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tapAt(boxOf(tester, '- [x] fatto'), kind: kind);
        await tester.pump();
        expect(buffer.text, 'caret\n\n- [x] da fare\n- [ ] fatto\n');
        expect(state.undo(), isTrue);
        expect(
          buffer.text,
          'caret\n\n- [x] da fare\n- [x] fatto\n',
          reason: 'one tick, one undo step',
        );
      });
    }

    testWidgets('on the caret line the box is text, and a click is a caret', (
      tester,
    ) async {
      // The caret is on the first item: its markers are drawn as written.
      final state = await pumpMode(
        tester,
        MarkdownSurfaceMode.live,
        caret: 9,
        text: note,
      );
      await tester.tapAt(
        boxOf(tester, '- [ ] da'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(state.widget.buffer.text, note);
    });

    testWidgets('source draws no box, and ticks none', (tester) async {
      final state = await pumpMode(
        tester,
        MarkdownSurfaceMode.source,
        caret: 0,
        text: note,
      );
      await tester.tapAt(
        boxOf(tester, '- [ ] da'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(state.widget.buffer.text, note);
    });
  });

  testWidgets('live draws a format inside another as both', (tester) async {
    // A line's tokens are disjoint, and the innermost won: `<u>**x**</u>` was
    // drawn bold and not underlined.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n<u>**both**</u> and <u>~~lines~~</u>\n',
    );
    final spans = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    final both = spans.singleWhere((span) => span.text == 'both').style!;
    expect(both.fontWeight, isNot(FontWeight.normal));
    expect(both.fontWeight, isNotNull, reason: 'bold');
    expect(both.decoration!.contains(TextDecoration.underline), isTrue);
    final lines = spans.singleWhere((span) => span.text == 'lines').style!;
    expect(lines.decoration!.contains(TextDecoration.underline), isTrue);
    expect(lines.decoration!.contains(TextDecoration.lineThrough), isTrue);
  });

  testWidgets('live draws what a line marker stood for, beside the text', (
    tester,
  ) async {
    // A bullet, a number, a checkbox, a quote's bar and a rule: the markers
    // are hidden by style, so what they meant is painted behind the line.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 0,
      text: 'caret\n\n- item\n1. one\n- [x] done\n\n> quoted\n\n---\n',
    );
    final painters = <LiveDecorationPainter>[
      for (final paint in tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      ))
        if (paint.painter case final LiveDecorationPainter painter) painter,
    ];
    final shapes = painters.map((painter) => painter.shape).toList();
    expect(shapes, contains(const LineShape(marker: 0)));
    expect(shapes.any((shape) => shape.ordinal == 1), isTrue);
    expect(shapes.any((shape) => shape.task == true), isTrue);
    expect(shapes.any((shape) => shape.quoteDepth == 1), isTrue);
    expect(shapes.any((shape) => shape.rule), isTrue);
    expect(
      painters.every((painter) => !painter.revealed),
      isTrue,
      reason: 'the caret is on none of them',
    );
    final rule = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text == '---') rule.add(span);
        return true;
      });
    }
    expect(rule.single.style?.fontSize, 0.01, reason: 'the rule is drawn');

    // The caret on the item: its marker is the source again, and nothing
    // stands in for it.
    await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: 9,
      text: 'caret\n\n- item\n',
    );
    final item = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<LiveDecorationPainter>()
        .single;
    expect(item.revealed, isTrue);
  });

  testWidgets('live typesets a display formula until the caret is in it', (
    tester,
  ) async {
    final cache = MathCache();
    addTearDown(cache.dispose);
    Future<void> pumpAt(int caret) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText('caret\n\n\$\$\na^2\n\$\$\n'),
              mode: MarkdownSurfaceMode.live,
              theme: _theme,
              selection: SelectionModel.at(caret),
              showLineNumbers: false,
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpAt(0);
    expect(find.byType(BlockMathView), findsOneWidget);
    expect(
      tester.getSize(find.text('a^2', findRichText: true)).height,
      lessThan(1),
      reason: "the formula's source takes no room",
    );
    await pumpAt(12);
    expect(
      find.byType(BlockMathView),
      findsNothing,
      reason: 'with the caret in it, the formula is its source',
    );
    expect(
      tester.getSize(find.text('a^2', findRichText: true)).height,
      greaterThan(10),
    );
  });

  testWidgets("live typesets an inline formula in its source's room", (
    tester,
  ) async {
    final cache = MathCache();
    addTearDown(cache.dispose);
    const note = 'caret\n\nsia \$x^2\$ qui\n';
    Future<void> pumpAt(int caret) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText(note),
              mode: MarkdownSurfaceMode.live,
              theme: _theme,
              selection: SelectionModel.at(caret),
              showLineNumbers: false,
              mathCache: cache,
            ),
          ),
        ),
      );
      // The formula is typeset in the background of the first frame, and
      // the line is drawn again when it lands.
      await tester.pump();
      await tester.pump();
    }

    RenderParagraph lineOf(String prefix) => tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere(
          (paragraph) => paragraph.text.toPlainText().startsWith(prefix),
        );

    await pumpAt(0);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.foregroundPainter)
        .whereType<InlineMathPainter>()
        .single;
    final formula = painter.formulas.single;
    expect((formula.start, formula.end), (4, 9));
    // The paragraph is the source, every offset where it was: nothing to
    // correct. Only the formula's hidden characters are laid out as others.
    final line = lineOf('sia ');
    expect(line.text.toPlainText(), 'sia xxxxx qui');
    final room = line
        .getBoxesForSelection(
          const TextSelection(baseOffset: 4, extentOffset: 9),
        )
        .first;
    expect(
      room.right - room.left,
      closeTo(boxSizePx(formula.box, formula.fontSize).width, 1),
      reason: "the source takes the formula's width",
    );

    await pumpAt(12);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.foregroundPainter)
          .whereType<InlineMathPainter>(),
      isEmpty,
      reason: 'with the caret in its word, the formula is its source',
    );
  });

  testWidgets("an inline formula's room stays on one row", (tester) async {
    // The source has spaces, and a row that ended at one of them split the
    // room in two: the formula, painted whole where its room starts, ran
    // past the margin, and the rest of the room was a gap on the next row.
    final cache = MathCache();
    addTearDown(cache.dispose);
    const line = r'parole parole $a + b + c + d + e$ fine';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: MarkdownSurface(
                buffer: SourceBuffer.fromText('caret\n\n$line\n'),
                mode: MarkdownSurfaceMode.live,
                theme: _theme,
                selection: const SelectionModel.at(0),
                showLineNumbers: false,
                mathCache: cache,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final paragraph = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((paragraph) => paragraph.text.toPlainText().length > 20);
    final start = line.indexOf(r'$');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: start,
        extentOffset: line.lastIndexOf(r'$') + 1,
      ),
    );
    expect(
      paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: line.length),
          )
          .map((box) => box.top)
          .toSet()
          .length,
      greaterThan(1),
      reason: 'the line wraps',
    );
    expect(
      boxes.map((box) => box.top).toSet(),
      hasLength(1),
      reason: "the formula's room is one piece",
    );
  });

  testWidgets('live draws a picture under its line, its source hidden', (
    tester,
  ) async {
    Future<void> pumpAt(int caret) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText('caret\n\nsee ![[pic.png]] here\n'),
              mode: MarkdownSurfaceMode.live,
              theme: _theme,
              selection: SelectionModel.at(caret),
              showLineNumbers: false,
              embedResolver: (_) async => null,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpAt(0);
    final embed = tester.widget<EmbedView>(find.byType(EmbedView));
    expect(embed.target, 'pic.png');
    final spans = <TextSpan>[];
    for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    // The line's own runs of the embed — not the placeholder the picture
    // draws when the file is not there, which is meant to be read.
    final source = spans.where(
      (span) => span.text == 'pic.png' || span.text == '![[',
    );
    expect(source, isNotEmpty);
    expect(
      source.every((span) => span.style?.fontSize == 0.01),
      isTrue,
      reason: 'the picture stands in for its source',
    );
    await pumpAt(9);
    expect(
      find.byType(EmbedView),
      findsOneWidget,
      reason: 'the picture stays while its source is edited',
    );
  });

  testWidgets('live reveals the markers of the line the caret is in', (
    tester,
  ) async {
    // Policy A: the line being written shows its syntax, and nothing else
    // does. The reveal is a style, so the text is the same either way — which
    // is what keeps the caret's offset true while the line is revealed.
    Future<List<TextSpan>> spansAt(int caret) async {
      await pumpMode(tester, MarkdownSurfaceMode.live, caret: caret);
      final spans = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        widget.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
      }
      return spans;
    }

    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;
    final away = await spansAt(10);
    expect(
      away.where((span) => span.text == '#').every(hidden),
      isTrue,
      reason: 'the caret is on another line, so the hash is hidden',
    );
    final on = await spansAt(3);
    expect(
      on.any((span) => span.text == '#' && !hidden(span)),
      isTrue,
      reason: 'the caret is in the heading, so the hash is drawn',
    );
    // Revealing is not a content change: the two lines say the same thing.
    expect(
      away.map((span) => span.text).join(),
      on.map((span) => span.text).join(),
    );
  });

  testWidgets('live reveals the markers of the word the caret is in', (
    tester,
  ) async {
    // The per-word refinement of policy A (D9): the syntax of the word being
    // written shows, and the syntax of the words around it does not — while a
    // *structural* mark, which is the shape of the line rather than of a word,
    // still follows the line.
    const text = 'a **bold** c\n\n# Titolo\n';
    Future<List<TextSpan>> spansAt(int caret) async {
      await pumpMode(
        tester,
        MarkdownSurfaceMode.live,
        caret: caret,
        text: text,
      );
      final spans = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        widget.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
      }
      return spans;
    }

    bool hidden(TextSpan span) => span.style?.fontSize == 0.01;

    // The caret is inside `bold`: the run is `**bold**`, so *both* pairs are
    // drawn — the one behind the caret and the one it has not reached yet.
    final inBold = await spansAt(6);
    final pairs = inBold.where((span) => span.text == '**').toList();
    expect(pairs, hasLength(2), reason: 'one pair per side of the word');
    expect(pairs.every((span) => !hidden(span)), isTrue);

    // The caret is in the plain `a`: the bold word's syntax is hidden, because
    // the writer is not in it.
    final inA = await spansAt(0);
    expect(
      inA.where((span) => span.text == '**').every(hidden),
      isTrue,
      reason: 'the caret is in another word, so `**` is syntax, not text',
    );

    // The heading's hash is the shape of its *line*: it is drawn wherever the
    // caret is in the title, which is what keeps a heading a heading.
    final inHeading = await spansAt(18);
    expect(
      inHeading.any((span) => span.text == '#' && !hidden(span)),
      isTrue,
      reason: 'a structural mark follows the line, not the word',
    );
  });

  testWidgets('a caret move inside a word rebuilds no line', (tester) async {
    // The budget: the reveal may not fire more than once per caret row change.
    // The lines listen to a *value* (line and run), so a move that stays in the
    // run is the same value and tells nobody; crossing a boundary tells the two
    // lines involved. This is the property the per-word reveal was allowed to
    // have, and it is worth holding with a test rather than by reading.
    // The surface owns its own caret here (`caret: null`), which is what a
    // `placeCaret` call needs to be able to move: a caller that holds the
    // selection hears the move through `onSelection` and hands it back.
    final state = await pumpMode(
      tester,
      MarkdownSurfaceMode.live,
      caret: null,
      text: 'a **bold** c\n\nsecond\n',
    );
    state.placeCaret(6);
    await tester.pump();
    var told = 0;
    state.caretSpot.addListener(() => told++);

    state.placeCaret(7);
    await tester.pump();
    expect(told, 0, reason: 'still inside `**bold**`: the spot did not change');

    state.placeCaret(0);
    await tester.pump();
    expect(told, 1, reason: 'another word: the spot changed, once');
  });

  testWidgets('a long note is coloured once its reading lands', (tester) async {
    MarkdownSourceViewState.backgroundLines = 2;
    addTearDown(() => MarkdownSourceViewState.backgroundLines = 50000);
    final state = await pumpMode(
      tester,
      MarkdownSurfaceMode.source,
      text: 'a **bold** line\n\nmore\n',
    );
    expect(state.tokensOf(0), isEmpty, reason: 'drawn plain meanwhile');
    for (var round = 0; round < 50 && state.tokensOf(0).isEmpty; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      state.tokensOf(0).map((token) => token.kind),
      contains(TokenKind.bold),
    );
  });

  testWidgets('a hidden bullet leaves an indent, not a word at the margin', (
    tester,
  ) async {
    // The item's text is set one column in from where a paragraph's is: its
    // glyph, not its paragraph's box, which starts where the hidden marker
    // does.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            // The caret on the other line: on its own, the item's marker is
            // drawn as written, in the indent the bullet had.
            buffer: SourceBuffer.fromText('testo\n- una voce\n'),
            mode: MarkdownSurfaceMode.live,
            theme: _theme,
            selection: const SelectionModel.at(0),
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    double glyph(String start, int offset) {
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().startsWith(start));
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: offset, extentOffset: offset + 1),
          )
          .first;
      return paragraph.localToGlobal(Offset(box.left, 0)).dx;
    }

    expect(
      glyph('- ', 2),
      closeTo(glyph('testo', 0) + _theme.listIndentPerLevel, 0.01),
      reason: 'the item is set in by the column its marker was',
    );
  });
  testWidgets('the caret is at the same offset in both modes', (tester) async {
    // The property the whole arrangement rests on: hiding a marker does not
    // move
    // a single text offset, so the caret is asked of the paragraph and lands in
    // the same place in the note in either mode.
    // The caret is on the note's plain line, so nothing live mode hides is
    // beside it: the two modes draw that run identically, and what the test
    // compares is the caret's own geometry rather than the line's height —
    // the heading above it is set at the heading's size in live mode and at
    // the body's in source, so the two lines do not start at the same y
    // (measured: 50.0 against 65.0).
    final source = await pumpMode(
      tester,
      MarkdownSurfaceMode.source,
      caret: 10,
    );
    final sourceRect = source.caretRect!;
    final live = await pumpMode(tester, MarkdownSurfaceMode.live, caret: 10);
    final liveRect = live.caretRect!;
    expect(liveRect.left, closeTo(sourceRect.left, 0.01));
    expect(source.placeCaret, isNotNull);
    // The hit test agrees with the caret it drew: a point just right of the
    // caret's offset is still inside the character that offset sits on.
    expect(live.offsetAt(Offset(liveRect.left + 1, liveRect.top + 2)), 10);
  });
}
