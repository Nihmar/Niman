// #7: Settings → Library → Journal — the folder, the entry name with
// today's entry shown as it is typed, the template, and the day's start.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/ui/journal/settings_journal.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/lib', create: true);
  });

  tearDown(() => session.dispose());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsJournalScreen(
          controller: session,
          clock: () => DateTime(2026, 9, 23, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("a fresh library's journal, with today's entry spelled out", (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Journal'), findsWidgets);
    expect(find.text('YYYY/MM/YYYY-MM-DD'), findsOne);
    expect(find.text("Today's entry: Journal/2026/09/2026-09-23.md"), findsOne);
    expect(find.text('None: a heading with the date'), findsOne);
    expect(find.text('00:00'), findsOne);
  });

  testWidgets('an entry name that cannot be one is not saved', (tester) async {
    await pump(tester);
    await tester.tap(find.text('YYYY/MM/YYYY-MM-DD'));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('journal-entry-name-field'));
    await tester.enterText(field, 'YYYY-MM');
    await tester.pump();
    final save = find.byKey(const Key('journal-entry-name-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(field, 'YYYY-MM-DD');
    await tester.pump();
    expect(find.byKey(const Key('journal-entry-name-preview')), findsOne);
    expect(find.text("Today's entry: Journal/2026-09-23.md"), findsWidgets);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect((await session.journal).entryName, 'YYYY-MM-DD');
  });

  testWidgets('the template is picked from the templates, or none', (
    tester,
  ) async {
    await session.ensureFolder('Templates');
    await session.createNote(parentPath: 'Templates', name: 'Day');
    await pump(tester);
    await tester.tap(find.text('None: a heading with the date'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('journal-template-Templates/Day.md')),
    );
    await tester.pumpAndSettle();
    expect((await session.journal).template, 'Templates/Day.md');

    await tester.tap(find.text('Templates/Day.md'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-template-none')));
    await tester.pumpAndSettle();
    expect((await session.journal).template, isNull);
  });

  testWidgets('a new day can start later than midnight', (tester) async {
    await pump(tester);
    await tester.tap(find.text('00:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-day-start-4')));
    await tester.pumpAndSettle();
    expect(await session.journal, const JournalSettings(dayStartHour: 4));
  });
}
