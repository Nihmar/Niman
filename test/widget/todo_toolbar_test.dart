// #1003: the controls of the Todo list — the phone's app bar actions (help,
// Filter, Sort, the dot) and the desktop toolbar (labelled pills, or icons
// in a pane too narrow for them) — over one shared TodoListView.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/todo_list_buttons.dart';
import 'package:niman/src/ui/todo_tab.dart';
import 'package:niman/src/ui/todo_toolbar.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  DateTime clock() => DateTime(2026, 9, 7);

  late TodoController controller;
  late TodoListView view;
  late FakeTodoSource source;

  Future<void> prepare(List<String> todo) async {
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    source = FakeTodoSource(todo: todo);
    controller = TodoController(
      session: session,
      clock: clock,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => source,
    );
    addTearDown(controller.dispose);
    view = TodoListView();
    addTearDown(view.dispose);
  }

  void windowSized(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// The phone: the shell's app bar carries the actions, the tab the list.
  Future<void> pumpPhone(WidgetTester tester, List<String> todo) async {
    windowSized(tester, const Size(400, 800));
    await prepare(todo);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Todo'),
            actions: [
              TodoAppBarActions(
                controller: controller,
                view: view,
                clock: clock,
              ),
            ],
          ),
          body: TodoTab(controller: controller, view: view, clock: clock),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// The desktop: the tab in a pane [width] dp wide of a wide window.
  Future<void> pumpPane(
    WidgetTester tester,
    double width,
    List<String> todo,
  ) async {
    windowSized(tester, const Size(1200, 900));
    await prepare(todo);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 600,
              child: TodoTab(
                controller: controller,
                view: view,
                clock: clock,
                onAddTask: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder key(String name) => find.byKey(Key(name));

  /// The Filter icon's dot.
  Badge dot(WidgetTester tester) =>
      tester.widget<Badge>(key('todo-filter-dot'));

  group('the phone app bar', () {
    testWidgets('has help, Filter and Sort as outline icons, in that order', (
      tester,
    ) async {
      await pumpPhone(tester, ['a']);
      expect(
        find.byType(TodoToolbar),
        findsNothing,
        reason: 'the bar has them',
      );
      final help = tester.getCenter(key('todo-help')).dx;
      final filter = tester.getCenter(key('todo-filter-button')).dx;
      final sort = tester.getCenter(key('todo-sort-button')).dx;
      expect(help, lessThan(filter));
      expect(filter, lessThan(sort));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsNothing, reason: 'no filled');
      // No Open/Done switch, no count: the sections replace them.
      expect(key('todo-view-switch'), findsNothing);
      expect(key('todo-count'), findsNothing);
    });

    testWidgets('the Filter icon takes the accent and a dot while a filter is '
        'active', (tester) async {
      await pumpPhone(tester, ['a +p']);
      final scheme = Theme.of(tester.element(key('todo-filter-button')))
          .colorScheme;
      Color? iconColor() =>
          tester.widget<Icon>(find.byIcon(Icons.filter_alt_outlined)).color;

      expect(dot(tester).isLabelVisible, isFalse);
      expect(iconColor(), isNull);
      final idle = tester.getRect(find.byIcon(Icons.filter_alt_outlined));

      view.toggleToken('+p');
      await tester.pump();
      expect(dot(tester).isLabelVisible, isTrue);
      expect(dot(tester).label, isNull, reason: 'a dot, not a count');
      expect(iconColor(), scheme.primary);
      expect(
        tester.getRect(find.byIcon(Icons.filter_alt_outlined)),
        idle,
        reason: 'nothing moves',
      );
      // The sort is not a filter.
      view
        ..clearFilters()
        ..setSort(TodoSort.priority);
      await tester.pump();
      expect(dot(tester).isLabelVisible, isFalse);
    });

    testWidgets('Filter opens the sheet: the due range above the tokens', (
      tester,
    ) async {
      await pumpPhone(tester, ['a +p due:2026-09-01', 'b +q']);
      await tester.tap(key('todo-filter-button'));
      await settle(tester);
      for (final range in TodoDueRange.values) {
        expect(key('todo-due-${range.name}'), findsOneWidget);
      }
      expect(
        tester.getTopLeft(key('todo-due-all')).dy,
        lessThan(tester.getTopLeft(key('todo-token-+p')).dy),
      );
      // No sort chips any more: Sort is its own control.
      expect(key('todo-sort-priority'), findsNothing);
      expect(find.text('+p (1)'), findsOneWidget);
      expect(find.text('+q (1)'), findsOneWidget);

      // The due range is a single choice, and narrows the tokens counted.
      await tester.tap(key('todo-due-overdue'));
      await tester.pump();
      expect(view.filter.dueRange, TodoDueRange.overdue);
      expect(
        tester.widget<ChoiceChip>(key('todo-due-overdue')).selected,
        isTrue,
      );
      expect(tester.widget<ChoiceChip>(key('todo-due-all')).selected, isFalse);
      expect(find.text('+q (1)'), findsNothing, reason: 'not overdue');
      await tester.tap(key('todo-token-+p'));
      await tester.pump();
      expect(view.filter.tokens, {'+p'});
    });

    testWidgets('Sort opens a menu of the three keys, the current one '
        'checked', (tester) async {
      await pumpPhone(tester, ['(B) bee', '(A) aye']);
      await tester.tap(key('todo-sort-button'));
      await settle(tester);
      for (final sort in TodoSort.values) {
        expect(key('todo-sort-${sort.name}'), findsOneWidget);
      }
      expect(
        find.descendant(
          of: key('todo-sort-due'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(key('todo-sort-priority'));
      await settle(tester);
      expect(view.filter.sort, TodoSort.priority);
      expect(find.text('Priority A'), findsOneWidget);

      await tester.tap(key('todo-sort-button'));
      await settle(tester);
      expect(
        find.descendant(
          of: key('todo-sort-priority'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('help opens the todo.txt reference', (tester) async {
      await pumpPhone(tester, ['a']);
      await tester.tap(key('todo-help'));
      await settle(tester);
      expect(find.text('The todo.txt format'), findsOneWidget);
    });
  });

  group('the desktop toolbar', () {
    testWidgets('a wide pane has labelled pills, Add task and help', (
      tester,
    ) async {
      await pumpPane(tester, 700, ['a']);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Due date'), findsOneWidget, reason: 'the sort key');
      expect(find.text('Add task'), findsOneWidget);
      expect(key('todo-help'), findsOneWidget);
      expect(key('todo-view-switch'), findsNothing);
      expect(key('todo-count'), findsNothing);
      expect(key('todo-due-menu'), findsNothing);
      // Filter and Sort lead, Add task and help end the row.
      expect(
        tester.getCenter(key('todo-filter-button')).dx,
        lessThan(tester.getCenter(key('todo-sort-button')).dx),
      );
      expect(
        tester.getCenter(key('todo-sort-button')).dx,
        lessThan(tester.getCenter(key('todo-add-button')).dx),
      );
      expect(
        tester.getCenter(key('todo-add-button')).dx,
        lessThan(tester.getCenter(key('todo-help')).dx),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Sort pill names the key, and its menu changes it', (
      tester,
    ) async {
      await pumpPane(tester, 700, ['(B) bee', '(A) aye']);
      await tester.tap(key('todo-sort-button'));
      await settle(tester);
      await tester.tap(key('todo-sort-creation'));
      await settle(tester);
      expect(find.text('Creation date'), findsOneWidget);
      expect(find.text('Due date'), findsNothing);
      expect(view.filter.sort, TodoSort.creation);
    });

    testWidgets('the Filter pill counts the filters and takes the accent', (
      tester,
    ) async {
      await pumpPane(tester, 700, ['a +p +q', 'b +p']);
      final scheme = Theme.of(tester.element(key('todo-filter-button')))
          .colorScheme;
      Color? fill() {
        final button = tester.widget<OutlinedButton>(
          find.descendant(
            of: key('todo-filter-button'),
            matching: find.byType(OutlinedButton),
          ),
        );
        return button.style?.backgroundColor?.resolve(<WidgetState>{});
      }

      final before = tester.getTopLeft(key('todo-sort-button'));
      expect(fill(), isNull);

      view
        ..toggleToken('+p')
        ..setDueRange(TodoDueRange.overdue);
      await tester.pump();
      expect(find.text('Filter · 2'), findsOneWidget);
      expect(fill(), scheme.primaryContainer);
      expect(
        tester.getTopLeft(key('todo-sort-button')),
        before,
        reason: 'the Sort pill does not move as a filter comes',
      );
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    });

    testWidgets('the Filter pill opens the sheet, with the due range', (
      tester,
    ) async {
      await pumpPane(tester, 700, ['a +p']);
      await tester.tap(key('todo-filter-button'));
      await settle(tester);
      expect(key('todo-due-today'), findsOneWidget);
      expect(key('todo-token-+p'), findsOneWidget);
      expect(key('todo-sort-priority'), findsNothing);
    });

    testWidgets('a narrow pane takes the same four controls as icons', (
      tester,
    ) async {
      await pumpPane(tester, 400, ['a']);
      expect(find.text('Filter'), findsNothing);
      expect(find.text('Due date'), findsNothing);
      expect(find.text('Add task'), findsNothing);
      for (final name in [
        'todo-filter-button',
        'todo-sort-button',
        'todo-add-button',
        'todo-help',
      ]) {
        expect(key(name), findsOneWidget, reason: name);
      }
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);

      // The Filter icon says "on" like the phone's: accent and a dot.
      expect(dot(tester).isLabelVisible, isFalse);
      view.setDueRange(TodoDueRange.today);
      await tester.pump();
      expect(dot(tester).isLabelVisible, isTrue);

      // And they work.
      await tester.tap(key('todo-sort-button'));
      await settle(tester);
      expect(key('todo-sort-priority'), findsOneWidget);
    });

    testWidgets('the panes in between never overflow', (tester) async {
      for (final width in [320.0, 420.0, 479.0, 480.0, 560.0]) {
        await pumpPane(tester, width, ['a']);
        view.toggleToken('+p');
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'at $width dp');
      }
    });
  });
}
