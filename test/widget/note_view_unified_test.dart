// The read mode behind the flag, at the level the app actually uses it: a
// `NoteView` with a note in it, pumped both ways. This is the test that says
// the branch is reachable and that turning it on does not break the note —
// what it draws is the block view's business, tested next door.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/ui/note_view.dart';

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
    final screen = StringBuffer();
    for (final widget in tester.allWidgets) {
      if (widget is Text) {
        final data = widget.data;
        if (data != null) screen.write(data);
        final span = widget.textSpan;
        if (span != null) screen.write(span.toPlainText());
      }
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
