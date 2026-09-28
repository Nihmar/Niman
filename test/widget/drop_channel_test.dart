// #224: a drop as the platform delivers it — through the niman/drop
// channel the runners report on — rather than as the app's own requests
// are poked. A dropped file opens the way Open file opens one, a dropped
// folder goes the way a folder import goes, the frame follows the drag,
// and a drop that carries nothing says so rather than sitting there.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/drop_in.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late PlatformDropTargetService drops;
  late File note;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    // The app's own service, on a channel the test speaks down: what the
    // runners send arrives here and nowhere else.
    drops = PlatformDropTargetService();
    // Straight in the system's temp folder, not a folder of its own: the
    // note opens outside the library, which watches the folder it sits
    // in, and Windows lets go of a watched folder only some time after
    // the watch is closed — a folder of the test's own could not be
    // deleted when the test ends. The file inside it can.
    note = File(
      p.join(
        Directory.systemTemp.path,
        'niman-drop-${DateTime.now().microsecondsSinceEpoch}.md',
      ),
    );
  });
  tearDown(() async {
    await drops.dispose();
    if (note.existsSync()) note.deleteSync();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String parent = '/fake',
    bool ownService = false,
  }) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
          if (!ownService) dropTargetServiceProvider.overrideWithValue(drops),
        ],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
    await openLibrary(tester, filePicker, parent: parent);
  }

  /// What the window's drop target reports, as the runners send it.
  Future<void> fromHost(WidgetTester tester, String method, Object? args) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'niman/drop',
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );

  Future<void> dropped(WidgetTester tester, List<String> paths) async {
    await fromHost(tester, 'drop', paths);
    await settle(tester);
  }

  /// Lets real work the test's fake clock does not move — a folder walk off
  /// the isolate, a copy, a read — run a frame at a time until [done].
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 300 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('a note dropped on the window opens', (tester) async {
    await pumpApp(tester);
    note.writeAsStringSync('# Dropped\n');

    await dropped(tester, [note.path]);

    expect(
      tester.widgetList<NoteView>(find.byType(NoteView)).map((v) => v.path),
      contains(note.path),
      reason: 'the file the desktop named is the file that opens',
    );
    // Lets the read — real disk work — finish before the test ends: a read
    // still in flight holds the file open.
    await until(
      tester,
      () => find
          .textContaining('Dropped', findRichText: true)
          .evaluate()
          .isNotEmpty,
    );
  });

  // The app's own wiring, with nothing overridden: a runner's message has
  // to reach the service the app builds for itself. Every case above hands
  // the app a service of the test's own, so a drop target the app never
  // connected would still pass them (#224).
  testWidgets('a drop reaches the service the app builds itself', (
    tester,
  ) async {
    // The channel carries one handler; the test's own service lets go of it.
    await drops.dispose();
    await pumpApp(tester, ownService: true);
    note.writeAsStringSync('# Dropped\n');

    await dropped(tester, [note.path]);

    expect(
      tester.widgetList<NoteView>(find.byType(NoteView)).map((v) => v.path),
      contains(note.path),
      reason: 'the app listens to the channel a runner reports on',
    );
    await until(
      tester,
      () => find
          .textContaining('Dropped', findRichText: true)
          .evaluate()
          .isNotEmpty,
    );
  });

  testWidgets('a folder dropped on the window is imported', (tester) async {
    // Real folders on both sides: the walk and the copy read the disk.
    final tmp = Directory.systemTemp.createTempSync('niman_drop_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final source = Directory(p.join(tmp.path, 'Drafts'))..createSync();
    File(p.join(source.path, 'one.md')).writeAsStringSync('# One');
    File(p.join(source.path, 'sub', 'two.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('# Two');

    // A library of its own under the temp folder: the import writes real
    // files into it.
    await pumpApp(tester, parent: tmp.path);
    final root = controller.root!;

    await dropped(tester, [source.path]);

    // The count is a walk off the isolate, so the offer comes a turn later.
    await until(
      tester,
      () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
    );
    expect(
      find.byKey(const Key('import-folder')),
      findsOne,
      reason: 'a folder from outside the library is offered for import',
    );

    await tester.tap(find.byKey(const Key('import-folder-yes')));
    final copied = File(p.join(root, 'Drafts', 'one.md'));
    await until(
      tester,
      () => find
          .text(AppStrings.importFolderDone('Drafts'))
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text(AppStrings.importFolderDone('Drafts')), findsOne);

    expect(copied.readAsStringSync(), '# One');
    expect(
      File(p.join(root, 'Drafts', 'sub', 'two.md')).existsSync(),
      isTrue,
      reason: 'the layout inside the folder is kept',
    );
  });

  // A drag over the window: the frame says a drop would be taken.
  testWidgets('the frame follows the drag', (tester) async {
    await pumpApp(tester);

    await fromHost(tester, 'dragEntered', null);
    await tester.pump();
    expect(find.byKey(const Key('drop-frame')), findsOne);

    await fromHost(tester, 'dragExited', null);
    await tester.pump();
    expect(find.byKey(const Key('drop-frame')), findsNothing);
  });

  // The desktop can hand over a drop that names nothing, and the window
  // used to sit there as if no drop had been made at all (#224).
  testWidgets('a drop that brings nothing says so', (tester) async {
    await pumpApp(tester);

    await dropped(tester, const []);

    expect(find.text(AppStrings.dropNothing), findsOne);
  });
}
