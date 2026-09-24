// A task list opens in the source pane with its own colours, whatever pane
// the tab asks for: the preview and `live` read Markdown, and would run its
// lines together.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

Widget _app(String path) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: path,
      showLineNumbers: false,
      autofocusEditor: false,
      showPreview: true,
      showWysiwyg: true,
      onEditorKindChanged: (_) {},
      readNote: (_) async => '(A) Call +Home @phone\nx done task\n',
      writeNote: (_, _) async {},
    ),
  ),
);

void main() {
  testWidgets('todo.txt: the source pane, coloured as a task list', (
    tester,
  ) async {
    await tester.pumpWidget(_app('/notes/todo.txt'));
    await tester.pump();

    final source = tester.widget<MarkdownSourceView>(
      find.byType(MarkdownSourceView),
    );
    expect(source.hideMarkers, isFalse, reason: 'source, not live');
    expect(source.lineTokens, isNotNull);
    expect(source.lineTokens!('(A) Call').first.kind, TokenKind.todoPriority);
    // The read view is not the one on stage.
    expect(find.byType(MarkdownReadView), findsNothing);
    // The switch stays in its place, off.
    final toggle = tester.widget<TextButton>(
      find.byKey(const Key('editor-kind-toggle')),
    );
    expect(toggle.onPressed, isNull);
  });

  testWidgets('a note keeps the panes the tab asks for', (tester) async {
    await tester.pumpWidget(_app('/notes/todo.md'));
    await tester.pump();
    // Behind the preview, which has the stage.
    final source = tester.widget<MarkdownSourceView>(
      find.byType(MarkdownSourceView, skipOffstage: false),
    );
    expect(source.lineTokens, isNull);
    expect(find.byType(MarkdownReadView), findsOneWidget);
  });
}
