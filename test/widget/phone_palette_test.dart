// #206: on a phone the palette is its own thing, not the library's
// search. Two fingers dragged down open it, as do the button on the
// Search tab and the note's ⋮ menu; the Search tab answers with notes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/palette/palette_swipe.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpPhone(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'settings notes');
    await settle(tester);
  }

  /// Drags [fingers] down [distance] from the middle of the shell.
  Future<void> swipeDown(
    WidgetTester tester, {
    int fingers = 2,
    double distance = PaletteSwipe.distance + 20,
    double sideways = 0,
  }) async {
    final centre = tester.getCenter(find.byType(PaletteSwipe));
    final pointers = [
      for (var i = 0; i < fingers; i++)
        await tester.startGesture(centre + Offset(i * 24.0 - 12, 0)),
    ];
    for (var step = 0; step < 4; step++) {
      for (final pointer in pointers) {
        await pointer.moveBy(Offset(sideways / 4, distance / 4));
      }
      await tester.pump();
    }
    for (final pointer in pointers) {
      await pointer.up();
    }
    await settle(tester);
  }

  final palette = find.byKey(const Key('command-palette'));

  testWidgets('two fingers down open the palette', (tester) async {
    await pumpPhone(tester);
    expect(palette, findsNothing);
    await swipeDown(tester);
    expect(palette, findsOne);
  });

  testWidgets('one finger, a short drag or a sideways one do not', (
    tester,
  ) async {
    await pumpPhone(tester);
    await swipeDown(tester, fingers: 1);
    expect(palette, findsNothing, reason: 'one finger belongs to the page');
    await swipeDown(tester, distance: PaletteSwipe.distance / 2);
    expect(palette, findsNothing, reason: 'too short');
    await swipeDown(tester, sideways: PaletteSwipe.slack * 3);
    expect(palette, findsNothing, reason: 'a pan, not this gesture');
    await swipeDown(tester);
    expect(palette, findsOne, reason: 'and the gesture still works after');
  });

  testWidgets('the Search tab answers with notes, and offers the palette', (
    tester,
  ) async {
    await pumpPhone(tester);
    await tester.tap(find.byKey(const Key('tab-search')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'settings');
    await settle(tester);
    // The commands used to head the results here (#155); they have their
    // own way in now.
    expect(find.byKey(const Key('search-command-tabSettings')), findsNothing);

    await tester.tap(find.byKey(const Key('search-open-palette')));
    await settle(tester);
    expect(palette, findsOne);
  });

  testWidgets('the open note offers it in its ⋮ menu', (tester) async {
    await pumpPhone(tester);
    await tester.tap(noteRow('settings notes.md'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-palette')));
    await settle(tester);
    expect(palette, findsOne);
  });
}
