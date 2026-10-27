// A long note is not joined and kept to follow its edits (#1197): its tags
// panel reads what the scan keeps, and a join made for a caller that needs
// the whole note is that caller's alone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// Pumps a note view over [text] and waits until its scan keeps the note's
/// references, which a long note's scan does once it is read.
Future<NoteViewHandle> _open(WidgetTester tester, String text) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/notes/note.md',
          showLineNumbers: false,
          autofocusEditor: false,
          readNote: (_) async => text,
          writeNote: (_, _) async {},
        ),
      ),
    ),
  );
  for (var round = 0; round < 50; round++) {
    if (find.byType(MarkdownSourceView).evaluate().isNotEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  return tester.state(find.byType(NoteView)) as NoteViewHandle;
}

MarkdownSourceViewState _view(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

/// Waits for the scan's references, which a long note's scan keeps.
Future<void> _settle(WidgetTester tester) async {
  for (var round = 0; round < 50 && _view(tester).references() == null;) {
    round++;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

const String _note =
    '---\ntags: [Work]\n---\nOne #first line.\n\nMore #idea.\n';

void main() {
  group('a long note', () {
    setUp(() => MarkdownSourceViewState.backgroundLines = 2);
    tearDown(() => MarkdownSourceViewState.backgroundLines = 50000);

    testWidgets('joins its text for each ask after an edit, keeping none', (
      tester,
    ) async {
      final note = await _open(tester, _note);
      await _settle(tester);
      _view(tester).replaceText(0, 0, 'x');
      await tester.pump();

      final first = note.currentText;
      final second = note.currentText;
      expect(first, second);
      expect(first, startsWith('x---'));
      // Two asks, two joins: nothing kept the first.
      expect(identical(first, second), isFalse);
    });

    testWidgets('has its tags read off the scan, as the index reads them', (
      tester,
    ) async {
      final note = await _open(tester, _note);
      await _settle(tester);
      expect(_view(tester).references(), isNotNull);

      expect(await note.currentTags(), ['work', 'first', 'idea']);

      _view(tester).replaceText(
        _note.indexOf('More'),
        _note.indexOf('More'),
        'Now #added. ',
      );
      await tester.pump();
      await _settle(tester);
      expect(await note.currentTags(), ['work', 'first', 'added', 'idea']);
    });
  });

  testWidgets('a short note keeps its join for the revision', (tester) async {
    final note = await _open(tester, _note);
    await tester.pump();
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(_note.length, _note.length, 'x');
    await tester.pump();

    expect(identical(note.currentText, note.currentText), isTrue);
    expect(await note.currentTags(), ['work', 'first', 'idea']);
  });
}
