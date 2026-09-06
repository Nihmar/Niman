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

  testWidgets('drag extends the selection', (tester) async {
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
    // Drag row 0, col 0 (offset 0) → row 1, col 4 (line 'efgh' starts at
    // offset 5, col 4 → offset 9). Horizontal first: the direction lock
    // (M2a fix P4) sees the horizontal axis clear the slop before the
    // vertical one, so this is a selection drag, not a scroll.
    final gesture =
        await tester.startGesture(const Offset(left, rowH * 0.5));
    await gesture.moveTo(Offset(left + 6 * charWidth, rowH * 0.5));
    await tester.pump();
    await gesture.moveTo(Offset(left + 4 * charWidth, rowH * 1.5));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // The drag-end persists the selection (no collapse, M2a fix P4): the
    // handles and toolbar stay up over it.
    expect(
      input.selection,
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
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
    // The drag ends: the selection persists (no collapse, M2a fix P4) and
    // is pushed once (window-sized).
    await gesture.up();
    await tester.pump();
    expect(tester.testTextInput.editingState?['selectionBase'], 0);
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
}
