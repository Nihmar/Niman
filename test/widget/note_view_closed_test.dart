// A note edited and closed is reported once its last edit is on disk —
// where the library tidies it (`LibraryConfig.tidyOnClose`); a note only
// read is not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  late Map<String, String> disk;
  late List<String> events;

  Widget app(String path) => MaterialApp(
    home: Scaffold(
      body: NoteView(
        path: path,
        showLineNumbers: false,
        autofocusEditor: false,
        readNote: (path) async => disk[path] ?? '',
        writeNote: (path, text) async {
          events.add('saved $path');
          disk[path] = text;
        },
        onEditedNoteClosed: (path) => events.add('closed $path'),
      ),
    ),
  );

  void type(WidgetTester tester, String text) => tester
      .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
      .replaceText(0, 0, text);

  setUp(() {
    disk = {'/notes/a.md': 'a', '/notes/b.md': 'b'};
    events = [];
  });

  testWidgets('an edited note is reported after its save, on a switch', (
    tester,
  ) async {
    await tester.pumpWidget(app('/notes/a.md'));
    await tester.pump();
    type(tester, 'typed ');
    await tester.pump();

    await tester.pumpWidget(app('/notes/b.md'));
    await tester.pump();
    expect(events, ['saved /notes/a.md', 'closed /notes/a.md']);
    expect(disk['/notes/a.md'], 'typed a');
  });

  testWidgets('a note only read is not reported', (tester) async {
    await tester.pumpWidget(app('/notes/a.md'));
    await tester.pump();
    await tester.pumpWidget(app('/notes/b.md'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('an edited note is reported when the view goes away', (
    tester,
  ) async {
    await tester.pumpWidget(app('/notes/a.md'));
    await tester.pump();
    type(tester, 'typed ');
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(events, ['saved /notes/a.md', 'closed /notes/a.md']);
  });

  testWidgets('an edit saved before the switch is still reported', (
    tester,
  ) async {
    await tester.pumpWidget(app('/notes/a.md'));
    await tester.pump();
    type(tester, 'typed ');
    // The save debounce runs out while the note is still open.
    await tester.pump(const Duration(seconds: 2));
    expect(events, ['saved /notes/a.md']);

    await tester.pumpWidget(app('/notes/b.md'));
    await tester.pump();
    expect(events, ['saved /notes/a.md', 'closed /notes/a.md']);
    // The note switched to starts with nothing to report.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(events, hasLength(2));
  });
}
