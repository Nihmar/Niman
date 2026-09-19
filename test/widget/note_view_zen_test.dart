// Issue #69: a note in Zen mode. Its row above, its status row and its
// row numbers go, the caret thickens, and the preview — split or on its
// own — makes way for the editor without being turned off: the tab's
// memento still says it was on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/ui/editor_preview_split.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/workspace/note_memento.dart';

Widget _app({
  bool zen = false,
  bool active = true,
  bool showPreview = false,
  bool splitPreview = false,
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
      splitPreview: splitPreview,
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

  testWidgets('the split preview makes way for the editor', (tester) async {
    await tester.pumpWidget(_app(splitPreview: true));
    await tester.pumpAndSettle();
    expect(find.byType(EditorPreviewSplit), findsOne);

    await tester.pumpWidget(_app(splitPreview: true, zen: true));
    await tester.pumpAndSettle();
    expect(find.byType(EditorPreviewSplit), findsNothing);
    expect(preview, findsNothing);
    expect(find.byType(NoteEditor), findsOne);
  });

  testWidgets('the preview is hidden, not turned off: its tab going behind '
      'another still hands it in as on', (tester) async {
    NoteMemento? handed;
    void keep(String _, NoteMemento m) => handed = m;
    await tester.pumpWidget(_app(showPreview: true, onMemento: keep));
    await tester.pumpAndSettle();
    expect(preview, findsOne);

    await tester.pumpWidget(
      _app(showPreview: true, zen: true, onMemento: keep),
    );
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
    expect(find.byType(NoteEditor), findsOne);

    await tester.pumpWidget(
      _app(showPreview: true, zen: true, active: false, onMemento: keep),
    );
    expect(handed?.preview, isTrue);

    await tester.pumpWidget(_app(showPreview: true, onMemento: keep));
    await tester.pumpAndSettle();
    expect(preview, findsOne);
  });
}
