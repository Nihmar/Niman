// T-M4-07 AC: pick a template, name the note, and the note is created
// with the template's text — frontmatter included — substituted, and
// opened.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  /// Opens a library and seeds `Templates/` with the given templates.
  Future<void> openWithTemplates(
    WidgetTester tester,
    Map<String, String> templates, {
    String folder = 'Templates',
  }) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    if (templates.isNotEmpty) {
      var prefix = '';
      for (final part in folder.split('/')) {
        await controller.createFolder(parentPath: prefix, name: part);
        prefix = prefix.isEmpty ? part : '$prefix/$part';
      }
      for (final entry in templates.entries) {
        await controller.createNote(
          parentPath: folder,
          name: entry.key,
          content: entry.value,
        );
      }
    }
    await settle(tester);
  }

  /// Opens the FAB menu and taps "New from template".
  Future<void> tapNewFromTemplate(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
  }

  testWidgets('the template becomes the note, placeholders substituted', (
    tester,
  ) async {
    await openWithTemplates(tester, {
      'Meeting': '---\ntags: [meeting]\n---\n\n# {{title}}\n\n## Notes\n',
    });

    await tapNewFromTemplate(tester);
    expect(find.byKey(const Key('template-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('template-Templates/Meeting.md')));
    await settle(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Standup');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(
      controller.contentOf('Standup.md'),
      '---\ntags: [meeting]\n---\n\n# Standup\n\n## Notes\n',
    );
    // And it opened.
    expect(find.byType(NoteView), findsOneWidget);
  });

  testWidgets('the template frontmatter is indexed on the new note', (
    tester,
  ) async {
    await openWithTemplates(tester, {
      'Pinned thing': '---\npinned: true\nstatus: draft\n---\nbody\n',
    });

    await tapNewFromTemplate(tester);
    await tester.tap(
      find.byKey(const Key('template-Templates/Pinned thing.md')),
    );
    await settle(tester);
    await tester.enterText(dialogField(), 'Made');
    await tester.tap(find.text('OK'));
    await settle(tester);

    final row = await controller.ops!.find('Made.md');
    expect(row!.pinned, isTrue, reason: "the template's frontmatter is ours");
    final fields = await controller.fieldSource;
    expect(
      (await fields!.notesWithField('status', 'draft')).map((n) => n.path),
      contains('Made.md'),
    );
  });

  testWidgets('the name box starts from the template name', (tester) async {
    await openWithTemplates(tester, {'Daily': 'body'});

    await tapNewFromTemplate(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Daily.md')));
    await settle(tester);

    expect(find.widgetWithText(TextField, 'Daily'), findsOneWidget);
  });

  testWidgets('several templates are listed, one per note', (tester) async {
    await openWithTemplates(tester, {'Daily': 'a', 'Meeting': 'b'});

    await tapNewFromTemplate(tester);

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Meeting'), findsOneWidget);
  });

  testWidgets('a library with no templates says where to put them', (
    tester,
  ) async {
    await openWithTemplates(tester, const {});

    await tapNewFromTemplate(tester);

    expect(find.byKey(const Key('template-picker-empty')), findsOneWidget);
    expect(find.textContaining('Templates/'), findsOneWidget);
  });

  testWidgets('the configured folder is where templates come from', (
    tester,
  ) async {
    await controller.setTemplateFolder(folder: 'Modelli');
    await openWithTemplates(tester, {'Giornaliero': 'x'}, folder: 'Modelli');

    await tapNewFromTemplate(tester);

    expect(find.byKey(const Key('template-Modelli/Giornaliero.md')), findsOne);
  });

  testWidgets('dismissing the picker creates nothing', (tester) async {
    await openWithTemplates(tester, {'Daily': 'body'});

    await tapNewFromTemplate(tester);
    await tester.tapAt(const Offset(20, 20)); // the barrier
    await settle(tester);

    expect(await controller.ops!.find('Daily.md'), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the row menu creates from a template in that folder', (
    tester,
  ) async {
    await openWithTemplates(tester, {'Daily': '# {{title}}\n'});
    await controller.createFolder(parentPath: '', name: 'Journal');
    await settle(tester);

    await tester.longPress(noteRow('Journal'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-new-from-template')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Daily.md')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Monday');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(controller.contentOf('Journal/Monday.md'), '# Monday\n');
  });
}
