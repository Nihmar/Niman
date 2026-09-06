import 'package:copist/src/editor/caret_painter.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

CaretPainter? _findCaretPainter(WidgetTester tester) {
  for (final element in find.byType(CustomPaint).evaluate()) {
    final ro = element.renderObject;
    if (ro is RenderCustomPaint) {
      final painter = ro.painter;
      if (painter is CaretPainter) {
        return painter;
      }
    }
  }
  return null;
}

void main() {
  testWidgets('reports the buffer revision after a text edit', (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    int? reported;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (r) => reported = r,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    final before = input.revision;
    input.apply(
      const TextEditingDeltaInsertion(
        oldText: 'hi',
        insertionOffset: 2,
        textInserted: '!',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange.empty,
      ),
    );
    await tester.pump();
    expect(reported, before + 1);
    focus.dispose();
  });

  testWidgets('does not report on selection-only changes', (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    int? reported;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (r) => reported = r,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    input.setSelection(const TextSelection(baseOffset: 0, extentOffset: 2));
    await tester.pump();
    expect(reported, isNull);
    focus.dispose();
  });

  testWidgets('caret overlay tracks the scroll', (tester) async {
    final text = List.generate(100, (i) => 'line $i').join('\n');
    final input = ComposingInput(text);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: text,  
          input: input,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          ),
        ),
      ),
    );
    expect(_findCaretPainter(tester), isNotNull);
    expect(_findCaretPainter(tester)!.scrollOffset, 0);
    await tester.drag(find.byType(NoteEditor), const Offset(0, -200));
    await tester.pump();
    expect(_findCaretPainter(tester)!.scrollOffset, greaterThan(0));
    focus.dispose();
  });

  testWidgets('tap places the caret', (tester) async {
    final input = ComposingInput('ab\ncdefgh\nij');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'ab\ncdefgh\nij',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    // Tap row 1, col 3 → line 1 ('cdefgh'), col 3 → offset 6.
    final charWidth = VirtualizedTextView.measureCharWidth();
    await tester.tapAt(
      Offset(
        VirtualizedTextView.leftPadding + 3 * charWidth,
        VirtualizedTextView.rowHeight,
      ),
    );
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: 6));
  });

  testWidgets('collapsed horizontal drag moves the caret, never selects (S1)',
      (tester) async {
    final input = ComposingInput('abcd\nefgh\nijkl');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'abcd\nefgh\nijkl',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    final charWidth = VirtualizedTextView.measureCharWidth();
    const left = VirtualizedTextView.leftPadding;
    const rowH = VirtualizedTextView.rowHeight;
    // The stock-editor touch-drag rule (round-5 S1+S2): a collapsed drag
    // follows with the caret, it never grows a selection (selections come
    // from long-press, handles, or an already-active selection).
    final gesture =
        await tester.startGesture(const Offset(left, rowH * 0.5));
    await gesture.moveTo(Offset(left + 4 * charWidth, rowH * 0.5));
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: 4));
    await gesture.up();
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: 4));
    focus.dispose();
  });

  testWidgets('selection-active drag extends on any axis, scroll frozen (S1)',
      (tester) async {
    // 40 lines exceed the 600px viewport (row height 21): scrollable.
    final text = List.generate(40, (i) => 'line $i').join('\n');
    final input = ComposingInput(text);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: text,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    input.setSelection(const TextSelection(baseOffset: 0, extentOffset: 4));
    await tester.pump();
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.pixels, 0.0);
    // Diagonal and vertical-dominant: the old direction lock would have
    // yielded to scrolling (and the 123451 log showed the scroll running
    // 418→475 while the selection sat frozen). With a selection active
    // the drag selects and the list stays put.
    const left = VirtualizedTextView.leftPadding;
    final gesture = await tester.startGesture(const Offset(left, 10));
    await tester.pump();
    await gesture.moveTo(const Offset(left + 30, 70));
    await tester.pump();
    expect(input.selection.isCollapsed, isFalse);
    expect(input.selection.baseOffset, 0);
    expect(position.pixels, 0.0);
    await gesture.up();
    await tester.pump();
    expect(input.selection.isCollapsed, isFalse);
    focus.dispose();
  });

  testWidgets('a second finger mid-drag keeps the selection (S2)',
      (tester) async {
    final input = ComposingInput('hello world');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hello world',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    final charWidth = VirtualizedTextView.measureCharWidth();
    const left = VirtualizedTextView.leftPadding;
    input.setSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    await tester.pump();
    // First finger drags from inside the selection rightward. Exact end
    // columns are pinned by the R2 round-trip test; here only the anchor
    // (the S2 contract) and the rightward extension matter.
    final first =
        await tester.startGesture(Offset(left + 2 * charWidth, 10));
    await tester.pump();
    await first.moveTo(Offset(left + 9.4 * charWidth, 10));
    await tester.pump();
    expect(input.selection.baseOffset, 2);
    expect(input.selection.extentOffset, greaterThan(5));
    // A second finger taps elsewhere mid-drag (the 123451 mid-drag
    // collapse: the lock reset and the next move re-anchored). It must be
    // ignored entirely: same anchor, same extent.
    final before = input.selection;
    final second = await tester.startGesture(const Offset(left, 100));
    await tester.pump();
    await second.up();
    await tester.pump();
    expect(input.selection, before);
    await first.moveTo(Offset(left + 11.4 * charWidth, 10));
    await tester.pump();
    await first.up();
    await tester.pump();
    expect(input.selection.baseOffset, 2);
    expect(input.selection.extentOffset, 11);
    focus.dispose();
  });

  testWidgets('a vertical drag scrolls, not selects (M2a fix P4)',
      (tester) async {
    // 40 lines exceed the 600px viewport (row height 21): the last lines
    // start off-screen.
    final text = List.generate(40, (i) => 'line $i').join('\n');
    final input = ComposingInput(text);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: text,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    // A vertical drag (the vertical axis clears the slop before the
    // horizontal one): the scrollable owns the gesture, the selection is
    // untouched. The drag is upward: a downward drag from the top of the
    // content is an overscroll and clamps (no net scroll, here and on
    // device).
    await tester.fling(
      find.byType(Scrollable),
      const Offset(0, -200),
      500,
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(90.0));
    expect(input.selection, const TextSelection.collapsed(offset: 0));
    focus.dispose();
  });

  testWidgets('the caret scroll sync keeps the caret visible', (tester) async {
    // 40 lines exceed the default 600px viewport (row height 21), so the
    // last line starts off-screen.
    final text = List.generate(40, (i) => 'line $i').join('\n');
    final input = ComposingInput(text);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: text,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0.0,
    );

    // Move the caret to the start of the last line (off-screen).
    input.setSelection(
      TextSelection.collapsed(offset: text.lastIndexOf('\n') + 1),
    );
    await tester.pump();

    // The scroll moved so the last line is visible (the offset > 0).
    final pixels =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(pixels, greaterThan(0));
  });

  testWidgets('caret shows only while focused', (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          ),
        ),
      ),
    );
    expect(_findCaretPainter(tester)!.caretVisible, isFalse);
    focus.requestFocus();
    await tester.pump();
    expect(_findCaretPainter(tester)!.caretVisible, isTrue);
    focus.unfocus();
    await tester.pump();
    await tester.pump();
    expect(_findCaretPainter(tester)!.caretVisible, isFalse);
    focus.dispose();
  });

  testWidgets('long-press selects the word under the pointer',
      (tester) async {
    final input = ComposingInput('hello world');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hello world',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          ),
        ),
      ),
    );
    // x 14 = the left padding (12) + 2 px, i.e. column 0 of row 0.
    await tester.longPressAt(const Offset(14, 10));
    await tester.pump();
    expect(input.hasSelection, isTrue);
    expect(input.selectionText, 'hello');
    focus.dispose();
  });

  testWidgets('a tap pushes the caret to the IME', (tester) async {
    final input = ComposingInput('ab\ncdefgh\nij');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'ab\ncdefgh\nij',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // Tap row 1, col 3 → line 1 ('cdefgh'), col 3 → offset 6.
    final charWidth = VirtualizedTextView.measureCharWidth();
    await tester.tapAt(
      Offset(
        VirtualizedTextView.leftPadding + 3 * charWidth,
        VirtualizedTextView.rowHeight,
      ),
    );
    await tester.pump();
    // The platform copy moved with the tap (the lockstep the next
    // keystroke edits against).
    expect(tester.testTextInput.editingState?['selectionBase'], 6);
    expect(tester.testTextInput.editingState?['selectionExtent'], 6);
    focus.dispose();
  });

  testWidgets('a long-press selection is pushed to the IME', (tester) async {
    final input = ComposingInput('hello world');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hello world',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          ),
        ),
      ),
    );
    // x 14 = the left padding (12) + 2 px, i.e. column 0 of row 0.
    await tester.longPressAt(const Offset(14, 10));
    await tester.pump();
    expect(tester.testTextInput.editingState?['selectionBase'], 0);
    expect(tester.testTextInput.editingState?['selectionExtent'], 5);
    focus.dispose();
  });

  testWidgets('a drag pushes once, at the end (no per-move pushes)',
      (tester) async {
    final input = ComposingInput('hello world');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hello world',  
          input: input,  
          focusNode: focus,  
          onTextChanged: (_) {},  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump(); // attach + initial push (caret 0).
    // Hold a horizontal drag (pan) from col 0 to col 10: the IME must not
    // hear about the moves (a full-text push at novel length is a platform
    // round trip; the per-move pushes froze the app, M2a on-device round 3).
    final charWidth = VirtualizedTextView.measureCharWidth();
    final gesture = await tester.startGesture(
      const Offset(VirtualizedTextView.leftPadding, 10),
    );
    for (var col = 1; col <= 10; col++) {
      await gesture.moveBy(Offset(charWidth, 0));
    }
    await tester.pump();
    expect(tester.testTextInput.editingState?['selectionBase'], 0);
    expect(tester.testTextInput.editingState?['selectionExtent'], 0);
    // The drag ends: the followed caret is pushed once (collapsed —
    // the stock-editor touch-drag rule moves the caret, it never grows a
    // selection; round-5 S1).
    await gesture.up();
    await tester.pump();
    expect(tester.testTextInput.editingState?['selectionBase'], 10);
    expect(tester.testTextInput.editingState?['selectionExtent'], 10);
    focus.dispose();
  });

  testWidgets('the IME is told the field is multiline with a newline action',
      (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // multiline (not the single-line default): the keyboard offers Enter,
    // not a checkmark.
    expect(
      (tester.testTextInput.setClientArgs?['inputType'] as Map?)?['name'],
      'TextInputType.multiline',
    );
    // The action is `newline` (⏎), not the default `done` (which Gboard
    // renders as the ✓ checkmark) — the M2a on-device keyboard complaint.
    expect(
      tester.testTextInput.setClientArgs?['inputAction'],
      'TextInputAction.newline',
    );
    // Delta model: the platform sends a delta per edit, not the whole field.
    expect(tester.testTextInput.setClientArgs?['enableDeltaModel'], isTrue);
    focus.dispose();
  });

  testWidgets('performAction(newline) inserts a line break and pushes it',
      (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // Caret at the end of the line (the fresh-load caret is 0).
    input.setSelection(const TextSelection.collapsed(offset: 2));
    await tester.pump();
    // The soft Enter (the keyboard's ⏎) arrives as an IME action, not an
    // insertion delta: it must split the line at the caret.
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(input.text, 'hi\n');
    // The caret is after the break: the start of the new (empty) line.
    expect(input.selection, const TextSelection.collapsed(offset: 3));
    // And the split is pushed to the platform (lockstep for the next key).
    expect(tester.testTextInput.editingState?['text'], 'hi\n');
    expect(tester.testTextInput.editingState?['selectionBase'], 3);
    expect(tester.testTextInput.editingState?['selectionExtent'], 3);
    focus.dispose();
  });

  testWidgets('performAction(done) unfocuses (hides the keyboard)',
      (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    // The buffer is untouched by the action (only the keyboard dismisses).
    expect(input.text, 'hi');
    focus.dispose();
  });

  testWidgets('a tap re-attaches after a system dismiss (R1)',
      (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hi',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    // The system dismisses the keyboard (back/gesture): the platform kills
    // the connection while Flutter focus is retained (the M2a on-device
    // round-4 keyboard complaint — the log showed one attach, then
    // silence across 25+ taps).
    tester.testTextInput.closeConnection();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    final callsBefore = tester.testTextInput.log.length;
    // A tap must bring the keyboard back: re-attach (setClient) + push the
    // window (setEditingState) + show.
    await tester.tapAt(const Offset(20, 10));
    await tester.pump();
    final after = tester.testTextInput.log.sublist(callsBefore);
    expect(
      after.any((c) => c.method == 'TextInput.setClient'),
      isTrue,
      reason: 'a tap after a system dismiss must re-attach the connection',
    );
    expect(
      after.any((c) => c.method == 'TextInput.show'),
      isTrue,
      reason: 'a tap after a system dismiss must re-show the keyboard',
    );
    expect(tester.testTextInput.isVisible, isTrue);
    focus.dispose();
  });

  testWidgets('long-press jitter below slop keeps the word (R3)',
      (tester) async {
    final input = ComposingInput('hello world');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(

          initialText: 'hello world',  
          focusNode: focus,  
          onTextChanged: (_) {},  
          input: input,  
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // x 14 = the left padding (12) + 2 px, i.e. column 0 of row 0.
    final gesture = await tester.startGesture(const Offset(14, 10));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(input.selectionText, 'hello');
    // Touch jitter below the slop must not shrink the fresh word selection
    // (the M2a round-4 R3 log finding: a same-coordinate `longPressDrag`
    // collapsed `410..417` to `410..412`).
    await gesture.moveTo(const Offset(16, 11));
    await tester.pump();
    expect(input.selectionText, 'hello');
    // A real drag past the slop still extends the selection.
    final charWidth = VirtualizedTextView.measureCharWidth();
    await gesture.moveTo(Offset(14 + 6 * charWidth, 10));
    await tester.pump();
    expect(input.selectionText, 'hello ');
    await gesture.up();
    await tester.pump();
    // The extended selection persists after release (no collapse).
    expect(input.selectionText, 'hello ');
    focus.dispose();
  });

  testWidgets('tap on a rendered glyph lands its column at 0.85 scaler (R2)',
      (tester) async {
    // A 60-column single row: far enough right that a shrunken render
    // drifts by whole characters under grid math (the M2a round-4 R2
    // minimum-font report — col 20 at 0.85 lands 3 chars off).
    const line = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWX';
    final input = ComposingInput(line);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(0.85),
          ),
          child: Scaffold(
            body: NoteEditor(

            initialText: line,  
            focusNode: focus,  
            onTextChanged: (_) {},  
            input: input,  
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // The ground truth is the painted row itself: the caret x the real
    // RenderParagraph reports for column 20.
    final paragraph =
        tester.renderObject<RenderParagraph>(find.text(line));
    const col = 20;
    final caretX = paragraph
        .getOffsetForCaret(const TextPosition(offset: col), Rect.zero)
        .dx;
    final topLeft = tester.getTopLeft(find.text(line));
    await tester.tapAt(topLeft + Offset(caretX, 10));
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: col));
    // And the same pixel re-tapped is a no-op (tap round-trips).
    await tester.tapAt(topLeft + Offset(caretX, 10));
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: col));
    focus.dispose();
  });
}
