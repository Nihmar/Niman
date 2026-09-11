// T-TPL-02 AC: a template that files its own notes. The folder is made,
// the name is not asked for, a second use adds to the file instead of
// making a second one, and `open: none` leaves the user where they were.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/tree.dart';

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

  /// Opens a library holding one template called `Filed`.
  Future<void> openWith(WidgetTester tester, String template) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Templates');
    await controller.createNote(
      parentPath: 'Templates',
      name: 'Filed',
      content: template,
    );
    await settle(tester);
  }

  /// Picks the one template from the create menu.
  Future<void> useTemplate(WidgetTester tester) async {
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Filed.md')));
    await settle(tester);
  }

  testWidgets('a template that names itself is not asked about', (
    tester,
  ) async {
    await openWith(
      tester,
      '---\nniman:\n  filename: "Fixed name"\n---\n\n# {{title}}\n',
    );

    await useTemplate(tester);

    // No name dialog: the template already answered.
    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.contentOf('Fixed name.md'), '# Fixed name\n');
    expect(find.byType(NoteView), findsOneWidget);
  });

  testWidgets('the folder is made, however deep, and the note goes in it', (
    tester,
  ) async {
    await openWith(
      tester,
      '---\nniman:\n  folder: Journal/2026/03\n  filename: Monday\n---\nbody\n',
    );

    await useTemplate(tester);

    expect(controller.contentOf('Journal/2026/03/Monday.md'), 'body\n');
    expect(await controller.ops!.find('Journal'), isNotNull);
    expect(await controller.ops!.find('Journal/2026'), isNotNull);
  });

  testWidgets('append adds to the file instead of making a second one', (
    tester,
  ) async {
    await openWith(
      tester,
      '---\nniman:\n  filename: Log\n  append: true\n---\n- an entry\n',
    );

    await useTemplate(tester);
    await useTemplate(tester);

    expect(await controller.ops!.find('Log 2.md'), isNull);
    expect(controller.contentOf('Log.md'), '- an entry\n\n- an entry\n');
  });

  testWidgets('without append a second use leaves the first file alone', (
    tester,
  ) async {
    await openWith(tester, '---\nniman:\n  filename: Log\n---\nbody\n');

    await useTemplate(tester);
    await useTemplate(tester);

    // The second note went elsewhere, under whatever name the library
    // uniquified to; what matters is that the first was not added to.
    expect(controller.contentOf('Log.md'), 'body\n');
  });

  testWidgets('open: none files the note and leaves the tree showing', (
    tester,
  ) async {
    await openWith(
      tester,
      '---\nniman:\n  filename: Filed away\n  open: none\n---\nbody\n',
    );

    await useTemplate(tester);

    expect(controller.contentOf('Filed away.md'), 'body\n');
    expect(find.byType(NoteView), findsNothing);
    expect(find.byType(NoteTree), findsOneWidget);
  });

  // 2026-09-10 device report: a template that named a folder put its note
  // in the template folder instead. Trying a template out is done with the
  // template open, so the FAB's target was `Templates` — and a note filed
  // among the templates is then offered as one.
  testWidgets('a template that says nothing does not file into Templates', (
    tester,
  ) async {
    await openWith(tester, '# {{title}}\n');
    // Standing on the template itself, which is where you stand while
    // writing one.
    await tester.tap(noteRow('Templates'));
    await settle(tester);
    await tester.tap(noteRow('Filed.md'));
    await settle(tester);

    await useTemplate(tester);
    await tester.enterText(dialogField(), 'Tried');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(await controller.ops!.find('Templates/Tried.md'), isNull);
    expect(controller.contentOf('Tried.md'), '# Tried\n');
  });

  testWidgets('a template whose frontmatter is broken says so', (tester) async {
    await openWith(
      tester,
      '---\nniman:\n  folder: [unclosed\n---\n\n# {{title}}\n',
    );

    await useTemplate(tester);
    await tester.enterText(dialogField(), 'Anyway');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The note is still made — the template is the thing at fault, and
    // refusing to create anything would lose what was typed.
    expect(await controller.ops!.find('Anyway.md'), isNotNull);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Filed'), findsWidgets);
  });

  testWidgets('a template with no directives still asks for a name', (
    tester,
  ) async {
    await openWith(tester, '# {{title}}\n');

    await useTemplate(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Asked');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(controller.contentOf('Asked.md'), '# Asked\n');
  });
}
