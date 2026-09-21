// Issue #23's acceptance criteria, checked on the pieces the app runs:
//
// - two notes are edited independently, and each keeps its state across
//   a switch (its text and its own undo);
// - each keeps its state across a restart (where it was left, through
//   the store);
// - closing the window asks about every unsaved one.
//
// The pane split and the phone's switcher have their own suites
// (shell_split_test, open_notes_switcher_test).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/close_guard.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/shell_detail_pane.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_store.dart';
import 'package:re_editor/re_editor.dart';

import '../fakes/fake_window_controller.dart';

const _notes = {'/lib/a.md': 'alpha text', '/lib/b.md': 'beta text'};

/// The deck showing [active] of a.md and b.md, both mounted.
Widget _deck(
  String active, {
  required UnsavedTracker tracker,
  Map<String, NoteMemento> mementos = const {},
  void Function(String, NoteMemento)? onMemento,
  Future<void> Function(String, String)? write,
}) => ShellDetailPane(
  root: '/lib',
  unifiedMarkdown: false,
  tabs: [
    for (final path in ['a.md', 'b.md'])
      DetailTab(
        path: path,
        active: path == active,
        memento: mementos[path] ?? const NoteMemento(),
        showWysiwyg: false,
        showPreview: false,
        splitPreview: false,
      ),
  ],
  onMemento: onMemento,
  readNote: (path) async => _notes[path]!,
  writeNote: write ?? (_, _) async {},
  showLineNumbers: true,
  noteColumn: NoteColumn.off,
  barActions: const [],
  autofocusEditor: false,
  linkType: LinkType.wikilink,
  missingNoteLocation: MissingNoteLocation.currentFolder,
  attachmentsFolder: 'assets',
  indentWidth: 2,
  toolbarLayout: ToolbarLayout.defaults,
  onEditorKindChanged: null,
  splitFraction: 0.5,
  onSplitFractionChanged: (_) {},
  onSplitDragEnd: () {},
  linkSource: null,
  onOpenNote: (_, _) {},
  kindMode: true,
  onNoteKindChanged: (_) {},
  unsavedTracker: tracker,
  statusActions: const [],
  spellCheck: EditorSpellCheck(createChecker: (_) => const _NoSpelling()),
);

/// The editor controller of the note at [path], mounted or behind.
CodeLineEditingController _editorOf(WidgetTester tester, String path) {
  final view = find.byWidgetPredicate(
    (w) => w is NoteView && w.path.endsWith(path),
    skipOffstage: false,
  );
  return tester
      .widget<NoteEditor>(
        find.descendant(
          of: view,
          matching: find.byType(NoteEditor, skipOffstage: false),
          skipOffstage: false,
        ),
      )
      .controller;
}

/// A checker with nothing to say: the criteria are not about spelling.
final class _NoSpelling implements SpellChecker {
  const new();

  @override
  bool get available => false;

  @override
  bool isCorrect(String word) => true;

  @override
  List<String> suggest(String word) => const [];

  @override
  void dispose() {}
}

void main() {
  testWidgets('two notes edited independently keep their state across a '
      'switch', (tester) async {
    final tracker = UnsavedTracker();
    Widget app(String active) => MaterialApp(
      home: Scaffold(body: _deck(active, tracker: tracker)),
    );
    await tester.pumpWidget(app('a.md'));
    await tester.pumpAndSettle();

    final a = _editorOf(tester, 'a.md')
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 10)
      ..replaceSelection(' + A');
    await tester.pumpWidget(app('b.md'));
    await tester.pumpAndSettle();
    final b = _editorOf(tester, 'b.md')
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 9)
      ..replaceSelection(' + B');
    await tester.pumpWidget(app('a.md'));
    await tester.pumpAndSettle();

    // Each kept its own text, in its own editor...
    expect(identical(_editorOf(tester, 'a.md'), a), isTrue);
    expect(a.text, 'alpha text + A');
    expect(b.text, 'beta text + B');
    // ...and its own undo: undoing A leaves B alone.
    expect(a.canUndo, isTrue);
    a.undo();
    expect(a.text, 'alpha text');
    expect(b.text, 'beta text + B');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('where a note was left survives a restart', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = WorkspaceStore(db);
    final tracker = UnsavedTracker();
    var workspace = Workspace.empty.open('a.md').open('b.md');
    void remember(String path, NoteMemento memento) =>
        workspace = workspace.withMemento(path, memento);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _deck('a.md', tracker: tracker, onMemento: remember),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _editorOf(tester, 'a.md').selection = const CodeLineSelection(
      baseIndex: 0,
      baseOffset: 6,
      extentIndex: 0,
      extentOffset: 10,
    );
    await tester.pump();
    // Quitting takes the views down; each hands in where it was left.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.save('/lib', workspace));

    // The next launch.
    final restored = (await tester.runAsync(() => store.load('/lib')))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _deck(
            'a.md',
            tracker: UnsavedTracker(),
            mementos: {for (final tab in restored.tabs) tab.path: tab.memento},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selection = _editorOf(tester, 'a.md').selection;
    expect((selection.baseOffset, selection.extentOffset), (6, 10));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('closing the window asks about every unsaved note', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    final written = <String, String>{};
    Future<void> write(String path, String content) async =>
        written[path] = content;
    Widget app(String active) => MaterialApp(
      home: CloseGuard(
        tracker: tracker,
        window: window,
        child: Scaffold(
          body: _deck(active, tracker: tracker, write: write),
        ),
      ),
    );
    await tester.pumpWidget(app('a.md'));
    await tester.pumpAndSettle();
    _editorOf(tester, 'a.md').replaceSelection('x');
    await tester.pumpWidget(app('b.md'));
    await tester.pump();
    _editorOf(tester, 'b.md').replaceSelection('y');
    await tester.pump();
    // Both before their autosave: one showing, one kept behind.
    expect(tracker.unsavedPaths, hasLength(2));

    window.onCloseRequested!();
    await tester.pump();
    // One question for all of them...
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOne);
    expect(
      find.descendant(of: dialog, matching: find.textContaining('2 notes')),
      findsOne,
    );
    // ...and its answer writes every one, the tab behind included,
    // before the window goes.
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(written.keys, unorderedEquals(['/lib/a.md', '/lib/b.md']));
    expect(tracker.hasUnsaved, isFalse);
    expect(window.closeCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
