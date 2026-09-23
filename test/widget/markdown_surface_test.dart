// The one surface in its two modes (#245, #246), and the property that makes
// them
// one widget: the same note, the same offsets, one flag between them.
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

void main() {
  Future<MarkdownSourceViewState> pumpMode(
    WidgetTester tester,
    MarkdownSurfaceMode mode, {
    int? caret = 3,
    String text = '# Titolo\n\ntesto\n',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: SourceBuffer.fromText(text),
            mode: mode,
            theme: _theme,
            // A caret the caller holds, or `null` for a surface that owns its
            // own — the two contracts a caller can have, and the reveal has to
            // hold for both.
            selection: caret == null ? null : SelectionModel.at(caret),
            showLineNumbers: false,
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
      hidden.any((span) => span.text == '#' && span.style?.fontSize == 0.01),
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
    Future<Rect> textRect(MarkdownSurfaceMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText('- una voce\ntesto\n'),
              mode: mode,
              theme: _theme,
              showLineNumbers: false,
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getRect(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText().startsWith('-'),
            )
            .first,
      );
    }

    final source = await textRect(MarkdownSurfaceMode.source);
    final live = await textRect(MarkdownSurfaceMode.live);
    expect(
      live.left,
      closeTo(source.left + _theme.listIndentPerLevel, 0.01),
      reason: 'the item is indented by the level its marker was',
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
