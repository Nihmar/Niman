// The source surface (#245, phase 3): the note's own text, styled, with the
// caret where the layout says it is.
//
// The properties here are the phase's own exit criteria, in the form a test can
// hold them: a line is drawn as its tokens say, a tap lands on the offset under
// the finger, the caret rectangle comes from the line's `RenderParagraph`
// rather
// than from a metric computed beside it, and only the viewport's lines are
// built.
import 'package:flutter/gestures.dart';
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

  testWidgets('down moves a visual row, not a source line', (tester) async {
    // The property that separates this motion from the logical ones: a wrapped
    // paragraph is *one* source line and many screen rows, and the caret has to
    // walk the rows.
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(30, 'parola').join(' ');
    final buffer = SourceBuffer.fromText('$long\nseconda\n');
    final carets = <SelectionModel>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onSelection: carets.add,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    // Start a few characters in, so the caret has an x to keep. Not a cascade
    // with the move below: the caret's rectangle comes from a post-frame
    // callback, so the pumps between the two calls are the point.
    // ignore: cascade_invocations
    state.placeCaret(8);
    await tester.pump();
    await tester.pump();
    final before = state.caretRect!.top;
    state.moveCaretVertically(1);
    await tester.pump();
    expect(
      carets.last.extent,
      greaterThan(8),
      reason: 'down moved forward inside the same source line',
    );
    expect(
      buffer.lineOf(carets.last.extent),
      0,
      reason: 'still the first source line, one row lower',
    );
    expect(
      state.caretRect!.top,
      greaterThan(before),
      reason: 'and the caret is drawn a row lower',
    );
  });

  testWidgets('down at the last row of a line crosses into the next', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('prima\nseconda\nterza\n');
    final carets = <SelectionModel>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onSelection: carets.add,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    // The same reason as above: the pumps between placing and moving are what
    // the caret's rectangle is measured between.
    // ignore: cascade_invocations
    state.placeCaret(2);
    await tester.pump();
    await tester.pump();
    state.moveCaretVertically(1);
    await tester.pump();
    expect(buffer.lineOf(carets.last.extent), 1, reason: 'the next line');
    state.moveCaretVertically(-1);
    await tester.pump();
    expect(buffer.lineOf(carets.last.extent), 0, reason: 'and back up');
  });

  testWidgets('a mouse drag selects, and a tap does not', (tester) async {
    // Mouse only, deliberately: on a phone a vertical drag on the text scrolls
    // the note, and stealing that gesture to select would break reading.
    final buffer = SourceBuffer.fromText('una riga di testo\n');
    final carets = <SelectionModel>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onSelection: carets.add,
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.startGesture(
      const Offset(16, 16),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(const Offset(120, 16));
    await gesture.up();
    await tester.pump();
    final selection = carets.last;
    expect(selection.isCollapsed, isFalse, reason: 'the drag selected');
    expect(selection.start, 0, reason: 'from where the mouse went down');
    expect(selection.end, greaterThan(0));
  });

  testWidgets('Ctrl+A selects the whole note', (tester) async {
    final buffer = SourceBuffer.fromText('una\ndue\ntre\n');
    final carets = <SelectionModel>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onSelection: carets.add,
          ),
        ),
      ),
    );
    await tester.pump();
    // The keys reach the surface through the focus it owns: without a tap there
    // is no focus to travel to, which is the same rule that makes the
    // connection
    // exist only while the keyboard is up.
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(carets, isNotEmpty);
    expect(carets.last.start, 0);
    expect(carets.last.end, buffer.length);
  });

  testWidgets('copy, cut and paste go through the clipboard', (tester) async {
    // The clipboard is a platform channel, so the test owns it: what matters
    // here
    // is that the surface asks for the right text and puts back what it is
    // given.
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboard = (call.arguments as Map)['text'] as String?;
            return null;
          case 'Clipboard.getData':
            return clipboard == null
                ? null
                : <String, dynamic>{'text': clipboard};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final buffer = SourceBuffer.fromText('una riga\n');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
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
    // Not a cascade with the calls below: each is separated by a pump, because
    // what is asserted between them comes from the frame in between.
    // ignore: cascade_invocations
    state.selectAll();
    await tester.pump();
    expect(state.selectedText, 'una riga\n');
    await state.copySelection();
    expect(clipboard, 'una riga\n');
    await state.cutSelection();
    await tester.pump();
    expect(buffer.text, '', reason: 'cut removed the selection');
    expect(state.canUndo, isTrue, reason: 'and it is one undo step');
    await state.paste();
    await tester.pump();
    expect(buffer.text, 'una riga\n', reason: 'paste put it back');
    state.undo();
    await tester.pump();
    expect(buffer.text, '', reason: 'the paste is undoable like any edit');
  });

  testWidgets('two taps take the word, three take the line', (tester) async {
    final buffer = SourceBuffer.fromText('due parole, fine\n');
    final carets = <SelectionModel>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onSelection: carets.add,
          ),
        ),
      ),
    );
    await tester.pump();
    // Inside `parole`, which starts at x = 4 * the advance of the test font.
    const inside = Offset(16 + 14 * 5, 16);
    await tester.tapAt(inside);
    await tester.pump(const Duration(milliseconds: 50));
    expect(carets.last.isCollapsed, isTrue, reason: 'one tap is a caret');
    await tester.tapAt(inside);
    await tester.pump(const Duration(milliseconds: 50));
    expect(carets.last.start, 4);
    expect(carets.last.end, 10, reason: 'the word under the second tap');
    await tester.tapAt(inside);
    await tester.pump(const Duration(milliseconds: 50));
    expect(carets.last.start, 0);
    expect(
      carets.last.end,
      buffer.lineAt(0).length,
      reason: "the line's text, without the terminator that ends it",
    );
  });

  testWidgets('an edit tells the shell what the note says now', (tester) async {
    // The one thing the shell needs from the surface: the text, after every
    // edit.
    // The debounce, the memento, the statistics and the preview are the
    // shell's.
    final buffer = SourceBuffer.fromText('ciao\n');
    final told = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onChanged: told.add,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'ciao!\n',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pump();
    expect(told, isNotEmpty);
    expect(told.last, 'ciao!\n');
    // And an app-driven edit reports too, including the one an undo makes.
    told.clear();
    state.undo();
    await tester.pump();
    expect(told.last, 'ciao\n');
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
