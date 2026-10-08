// #538: the note's text zooms in and out from the keyboard — Ctrl+=,
// Ctrl+- and Ctrl+0, the browsers' keys — through the library's note text
// size, the setting the slider sets. With a book on screen the same keys
// zoom the book's text instead, on the books' own size.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  tearDown(() {
    AppTextScales.reset();
    EpubLooks.reset();
  });

  test('a zoom step lands on the grid, in range', () {
    expect(AppTextScales.zoomed(1, 1), closeTo(1.1, 1e-9));
    expect(AppTextScales.zoomed(1, -1), closeTo(0.9, 1e-9));
    expect(AppTextScales.zoomed(1.25, 1), closeTo(1.4, 1e-9));
    expect(AppTextScales.zoomed(maxTextScale, 1), maxTextScale);
    expect(AppTextScales.zoomed(minTextScale, -1), minTextScale);
    expect(AppTextScales.zoomed(1.6, 0), defaultTextScale);
  });

  /// The shell on a wide window over [controller]'s library.
  Future<void> pumpShell(
    WidgetTester tester,
    FakeLibrarySession controller,
  ) async {
    final picker = useFakeFilePicker();
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
    await tester.pump();
    await openLibrary(tester, picker);
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  testWidgets('Ctrl+= and Ctrl+- zoom the note, Ctrl+0 puts it back', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    await pumpShell(tester, controller);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    await press(tester, LogicalKeyboardKey.equal);
    await press(tester, LogicalKeyboardKey.equal);
    expect(await controller.noteTextScale, closeTo(1.2, 1e-9));
    expect(AppTextScales.note, closeTo(1.2, 1e-9));
    await press(tester, LogicalKeyboardKey.minus);
    expect(await controller.noteTextScale, closeTo(1.1, 1e-9));
    await press(tester, LogicalKeyboardKey.digit0);
    expect(await controller.noteTextScale, defaultTextScale);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("a book on screen zooms the books' text, not the note's", (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    await pumpShell(tester, controller);
    await controller.seedFile('book.epub');
    await settle(tester);
    // The focus stays in the tree: the shell's keys find the book.
    await tester.tap(noteRow('book.epub'));
    await settle(tester);

    await press(tester, LogicalKeyboardKey.equal);
    expect((await controller.epubLook).textScale, closeTo(1.1, 1e-9));
    expect(await controller.noteTextScale, defaultTextScale);
    await press(tester, LogicalKeyboardKey.digit0);
    expect((await controller.epubLook).textScale, defaultTextScale);

    // A pinch over the book is the book's: the note's size stays.
    final at = tester.getCenter(find.byType(AttachmentView));
    final one = await tester.startGesture(at - const Offset(30, 0));
    final two = await tester.startGesture(at + const Offset(30, 0));
    await one.moveTo(at - const Offset(45, 0));
    await two.moveTo(at + const Offset(45, 0));
    await tester.pump();
    await one.up();
    await two.up();
    await settle(tester);
    expect(await controller.noteTextScale, defaultTextScale);
    expect(AppTextScales.note, defaultTextScale);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
