// #224: a drop as the platform delivers it — through the desktop_drop
// channel — rather than as the app's own requests are poked. The Linux
// side sends the dropped URIs as one text; the portal target sends a
// transfer key instead, and when that resolves to nothing the window
// says so rather than sitting there.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
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
  late File note;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
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
  tearDown(() {
    if (note.existsSync()) note.deleteSync();
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
        ],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
    await openLibrary(tester, filePicker);
  }

  Future<void> send(WidgetTester tester, String method, Object args) async {
    const codec = StandardMethodCodec();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'desktop_drop',
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
  }

  /// Delivers what the Linux side of desktop_drop sends: the dropped
  /// URIs as one text, and where the pointer was.
  ///
  /// GTK says the pointer left before it says what was dropped, so the
  /// plugin lets this one through only when the host itself is Linux —
  /// it asks the host, not the [TargetPlatform] a test pretends to be.
  Future<void> dropUris(WidgetTester tester, List<String> uris) async {
    await send(tester, 'performOperation_linux', <Object>[
      uris.join('\n'),
      const <double>[10, 10],
    ]);
    await settle(tester);
  }

  /// Delivers what the Windows side sends: the pointer comes in, then the
  /// dropped paths, as the paths they are.
  Future<void> dropPaths(WidgetTester tester, List<String> paths) async {
    await send(tester, 'entered', const <double>[10, 10]);
    await send(tester, 'performOperation', paths);
    await settle(tester);
  }

  /// Lets the note's read — real disk work, which the test's fake clock
  /// does not move — run a frame at a time until its text is on screen.
  ///
  /// Also what lets the test end cleanly on Windows: a read still in
  /// flight holds the file open, and the file could not be deleted.
  Future<void> untilShown(WidgetTester tester) async {
    final text = find.textContaining('Dropped', findRichText: true);
    for (var i = 0; i < 50 && text.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(text, findsWidgets, reason: 'the note shows what it says');
  }

  testWidgets(
    'a note dropped on the window opens',
    (tester) async {
      await pumpApp(tester);
      note.writeAsStringSync('# Dropped\n');

      await dropUris(tester, [Uri.file(note.path).toString()]);

      expect(
        tester.widgetList<NoteView>(find.byType(NoteView)).map((v) => v.path),
        contains(note.path),
        reason: 'the file the desktop named is the file that opens',
      );
      await untilShown(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    skip: !Platform.isLinux,
  );

  testWidgets(
    'a note dropped on the window opens, on Windows',
    (tester) async {
      await pumpApp(tester);
      note.writeAsStringSync('# Dropped\n');

      await dropPaths(tester, [note.path]);

      expect(
        tester.widgetList<NoteView>(find.byType(NoteView)).map((v) => v.path),
        contains(note.path),
        reason: 'the file the desktop named is the file that opens',
      );
      await untilShown(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
    skip: !Platform.isWindows,
  );

  // KDE hands the files through the portal, which answers with a key the
  // desktop resolves — and when it resolves to nothing, the drop used to
  // be indistinguishable from no drop at all (#224).
  // A Linux-only case: the portal is a Linux desktop's.
  testWidgets(
    'a drop that brings nothing says so',
    (tester) async {
      await pumpApp(tester);

      await dropUris(tester, const <String>['']);

      expect(find.text(AppStrings.dropNothing), findsOne);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    skip: !Platform.isLinux,
  );
}
