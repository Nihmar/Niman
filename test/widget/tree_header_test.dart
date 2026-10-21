// #1134: on a window with no title bar of the app's own, a line over the
// tree says which library it is and which folder the selection is in. It
// is as tall as the panes' tab row, and the tree's footer meets the note's
// status row, so the rules on either side line up.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/tree_header.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpShell(WidgetTester tester, {bool ownBar = false}) async {
    setSurfaceSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: ownBar),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Inbox');
    await controller.createNote(parentPath: 'Inbox', name: 'idea');
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
  }

  final header = find.byKey(const Key('tree-header'));
  final folder = find.byKey(const Key('tree-header-folder'));

  testWidgets('it names the library, and the folder of the selection', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(header, findsOne);
    final library = tester.widget<Text>(
      find.byKey(const Key('tree-header-library')),
    );
    expect(library.data, p.basename(controller.root!));
    // The root says nothing more.
    expect(folder, findsNothing);

    await tester.tap(noteRow('Inbox'));
    await settle(tester);
    expect(tester.widget<Text>(folder).data, 'Inbox');

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(folder, findsNothing);
  });

  testWidgets("its rule meets the tab row's, the footer the status row", (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    final row = find.byKey(const Key('pane-tab-row'));
    expect(tester.getRect(header).bottom, tester.getRect(row).bottom);
    expect(
      tester.getRect(find.byKey(const Key('tree-footer'))).top,
      tester.getRect(find.byKey(const Key('status-row'))).top,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets("a title bar of the app's own says it instead", (tester) async {
    await pumpShell(tester, ownBar: true);
    expect(header, findsNothing);
  });

  testWidgets('a large text scale cuts the folder line, not the row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Material(
            child: Column(
              children: [
                TreeHeader(
                  library: 'Notes',
                  folder: 'projects/2026',
                  height: 56,
                  onSwitchLibrary: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('tree-header'))).height, 56);
  });
}
