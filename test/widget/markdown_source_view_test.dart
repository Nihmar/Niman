// The source surface (#245, phase 3): the note's own text, styled, with the
// caret where the layout says it is.
//
// The properties here are the phase's own exit criteria, in the form a test can
// hold them: a line is drawn as its tokens say, a tap lands on the offset under
// the finger, the caret rectangle comes from the line's `RenderParagraph`
// rather
// than from a metric computed beside it, and only the viewport's lines are
// built.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The monospace theme the source mode is set in.
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
  Future<MarkdownSourceViewState> pump(
    WidgetTester tester,
    String text, {
    SelectionModel? selection,
    ValueChanged<SelectionModel>? onSelection,
    Size size = const Size(500, 400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: SourceBuffer.fromText(text),
            theme: _theme,
            selection: selection,
            onSelection: onSelection,
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
  }

  testWidgets('the note is drawn, its markers and all', (tester) async {
    await pump(tester, '# Title\n\na paragraph with **bold** text\n');
    final screen = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.textSpan?.toPlainText() ?? widget.data ?? '')
        .join('\n');
    expect(screen, contains('# Title'));
    expect(screen, contains('**bold**'), reason: 'source mode hides nothing');
    expect(screen, contains('a paragraph with'));
  });

  testWidgets('a wrapped line is one line of the note and many of the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(40, 'wrapping words').join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: SourceBuffer.fromText('$long\nsecond\n'),
            theme: _theme,
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    );
    // The property is the *wrapping*, not the count: with the test font every
    // glyph is as wide as it is tall, so a 600-character line is some twenty-
    // odd
    // rows tall and fills the viewport by itself. What matters is that one line
    // of the note is drawn as many rows of the screen, at the height those rows
    // need — which is what `getOffsetForCaret` will answer the caret with.
    expect(paragraphs, isNotEmpty);
    expect(
      paragraphs.first.size.height,
      greaterThan(_theme.lineHeight * 2),
      reason: 'the line wrapped, and is drawn at its wrapped height',
    );
    expect(
      paragraphs.first.size.height,
      greaterThan(_theme.lineHeight * 2),
      reason: 'the first line wrapped, and is drawn at its wrapped height',
    );
  });

  testWidgets('the caret is where the offset is, from the line itself', (
    tester,
  ) async {
    final state = await pump(
      tester,
      'first line\nsecond line\n',
      selection: const SelectionModel.at(3),
    );
    await tester.pump();
    final rect = state.caretRect;
    expect(rect, isNotNull);
    // Three characters into a 14 px monospace line, at the top: the caret is
    // inside the first line's box, and left of it the text starts at x=0.
    expect(rect!.top, lessThan(_theme.lineHeight + 8));
    expect(rect.left, greaterThan(0));
    expect(rect.width, lessThan(3));
  });

  testWidgets('the caret follows the offset down the note', (tester) async {
    const text = 'first line\nsecond line\nthird line\n';
    var selection = const SelectionModel.at(0);
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MarkdownSourceView(
                buffer: SourceBuffer.fromText(text),
                theme: _theme,
                selection: selection,
                showLineNumbers: false,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    final first = state.caretRect!.top;
    selection = const SelectionModel.at(text.length - 2);
    rebuild(() {});
    await tester.pump();
    await tester.pump();
    expect(
      state.caretRect!.top,
      greaterThan(first),
      reason: 'the caret moved to the last line',
    );
  });

  testWidgets('a tap places the caret under the finger', (tester) async {
    final placed = <SelectionModel>[];
    await pump(
      tester,
      'first line\nsecond line\n',
      selection: const SelectionModel.at(0),
      onSelection: placed.add,
    );
    await tester.tapAt(const Offset(60, 30));
    await tester.pump();
    expect(placed, hasLength(1));
    expect(
      placed.single.extent,
      greaterThan(0),
      reason: 'a tap past the start of a line is an offset into it',
    );
    expect(placed.single.isCollapsed, isTrue, reason: 'a tap is a caret');
  });

  testWidgets('only the viewport lines are built', (tester) async {
    tester.view.physicalSize = const Size(500, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final note = StringBuffer();
    for (var at = 0; at < 4000; at++) {
      note.writeln('line $at of a long note');
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: SourceBuffer.fromText(note.toString()),
            theme: _theme,
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    expect(
      state.lineCount,
      4001,
      reason: '4000 lines and the empty one a trailing newline makes',
    );
    final built = find.byType(RichText).evaluate().length;
    expect(
      built,
      lessThan(200),
      reason: '$built lines of 4000 were built for one viewport',
    );
  });

  testWidgets('an arrow key moves the caret, and shift extends it', (
    tester,
  ) async {
    // Uncontrolled on purpose: with a caller holding the selection, the caller
    // is the only one who moves it, and this test is about the surface moving
    // it.
    final state = await pump(tester, 'una riga di testo\n');
    await tester.pump();
    // The surface answers the logical motions itself, so a desktop user's arrow
    // keys do not depend on the shell's command table.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump();
    expect(state.caretRect, isNotNull);
    final after = state.caretRect!.left;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump();
    expect(
      state.caretRect!.left,
      greaterThan(after),
      reason: 'a second press moves the caret on',
    );
  });

  testWidgets('Ctrl+Z takes back what the keyboard typed', (tester) async {
    final buffer = SourceBuffer.fromText('ciao\n');
    var selection = const SelectionModel.at(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MarkdownSourceView(
              buffer: buffer,
              theme: _theme,
              selection: selection,
              onSelection: (next) => selection = next,
              showLineNumbers: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    // The connection exists only while the surface has focus: tapping it is
    // what
    // raises the keyboard, so the test taps it too.
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    expect(state.isKeyboardAttached, isTrue);
    // Type through the platform's own path, which is what the real keyboard
    // does.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Xciao\n',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(buffer.text, 'Xciao\n');
    expect(state.canUndo, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(buffer.text, 'ciao\n', reason: 'undo took the X back');
  });

  testWidgets('a jump to a line brings it to the top', (tester) async {
    final note = StringBuffer();
    for (var at = 0; at < 500; at++) {
      note.writeln('line $at of the note');
    }
    final state = await pump(
      tester,
      note.toString(),
      size: const Size(500, 300),
    );
    state.jumpToLine(400);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('line 400', findRichText: true),
      findsWidgets,
      reason: 'the line a jump names is on screen',
    );
  });
}
