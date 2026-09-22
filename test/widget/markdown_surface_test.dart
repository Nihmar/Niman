// The one surface in its two modes (#245, #246), and the property that makes
// them
// one widget: the same note, the same offsets, one flag between them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

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
    int caret = 3,
    String text = '# Titolo\n\ntesto\n',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: SourceBuffer.fromText(text),
            mode: mode,
            theme: _theme,
            selection: SelectionModel.at(caret),
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
    Future<List<TextSpan>> spansAfter(MarkdownSurfaceMode mode) async {
      await pumpMode(tester, mode);
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
      await pumpMode(tester, mode, text: 'a **bold** and [a link](u)\n');
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
    final source = await pumpMode(tester, MarkdownSurfaceMode.source);
    final sourceRect = source.caretRect!;
    final live = await pumpMode(tester, MarkdownSurfaceMode.live);
    final liveRect = live.caretRect!;
    expect(liveRect.left, closeTo(sourceRect.left, 0.01));
    expect(liveRect.top, closeTo(sourceRect.top, 0.01));
    expect(source.placeCaret, isNotNull);
    // The hit test agrees with the caret it drew: a point just right of offset
    // 3
    // is still inside the character that offset sits on — the heading is drawn
    // at
    // its own size, so that character is wider than the body's.
    expect(live.offsetAt(Offset(liveRect.left + 1, liveRect.top + 2)), 3);
  });
}
