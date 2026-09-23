// #7: where the journal is reached — the phone's + button and File bar,
// the desktop's dock, the strip's day.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/journal/journal_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() => ProviderScope(
    overrides: [librarySessionProvider.overrideWithValue(controller)],
    child: const NimanApp(),
  );

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  String todayPath() {
    const journal = JournalSettings();
    return journal.entryPath(journal.today(DateTime.now()));
  }

  testWidgets("phone: the + button opens today's entry, with its strip", (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('journal-today-action')));
    await settle(tester);
    expect(controller.contentOf(todayPath()), startsWith('# '));
    expect(find.byKey(const Key('journal-strip')), findsOne);
    await controller.close();
    await controller.dispose();
  });

  testWidgets('phone: the File bar opens the Journal screen', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const Key('open-journal')));
    await settle(tester);
    expect(find.byType(JournalScreen), findsOne);
    // Today, picked by default, is made from its card and opened in the
    // shell, the screen gone.
    await tester.tap(find.byKey(const Key('journal-day-open')));
    await settle(tester);
    expect(find.byType(JournalScreen), findsNothing);
    expect(controller.contentOf(todayPath()), startsWith('# '));
    await controller.close();
    await controller.dispose();
  });

  testWidgets("desktop: the strip's day opens the journal in the dock", (
    tester,
  ) async {
    await pumpAt(tester, const Size(1400, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.byType(JournalBrowser), findsNothing);
    await tester.tap(find.byKey(const Key('journal-day')));
    await settle(tester);
    expect(find.byType(JournalBrowser), findsOne);
    expect(find.byKey(const Key('right-dock')), findsOne);
    expect(find.byType(JournalScreen), findsNothing);
    await controller.close();
    await controller.dispose();
  });
}
