// T-TPL-03 AC: the template's questions are asked once, in one form,
// before the note exists — so an answer can name the file. Backing out
// creates nothing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';

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

  /// Opens a library holding one template called `Sheet`.
  Future<void> openWith(WidgetTester tester, String template) async {
    // Tall enough for a form of a few fields plus its buttons.
    setSurfaceSize(tester, const Size(900, 1400));
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
      name: 'Sheet',
      content: template,
    );
    await settle(tester);
  }

  /// Picks the one template from the create menu.
  Future<void> useTemplate(WidgetTester tester) async {
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Sheet.md')));
    await settle(tester);
  }

  testWidgets('a template with fields asks them all in one form', (
    tester,
  ) async {
    await openWith(
      tester,
      '# {{ask:Name}}\n\nBy {{ask:Author:Ada}}, of the '
      '{{choice:Faction:Crown,Rebels}}.\n',
    );

    await useTemplate(tester);

    expect(find.byKey(const Key('template-form')), findsOneWidget);
    expect(find.byKey(const Key('template-field-Name')), findsOneWidget);
    expect(find.byKey(const Key('template-field-Author')), findsOneWidget);
    expect(find.byKey(const Key('template-field-Faction')), findsOneWidget);
    // The hint is what the box starts with, and the first option is what
    // the list starts on.
    expect(find.widgetWithText(TextField, 'Ada'), findsOneWidget);
    expect(find.text('Crown'), findsWidgets);
  });

  testWidgets('the answers fill the note, every occurrence of each', (
    tester,
  ) async {
    await openWith(
      tester,
      '# {{ask:Name}}\n\n{{ask:Name}} is with the '
      '{{choice:Faction:Crown,Rebels}}.\n',
    );

    await useTemplate(tester);
    await tester.enterText(
      find.byKey(const Key('template-field-Name')),
      'Elyria',
    );
    await tester.tap(find.byKey(const Key('template-field-Faction')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rebels').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('template-form-ok')));
    await settle(tester);

    // Then the name dialog, since this template does not name itself.
    await tester.enterText(dialogField(), 'Elyria');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(
      controller.contentOf('Elyria.md'),
      '# Elyria\n\nElyria is with the Rebels.\n',
    );
  });

  testWidgets('an answer names the file, and then nothing else is asked', (
    tester,
  ) async {
    await openWith(
      tester,
      '---\nniman:\n  folder: World\n  filename: "{{ask:Name}}"\n---\n\n'
      '# {{ask:Name}}\n',
    );

    await useTemplate(tester);
    await tester.enterText(
      find.byKey(const Key('template-field-Name')),
      'Elyria',
    );
    await tester.tap(find.byKey(const Key('template-form-ok')));
    await settle(tester);

    // No name dialog: the form already answered it.
    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.contentOf('World/Elyria.md'), '# Elyria\n');
    expect(find.byType(NoteView), findsOneWidget);
  });

  testWidgets('backing out of the form creates nothing', (tester) async {
    await openWith(tester, '# {{ask:Name}}\n');

    await useTemplate(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(find.byKey(const Key('template-form')), findsNothing);
    expect(await controller.ops!.find('Sheet.md'), isNull);
    expect(find.byType(NoteView), findsNothing);
  });

  testWidgets('a template that asks nothing shows no form', (tester) async {
    await openWith(tester, '# {{title}}\n');

    await useTemplate(tester);

    expect(find.byKey(const Key('template-form')), findsNothing);
    // Straight to the name dialog, as it always was.
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
