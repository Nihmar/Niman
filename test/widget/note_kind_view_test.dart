// T-TK-02/05: NoteView kind dispatch — a `type: list` note renders the
// list GUI instead of the editor; kindMode false (the pencil) shows the
// editor, and edits in either surface persist through the note.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

NoteView _view({
  required String path,
  required String content,
  bool kindMode = true,
  void Function(String?)? onNoteKindChanged,
  Future<void> Function(String path, String content)? writeNote,
}) => NoteView(
  path: path,
  showLineNumbers: true,
  autofocusEditor: false,
  kindMode: kindMode,
  onNoteKindChanged: onNoteKindChanged,
  readNote: (_) async => content,
  writeNote: writeNote,
);

void main() {
  testWidgets('a type: list note shows the list GUI, not the editor', (
    tester,
  ) async {
    String? kind;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _view(
            path: '/n/a.md',
            content: '---\ntype: list\n---\n- [ ] one\n',
            onNoteKindChanged: (t) => kind = t,
          ),
        ),
      ),
    );
    await tester.pump(); // Let the async load land.
    await tester.pump();
    expect(kind, 'list');
    expect(find.byType(ListNoteView), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });

  testWidgets('a plain note and an unknown kind show the editor', (
    tester,
  ) async {
    String? kind;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _view(
            path: '/n/a.md',
            content: '---\ntype: recipe\n---\n# Soup\n',
            onNoteKindChanged: (t) => kind = t,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(kind, 'recipe'); // Reported verbatim; the kind decides.
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(ListNoteView), findsNothing);
  });

  testWidgets('kindMode false (the pencil) shows the editor instead', (
    tester,
  ) async {
    const content = '---\ntype: list\n---\n- [ ] one\n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _view(path: '/n/a.md', content: content, kindMode: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(ListNoteView), findsNothing);
  });

  testWidgets('pencil edits are re-parsed when returning to the list', (
    tester,
  ) async {
    const content = '---\ntype: list\n---\n- [ ] one\n';
    final controller = CodeLineEditingController.fromText(content);

    // The pencil: the raw editor for the same note.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: true,
            autofocusEditor: false,
            kindMode: false,
            readNote: (_) async => content,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump(); // Let the async load land.
    await tester.pump();
    expect(find.byType(NoteEditor), findsOneWidget);

    // An edit in the editor.
    controller.text = '$content- [ ] two\n';
    await tester.pump();

    // Returning to the list re-parses the edited text.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: true,
            autofocusEditor: false,
            readNote: (_) async => content,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(ListNoteView), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a kind edit saves through the note', (tester) async {
    final writes = <String>[];
    const content = '---\ntype: list\n---\n- [ ] one\n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _view(
            path: '/n/a.md',
            content: content,
            writeNote: (path, c) async => writes.add(c),
          ),
        ),
      ),
    );
    await tester.pump(); // Let the async load land.
    await tester.pump();
    // Tapping the checkbox (not the text) flips the item.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    expect(writes, ['---\ntype: list\n---\n- [x] one\n']);
  });
}
