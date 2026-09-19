// Issue #75 in the app: what is dropped on the window reaches the same
// flows a launch does. A Markdown file opens as #77 opens one; a folder
// of the library is shown in the tree; a folder from elsewhere is offered
// for import and shown once it is in; with no library open, a folder
// opens as one; and what cannot be opened is named.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/drop_target.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late LaunchRequests requests;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    requests = LaunchRequests();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
          launchRequestsProvider.overrideWithValue(requests),
        ],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
  }

  void drop(WidgetTester tester, List<String> paths, {Set<String>? dirs}) =>
      deliverDrop(
        sortDrop(paths, isFolder: (path) => dirs?.contains(path) ?? false),
        requests,
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)),
      );

  final outside = find.byKey(const Key('outside-file-bar'));

  testWidgets('a Markdown file opens on its own; the rest is named', (
    tester,
  ) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    drop(tester, ['/elsewhere/a.md', '/elsewhere/photo.png']);
    await settle(tester);
    expect(outside, findsOne);
    expect(find.textContaining('photo.png'), findsOne);
  });

  testWidgets('a folder of the library is shown in the tree', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Work');
    await controller.createFolder(parentPath: 'Work', name: 'Plans');
    await settle(tester);
    final path = '${controller.root}/Work/Plans';
    drop(tester, [path], dirs: {path});
    await settle(tester);
    // Its parent opened on the way to it.
    expect(noteRow('Plans'), findsOne);
  });

  testWidgets('a folder from elsewhere is offered for import, copied in, '
      'and the library re-read', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('niman-drop');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final drafts = Directory(p.join(tmp.path, 'Drafts'))..createSync();
    File(p.join(drafts.path, 'one.md')).writeAsStringSync('# One');
    await pumpApp(tester);
    await openLibrary(tester, filePicker, parent: tmp.path);

    await tester.runAsync(() async {
      drop(tester, [drafts.path], dirs: {drafts.path});
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settle(tester);
    expect(find.byKey(const Key('import-folder')), findsOne);

    await tester.tap(find.byKey(const Key('import-folder-yes')));
    // The copy is real disk work: let it run, a frame at a time.
    for (var i = 0; i < 40 && controller.rescans == 0; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await settle(tester);
    expect(
      File(p.join(controller.root!, 'Drafts', 'one.md')).existsSync(),
      isTrue,
    );
    expect(controller.rescans, 1);
    expect(find.textContaining('Imported into Drafts'), findsOne);
  });

  testWidgets('declined, the import writes nothing', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('niman-drop');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final drafts = Directory(p.join(tmp.path, 'Drafts'))..createSync();
    File(p.join(drafts.path, 'one.md')).writeAsStringSync('# One');
    await pumpApp(tester);
    await openLibrary(tester, filePicker, parent: tmp.path);
    await tester.runAsync(() async {
      drop(tester, [drafts.path], dirs: {drafts.path});
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(Directory(p.join(controller.root!, 'Drafts')).existsSync(), isFalse);
  });

  testWidgets('with no library open, a folder opens as one', (tester) async {
    await pumpApp(tester);
    drop(tester, ['/some/notes'], dirs: {'/some/notes'});
    await settle(tester);
    expect(controller.root, '/some/notes');
    expect(noteTree(), findsOne);
  });
}
