// The classic in-editor find & replace bar (re_editor find machinery +
// NimanFindPanel): opens from the status-row action, expands to the
// replace row, and closes back to a clean editor.
//
// Note: typing a pattern starts the package's isolate-backed search, which
// does not run under the fake-async test zone — these tests exercise the
// bar's structure and state toggles, not the match results.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({String content = 'plain note body'}) => NoteView(
  showLineNumbers: true,
  autofocusEditor: false,
  path: '/notes/a.md',
  readNote: (_) async => content,
  writeNote: (_, _) async {},
);

void main() {
  testWidgets('find opens from the status row; replace row toggles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_view()));
    await tester.pump();
    await tester.pump();
    // Closed: no bar.
    expect(find.byKey(const Key('editor-find-input')), findsNothing);

    await tester.tap(find.byKey(const Key('editor-find-open')));
    await tester.pump();
    await tester.pump();
    // Find row open, replace row hidden.
    expect(find.byKey(const Key('editor-find-input')), findsOneWidget);
    expect(find.byKey(const Key('editor-replace-input')), findsNothing);

    await tester.tap(find.byKey(const Key('editor-find-mode')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('editor-replace-input')), findsOneWidget);
    // Still one editor only.
    expect(find.byType(NoteView), findsOneWidget);
  });

  testWidgets('close collapses the bar back to the clean editor', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_view()));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('editor-find-open')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('editor-find-input')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editor-find-close')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('editor-find-input')), findsNothing);
    expect(find.byKey(const Key('editor-replace-input')), findsNothing);
    // Closing refocuses the editor: release the focus (stops the cursor
    // blink) and let the one-shot focus timer fire before the invariant
    // check.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('the find action is absent in preview-only mode', (tester) async {
    await tester.pumpWidget(
      _app(
        NoteView(
          showLineNumbers: true,
          autofocusEditor: false,
          path: '/notes/a.md',
          showPreview: true,
          readNote: (_) async => 'plain',
          writeNote: (_, _) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('editor-find-open')), findsNothing);
  });
}
