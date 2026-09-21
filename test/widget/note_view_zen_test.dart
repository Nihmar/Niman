// Issue #69: a note in Zen mode. Its row above, its status row and its
// row numbers go, the caret thickens, and the tab's own flag says
// whether the editor or the preview shows.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/workspace/note_memento.dart';

Widget _app({
  bool zen = false,
  bool active = true,
  bool showPreview = false,
  void Function(String, NoteMemento)? onMemento,
}) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/n/a.md',
      showLineNumbers: true,
      autofocusEditor: false,
      toolbarTop: true,
      zen: zen,
      active: active,
      showPreview: showPreview,
      onMemento: onMemento,
      readNote: (_) async => '# Title\n\nSome text.',
      writeNote: (_, _) async {},
    ),
  ),
);

void main() {
  final preview = find.byKey(const ValueKey('pane-preview'));

  testWidgets('the chrome and the row numbers go, the caret thickens', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    NoteEditor editor() => tester.widget<NoteEditor>(find.byType(NoteEditor));
    expect(find.byType(NoteTopBar), findsOne);
    expect(find.byType(NoteStatusRow), findsOne);
    expect(editor().showLineNumbers, isTrue);
    expect(editor().caretWidth, isNull);

    await tester.pumpWidget(_app(zen: true));
    await tester.pumpAndSettle();
    expect(find.byType(NoteTopBar), findsNothing);
    expect(find.byType(NoteStatusRow), findsNothing);
    expect(editor().showLineNumbers, isFalse);
    expect(editor().caretWidth, zenCaretWidth);
  });

  // 0.0.8 test round: a note read rather than written is read in Zen
  // too — in its preview.
  testWidgets('a tab in its preview shows the preview in Zen, and hands '
      'its flag in unchanged', (tester) async {
    NoteMemento? handed;
    void keep(String _, NoteMemento m) => handed = m;
    await tester.pumpWidget(
      _app(showPreview: true, zen: true, onMemento: keep),
    );
    await tester.pumpAndSettle();
    expect(preview, findsOne);

    await tester.pumpWidget(
      _app(showPreview: true, zen: true, active: false, onMemento: keep),
    );
    expect(handed?.preview, isTrue);
  });
}
