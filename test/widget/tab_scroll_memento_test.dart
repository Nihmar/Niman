// #1075: where a tab was scrolled survives its editor being torn down
// (evicted from the kept-alive tabs, or remounted by a resize across the
// wide/narrow breakpoint): the view is gone by the time the note view
// hands in its memento, so the controller keeps what the view had.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';

import '../fakes/detail_pane_harness.dart';

void main() {
  setUp(() {
    paneKeys.clear();
    paneNotes
      ..clear()
      ..['a.md'] = [for (var i = 0; i < 400; i++) 'line $i'].join('\n')
      ..['b.md'] = 'beta text';
  });

  testWidgets('the memento a torn-down editor hands in has its scroll', (
    tester,
  ) async {
    final handed = <String, NoteMemento>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: detailPane(
            'a.md',
            tracker: UnsavedTracker(),
            onMemento: (path, memento) => handed[path] = memento,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    paneEditorOf(tester, 'a.md').jumpToOffset(800);
    await tester.pump();
    expect(paneEditorOf(tester, 'a.md').scrollOffset, 800);

    // The editor goes: the tab fell out of the kept-alive ones.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(handed['a.md']?.scrollOffset, 800);
  });
}
