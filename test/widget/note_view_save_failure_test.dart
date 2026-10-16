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
}
