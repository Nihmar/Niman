// #1003: the Todo list in sections that follow the sort key, the Done
// section last, the folded sections kept per device, the filter strip.
// The phone's shape: a thumb's rows and swipes (the desktop's are in
// todo_pointer_test.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/todo/todo_list_view_session.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late FakeLibrarySession session;
  late FakeTodoSource source;
  late TodoController controller;
  late TodoListView view;

  /// A phone-sized window: a thumb's rows, no toolbar over the list.
  void phoneSized(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Mounts a tab over the current controller and view.
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoTab(controller: controller, view: view, clock: clock),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpTab(
    WidgetTester tester, {
    List<String>? todo,
    List<String>? done,
    bool persisted = false,
  }) async {
    phoneSized(tester);
    session = FakeLibrarySession();
    await session.open('/fake', create: false);
    source = FakeTodoSource(todo: todo, done: done);
    controller = TodoController(
      session: session,
      clock: clock,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => source,
    );
    addTearDown(controller.dispose);
    view = persisted ? todoListViewFor(session) : TodoListView();
    addTearDown(view.dispose);
    await mount(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Finder header(String id) => find.byKey(Key('todo-section-$id'));

  /// The count the header of [id] shows.
  String count(WidgetTester tester, String id) {
    final text = find.descendant(
      of: header(id),
      matching: find.byKey(const Key('todo-section-count')),
    );
    return tester.widget<Text>(text).data!;
  }

  /// The ids of the section headers on screen, top to bottom.
  List<String> headers(WidgetTester tester) {
    final found = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('todo-section-') &&
          (w.key! as ValueKey<String>).value != 'todo-section-count',
    );
    final elements = found.evaluate().toList()
      ..sort(
        (a, b) => tester
            .getTopLeft(find.byWidget(a.widget))
            .dy
            .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy),
      );
    return [
      for (final e in elements)
        (e.widget.key! as ValueKey<String>).value.substring(
          'todo-section-'.length,
        ),
    ];
  }

  group('sections', () {
    testWidgets('by due date: the ranges with their counts, empty ones '
        'hidden', (tester) async {
      await pumpTab(
        tester,
        todo: [
          'late one due:2026-09-01',
          'late two due:2026-09-02',
          'now due:2026-09-07',
          'far due:2026-12-01',
          'someday',
        ],
      );
      expect(headers(tester), [
        'due.overdue',
        'due.today',
        'due.later',
        'due.none',
      ]);
      expect(count(tester, 'due.overdue'), '2');
      expect(count(tester, 'due.today'), '1');
      expect(count(tester, 'due.later'), '1');
      expect(header('due.next7'), findsNothing, reason: 'empty: hidden');
      expect(find.text('Next 7 days'), findsNothing);
      // The Overdue heading is the error colour.
      final scheme = Theme.of(tester.element(header('due.overdue')))
          .colorScheme;
      expect(
        tester.widget<Text>(find.text('Overdue')).style?.color,
        scheme.error,
      );
      expect(
        tester.widget<Text>(find.text('Today')).style?.color,
        isNot(scheme.error),
      );
    });

    testWidgets('by priority: a section per letter, then none', (tester) async {
      await pumpTab(tester, todo: ['(B) bee', 'plain', '(A) aye', '(A) also']);
      // Sorted by due date the priority shows on the row...
      expect(find.byKey(const Key('todo-row-priority')), findsNWidgets(3));
      view.setSort(TodoSort.priority);
      await tester.pump();
      expect(headers(tester), ['priority.A', 'priority.B', 'priority.none']);
      expect(find.text('Priority A'), findsOneWidget);
      expect(find.text('No priority'), findsOneWidget);
      expect(count(tester, 'priority.A'), '2');
      // ...and not when the section already says it.
      expect(find.byKey(const Key('todo-row-priority')), findsNothing);
    });

    testWidgets('by creation date: a flat list, no headers', (tester) async {
      await pumpTab(
        tester,
        todo: ['2026-09-01 old', '2026-09-05 new', 'undated'],
        done: ['x 2026-09-06 finished'],
      );
      view.setSort(TodoSort.creation);
      await tester.pump();
      expect(headers(tester), ['done'], reason: 'only Done is a section');
      expect(find.text('new'), findsOneWidget);
      expect(find.text('old'), findsOneWidget);
    });

    testWidgets('a row shows its priority as a badge', (tester) async {
      await pumpTab(tester, todo: ['(C) cee', 'plain']);
      final badge = find.byKey(const Key('todo-row-priority'));
      expect(badge, findsOneWidget);
      expect(
        find.descendant(of: badge, matching: find.text('C')),
        findsOneWidget,
      );
    });
  });

  group('folding', () {
    testWidgets('a header folds its section to the header alone', (
      tester,
    ) async {
      await pumpTab(tester, todo: ['late due:2026-09-01', 'someday']);
      expect(find.text('late'), findsOneWidget);
      await tester.tap(header('due.overdue'));
      await tester.pump();
      expect(find.text('late'), findsNothing);
      expect(header('due.overdue'), findsOneWidget);
      expect(count(tester, 'due.overdue'), '1', reason: 'the count stays');
      expect(find.text('someday'), findsOneWidget);
      await tester.tap(header('due.overdue'));
      await tester.pump();
      expect(find.text('late'), findsOneWidget);
    });

    testWidgets('a header is a touch target of at least 48 dp', (tester) async {
      await pumpTab(tester, todo: ['someday']);
      final box = tester.getSize(header('due.none'));
      expect(box.height, greaterThanOrEqualTo(48));
      expect(box.width, 400, reason: 'the whole row is the target');
    });

    testWidgets('the chevron says the state', (tester) async {
      await pumpTab(tester, todo: ['someday'], done: ['x 2026-09-01 old']);
      Finder chevron(String id, IconData icon) =>
          find.descendant(of: header(id), matching: find.byIcon(icon));
      expect(chevron('due.none', Icons.expand_more), findsOneWidget);
      expect(chevron('done', Icons.chevron_right), findsOneWidget);
      await tester.tap(header('done'));
      await tester.pump();
      expect(chevron('done', Icons.expand_more), findsOneWidget);
    });

    testWidgets('the folded sections are saved and come back', (tester) async {
      await pumpTab(
        tester,
        todo: ['late due:2026-09-01', 'someday'],
        done: ['x 2026-09-01 old'],
        persisted: true,
      );
      // A fresh library: Done alone is folded.
      expect(await session.todoCollapsedSections, {'done'});
      await tester.tap(header('due.none'));
      await tester.pump();
      await tester.tap(header('done'));
      await tester.pump();
      expect(await session.todoCollapsedSections, {'due.none'});

      // Another run of the app: the same sections are folded again.
      view = todoListViewFor(session);
      addTearDown(view.dispose);
      await mount(tester);
      await tester.pump();
      expect(find.text('someday'), findsNothing);
      expect(find.text('late'), findsOneWidget);
    });
  });

  group('the Done section', () {
    testWidgets('starts folded, newest first, with its count', (tester) async {
      await pumpTab(
        tester,
        todo: ['open'],
        done: ['x 2026-09-01 older', 'x 2026-09-05 newer'],
      );
      expect(count(tester, 'done'), '2');
      expect(find.text('newer'), findsNothing);
      await tester.tap(header('done'));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('newer')).dy,
        lessThan(tester.getTopLeft(find.text('older')).dy),
      );
      // Where the due date would be: when it was done.
      expect(find.text('Done 5 Sep'), findsOneWidget);
      expect(find.text('Done 1 Sep'), findsOneWidget);
      final checks = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checks.where((c) => c.value ?? false), hasLength(2));
    });

    testWidgets('a done row edits done.txt, not todo.txt', (tester) async {
      await pumpTab(tester, todo: ['open task'], done: ['x 2026-09-01 old']);
      await tester.tap(header('done'));
      await tester.pump();
      await tester.tap(find.text('old'));
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('todo-dialog-field')),
        'old, edited',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);
      expect(source.todoLines, ['open task']);
      expect(source.doneLines, hasLength(1));
      expect(source.doneLines.single, contains('old, edited'));
    });

    testWidgets('a done row deletes from done.txt: menu and swipe', (
      tester,
    ) async {
      await pumpTab(
        tester,
        todo: ['open task'],
        done: ['x 2026-09-01 one', 'x 2026-09-02 two', 'x 2026-09-03 three'],
      );
      await tester.tap(header('done'));
      await tester.pump();

      await tester.longPress(find.text('three'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-menu-delete')));
      await settle(tester);
      expect(source.doneLines, ['x 2026-09-01 one', 'x 2026-09-02 two']);

      await tester.drag(find.text('two'), const Offset(-600, 0));
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-swipe-confirm')));
      await settle(tester);
      expect(source.doneLines, ['x 2026-09-01 one']);
      expect(source.todoLines, ['open task'], reason: 'todo.txt untouched');
    });

    testWidgets('a done row unchecks back to todo.txt', (tester) async {
      await pumpTab(tester, done: ['x 2026-09-01 old']);
      await tester.tap(header('done'));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await settle(tester);
      expect(source.doneLines, isEmpty);
      expect(source.todoLines, ['old']);
      expect(header('done'), findsNothing, reason: 'nothing left to hold');
    });
  });

  group('the filter strip', () {
    testWidgets('is there only while a filter is active', (tester) async {
      await pumpTab(tester, todo: ['a +p', 'b +q due:2026-09-01', 'c']);
      final strip = find.byKey(const Key('todo-filter-strip'));
      expect(strip, findsNothing);
      view.setDueRange(TodoDueRange.overdue);
      await tester.pump();
      expect(strip, findsOneWidget);
      expect(find.byKey(const Key('todo-strip-due')), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      view.toggleToken('+q');
      await tester.pump();
      expect(find.byKey(const Key('todo-strip-token-+q')), findsOneWidget);
      view.clearFilters();
      await tester.pump();
      expect(strip, findsNothing);
    });

    testWidgets('has a removable chip per filter, and Clear', (tester) async {
      await pumpTab(tester, todo: ['a +p', 'b +p +q', 'c +q']);
      view
        ..toggleToken('+p')
        ..toggleToken('+q');
      await tester.pump();
      expect(find.text('1 of 3'), findsOneWidget);

      // The chip's own delete icon removes that filter alone.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('todo-strip-token-+q')),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pump();
      expect(view.filter.tokens, {'+p'});
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('todo-clear-filters')));
      await tester.pump();
      expect(view.hasActiveFilters, isFalse);
      expect(find.byKey(const Key('todo-filter-strip')), findsNothing);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('a filter that hides everything says so, the strip stays', (
      tester,
    ) async {
      await pumpTab(tester, todo: ['a', 'b']);
      view.setDueRange(TodoDueRange.overdue);
      await tester.pump();
      expect(find.text('No tasks match'), findsOneWidget);
      expect(find.text('0 of 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('todo-clear-filters')));
      await tester.pump();
      expect(find.text('No tasks match'), findsNothing);
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('a token the file lost is dropped from the filter', (
      tester,
    ) async {
      await pumpTab(tester, todo: ['a +p', 'b']);
      view.toggleToken('+p');
      await tester.pump();
      expect(view.hasActiveFilters, isTrue);
      await controller.updateTodo(controller.snapshot!.todo.first, 'a');
      await tester.pump();
      expect(view.filter.tokens, isEmpty);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('the Done section is narrowed by the same filter', (
      tester,
    ) async {
      await pumpTab(
        tester,
        todo: ['a +p'],
        done: ['x 2026-09-01 d1 +p', 'x 2026-09-01 d2 +q'],
      );
      expect(count(tester, 'done'), '2');
      view.toggleToken('+p');
      await tester.pump();
      expect(count(tester, 'done'), '1');
      view
        ..toggleToken('+p')
        ..toggleToken('+q');
      await tester.pump();
      expect(find.text('0 of 1'), findsOneWidget, reason: 'open tasks only');
      expect(count(tester, 'done'), '1');
    });
  });

  testWidgets('no task at all: the empty state, no sections', (tester) async {
    await pumpTab(tester);
    expect(find.text('No open tasks yet'), findsOneWidget);
    expect(headers(tester), isEmpty);
  });
}
