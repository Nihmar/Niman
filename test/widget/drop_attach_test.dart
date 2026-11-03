// #1250: a file dropped on the window with a note open — a PDF, a picture,
// what nothing opens — is copied into the library's attachments folder and
// linked at the note's caret, as a pasted one is (#1249), while a note
// dropped beside it still opens. With no note on screen it is named and
// left alone, as before.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/drop_in.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/drop_target.dart';
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
  late Directory sandbox;
  late String pdf;

  final foldersOffIsolate = foldersAmong;
  setUpAll(
    () => foldersAmong = (paths) async => {
      for (final path in paths)
        if (FileSystemEntity.isDirectorySync(path)) path,
    },
  );
  tearDownAll(() => foldersAmong = foldersOffIsolate);

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    drops = PlatformDropTargetService();
    sandbox = Directory.systemTemp.createTempSync('niman_drop_attach_');
    pdf = p.join(sandbox.path, 'Ticket.pdf');
    File(pdf).writeAsStringSync('%PDF-1.7');
  });
  tearDown(() async {
    await drops.dispose();
    sandbox.deleteSync(recursive: true);
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
          dropTargetServiceProvider.overrideWithValue(drops),
        ],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
    await openLibrary(tester, filePicker, parent: sandbox.path);
  }

  Future<void> dropped(WidgetTester tester, List<String> paths) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'niman/drop',
      const StandardMethodCodec().encodeMethodCall(MethodCall('drop', paths)),
      (_) {},
    );
    await settle(tester);
  }

  /// Lets real work the fake clock does not move — the copy into the
  /// library, in an isolate — run a frame at a time until [done].
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 300 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  String? noteText(WidgetTester tester) {
    final views = find.byType(MarkdownSourceView, skipOffstage: false);
    if (views.evaluate().isEmpty) return null;
    return tester
        .state<MarkdownSourceViewState>(views.first)
        .widget
        .buffer
        .text;
  }

  testWidgets('a PDF dropped on the open note is attached at its caret', (
    tester,
  ) async {
    await pumpApp(tester);
    await controller.createNote(parentPath: '', name: 'trip');
    // The library is on a real disk, where the shell looks for the note's
    // file as well as its row.
    File(p.join(controller.root!, 'trip.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    await settle(tester);
    await tester.tap(noteRow('trip.md'));
    // The note's opening is real work the fake clock does not move.
    await until(tester, () => noteText(tester) != null);
    await settle(tester);
    expect(noteText(tester), '');

    await dropped(tester, [pdf]);
    await until(tester, () => noteText(tester)?.isNotEmpty ?? false);

    final stored = '${sha256.convert(File(pdf).readAsBytesSync())}.pdf';
    final root = controller.root!;
    expect(noteText(tester), contains('Ticket.pdf'));
    expect(noteText(tester), contains(stored));
    expect(File(p.join(root, 'assets', stored)).existsSync(), isTrue);
    expect(
      find.text(AppStrings.dropRejected('Ticket.pdf')),
      findsNothing,
      reason: 'taken by the note, not refused',
    );
  });

  testWidgets('with no note open, the PDF is named and left alone', (
    tester,
  ) async {
    await pumpApp(tester);
    await dropped(tester, [pdf]);
    expect(find.text(AppStrings.dropRejected('Ticket.pdf')), findsOne);
    expect(Directory(p.join(controller.root!, 'assets')).existsSync(), isFalse);
  });
}
