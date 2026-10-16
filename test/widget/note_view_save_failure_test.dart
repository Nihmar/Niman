// A save that fails is seen, retried and never forgotten (#1054, #1061).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

void main() {
  void type(WidgetTester tester, String text) => tester
      .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
      .replaceText(0, 0, text);

  testWidgets('the status says it, one snack bar says why, a tap retries', (
    tester,
  ) async {
    final zoneErrors = <Object>[];
    var failing = true;
    final writes = <String>[];
    await runZonedGuarded(() async {
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            showLineNumbers: false,
            autofocusEditor: false,
            readNote: (_) async => 'a',
            writeNote: (_, text) async {
              if (failing) throw StateError('disk full');
              writes.add(text);
            },
          ),
        ),
      );
      await tester.pump();
      type(tester, 'x');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text(AppStrings.noteStatusSaveFailed), findsOneWidget);
      expect(find.text(AppStrings.noteSaveFailedSnack), findsOneWidget);

      failing = false;
      await tester.tap(find.byKey(const Key('note-status-retry')));
      await tester.pump();
      await tester.pump();
      expect(writes, ['xa']);
      expect(find.text(AppStrings.noteStatusSaved), findsOneWidget);
      // Drain the retry timer the failure left behind.
      await tester.pump(const Duration(seconds: 30));
    }, (error, stack) => zoneErrors.add(error));
    expect(zoneErrors, isEmpty, reason: 'no uncaught async error');
  });

  testWidgets('switching away from a note whose save fails keeps its text', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    var failing = true;
    final writes = <String, String>{};
    NoteView view(String path) => NoteView(
      path: path,
      showLineNumbers: false,
      autofocusEditor: false,
      unsavedTracker: tracker,
      readNote: (_) async => 'a',
      writeNote: (path, text) async {
        if (failing) throw StateError('card removed');
        writes[path] = text;
      },
    );

    await tester.pumpWidget(_app(view('/notes/a.md')));
    await tester.pump();
    type(tester, 'typed ');
    await tester.pumpWidget(_app(view('/notes/b.md')));
    await tester.pump();
    await tester.pump();

    expect(tracker.unsavedPaths, ['/notes/a.md']);
    expect(tracker.unsavedTextOf('/notes/a.md'), 'typed a');

    failing = false;
    await tracker.saveAll();
    expect(writes, {'/notes/a.md': 'typed a'});
    expect(tracker.hasUnsaved, isFalse);
  });

  testWidgets('a note opened again takes back the text a failed write held, '
      'and the held write never lands over what follows', (tester) async {
    final tracker = UnsavedTracker();
    var failing = true;
    final disk = <String, String>{'/notes/a.md': 'a', '/notes/b.md': 'b'};
    final writes = <String>[];
    NoteView view(String path) => NoteView(
      path: path,
      showLineNumbers: false,
      autofocusEditor: false,
      unsavedTracker: tracker,
      readNote: (path) async => disk[path]!,
      writeNote: (path, text) async {
        if (failing) throw StateError('card removed');
        writes.add(text);
        disk[path] = text;
      },
    );

    await tester.pumpWidget(_app(view('/notes/a.md')));
    await tester.pump();
    type(tester, 'one ');
    // Switched away while the disk refuses the write: the text is held.
    await tester.pumpWidget(_app(view('/notes/b.md')));
    await tester.pump();
    await tester.pump();
    expect(tracker.unsavedTextOf('/notes/a.md'), 'one a');

    // Opened again: the disk still has the old text, the editor has the
    // held one — as unsaved edits of its own.
    await tester.pumpWidget(_app(view('/notes/a.md')));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
          .widget
          .buffer
          .text,
      'one a',
    );
    expect(tracker.unsavedPaths, ['/notes/a.md'], reason: 'the editor owns it');

    failing = false;
    type(tester, 'two ');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    // The held write's retry would have come by now: nothing may follow the
    // editor's own write.
    await tester.pump(const Duration(seconds: 30));

    expect(disk['/notes/a.md'], 'two one a');
    expect(writes.last, 'two one a');
    expect(tracker.hasUnsaved, isFalse);
  });
}
