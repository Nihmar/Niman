// T-TPL-06 in the shell: a partial living beside the templates that use
// it, found by the name a person writes, and its own questions asked in
// the same form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';

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

  /// Opens a library whose `Templates/` holds [templates], keyed by name
  /// without the `.md`.
  Future<void> openWith(
    WidgetTester tester,
    Map<String, String> templates,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Templates');
    for (final entry in templates.entries) {
      await controller.createNote(
        parentPath: 'Templates',
        name: entry.key,
        content: entry.value,
      );
    }
    await settle(tester);
  }

  /// Picks `Bug` from the create menu and names the note [name].
  Future<void> useTemplate(WidgetTester tester, String name) async {
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Bug.md')));
    await settle(tester);
    await tester.enterText(dialogField(), name);
    await tester.tap(find.text('OK'));
    await settle(tester);
  }

  testWidgets('a partial beside the templates is found by its bare name', (
    tester,
  ) async {
    await openWith(tester, {
      'Bug': '# {{title}}\n\n{{include:_repro}}\n',
      '_repro': '## Steps\n1. \n2. ',
    });

    await useTemplate(tester, 'Crash');

    expect(controller.contentOf('Crash.md'), '# Crash\n\n## Steps\n1. \n2. \n');
  });

  testWidgets('the pasted text is substituted like the rest of the note', (
    tester,
  ) async {
    await openWith(tester, {
      'Bug': '{{include:_repro}}',
      '_repro': 'Filed as {{title}}',
    });

    await useTemplate(tester, 'Crash');

    expect(controller.contentOf('Crash.md'), 'Filed as Crash');
  });

  testWidgets("a partial's questions join the same form", (tester) async {
    await openWith(tester, {
      'Bug': '# {{ask:Summary}}\n\n{{include:_repro}}\n',
      '_repro': 'Seen on {{choice:Platform:Android,Windows}}',
    });

    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Bug.md')));
    await settle(tester);

    // Both questions, in one form, though only one of them was written
    // in the template that was picked.
    expect(find.byKey(const Key('template-field-Summary')), findsOneWidget);
    expect(find.byKey(const Key('template-field-Platform')), findsOneWidget);
  });

  testWidgets('a missing partial says so in the note it made', (tester) async {
    await openWith(tester, {'Bug': 'a\n{{include:_gone}}\nb\n'});

    await useTemplate(tester, 'Crash');

    final made = controller.contentOf('Crash.md')!;
    expect(made, contains('{{include:_gone}}'));
    expect(made, contains('_gone'));
    expect(made, startsWith('a\n'));
    expect(made, endsWith('\nb\n'));
  });

  testWidgets('a template that includes itself still makes its note', (
    tester,
  ) async {
    await openWith(tester, {'Bug': 'top\n{{include:Bug}}\n'});

    await useTemplate(tester, 'Crash');

    // No hang, no stack overflow: the loop is named where it was found.
    expect(controller.contentOf('Crash.md'), contains('{{include:Bug}}'));
    expect(controller.contentOf('Crash.md'), startsWith('top\n'));
  });
}
