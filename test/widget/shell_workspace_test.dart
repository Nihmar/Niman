// Issue #23, PR 1: the shell keeps the workspace current — the note it
// shows, and the library changing under it — and keeps it on this device,
// with nothing on screen changed yet.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late UnsavedTracker unsaved;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    // Not disposed here: the shell watches it, and the test binding
    // finalizes the tree after tear-down callbacks.
    unsaved = UnsavedTracker();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          unsavedTrackerProvider.overrideWithValue(unsaved),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> rowMenu(WidgetTester tester, String row, String action) async {
    await tester.longPress(noteRow(row));
    await settle(tester);
    final item = find.byKey(Key('menu-$action'));
    await tester.ensureVisible(item);
    await settle(tester);
    await tester.tap(item);
    await settle(tester);
  }

  testWidgets('the note on screen is the one kept', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(controller.workspace.activePath, 'alpha.md');
    // One note at a time still: the next one takes its place.
    await controller.createNote(parentPath: '', name: 'beta');
    await settle(tester);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    expect(controller.workspace.tabs.map((t) => t.path), ['beta.md']);
  });

  testWidgets('a renamed folder takes the open note along', (tester) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createNote(parentPath: 'Docs', name: 'alpha');
    await settle(tester);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(controller.workspace.activePath, 'Docs/alpha.md');

    await rowMenu(tester, 'Docs', 'rename');
    await tester.enterText(dialogField(), 'Books');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(controller.workspace.activePath, 'Books/alpha.md');
  });

  // #507: a rename rewrites the links other notes hold, on disk, so an open
  // note's unsaved edits go there first — or its next save would put the old
  // links back.
  testWidgets('a rename saves the open notes first', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    final dirty = _DirtyNote();
    unsaved.register(dirty);

    await rowMenu(tester, 'alpha.md', 'rename');
    await tester.enterText(dialogField(), 'omega');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(dirty.saves, 1);
    expect(noteRow('omega.md'), findsOne);
  });

  testWidgets('a note that will not save stops the rename', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    unsaved.register(_DirtyNote(fails: true));

    await rowMenu(tester, 'alpha.md', 'rename');
    await tester.enterText(dialogField(), 'omega');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(noteRow('alpha.md'), findsOne, reason: 'nothing renamed');
    expect(noteRow('omega.md'), findsNothing);
  });

  testWidgets('a deleted note leaves nothing open', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await rowMenu(tester, 'alpha.md', 'delete');
    expect(controller.workspace.tabs, isEmpty);
  });

  // #1321: the open editor's debounce would write a deleted note back.
  testWidgets('a delete drops the pending saves of the note', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    final open = _DiscardNote('/fake/library/alpha.md');
    unsaved.register(open);

    await rowMenu(tester, 'alpha.md', 'delete');

    expect(open.discards, 1);
    expect(open.restores, 0);
  });

  testWidgets('a delete of a folder drops those of the notes in it', (
    tester,
  ) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createNote(parentPath: 'Docs', name: 'alpha');
    await controller.createNote(parentPath: '', name: 'beta');
    await settle(tester);
    final inside = _DiscardNote('/fake/library/Docs/alpha.md');
    final outside = _DiscardNote('/fake/library/beta.md');
    unsaved
      ..register(inside)
      ..register(outside);

    await rowMenu(tester, 'Docs', 'delete');

    expect(inside.discards, 1);
    expect(outside.discards, 0);
  });

  testWidgets('a delete that fails gives the saves back', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    controller.failDeletes.add('alpha.md');
    final open = _DiscardNote('/fake/library/alpha.md');
    unsaved.register(open);

    await rowMenu(tester, 'alpha.md', 'delete');

    expect(open.discards, 1);
    expect(open.restores, 1);
    expect(open.unsaved, isTrue, reason: 'the edits were never dropped');
  });

  // #1363: a write held for a note no longer on screen has nobody to say
  // that the disk would not take it.
  testWidgets('a failed held write is said, with the name', (tester) async {
    await pumpShell(tester);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);

    unawaited(
      unsaved
          .hold(
            '/fake/library/alpha.md',
            () => 'text',
            () async => throw const FileSystemException('disk full'),
          )
          .then((_) {}, onError: (_) {}),
    );
    await settle(tester);

    expect(find.textContaining('alpha'), findsWidgets);
    expect(find.textContaining('Could not save "alpha"'), findsOne);
    expect(unsaved.hasUnsaved, isTrue);
    // The editor that opens the note takes the text, and the retry goes.
    expect(unsaved.takeOver('/fake/library/alpha.md'), 'text');
  });

  testWidgets('what was left open comes back as tabs', (tester) async {
    // The notes are in the tree, so the store's tabs come back as they are.
    await controller.saveNote('kept.md', '');
    await controller.saveNote('other.md', '');
    controller.workspace = Workspace.empty.open('kept.md').open('other.md');
    await pumpShell(tester);
    await settle(tester);
    expect(controller.workspace.activePath, 'other.md');
    // On a wide window the tabs are drawn from it (#23, PR 2).
    expect(find.byKey(const Key('note-tab-0')), findsOne);
    expect(find.byKey(const Key('note-tab-1')), findsOne);
    expect(find.byKey(const Key('note-top-bar')), findsOne);
  });
}

/// An open note holding edits the disk does not have yet.
final class _DirtyNote implements UnsavedNote {
  new({this.fails = false});

  /// Whether its save fails, as a full disk's would.
  final bool fails;

  /// How many times it was saved.
  int saves = 0;

  @override
  String get path => '/fake/library/open.md';

  @override
  bool get unsaved => saves == 0;

  @override
  String get text => '';

  @override
  Future<void> save() async {
    if (fails) throw const FileSystemException('disk full');
    saves++;
  }
}

/// An open note that can drop its pending writes for a delete.
final class _DiscardNote implements UnsavedNote, UnsavedNoteDiscard {
  new(this.path);

  @override
  final String path;

  int discards = 0;
  int restores = 0;

  @override
  bool unsaved = true;

  @override
  String get text => '';

  @override
  Future<void> save() async => unsaved = false;

  @override
  Future<void> discard() async {
    discards++;
    unsaved = false;
  }

  @override
  void restore() {
    restores++;
    unsaved = true;
  }
}
