// #7: a day's entry is opened when it exists and made when it does not —
// today's at once, another day's after asking — from the journal's
// template, dated with its own day.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/shell_template_flow.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;
  late JournalFlow flow;
  late List<String> opened;
  late List<(String, int?)> created;
  var now = DateTime(2026, 9, 23, 10, 30);

  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  setUp(() async {
    now = DateTime(2026, 9, 23, 10, 30);
    session = FakeLibrarySession();
    await session.open('/lib', create: true);
    opened = [];
    created = [];
    flow = JournalFlow(
      controller: session,
      templates: ShellTemplateFlow(
        controller: session,
        origin: () => (selected: null, isDir: false, treeVisible: true),
        createParent: () => '',
        guard: (action) => action(),
        opensPreviewOnly: () => false,
        onNoteFiled: ({required path, required preview, required caret}) {},
      ),
      guard: (action) => action(),
      onOpen: opened.add,
      onCreated: (path, caret) => created.add((path, caret)),
      clock: () => now,
    );
  });

  tearDown(() => session.dispose());

  const today = 'Journal/2026/09/2026-09-23.md';

  testWidgets("today's entry is made at once, then opened", (tester) async {
    final context = await pump(tester);
    await flow.openToday(context);
    expect(created.single.$1, today);
    expect(session.contentOf(today), '# Wednesday 23 September 2026\n\n');
    expect(created.single.$2, '# Wednesday 23 September 2026\n\n'.length);

    await flow.openToday(context);
    expect(opened, [today]);
    expect(created, hasLength(1));
  });

  testWidgets('another day asks first, and a no makes nothing', (tester) async {
    final context = await pump(tester);
    final asked = flow.openDay(context, DateTime(2026, 9, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('journal-create-dialog')), findsOne);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await asked;
    expect(created, isEmpty);

    final again = flow.openDay(context, DateTime(2026, 9, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-create-confirm')));
    await tester.pumpAndSettle();
    await again;
    expect(created.single.$1, 'Journal/2026/09/2026-09-20.md');
    expect(
      session.contentOf('Journal/2026/09/2026-09-20.md'),
      startsWith('# Sunday 20 September 2026'),
    );
  });

  testWidgets("the journal's template makes the entry, with its day's date", (
    tester,
  ) async {
    await session.ensureFolder('Templates');
    await session.createNote(
      parentPath: 'Templates',
      name: 'Day',
      content:
          '---\nniman:\n  folder: Elsewhere\n---\n'
          '# {{date:dddd}} {{title}}\n[[{{date|-1d}}]] · {{time}}\n',
    );
    now = DateTime(2026, 9, 23, 0, 30);
    await session.setJournal(
      const JournalSettings(template: 'Templates/Day.md', dayStartHour: 4),
    );
    final context = await pump(tester);
    await flow.openToday(context);
    // Half past midnight with the day starting at four: still the 22nd.
    const path = 'Journal/2026/09/2026-09-22.md';
    expect(created.single.$1, path);
    expect(
      session.contentOf(path),
      '# Tuesday 2026-09-22\n[[2026-09-21]] · 00:30\n',
    );
  });

  testWidgets('a template that is gone still makes the entry', (tester) async {
    await session.setJournal(
      const JournalSettings(template: 'Templates/Missing.md'),
    );
    final context = await pump(tester);
    await flow.openToday(context);
    await tester.pump();
    expect(created.single.$1, today);
    expect(find.textContaining('Templates/Missing.md'), findsOne);
  });

  testWidgets('previous and next skip the days without an entry', (
    tester,
  ) async {
    for (final day in ['2026-09-14', '2026-09-21', '2026-09-23']) {
      await session.ensureFolder('Journal/2026/09');
      await session.createNote(parentPath: 'Journal/2026/09', name: day);
    }
    final context = await pump(tester);
    await flow.openPrevious(context, DateTime(2026, 9, 21));
    await flow.openNext(context, DateTime(2026, 9, 21));
    expect(opened, [
      'Journal/2026/09/2026-09-14.md',
      'Journal/2026/09/2026-09-23.md',
    ]);
    // Past today there is nothing to go to.
    await flow.openNext(context, DateTime(2026, 9, 23));
    expect(opened, hasLength(2));
    expect(created, isEmpty);
  });
}
