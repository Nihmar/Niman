// The read mode behind the flag, at the level the app actually uses it: a
// `NoteView` with a note in it, pumped both ways. This is the test that says
// the branch is reachable and that turning it on does not break the note —
// what it draws is the block view's business, tested next door.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:re_editor/re_editor.dart';

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

/// A note view over [_note], with the flag set as asked.
Widget _app({required bool unified, bool showPreview = true}) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/tmp/niman-unified-test.md',
      showLineNumbers: true,
      autofocusEditor: false,
      showPreview: showPreview,
      unifiedMarkdown: unified,
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
            unifiedMarkdown: true,
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

  testWidgets('the flag off is the preview the app has always had', (
    tester,
  ) async {
    await tester.pumpWidget(_app(unified: false));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownReadView), findsNothing);
    expect(find.byType(MarkdownPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the flag on draws the unified read mode', (tester) async {
    await tester.pumpWidget(_app(unified: true));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(find.byType(MarkdownPreview), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the unified mode shows the note, markers out', (tester) async {
    await tester.pumpWidget(_app(unified: true));
    await tester.pumpAndSettle();
    // Scoped to the read pane: with the flag on, the *editor* pane is the
    // unified
    // surface too, and a source view shows its markers by design. What this
    // test
    // is about is that the read mode takes them out.
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

  testWidgets('the flag on turns the source pane into the surface', (
    tester,
  ) async {
    // The wiring's property: with the flag on and the preview hidden, the
    // editor
    // pane is the unified surface rather than re_editor — and the note it shows
    // is
    // the note the file has.
    await tester.pumpWidget(_app(unified: true, showPreview: false));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownSurface), findsOneWidget);
    expect(find.byType(CodeEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without the flag the source pane is still re_editor', (
    tester,
  ) async {
    await tester.pumpWidget(_app(unified: false, showPreview: false));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownSurface), findsNothing);
    expect(find.byType(CodeEditor), findsOneWidget);
  });

  testWidgets('flipping the flag over a live note does not throw', (
    tester,
  ) async {
    await tester.pumpWidget(_app(unified: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(unified: true));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownReadView), findsOneWidget);
    await tester.pumpWidget(_app(unified: false));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
