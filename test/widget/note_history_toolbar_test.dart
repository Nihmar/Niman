// #1336: undo and redo in the editor's toolbar, driven by what the history
// holds; #1358: a note undone to the text the disk holds is saved.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_view.dart';

const String _note = 'one two three\n';

NoteView _view(List<String> writes) => NoteView(
  path: '/notes/a.md',
  options: const NoteEditorOptions(
    showLineNumbers: false,
    autofocusEditor: false,
  ),
  toolbarTop: true,
  services: NoteServices(
    readNote: (_) async => _note,
    writeNote: (_, text) async => writes.add(text),
  ),
);

Future<void> _pump(WidgetTester tester, NoteView view) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(visualDensity: VisualDensity.compact),
      home: Scaffold(body: view),
    ),
  );
  await tester.pumpAndSettle();
}

MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

String _text(WidgetTester tester) => _surface(tester).widget.buffer.text;

/// Whether the toolbar button [key] can be pressed.
bool _enabled(WidgetTester tester, String key) =>
    tester.widget<InkWell>(find.byKey(Key(key))).onTap != null;

Future<void> _bold(WidgetTester tester, int from, int to) async {
  _surface(tester).select(SelectionModel(anchor: from, extent: to));
  await tester.pump();
  await tester.tap(find.byKey(const Key('toolbar-bold')));
  await tester.pump();
}

/// Lets the save debounce run out.
Future<void> _settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the buttons follow the history and undo and redo the note', (
    tester,
  ) async {
    await _pump(tester, _view(<String>[]));
    expect(_enabled(tester, 'toolbar-undo'), isFalse, reason: 'nothing yet');
    expect(_enabled(tester, 'toolbar-redo'), isFalse);

    await _bold(tester, 0, 3);
    expect(_text(tester), '**one** two three\n');
    expect(_enabled(tester, 'toolbar-undo'), isTrue);
    expect(_enabled(tester, 'toolbar-redo'), isFalse);

    await tester.tap(find.byKey(const Key('toolbar-undo')));
    await tester.pump();
    expect(_text(tester), _note);
    expect(
      _surface(tester).selection,
      const SelectionModel(anchor: 0, extent: 3),
      reason: 'the word it was applied to is selected again',
    );
    expect(_enabled(tester, 'toolbar-undo'), isFalse);
    expect(_enabled(tester, 'toolbar-redo'), isTrue);

    await tester.tap(find.byKey(const Key('toolbar-redo')));
    await tester.pump();
    expect(_text(tester), '**one** two three\n');
    expect(_enabled(tester, 'toolbar-undo'), isTrue);
    expect(_enabled(tester, 'toolbar-redo'), isFalse);
  });

  testWidgets('a note undone to the saved text is not written again', (
    tester,
  ) async {
    final writes = <String>[];
    await _pump(tester, _view(writes));
    await _bold(tester, 0, 3);
    await _settleSave(tester);
    expect(writes, ['**one** two three\n']);

    // Another edit, and undone before the save it owes.
    await _bold(tester, 12, 17);
    await tester.tap(find.byKey(const Key('toolbar-undo')));
    await tester.pump();
    await _settleSave(tester);
    expect(writes, hasLength(1), reason: 'the disk already holds this text');

    // Redo is an edit the disk does not have.
    await tester.tap(find.byKey(const Key('toolbar-redo')));
    await tester.pump();
    await _settleSave(tester);
    expect(writes, hasLength(2));
    expect(writes.last, '**one** two **three**\n');
  });
}
