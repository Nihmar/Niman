// #535: the Home's actions — a note made with its fields fixed or asked,
// from a template or not; a task with its project; an action whose
// template is gone; and the editor that sets them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

HomeLayout _withActions(List<HomeAction> actions) => HomeLayout([
  HomeTile(
    id: 'actions',
    kind: HomeTileKind.actions,
    cell: const (x: 0, y: 0, w: 4, h: 1),
    at: 0,
    actions: actions,
  ),
]);

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> open(WidgetTester tester, {Size size = _desktop}) async {
    setSurfaceSize(tester, size);
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
    await tester.tap(
      find.byKey(Key(size == _desktop ? 'rail-home' : 'tab-home')),
    );
    await settle(tester);
  }

  Future<void> press(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('home-action-$id')));
    await settle(tester);
  }

  testWidgets('a note with fixed and asked fields, suggestions offered', (
    tester,
  ) async {
    await controller.createNote(
      parentPath: '',
      name: 'Old meeting',
      content: '---\nattendees: Marta\n---\n',
    );
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 'm',
        label: 'Meeting',
        kind: HomeActionKind.newNote,
        folder: 'Work',
        name: FieldPreset.value('Standup'),
        fields: {
          'project': FieldPreset.value('alpha'),
          'attendees': FieldPreset.ask(),
        },
        open: false,
      ),
    ]);
    await open(tester);
    await press(tester, 'm');

    expect(find.byKey(const Key('template-form')), findsOne);
    expect(find.byKey(const Key('template-field-project')), findsNothing);
    await tester.tap(
      find.byKey(const Key('template-suggestion-attendees-Marta')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('template-form-ok')));
    await settle(tester);

    final content = controller.contentOf('Work/Standup.md');
    expect(content, isNotNull);
    expect(content, contains('project: alpha'));
    expect(content, contains('attendees: Marta'));
  });

  testWidgets('fixed values keep their YAML types, tags a list (#683)', (
    tester,
  ) async {
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 'b',
        label: 'Book',
        kind: HomeActionKind.newNote,
        name: FieldPreset.value('Dune'),
        fields: {
          'tags': FieldPreset.value('book, scifi'),
          'priority': FieldPreset.value('3'),
          'done': FieldPreset.value('false'),
          'author': FieldPreset.value('Herbert, F'),
          'code': FieldPreset.value('"007"'),
        },
        open: false,
      ),
    ]);
    await open(tester);
    await press(tester, 'b');

    final content = controller.contentOf('Dune.md')!;
    expect(content, contains('tags: [book, scifi]'));
    expect(content, contains('priority: 3\n'));
    expect(content, contains('done: false\n'));
    expect(content, contains('author: Herbert, F\n'));
    expect(content, contains('code: "007"\n'));
  });

  testWidgets('a fixed value answers the template, the name is asked', (
    tester,
  ) async {
    await controller.createFolder(parentPath: '', name: 'Templates');
    await controller.createNote(
      parentPath: 'Templates',
      name: 'Meeting',
      content: '---\nstatus: open\n---\n# {{ask:Topic}}\n',
    );
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 't',
        label: 'Kickoff',
        kind: HomeActionKind.newNote,
        template: 'Templates/Meeting.md',
        fields: {'Topic': FieldPreset.value('Kickoff')},
        open: false,
      ),
    ]);
    await open(tester);
    await press(tester, 't');

    expect(find.byKey(const Key('template-field-Topic')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('template-field-niman:name')),
      'Monday',
    );
    await tester.tap(find.byKey(const Key('template-form-ok')));
    await settle(tester);

    final content = controller.contentOf('Monday.md');
    expect(content, contains('status: open'));
    expect(content, contains('# Kickoff'));
    expect(content, isNot(contains('Topic:')), reason: 'an answer, not a key');
  });

  testWidgets('nothing to ask makes the note at once', (tester) async {
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 'i',
        label: 'Inbox',
        kind: HomeActionKind.newNote,
        name: FieldPreset.value('Inbox item'),
        open: false,
      ),
    ]);
    await open(tester);
    await press(tester, 'i');
    expect(find.byKey(const Key('template-form')), findsNothing);
    expect(controller.contentOf('Inbox item.md'), isNotNull);
  });

  testWidgets('an action whose template is gone is marked and says so', (
    tester,
  ) async {
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 'b',
        label: 'Book',
        kind: HomeActionKind.newNote,
        template: 'Templates/Book.md',
      ),
    ]);
    await open(tester);
    expect(find.byKey(const Key('home-action-broken-b')), findsOne);

    await press(tester, 'b');
    expect(find.textContaining('Templates/Book.md'), findsWidgets);
    expect(find.byKey(const Key('template-form')), findsNothing);
  });

  testWidgets('a task starts with its project and context', (tester) async {
    controller.libraryHome = _withActions([
      const HomeAction(
        id: 'k',
        label: 'Work task',
        kind: HomeActionKind.addTask,
        project: 'alpha',
        context: 'work',
      ),
    ]);
    await open(tester);
    await press(tester, 'k');
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.controller.text.trim(), '+alpha @work');
    expect(field.controller.selection.baseOffset, 0);
  });

  testWidgets('on a phone the questions come in a sheet', (tester) async {
    controller.libraryHome = _withActions([
      const HomeAction(id: 'q', label: 'Quick', kind: HomeActionKind.newNote),
    ]);
    await open(tester, size: _phone);
    await press(tester, 'q');
    expect(find.byType(BottomSheet), findsOne);
    expect(find.byKey(const Key('template-field-niman:name')), findsOne);
  });

  testWidgets('the editor adds an action to the tile', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('home-edit')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('home-settings-actions')));
    await settle(tester);
    expect(find.byKey(const Key('home-actions-dialog')), findsOne);

    await tester.tap(find.byKey(const Key('home-action-add')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('home-action-label')), 'Idea');
    await tester.tap(find.byKey(const Key('home-action-icon-lightbulb')));
    await tester.tap(find.byKey(const Key('home-action-name-mode')));
    await tester.pump();
    await tester.tap(find.text('Fixed').first);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('home-action-name-value')),
      '{{date}} idea',
    );
    final add = find.byKey(const Key('home-action-field-add'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('home-action-field-key-0')),
      'status',
    );
    await tester.enterText(
      find.byKey(const Key('home-action-field-0-value')),
      'raw',
    );
    await tester.tap(find.byKey(const Key('home-action-save')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('home-actions-save')));
    await settle(tester);

    final actions = controller.libraryHome!['actions']!.actions;
    final idea = actions.last;
    expect(idea.label, 'Idea');
    expect(idea.icon, 'lightbulb');
    expect(idea.kind, HomeActionKind.newNote);
    expect(idea.name, const FieldPreset.value('{{date}} idea'));
    expect(idea.fields, {'status': const FieldPreset.value('raw')});
    expect(
      actions,
      hasLength(HomeLayout.defaults['actions']!.actions.length + 1),
    );
  });
}
