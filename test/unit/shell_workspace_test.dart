// The shell's own hand on the workspace (#23): what it does to the notes'
// tabs. Only the piece the split's removal added is here — a template's
// `open: preview` (#51), which is asked for before the note has a tab.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_workspace.dart';

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
}
