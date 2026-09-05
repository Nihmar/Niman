import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
