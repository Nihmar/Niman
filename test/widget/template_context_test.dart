// T-TPL-04 AC: creating from inside a note links back to it, and an
// empty clipboard leaves an empty string rather than the placeholder.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Answers the platform clipboard with [text]; null makes every read
  /// come back empty, which is what a fresh session looks like.
  void useClipboard(String? text) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return text == null ? null : <String, Object?>{'text': text};
      }
      return null;
    });
  }

  /// Opens a library holding one template called `Spinoff`.
  Future<void> openWith(WidgetTester tester, String template) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Templates');
    await controller.createNote(
      parentPath: 'Templates',
      name: 'Spinoff',
      content: template,
    );
    await settle(tester);
  }

  /// Picks the one template from the FAB and names the note [name].
  Future<void> useTemplate(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-from-template-action')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('template-Templates/Spinoff.md')));
    await settle(tester);
    await tester.enterText(dialogField(), name);
    await tester.tap(find.text('OK'));
    await settle(tester);
  }

  testWidgets('a note made from inside another links back to it', (
    tester,
  ) async {
    useClipboard(null);
    await openWith(tester, '# {{title}}\n\nSpun out of [[{{parent}}]].\n');
    await controller.createNote(parentPath: '', name: 'Kingdoms');
    await settle(tester);
    await tester.tap(noteRow('Kingdoms.md'));
    await settle(tester);

    await useTemplate(tester, 'Elyria');

    expect(
      controller.contentOf('Elyria.md'),
      '# Elyria\n\nSpun out of [[Kingdoms]].\n',
    );
  });

  testWidgets('made from the tree, the backlink is simply empty', (
    tester,
  ) async {
    useClipboard(null);
    await openWith(tester, 'From [{{parent}}]\n');

    await useTemplate(tester, 'Loose');

    expect(controller.contentOf('Loose.md'), 'From []\n');
  });

  testWidgets('the clipboard lands in the note', (tester) async {
    useClipboard('Exception: everything is on fire');
    await openWith(tester, '# {{title}}\n\n```\n{{clipboard}}\n```\n');

    await useTemplate(tester, 'Bug');

    expect(
      controller.contentOf('Bug.md'),
      '# Bug\n\n```\nException: everything is on fire\n```\n',
    );
  });

  testWidgets('an empty clipboard leaves nothing, not the placeholder', (
    tester,
  ) async {
    useClipboard(null);
    await openWith(tester, 'Pasted: [{{clipboard}}]\n');

    await useTemplate(tester, 'Bug');

    expect(controller.contentOf('Bug.md'), 'Pasted: []\n');
  });

  testWidgets('the folder the note landed in can be written into it', (
    tester,
  ) async {
    useClipboard(null);
    await openWith(
      tester,
      '---\ncopist:\n  folder: Journal/2026\n---\n\nFiled under {{folder}}\n',
    );

    await useTemplate(tester, 'Monday');

    expect(
      controller.contentOf('Journal/2026/Monday.md'),
      'Filed under Journal/2026\n',
    );
  });
}
