// #1003: the view state the shell shares between the Todo tab and the
// phone app bar.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';

void main() {
  late TodoListView view;
  late int notifications;
  late List<Set<String>> saved;

  setUp(() {
    saved = <Set<String>>[];
    view = TodoListView(onCollapsedChanged: saved.add);
    notifications = 0;
    view.addListener(() => notifications++);
  });

  tearDown(() => view.dispose());

  group('filter', () {
    test('starts as everything, due soonest first', () {
      expect(view.filter, const TodoFilter());
      expect(view.activeFilterCount, 0);
      expect(view.hasActiveFilters, isFalse);
    });

    test('setDueRange, toggleToken and setSort edit one field each', () {
      view
        ..setDueRange(TodoDueRange.overdue)
        ..toggleToken('+home')
        ..setSort(TodoSort.priority);
      expect(
        view.filter,
        const TodoFilter(
          dueRange: TodoDueRange.overdue,
          tokens: {'+home'},
          sort: TodoSort.priority,
        ),
      );
      expect(notifications, 3);
    });

    test('toggleToken selects, then deselects', () {
      view
        ..toggleToken('@phone')
        ..toggleToken('+home');
      expect(view.filter.tokens, {'@phone', '+home'});
      view.toggleToken('@phone');
      expect(view.filter.tokens, {'+home'});
    });

    test('the filter never aliases a set a caller kept', () {
      view.toggleToken('+a');
      final before = view.filter.tokens;
      view.toggleToken('+b');
      expect(before, {'+a'});
    });

    test('a change that changes nothing notifies nobody', () {
      view
        ..setDueRange(TodoDueRange.all)
        ..setSort(TodoSort.due)
        ..clearFilters()
        ..pruneTokens({'+x'});
      expect(notifications, 0);
    });

    test('activeFilterCount is the tokens plus a due range', () {
      view
        ..toggleToken('+a')
        ..toggleToken('@b');
      expect(view.activeFilterCount, 2);
      view.setDueRange(TodoDueRange.noDate);
      expect(view.activeFilterCount, 3);
      expect(view.hasActiveFilters, isTrue);
      // The sort is not a filter.
      view.setSort(TodoSort.creation);
      expect(view.activeFilterCount, 3);
    });

    test('clearFilters resets the range and the tokens, not the sort', () {
      view
        ..setDueRange(TodoDueRange.today)
        ..toggleToken('#x')
        ..setSort(TodoSort.priority);
      notifications = 0;
      view.clearFilters();
      expect(view.filter, const TodoFilter(sort: TodoSort.priority));
      expect(view.activeFilterCount, 0);
      expect(notifications, 1);
    });

    test('pruneTokens drops the chips the file no longer carries', () {
      view
        ..toggleToken('+a')
        ..toggleToken('+b');
      notifications = 0;
      view.pruneTokens({'+b', '+c'});
      expect(view.filter.tokens, {'+b'});
      expect(notifications, 1);
    });

    test('setFilter replaces the whole filter', () {
      const next = TodoFilter(
        dueRange: TodoDueRange.next7,
        tokens: {'@x'},
        sort: TodoSort.creation,
      );
      view.setFilter(next);
      expect(view.filter, next);
      expect(notifications, 1);
    });

    test('a view can start from a filter', () {
      final started = TodoListView(filter: const TodoFilter(tokens: {'+a'}));
      addTearDown(started.dispose);
      expect(started.activeFilterCount, 1);
    });
  });

  group('collapsed sections', () {
    test('Done starts folded, the rest open', () {
      expect(view.isCollapsed('done'), isTrue);
      expect(view.isCollapsed('due.today'), isFalse);
      expect(view.collapsed, {'done'});
    });

    test('toggleSection flips, notifies and reports the new set', () {
      view.toggleSection('done');
      expect(view.isCollapsed('done'), isFalse);
      view.toggleSection('due.later');
      expect(view.isCollapsed('due.later'), isTrue);
      expect(notifications, 2);
      expect(saved, [
        <String>{},
        {'due.later'},
      ]);
    });

    test('the reported set is a copy', () {
      view.toggleSection('priority.A');
      saved.single.add('stray');
      expect(view.isCollapsed('stray'), isFalse);
      expect(() => view.collapsed.add('stray'), throwsUnsupportedError);
    });

    test('a view starts from the sections it is given', () {
      final started = TodoListView(collapsed: {'due.none'});
      addTearDown(started.dispose);
      expect(started.isCollapsed('done'), isFalse);
      expect(started.isCollapsed('due.none'), isTrue);
    });

    test('restoreCollapsed takes the persisted set without reporting it', () {
      view.restoreCollapsed({'due.later', 'done'});
      expect(view.collapsed, {'due.later', 'done'});
      expect(notifications, 1);
      expect(saved, isEmpty);
      view.restoreCollapsed({'done', 'due.later'});
      expect(notifications, 1, reason: 'the same set is not a change');
    });

    test('a section toggled before the stored set arrives is kept', () {
      view
        ..toggleSection('priority.A')
        ..restoreCollapsed({'due.later'});
      expect(view.collapsed, {'done', 'priority.A'});
    });

    test('without a callback toggling still works', () {
      final bare = TodoListView();
      addTearDown(bare.dispose);
      bare.toggleSection('done');
      expect(bare.isCollapsed('done'), isFalse);
    });

    test('the filter does not touch the folded sections', () {
      view
        ..setDueRange(TodoDueRange.overdue)
        ..clearFilters();
      expect(view.collapsed, {'done'});
      expect(saved, isEmpty);
    });
  });
}
