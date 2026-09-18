// Issue #23: a note's tab hands in where it was left when it goes behind
// another, and a note opened with a memento lands there again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:re_editor/re_editor.dart';

const _text = 'first line\nsecond line\nthird line';

Widget _app({
  required CodeLineEditingController controller,
  bool active = true,
  NoteMemento? memento,
  void Function(String, NoteMemento)? onMemento,
  void Function(String, int)? onLoaded,
}) => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/n/a.md',
      showLineNumbers: true,
      autofocusEditor: false,
      controller: controller,
      active: active,
      initialMemento: memento,
      onMemento: onMemento,
      onLoaded: onLoaded,
      readNote: (_) async => _text,
      writeNote: (_, _) async {},
    ),
  ),
);

void main() {
  testWidgets('going behind another tab hands in the selection', (
    tester,
  ) async {
    final controller = CodeLineEditingController();
    NoteMemento? handed;
    int? length;
    void keep(String _, NoteMemento m) => handed = m;
    await tester.pumpWidget(
      _app(
        controller: controller,
        onMemento: keep,
        onLoaded: (_, n) => length = n,
      ),
    );
    await tester.pumpAndSettle();
    expect(length, _text.length);
    // "second" selected: line 1, offsets 0..6 → flat 11..17.
    controller.selection = const CodeLineSelection(
      baseIndex: 1,
      baseOffset: 0,
      extentIndex: 1,
      extentOffset: 6,
    );
    await tester.pump();
    await tester.pumpWidget(
      _app(controller: controller, active: false, onMemento: keep),
    );
    expect(handed?.selectionBase, 11);
    expect(handed?.selectionExtent, 17);
    expect(handed?.editorKind, 'source');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('a memento puts the selection back, clamped', (tester) async {
    final controller = CodeLineEditingController();
    await tester.pumpWidget(
      _app(
        controller: controller,
        memento: const NoteMemento(
          selectionBase: 23,
          selectionExtent: 999,
          editorKind: 'source',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selection = controller.selection;
    expect((selection.baseIndex, selection.baseOffset), (2, 0));
    // Past the end of the note: the end of its last line.
    expect((selection.extentIndex, selection.extentOffset), (2, 10));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('a selection taken in the other editor is not applied', (
    tester,
  ) async {
    final controller = CodeLineEditingController();
    await tester.pumpWidget(
      _app(
        controller: controller,
        memento: const NoteMemento(
          selectionBase: 5,
          selectionExtent: 5,
          editorKind: 'wysiwyg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.selection.extentIndex, 0);
    expect(controller.selection.extentOffset, 0);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
