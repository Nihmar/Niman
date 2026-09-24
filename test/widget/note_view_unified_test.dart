// The read mode at the level the app actually uses it: a `NoteView` with a
// note in it. What it draws is the block view's business, tested next door.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';

import '../fakes/item_mark_finder.dart';

/// The note the editor is handed.
const String _note = '''
# A title

A paragraph with **bold** text and a `code span`.

- one
- two

> quoted

| a | b |
|---|---|
| 1 | 2 |
''';

/// A note view over [_note].
Widget _app({bool showPreview = true}) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/tmp/niman-unified-test.md',
      showLineNumbers: true,
      autofocusEditor: false,
      showPreview: showPreview,
      readNote: (_) async => _note,
      writeNote: (_, _) async {},
    ),
  ),
);

void main() {
  testWidgets('an anchor jump lands on its heading in the read mode', (
    tester,
  ) async {
    // #256: a jump arrives as a source line. The old path turned it into a
    // uniform fraction of the note's estimated height, which a note whose
    // paragraphs differ this much in height cannot honour.
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final filler = List.filled(30, 'filler words').join(' ');
    final note = StringBuffer('# First\n\n');
    for (var at = 0; at < 8; at++) {
      note.write('$filler\n\n');
    }
    note.write('## The target\n\nAfter the target.\n\n');
    // Prose below it too, so the heading *can* reach the top of the viewport: a
    // jump near the end of a note is clamped by the scroll extent, which is
    // right and useless for this assertion.
    for (var at = 0; at < 5; at++) {
      note.write('$filler\n\n');
    }
    final key = GlobalKey<State<NoteView>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            key: key,
            path: '/tmp/niman-anchor-test.md',
            showLineNumbers: true,
            autofocusEditor: false,
            showPreview: true,
            readNote: (_) async => note.toString(),
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The heading is at line 18: the title, a blank, then eight paragraphs of
    // two lines and a blank each. The jump corrects itself across frames, so
    // the settle runs them out.
    (key.currentState! as NoteViewHandle).jumpToHeading(18);
    await tester.pumpAndSettle();
    final heading = find.textContaining('The target', findRichText: true);

    expect(heading, findsWidgets, reason: 'the heading is on screen');
    expect(
      tester.getTopLeft(heading.first).dy,
      lessThan(80),
      reason: 'and it is at the top, not a screen away',
    );
  });

  testWidgets('the read mode is the unified read view', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the unified mode shows the note, markers out', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    // Scoped to the read pane: the *editor* pane is the surface too, and a
    // source view shows its markers by design. What this test is about is
    // that the read mode takes them out.
    final screen = StringBuffer();
    for (final widget in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(MarkdownReadView),
        matching: find.byType(Text),
      ),
    )) {
      final data = widget.data;
      if (data != null) screen.write(data);
      final span = widget.textSpan;
      if (span != null) screen.write(span.toPlainText());
    }
    final text = screen.toString();
    expect(text, contains('A title'));
    expect(text, contains('bold'));
    expect(text, contains('code span'));
    expect(text, contains('one'));
    expect(text, contains('quoted'));
    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('# A title')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the source pane is the surface', (tester) async {
    // With the preview hidden, the editor pane is the unified surface.
    await tester.pumpWidget(_app(showPreview: false));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownSurface), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the read pane takes the blocks the editor already has', (
    tester,
  ) async {
    // One reading of the note for both panes: opening the read pane after an
    // edit used to scan the note again — in an isolate past a size, 3.3 s on
    // a 246 MB note, after holding the frame to hand it over.
    MarkdownReadViewState.backgroundLines = 20;
    addTearDown(() => MarkdownReadViewState.backgroundLines = 50000);
    final note = StringBuffer();
    for (var at = 0; at < 30; at++) {
      note.write('Paragraph $at, cited[^1].\n\n');
    }
    note.write('[^1]: the footnote\n');
    Widget app({required bool showPreview}) => MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/tmp/niman-handover-test.md',
          showLineNumbers: true,
          autofocusEditor: false,
          showPreview: showPreview,
          readNote: (_) async => note.toString(),
          writeNote: (_, _) async {},
        ),
      ),
    );
    await tester.pumpWidget(app(showPreview: false));
    await tester.pumpAndSettle();
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(0, 0, '# Added\n\n');
    // Past the preview's debounce, which finds the read pane off stage.
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(app(showPreview: true));
    final read = tester.state<MarkdownReadViewState>(
      find.byType(MarkdownReadView),
    );
    expect(read.scanning, isFalse, reason: 'nothing was sent to scan');
    expect(
      find.descendant(
        of: find.byType(MarkdownReadView),
        matching: find.textContaining('Added', findRichText: true),
      ),
      findsWidgets,
      reason: 'the edit is on the first frame',
    );
    expect(read.blockCount, greaterThan(60));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a checkbox in the read pane ticks the note', (tester) async {
    const note = 'Tasks\n\n- [ ] one\n- [x] two\n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/tmp/niman-read-task-test.md',
            showLineNumbers: true,
            autofocusEditor: false,
            showPreview: true,
            readNote: (_) async => note,
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editor = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView, skipOffstage: false),
    );
    Finder inRead({required bool ticked}) => find.descendant(
      of: find.byType(MarkdownReadView),
      matching: findCheckbox(ticked: ticked),
    );
    expect(inRead(ticked: false), findsOneWidget);

    await tester.tap(inRead(ticked: false));
    await tester.pump();
    expect(editor.widget.buffer.text, 'Tasks\n\n- [x] one\n- [x] two\n');
    expect(
      inRead(ticked: true),
      findsNWidgets(2),
      reason: 'the pane shows the tick on the next frame, not after a debounce',
    );

    await tester.tap(inRead(ticked: true).last);
    await tester.pump();
    expect(editor.widget.buffer.text, 'Tasks\n\n- [x] one\n- [ ] two\n');
    expect(editor.undo(), isTrue);
    expect(
      editor.widget.buffer.text,
      'Tasks\n\n- [x] one\n- [x] two\n',
      reason: 'one tick, one undo step',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
