// T-M2-07 AC: fold/unfold a section (re_editor chunk path) and outline
// jumps land on the heading line; word count is live.
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/word_count.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

const String _note =
    '# Alpha\n\nparagraph one\n\n'
    '## Beta\n\ncontent\n\n# Gamma\n\nlast';

void main() {
  test('word count is whitespace-separated tokens plus chars', () {
    expect(countWords('one two three'), 3);
    expect(countWords('  spaced\nwords '), 2);
    expect(countWords(''), 0);
    expect(countCharacters('héllo'), 5);
  });

  testWidgets('the editor marks heading chunks and folds a section', (
    tester,
  ) async {
    final controller = CodeLineEditingController.fromText(_note);
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(
            controller: controller,
            focusNode: focus,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Collapse the '# Alpha' section (lines 0..8, up to '# Gamma') through
    // the controller's chunk API: the folded line becomes a chunk parent.
    controller.collapseChunk(0, 8);
    await tester.pump();
    expect(
      controller.codeLines[0].chunkParent,
      isTrue,
      reason: 'the Alpha section is folded',
    );
    expect(controller.codeLines.length, lessThan(11));
    controller.expandChunk(0);
    await tester.pump();
    expect(controller.codeLines.length, 11);
    controller.dispose();
    focus.dispose();
  });

  testWidgets('outline panel lists headings and a jump lands the caret', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        NoteView(
          path: '/notes/outline.md',
          showLineNumbers: true,
          autofocusEditor: false,
          readNote: (_) async => _note,
        ),
      ),
    );
    await tester.pump(); // load
    await tester.pump(const Duration(milliseconds: 400)); // stats debounce
    await tester.pump();

    // The word count is live from the debounced stats refresh.
    final words = find.textContaining('words');
    expect(words, findsOneWidget);
    expect(
      tester.widget<Text>(words).data,
      contains(countWords(_note).toString()),
    );

    // Open the outline: the headings are listed (the panel slides in).
    await tester.tap(find.byKey(const Key('outline-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Alpha', findRichText: true), findsOneWidget);
    expect(find.text('Gamma', findRichText: true), findsOneWidget);

    // Jump to 'Gamma' (line 8): the caret lands on that line.
    await tester.tap(find.text('Gamma', findRichText: true));
    await tester.pump();
    await tester.pump();
    final editor = tester.widget<NoteEditor>(find.byType(NoteEditor));
    expect(editor.controller.selection.isCollapsed, isTrue);
    expect(editor.controller.selection.startIndex, 8);
  });
}
