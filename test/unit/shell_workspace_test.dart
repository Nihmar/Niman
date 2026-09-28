// The shell's own hand on the workspace (#23): what it does to the notes'
// tabs. A template's `open: preview` (#51), which is asked for before the
// note has a tab, and the library loading with a note the index no longer
// holds (#372).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_library_session.dart';

void main() {
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
}
