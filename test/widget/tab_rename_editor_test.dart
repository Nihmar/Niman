// #1076: a note whose file is renamed keeps its editor — the text, the undo
// and the place — instead of being unmounted and loaded again under its new
// name.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_editor_keys.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/detail_pane_harness.dart';

void main() {
  setUp(() {
    paneKeys.clear();
    paneNotes
      ..clear()
      ..['a.md'] = [for (var i = 0; i < 400; i++) 'line $i'].join('\n')
      ..['z.md'] = [for (var i = 0; i < 400; i++) 'line $i'].join('\n');
  });

  testWidgets('a renamed note keeps its editor, its undo and its place', (
    tester,
  ) async {
    final handed = <String>[];
    Widget pane(String path, {String? movedFrom}) => MaterialApp(
      home: Scaffold(
        body: detailPane(
          path,
          paths: [path],
          tracker: UnsavedTracker(),
          onMemento: (path, _) => handed.add(path),
          movedFrom: movedFrom == null ? const {} : {path: movedFrom},
        ),
      ),
    );

    await tester.pumpWidget(pane('a.md'));
    await tester.pumpAndSettle();
    final before = paneEditorOf(tester, 'a.md')..replaceText(0, 0, 'typed ');
    await tester.pumpAndSettle();
    before.jumpToOffset(800);
    await tester.pump();
    expect(before.scrollOffset, 800);
    expect(before.canUndo, isTrue);

    // The shell's rename: the key follows the note, and the tab says where
    // it was.
    paneKeys['z.md'] = paneKeys['a.md']!;
    await tester.pumpWidget(pane('z.md', movedFrom: 'a.md'));
    await tester.pumpAndSettle();

    final after = paneEditorOf(tester, 'z.md');
    expect(identical(after, before), isTrue, reason: 'the same editor');
    expect(after.widget.buffer.text, startsWith('typed line 0'));
    expect(after.canUndo, isTrue);
    expect(after.scrollOffset, 800);
    // The old name has no memento to hand in: the note is not left.
    expect(handed, isNot(contains('a.md')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('without the move, another path is another note', (tester) async {
    Widget pane(String path) => MaterialApp(
      home: Scaffold(
        body: detailPane(path, paths: [path], tracker: UnsavedTracker()),
      ),
    );
    await tester.pumpWidget(pane('a.md'));
    await tester.pumpAndSettle();
    paneEditorOf(tester, 'a.md').replaceText(0, 0, 'typed ');
    await tester.pump();
    paneKeys['z.md'] = paneKeys['a.md']!;
    await tester.pumpWidget(pane('z.md'));
    await tester.pumpAndSettle();
    // z.md was loaded from its own text, not given a.md's buffer.
    expect(paneEditorOf(tester, 'z.md').widget.buffer.text, startsWith('line'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  test('the keys follow a rename, and a folder’s notes with it', () {
    final keys = NoteEditorKeys();
    final a = keys.keyOf('Notes/a.md');
    final b = keys.keyOf('Notes/deep/b.md');
    final c = keys.keyOf('Notes2/c.md');
    keys.moved('Notes', 'Archive');
    expect(keys['Archive/a.md'], same(a));
    expect(keys['Archive/deep/b.md'], same(b));
    expect(keys['Notes2/c.md'], same(c));
    expect(keys['Notes/a.md'], isNull);
    expect(keys.movedFrom('Archive/a.md'), 'Notes/a.md');
    expect(keys.movedFrom('Notes2/c.md'), isNull);
    keys.settle();
    expect(keys.movedFrom('Archive/a.md'), isNull);
  });
}
