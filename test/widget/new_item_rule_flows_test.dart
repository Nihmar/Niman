// #850: the creation flows that name no folder of their own ask the
// library's one rule — its setting and the note open at the time — and the
// ones that do (the tree's "Create … here") do not.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/ui/home/home_note_action.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late FakeLibrarySession session;
  late NewItemLocation location;
  late String? openNote;
  late List<CreatedItem> created;
  late List<String> opened;
  late List<String> filed;
  late BuildContext context;
  late List<Route<dynamic>> pushes;
  late GlobalKey<NavigatorState> navigator;
  late ShellCreateFlow creates;
  late ShellTemplateFlow templates;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_new_item_rule_');
    session = FakeLibrarySession();
    await session.open(dir.path, create: true);
    final _ = await session.ensureFolder('Projects/Niman');
    final _ = await session.ensureFolder('Elsewhere');
    final _ = await session.ensureFolder('Templates');
    await session.createNote(
      parentPath: 'Templates',
      name: 'Meeting',
      content: 'Notes of {{title}}\n',
    );
    location = NewItemLocation.openNoteFolder;
    openNote = 'Projects/Niman/Plan.md';
    created = [];
    opened = [];
    filed = [];
    pushes = [];
    navigator = GlobalKey<NavigatorState>();
    final rule = NewItemRule(
      location: () => location,
      activeNote: () => openNote,
    );
    creates = ShellCreateFlow(
      controller: session,
      newItemRule: rule,
      guard: (action) => action(),
      onCreated: created.add,
    );
    templates = ShellTemplateFlow(
      controller: session,
      origin: () => (selected: null, isDir: false, treeVisible: true),
      newItemRule: rule,
      guard: (action) => action(),
      opensPreviewOnly: () => false,
      onNoteFiled: ({required path, required preview, required caret}) =>
          filed.add(path),
    );
  });

  tearDown(() async {
    await session.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  Future<void> pumpTemplateHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [_PushLog(pushes)],
      home: Scaffold(
        body: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  /// Runs [flow] and confirms the name dialog it opens as it stands.
  Future<void> confirmName(
    WidgetTester tester,
    Future<void> Function() flow,
  ) async {
    final done = flow();
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.actionOk));
    await tester.pumpAndSettle();
    await done;
  }

  group('ShellCreateFlow', () {
    testWidgets("a note goes in the open note's folder", (tester) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createNote(context));
      expect(created.single.path, 'Projects/Niman/New note.md');
    });

    testWidgets('a note goes at the root under the root setting', (
      tester,
    ) async {
      await pumpHost(tester);
      location = NewItemLocation.libraryRoot;
      await confirmName(tester, () => creates.createNote(context));
      expect(created.single.path, 'New note.md');
    });

    testWidgets('with no note open a note goes at the root', (tester) async {
      await pumpHost(tester);
      openNote = null;
      await confirmName(tester, () => creates.createNote(context));
      expect(created.single.path, 'New note.md');
    });

    testWidgets('a folder follows the rule too', (tester) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createFolder(context));
      expect(created.single.path, 'Projects/Niman/New folder');
      expect(created.single.isDir, isTrue);

      location = NewItemLocation.libraryRoot;
      await confirmName(tester, () => creates.createFolder(context));
      expect(created.last.path, 'New folder');
    });

    testWidgets('a voice note follows the rule too', (tester) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createAudioNote(context));
      expect(created.single.path, startsWith('Projects/Niman/'));
      expect(created.single.hasKind, isTrue);

      location = NewItemLocation.libraryRoot;
      await confirmName(tester, () => creates.createAudioNote(context));
      expect(created.last.path.contains('/'), isFalse);
    });

    testWidgets('the setting is read at each creation', (tester) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createNote(context));
      location = NewItemLocation.libraryRoot;
      openNote = 'Elsewhere/Other.md';
      await confirmName(tester, () => creates.createNote(context));
      location = NewItemLocation.openNoteFolder;
      await confirmName(tester, () => creates.createNote(context));
      expect(created.map((c) => c.path), [
        'Projects/Niman/New note.md',
        'New note.md',
        'Elsewhere/New note.md',
      ]);
    });

    testWidgets('a slides note follows the rule too (it used to be the root)', (
      tester,
    ) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createSlidesNote(context));
      expect(created.single.path, 'Projects/Niman/My slides.md');
      expect(created.single.hasKind, isTrue);

      location = NewItemLocation.libraryRoot;
      await confirmName(tester, () => creates.createSlidesNote(context));
      expect(created.last.path, 'My slides.md');
    });

    testWidgets('a Kanban board follows the rule too', (tester) async {
      await pumpHost(tester);
      await confirmName(tester, () => creates.createKanban(context));
      expect(created.single.path, 'Projects/Niman/My board.md');
      expect(created.single.hasKind, isTrue);

      location = NewItemLocation.libraryRoot;
      await confirmName(tester, () => creates.createKanban(context));
      expect(created.last.path, 'My board.md');
    });

    testWidgets('"Create here" names its folder and bypasses the rule', (
      tester,
    ) async {
      await pumpHost(tester);
      await confirmName(
        tester,
        () => creates.createNote(context, parent: 'Elsewhere'),
      );
      await confirmName(
        tester,
        () => creates.createFolder(context, parent: 'Elsewhere'),
      );
      location = NewItemLocation.libraryRoot;
      await confirmName(
        tester,
        () => creates.createNote(context, parent: 'Elsewhere'),
      );
      expect(created.map((c) => c.path), [
        'Elsewhere/New note.md',
        'Elsewhere/New folder',
        'Elsewhere/New note_1.md',
      ]);
    });
  });

  group('ShellTemplateFlow', () {
    /// Files a note from the Meeting template: the picker answered with it,
    /// the name dialog with "Standup". The flow runs where the counter
    /// file's own I/O can complete, so the routes it opens are popped
    /// rather than pumped.
    Future<void> fromTemplate(WidgetTester tester, {String? parent}) async {
      final source = (await session.templateSource)!;
      final template = (await source.templates()).singleWhere(
        (t) => t.path == 'Templates/Meeting.md',
      );
      await tester.runAsync(() async {
        Future<void> untilPushed(int count) async {
          while (pushes.length < count) {
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
        }

        pushes.clear();
        final made = templates.createFromTemplate(context, parent: parent);
        await untilPushed(1);
        navigator.currentState!.pop(template);
        await untilPushed(2);
        navigator.currentState!.pop('Standup');
        await made;
      });
    }

    testWidgets('a note from a template goes by the rule', (tester) async {
      await pumpTemplateHost(tester);
      await fromTemplate(tester);
      expect(filed.single, 'Projects/Niman/Standup.md');

      location = NewItemLocation.libraryRoot;
      await fromTemplate(tester);
      expect(filed.last, 'Standup.md');
    });

    testWidgets('with no note open it goes at the root', (tester) async {
      await pumpTemplateHost(tester);
      openNote = null;
      await fromTemplate(tester);
      expect(filed.single, 'Standup.md');
    });

    testWidgets('"Create here" with a template names its folder', (
      tester,
    ) async {
      await pumpTemplateHost(tester);
      await fromTemplate(tester, parent: 'Elsewhere');
      location = NewItemLocation.libraryRoot;
      await fromTemplate(tester, parent: 'Elsewhere');
      expect(filed, ['Elsewhere/Standup.md', 'Elsewhere/Standup_1.md']);
    });
  });

  group("a Home action's new note", () {
    Future<void> press(WidgetTester tester, HomeAction action) async {
      await tester.runAsync(
        () => makeHomeNote(
          context,
          action,
          controller: session,
          templates: templates,
        ),
      );
    }

    const idea = HomeAction(
      id: 'idea',
      label: 'Idea',
      kind: HomeActionKind.newNote,
      name: FieldPreset.value('Idea'),
    );

    testWidgets('without a folder of its own goes by the rule', (tester) async {
      await pumpTemplateHost(tester);
      await press(tester, idea);
      expect(filed.single, 'Projects/Niman/Idea.md');

      location = NewItemLocation.libraryRoot;
      await press(tester, idea);
      expect(filed.last, 'Idea.md');
    });

    testWidgets('with a folder of its own keeps it', (tester) async {
      await pumpTemplateHost(tester);
      await press(tester, idea.copyWith(folder: 'Elsewhere'));
      expect(filed.single, 'Elsewhere/Idea.md');
    });
  });

  group('QuickNoteTab', () {
    Future<void> createQuickNote(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickNoteTab(
              controller: session,
              newItemRule: NewItemRule(
                location: () => location,
                activeNote: () => openNote,
              ),
              onOpen: opened.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('quick-note-create')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.actionOk));
      await tester.pumpAndSettle();
    }

    testWidgets("the new quick note goes in the open note's folder", (
      tester,
    ) async {
      await createQuickNote(tester);
      expect(opened.single, 'Projects/Niman/Quick note.md');
      expect(await session.quickNotePath, 'Projects/Niman/Quick note.md');
    });

    testWidgets('under the root setting it goes at the root', (tester) async {
      location = NewItemLocation.libraryRoot;
      await createQuickNote(tester);
      expect(opened.single, 'Quick note.md');
    });

    testWidgets('with no note open it goes at the root', (tester) async {
      openNote = null;
      await createQuickNote(tester);
      expect(opened.single, 'Quick note.md');
    });
  });
}

/// The routes pushed on the navigator, in order: the picker is the first
/// of a creation, the name dialog the one that follows it.
final class _PushLog extends NavigatorObserver {
  new(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}
