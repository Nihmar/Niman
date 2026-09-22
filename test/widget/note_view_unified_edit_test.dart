// The unified source pane inside the shell: what the shell does to the note
// has to reach the note, and what reaches the note has to reach the disk.
//
// Every command here used to edit the legacy editor's controller, which the
// unified pane does not show — the command's work went nowhere, and the save it
// scheduled wrote the note without it. So each test ends where a writer's work
// ends: in the text handed to `writeNote`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

import '../fakes/fake_embedder.dart';

/// A shell-sized note view over the unified source pane.
NoteView _view({
  required Future<String> Function(String) readNote,
  required List<String> writes,
  int reloadToken = 0,
  bool showWysiwyg = false,
  bool unified = true,
}) => NoteView(
  path: '/notes/a.md',
  showLineNumbers: false,
  autofocusEditor: false,
  toolbarTop: true,
  unifiedMarkdown: unified,
  showWysiwyg: showWysiwyg,
  readNote: readNote,
  writeNote: (_, text) async => writes.add(text),
  reloadToken: reloadToken,
);

Future<void> _pump(WidgetTester tester, NoteView view) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
  await tester.pumpAndSettle();
}

MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

/// Lets the save debounce run out.
Future<void> _settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a note of tens of megabytes waits for a real pause to save', (
    tester,
  ) async {
    // Its save stalls the window for 0.4 s: after every half-second breath
    // that was typing that stuttered.
    final line = '${List.filled(180, 'word').join(' ')}\n';
    final note = line * 20000;
    expect(note.length, greaterThan(16 << 20));
    final writes = <String>[];
    await _pump(tester, _view(readNote: (_) async => note, writes: writes));
    _surface(tester).select(const SelectionModel(anchor: 0, extent: 4));
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump(const Duration(seconds: 2));
    expect(writes, isEmpty, reason: 'two seconds is not a pause here');
    await tester.pump(const Duration(seconds: 4));
    expect(writes, hasLength(1));
    expect(writes.single, startsWith('**word** word'));
  });

  testWidgets('a toolbar command edits the note and the note is saved', (
    tester,
  ) async {
    final writes = <String>[];
    await _pump(
      tester,
      _view(readNote: (_) async => 'una parola qui', writes: writes),
    );
    _surface(tester).select(const SelectionModel(anchor: 4, extent: 10));
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(_surface(tester).widget.buffer.text, 'una **parola** qui');
    await _settleSave(tester);
    expect(writes, isNotEmpty);
    expect(writes.last, 'una **parola** qui');
  });

  testWidgets('what the keyboard types is what is saved', (tester) async {
    final writes = <String>[];
    final platform = FakeEmbedder(tester, EmbedderProfile.android)..install();
    await _pump(tester, _view(readNote: (_) async => 'ciao', writes: writes));
    _surface(tester).placeCaret(4);
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    _surface(tester).placeCaret(4);
    await tester.pump();
    await platform.type(' mondo');
    await platform.backspace();
    await _settleSave(tester);
    expect(writes.last, 'ciao mond');
  });

  testWidgets('a change on disk is adopted, and edits build on it', (
    tester,
  ) async {
    var disk = '- [ ] uno';
    final writes = <String>[];
    await _pump(tester, _view(readNote: (_) async => disk, writes: writes));
    disk = '- [x] uno';
    await _pump(
      tester,
      _view(readNote: (_) async => disk, writes: writes, reloadToken: 1),
    );
    expect(
      _surface(tester).widget.buffer.text,
      '- [x] uno',
      reason: 'the surface shows what the disk now says',
    );
    expect(writes, isEmpty, reason: 'adopting the disk is not an edit');
    _surface(tester)
      ..placeCaret(9)
      ..deleteBackward();
    await _settleSave(tester);
    expect(
      writes.last,
      '- [x] un',
      reason: 'the edit is on the disk text, not on the one it replaced',
    );
  });

  testWidgets('the WYSIWYG opens with what the unified pane holds', (
    tester,
  ) async {
    final writes = <String>[];
    await _pump(tester, _view(readNote: (_) async => 'prima', writes: writes));
    _surface(tester)
      ..placeCaret(5)
      ..replaceText(5, 5, ' e dopo');
    await tester.pump();
    await _pump(
      tester,
      _view(readNote: (_) async => 'prima', writes: writes, showWysiwyg: true),
    );
    expect(
      find.textContaining('prima e dopo', findRichText: true),
      findsWidgets,
      reason: 'the WYSIWYG got the edited text, not the text at load',
    );
    await _settleSave(tester);
    if (writes.isNotEmpty) expect(writes.last, 'prima e dopo');
  });

  testWidgets('the legacy editor takes the note when the engine goes back', (
    tester,
  ) async {
    // The legacy controller is left empty under the unified engine — filling
    // it froze the app on a 22 MB note — so switching back has to fill it
    // with what the unified pane holds, edits included.
    final writes = <String>[];
    await _pump(tester, _view(readNote: (_) async => 'prima', writes: writes));
    _surface(tester)
      ..placeCaret(5)
      ..replaceText(5, 5, ' e dopo');
    await tester.pump();
    await _pump(
      tester,
      _view(readNote: (_) async => 'prima', writes: writes, unified: false),
    );
    expect(find.byType(MarkdownSourceView), findsNothing);
    // And forward again: the unified buffer takes what the legacy controller
    // holds, so the edit is still there only if the legacy editor got it.
    await _pump(tester, _view(readNote: (_) async => 'prima', writes: writes));
    expect(_surface(tester).widget.buffer.text, 'prima e dopo');
    await _settleSave(tester);
    expect(writes.last, 'prima e dopo');
  });
}
