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

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late Directory temp;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    temp = Directory.systemTemp.createTempSync('niman-drop');
  });
  tearDown(() => temp.deleteSync(recursive: true));

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

  /// Delivers what the Linux side of desktop_drop sends: the dropped
  /// URIs as one text, and where the pointer was.
  Future<void> dropUris(WidgetTester tester, List<String> uris) async {
    const codec = StandardMethodCodec();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'desktop_drop',
      codec.encodeMethodCall(
        MethodCall('performOperation_linux', <Object>[
          uris.join('\n'),
          const <double>[10, 10],
        ]),
      ),
      (_) {},
    );
    await settle(tester);
  }

  testWidgets('a note dropped on the window opens', (tester) async {
    await pumpApp(tester);
    final note = File('${temp.path}/dropped.md')
      ..writeAsStringSync('# Dropped\n');

    await dropUris(tester, [Uri.file(note.path).toString()]);

    expect(
      tester.widgetList<NoteView>(find.byType(NoteView)).map((v) => v.path),
      contains(note.path),
      reason: 'the file the desktop named is the file that opens',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  // KDE hands the files through the portal, which answers with a key the
  // desktop resolves — and when it resolves to nothing, the drop used to
  // be indistinguishable from no drop at all (#224).
  testWidgets('a drop that brings nothing says so', (tester) async {
    await pumpApp(tester);

    await dropUris(tester, const <String>['']);

    expect(find.text(AppStrings.dropNothing), findsOne);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
