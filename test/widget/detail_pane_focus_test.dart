// #1074: the keyboard is in the note on stage. A tab behind is hidden with
// Offstage, which leaves its editor able to take focus and keys; the pane
// takes them off it and hands them to the note that shows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/detail_pane_harness.dart';

void main() {
  setUp(() {
    paneKeys.clear();
    paneNotes
      ..clear()
      ..['a.md'] = 'alpha text'
      ..['b.md'] = 'beta text';
  });

  Future<void> pump(
    WidgetTester tester,
    String? active, {
    FocusNode? shellFocus,
    FocusNode? beside,
    List<String> paths = const ['a.md', 'b.md'],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              if (beside != null)
                Focus(focusNode: beside, child: const SizedBox(height: 10)),
              Expanded(
                child: detailPane(
                  active,
                  tracker: UnsavedTracker(),
                  shellFocus: shellFocus,
                  paths: paths,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void focusNote(String path) {
    final Object? state = paneKeys[path]!.currentState;
    (state! as NoteViewHandle).takeFocus();
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a tab switch moves the caret to the note that shows', (
    tester,
  ) async {
    await pump(tester, 'a.md');
    focusNote('a.md');
    await tester.pump();
    expect(focusedNotePath(), 'a.md');

    await pump(tester, 'b.md');
    // Typing goes to the note on screen; the one behind keeps its text.
    expect(focusedNotePath(), 'b.md');
    tester.testTextInput.enterText('beta text!');
    await tester.pump();
    expect(paneEditorOf(tester, 'b.md').widget.buffer.text, 'beta text!');
    expect(paneEditorOf(tester, 'a.md').widget.buffer.text, 'alpha text');
    await teardown(tester);
  });

  testWidgets('a note behind cannot take the focus', (tester) async {
    await pump(tester, 'b.md');
    // The hidden editor asks for the keyboard: nothing happens.
    focusNote('a.md');
    await tester.pump();
    expect(focusedNotePath(), isNot('a.md'));
    await teardown(tester);
  });

  testWidgets('closing the note on stage hands the caret to the next', (
    tester,
  ) async {
    await pump(tester, 'a.md');
    focusNote('a.md');
    await tester.pump();
    await pump(tester, 'b.md', paths: const ['b.md']);
    expect(focusedNotePath(), 'b.md');
    await teardown(tester);
  });

  testWidgets('a control elsewhere keeps the focus through a switch', (
    tester,
  ) async {
    final elsewhere = FocusNode(debugLabel: 'a tree row');
    addTearDown(elsewhere.dispose);
    await pump(tester, 'a.md', beside: elsewhere);
    elsewhere.requestFocus();
    await tester.pump();
    await pump(tester, 'b.md', beside: elsewhere);
    expect(elsewhere.hasPrimaryFocus, isTrue);
    expect(focusedNotePath(), isNull);
    await teardown(tester);
  });

  testWidgets('the shell’s own node counts as nowhere: the note takes it', (
    tester,
  ) async {
    final shell = FocusNode(debugLabel: 'app shortcuts');
    addTearDown(shell.dispose);
    await pump(tester, 'a.md', shellFocus: shell, beside: shell);
    shell.requestFocus();
    await tester.pump();
    await pump(tester, 'b.md', shellFocus: shell, beside: shell);
    expect(focusedNotePath(), 'b.md');
    expect(find.byType(NoteView), findsOne);
    await teardown(tester);
  });
}
