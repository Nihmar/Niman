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
