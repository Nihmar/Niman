// T-PP-11: NoteView reports its live revision pair into the app-level
// tracker and saves on the close guard's request.
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/unsaved_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

Widget _host({
  required UnsavedTracker tracker,
  required CodeLineEditingController controller,
  required Future<void> Function(String, String) writeNote,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        readNote: (_) async => 'start',
        writeNote: writeNote,
        controller: controller,
        unsavedTracker: tracker,
      ),
    ),
  );
}

void main() {
  testWidgets('tracks edits and clears them when the save lands', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final writes = <String>[];
    final controller = CodeLineEditingController.fromText('start');

    await tester.pumpWidget(
      _host(
        tracker: tracker,
        controller: controller,
        writeNote: (path, content) async => writes.add(content),
      ),
    );
    await tester.pump(); // the load lands.
    expect(tracker.hasUnsaved, isFalse);

    controller.text = 'start!';
    await tester.pump();
    expect(tracker.hasUnsaved, isTrue);
    expect(tracker.unsavedPaths, ['/notes/a.md']);

    await tester.pump(const Duration(milliseconds: 600));
    expect(writes, ['start!']);
    expect(tracker.hasUnsaved, isFalse);
    controller.dispose();
  });

  testWidgets('the guard save writes the latest text at once', (tester) async {
    final tracker = UnsavedTracker();
    final writes = <String>[];
    final controller = CodeLineEditingController.fromText('start');

    await tester.pumpWidget(
      _host(
        tracker: tracker,
        controller: controller,
        writeNote: (path, content) async => writes.add(content),
      ),
    );
    await tester.pump();

    controller.text = 'start!';
    await tester.pump();
    // No debounce wait: this is exactly what CloseGuard does on "Save and
    // close".
    await tracker.saveAll();

    expect(writes, ['start!']);
    expect(tracker.hasUnsaved, isFalse);
    // Let the still-armed autosave debounce fire (a no-op) so the test
    // leaves no pending timer behind.
    await tester.pump(const Duration(milliseconds: 600));
    controller.dispose();
  });

  testWidgets('a note untracked by the owner works as before', (tester) async {
    final controller = CodeLineEditingController.fromText('start');
    final writes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/notes/a.md',
            showLineNumbers: true,
            autofocusEditor: false,
            readNote: (_) async => 'start',
            writeNote: (path, content) async => writes.add(content),
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();
    controller.text = 'start!';
    await tester.pump(const Duration(milliseconds: 600));
    expect(writes, ['start!']);
    controller.dispose();
  });
}
