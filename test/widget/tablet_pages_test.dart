// #1266: on a tablet Home and Todo are pages that want the width: the tree
// steps aside while one shows, the sidebar's toggle lays it over the page,
// and a note opened from it takes the pane back, the tree beside it again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/home/home_screen.dart';
import 'package:niman/src/ui/note_view.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';
import '../fakes/tablet_shell.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Finder treeOnScreen() => noteTree().hitTestable();

  for (final page in ['home', 'todo']) {
    testWidgets('$page takes the width, the toggle lays the tree over it', (
      tester,
    ) async {
      await pumpTabletShell(
        tester,
        controller: controller,
        filePicker: filePicker,
      );
      expect(treeOnScreen(), findsOne, reason: 'landscape: beside');

      await tester.tap(find.byKey(Key('rail-$page')));
      await settle(tester);
      expect(find.byKey(Key('content-tab-$page')), findsOne);
      expect(treeOnScreen(), findsNothing);
      if (page == 'home') expect(find.byType(HomeScreen), findsOne);

      await tester.tap(find.byKey(const Key('tabs-toggle-sidebar')));
      await settle(tester);
      expect(treeOnScreen(), findsOne);
      expect(find.byKey(const Key('tree-scrim')), findsOne);

      await tester.tap(noteRow('alpha.md'));
      await settle(tester);
      expect(find.byType(NoteView), findsOne);
      expect(treeOnScreen(), findsOne, reason: 'beside the note again');
      expect(find.byKey(const Key('tree-scrim')), findsNothing);
      expect(tester.takeException(), isNull);
    }, variant: tabletPlatform);
  }
}
