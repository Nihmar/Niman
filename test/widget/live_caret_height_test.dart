// The caret is the line it is drawn on, whatever laid that line out last
// (`docs/records/unified-surface.md` §8.7.2). A keystroke re-measures it
// (`_scheduleCaret`); a relayout that lands after the keystroke used to
// leave it at the height it had while typing (#395).
//
// An inline formula is the case: `typesetInline` conceals its source with a
// spacer only once the box arrives from the async `MathCache`, and that
// spacer is taller than a body line (`spacerStyleFor`). The formula lands
// with no edit behind it, so nothing asked the caret to be measured again.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart' show KatexOptions, renderToBox;
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

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
  testWidgets('the caret takes the height of its line once a formula lands', (
    tester,
  ) async {
    // The formula is typeset by the cache, but only when the test lets it:
    // its arrival is the relayout that happens outside an edit.
    final gate = Completer<void>();
    final cache = MathCache(
      asyncRenderer: (tex, {required displayMode}) async {
        await gate.future;
        return renderToBox(
          tex,
          options: KatexOptions(displayMode: displayMode),
        );
      },
    );
    addTearDown(cache.dispose);

    // One line, with an inline formula the caret is not in — concealed, its
    // source takes the typeset formula's room, which is taller than a body
    // line.
    const note =
        r'a $\frac{a}{b}$ b'
        '\n';
    final buffer = SourceBuffer.fromText(note);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: buffer,
            mode: MarkdownSurfaceMode.live,
            theme: _theme,
            showLineNumbers: false,
            mathCache: cache,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );

    // The caret line's own paragraph, and the height it gives the caret at
    // the offset the caret is on — the mode-switch test's invariant, read
    // here from the same line the surface measured.
    RenderParagraph caretParagraph() => tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().contains('bX'));
    double lineHeightAtCaret() =>
        caretParagraph().getFullHeightForCaret(const TextPosition(offset: 18));

    // Type through the platform's own path: focus, the caret at the end of
    // the line, one keystroke typed there.
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: note,
        selection: TextSelection.collapsed(offset: 17),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text:
            r'a $\frac{a}{b}$ bX'
            '\n',
        selection: TextSelection.collapsed(offset: 18),
      ),
    );
    await tester.pump();

    // The typing frame: the formula is not typeset yet — its source stands
    // as written — and the caret is the body line it is drawn on.
    expect(
      caretParagraph().text.toPlainText(),
      r'a $\frac{a}{b}$ bX',
      reason: 'the source, until the box lands',
    );
    final typed = state.caretRect!.height;
    expect(
      typed,
      closeTo(lineHeightAtCaret(), 0.5),
      reason: 'the typing frame',
    );

    // The formula lands, with no edit behind it.
    gate.complete();
    await tester.pump();
    await tester.pump();

    // The line is taller now, and the caret has to be too: it is the line.
    expect(
      lineHeightAtCaret(),
      greaterThan(typed),
      reason: 'the spacer stretched the line, and only the line',
    );
    expect(
      state.caretRect!.height,
      closeTo(lineHeightAtCaret(), 0.5),
      reason: 'the caret is its line, once the formula has landed',
    );
  });

  testWidgets('the caret after a trailing space is the line, not the space', (
    tester,
  ) async {
    // The glyph at the very end of a line is the space before the newline,
    // and its box is shorter than the line: on the test font 14 px against
    // 21. A caret measured from that glyph shrank, and the typewriter light
    // over it shrank with it (#509).
    const note = 'abc \n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: SourceBuffer.fromText(note),
            mode: MarkdownSurfaceMode.live,
            theme: _theme,
            showLineNumbers: false,
            selection: const SelectionModel.at(4),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    final paragraph = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().startsWith('abc'));

    expect(
      paragraph.getFullHeightForCaret(const TextPosition(offset: 4)),
      lessThan(paragraph.preferredLineHeight),
      reason: 'the trap: the trailing space measures short',
    );
    expect(
      state.caretRect!.height,
      closeTo(paragraph.preferredLineHeight, 0.5),
      reason: 'the caret is the line, trailing space or not',
    );
  });

  testWidgets('a wrapped line gives the caret the row it is on', (
    tester,
  ) async {
    // Only the characters beside the caret are measured (#509): on the last
    // visual line of a wrapped paragraph the caret is that line, not the
    // first one, and still a whole line tall.
    final note = '${List.filled(40, 'word').join(' ')}\n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: MarkdownSurface(
              buffer: SourceBuffer.fromText(note),
              mode: MarkdownSurfaceMode.live,
              theme: _theme,
              showLineNumbers: false,
              selection: SelectionModel.at(note.length - 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    final paragraph = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().startsWith('word'));
    final caret = state.caretRect!;

    expect(
      paragraph.size.height,
      greaterThan(paragraph.preferredLineHeight * 2),
      reason: 'the line wraps',
    );
    expect(caret.top, greaterThan(0), reason: 'the last row, not the first');
    expect(caret.height, closeTo(paragraph.preferredLineHeight, 0.5));
  });
}
