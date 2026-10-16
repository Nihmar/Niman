// The shell's own hand on the workspace (#23): what it does to the notes'
// tabs. A template's `open: preview` (#51), which is asked for before the
// note has a tab, and the library loading with a note the index no longer
// holds (#372).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';

void main() {
  // #1083: a library closed or switched under the shell. Its views hand in
  // where each note was left as they go down, after the session has let go
  // of the library; the last write belongs to that library all the same.
  test(
    'the last write after a close reaches the library it belongs to',
    () async {
      final session = FakeLibrarySession();
      addTearDown(session.dispose);
      await session.open('/lib/one', create: false);
      final workspace = ShellWorkspace(session)..show('a.md');
      await pumpEventQueue();

      await session.close();
      workspace.remember('a.md', const NoteMemento(selectionExtent: 7));
      await pumpEventQueue();
      workspace.dispose();
      await pumpEventQueue();

      final kept = session.workspacesByRoot['/lib/one'];
      expect(kept?.tabs.single.memento.selectionExtent, 7);
      expect(session.workspacesByRoot.containsKey(null), isFalse);
    },
  );

  test('a preview asked for before the tab exists lands on it', () async {
    final workspace = ShellWorkspace(FakeLibrarySession());
    addTearDown(workspace.dispose);
    // The template flow files a note and asks for its preview in the same
    // turn, while the tab the follow makes is still one microtask away. The
    // cascade is the order made visible: the preview request queues behind
    // the follow that creates the tab.
    workspace
      ..follow('Notes/Filed.md', alongside: true)
      ..showPreviewWhenOpen('Notes/Filed.md');
    await pumpEventQueue();
    expect(workspace.value.tabs.single.path, 'Notes/Filed.md');
    expect(workspace.value.tabs.single.memento.preview, isTrue);
  });

  test('a preview asked for on an open note lands at once', () async {
    final workspace = ShellWorkspace(FakeLibrarySession());
    addTearDown(workspace.dispose);
    workspace.show('Notes/Open.md');
    await pumpEventQueue();
    workspace.showPreviewWhenOpen('Notes/Open.md');
    await pumpEventQueue();
    expect(workspace.value.tabs.single.memento.preview, isTrue);
  });

  test(
    'a preview asked for on a note that never arrives changes nothing',
    () async {
      final workspace = ShellWorkspace(FakeLibrarySession());
      addTearDown(workspace.dispose);
      workspace.show('Notes/Open.md');
      await pumpEventQueue();
      workspace.showPreviewWhenOpen('Notes/Elsewhere.md');
      await pumpEventQueue();
      expect(workspace.value.tabs.single.memento.preview, isNull);
    },
  );

  test(
    'a note gone before the library opened keeps its tab, flagged',
    () async {
      // The store still opens it, this session's tree never had it: no
      // `removals` event is coming, and the tab must not vanish for that.
      final session = FakeLibrarySession();
      addTearDown(session.dispose);
      await session.createNote(parentPath: '', name: 'here');
      session.workspace = Workspace.empty.open('gone.md').open('here.md');
      final workspace = ShellWorkspace(session);
      addTearDown(workspace.dispose);

      await workspace.load();

      expect(workspace.value.tabs.map((t) => t.path), ['gone.md', 'here.md']);
      expect(workspace.value.tabs.map((t) => t.missing), [true, false]);
    },
  );

  test('a removal of another note leaves the flag standing', () async {
    final session = FakeLibrarySession();
    addTearDown(session.dispose);
    await session.createNote(parentPath: '', name: 'here');
    session.workspace = Workspace.empty.open('gone.md').open('here.md');
    final workspace = ShellWorkspace(session);
    addTearDown(workspace.dispose);
    await workspace.load();

    // `here.md` is deleted outside the app now: its re-index reports that
    // removal alone, and `gone.md` is still gone.
    workspace.missing({'here.md'});

    expect(workspace.value.tabs.map((t) => t.missing), [true, true]);
  });

  test('a flagged note the index holds again loses its flag', () async {
    final session = FakeLibrarySession();
    addTearDown(session.dispose);
    session.workspace = Workspace.empty.open('back.md').open('gone.md');
    final workspace = ShellWorkspace(session);
    addTearDown(workspace.dispose);
    await workspace.load();
    expect(workspace.value.tabs.map((t) => t.missing), [true, true]);

    await session.createNote(parentPath: '', name: 'back');
    await workspace.indexChanged();

    expect(workspace.value.tabs.map((t) => t.missing), [false, true]);
  });

  test('a removal while the index is asked is not undone', () async {
    final session = FakeLibrarySession();
    addTearDown(session.dispose);
    session.workspace = Workspace.empty.open('back.md');
    final workspace = ShellWorkspace(session);
    addTearDown(workspace.dispose);
    await workspace.load();
    await session.createNote(parentPath: '', name: 'back');

    // The index is asked while the note is there, and the note goes again
    // before the answer lands: the answer is older than the removal.
    final asked = workspace.indexChanged();
    workspace.missing({'back.md'});
    await asked;

    expect(workspace.value.tabs.single.missing, isTrue);
  });
}
