// The files the library's watcher reports changed reach the open editors
// through the shell and the unsaved tracker (#1055): the shell is the one
// that joins the session's `externalChanges` to the tracker every
// mounted note view listens to.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  testWidgets('what the watcher reports is announced to the open notes', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    final filePicker = useFakeFilePicker();
    final tracker = UnsavedTracker();
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          unsavedTrackerProvider.overrideWithValue(tracker),
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

    final heard = <Set<String>>[];
    final sub = tracker.diskChanges.listen(heard.add);
    addTearDown(sub.cancel);

    controller.externalChangesController.add({'/fake/library/a.md'});
    await tester.pump();

    expect(heard, [
      {'/fake/library/a.md'},
    ]);
  });
}
