// Convert list to mind map, as the palette runs it on an open note (#530):
// the list's lines become the fence, and one undo step gives the list back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';

Future<NoteViewHandle> _open(WidgetTester tester, String note) async {
  final key = GlobalKey<State<NoteView>>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NoteView(
          key: key,
          path: '/notes/mind.md',
          showLineNumbers: false,
          autofocusEditor: false,
          readNote: (_) async => note,
          writeNote: (_, _) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState! as NoteViewHandle;
}

MarkdownSourceViewState _editor(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

void main() {
  testWidgets('the list becomes a fence, and one undo gives it back', (
    tester,
  ) async {
    const note = 'Intro\n\n- A (one)\n  - B\n\nEnd\n';
    final handle = await _open(tester, note);
    final editor = _editor(tester)..placeCaret(note.indexOf('B'));
    await tester.pump();

    handle.convertListToMindMap();
    await tester.pump();
    expect(
      editor.widget.buffer.text,
      'Intro\n\n```mermaid\nmindmap\n  n0("A (one)")\n'
      '    B\n```\n\nEnd\n',
    );

    expect(editor.undo(), isTrue);
    expect(editor.widget.buffer.text, note);
  });
}
