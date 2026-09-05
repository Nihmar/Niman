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
  testWidgets('reports the buffer text after a text edit', (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    String? reported;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: 'hi',
          input: input,
          focusNode: focus,
          onTextChanged: (t) => reported = t,
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
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
    expect(reported, 'hi!');
    focus.dispose();
  });

  testWidgets('does not report on selection-only changes', (tester) async {
    final input = ComposingInput('hi');
    final focus = FocusNode();
    String? reported;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: 'hi',
          input: input,
          focusNode: focus,
          onTextChanged: (t) => reported = t,
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: text,
          input: input,
          focusNode: focus,
          onTextChanged: (_) {},
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: 'ab\ncdefgh\nij',
          focusNode: focus,
          onTextChanged: (_) {},
          input: input,
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: 'abcd\nefgh\nijkl',
          focusNode: focus,
          onTextChanged: (_) {},
          input: input,
        ),
      ),
    );
    final charWidth = VirtualizedTextView.measureCharWidth();
    const left = VirtualizedTextView.leftPadding;
    const rowH = VirtualizedTextView.rowHeight;
    // Drag row 0, col 0 (offset 0) → row 1, col 2 (line 'efgh' starts at
    // offset 5, col 2 → offset 7).
    final gesture =
        await tester.startGesture(const Offset(left, rowH * 0.5));
    await tester.pump();
    await gesture.moveTo(Offset(left + 2 * charWidth, rowH * 1.5));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // The drag-end collapses the selection per the E8a contract.
    expect(
      input.selection,
      const TextSelection.collapsed(offset: 7),
    );
  });

  testWidgets('the caret scroll sync keeps the caret visible', (tester) async {
    // 40 lines exceed the default 600px viewport (row height 21), so the
    // last line starts off-screen.
    final text = List.generate(40, (i) => 'line $i').join('\n');
    final input = ComposingInput(text);
    final focus = FocusNode();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: text,
          focusNode: focus,
          onTextChanged: (_) {},
          input: input,
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteEditor(
          initialText: 'hi',
          input: input,
          focusNode: focus,
          onTextChanged: (_) {},
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
}
