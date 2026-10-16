// #1003: the todo list is cut into sections that follow the sort key; the
// Done section is ordered newest completion first.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/todo/todo_store.dart';

void main() {
  /// Fixed "today" (a Monday).
  final today = DateTime(2026, 9, 7);

  List<TodoEntry> entries(List<String> lines) {
    return <TodoEntry>[
      for (var i = 0; i < lines.length; i++)
        TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
    ];
  }

  String firstWord(TodoEntry entry) => entry.task.description.split(' ').first;

  /// `id: first word of every entry` for each section, to compare lists.
  List<String> shape(List<TodoSection> sections) {
    return <String>[
      for (final section in sections)
        '${section.id}: ${section.entries.map(firstWord).join(',')}',
    ];
  }

  List<TodoSection> sectionsOf(
    List<String> lines,
    TodoSort sort, {
    DateTime? now,
  }) {
    final when = now ?? today;
    final sorted = applyTodoFilter(
      entries(lines),
      TodoFilter(sort: sort),
      when,
    );
    return todoSections(sorted, sort, when);
  }

  group('by due date', () {
    test('every boundary lands in its own section', () {
      final sections = sectionsOf(const [
        'older due:2026-08-01',
        'yesterday due:2026-09-06',
        'today due:2026-09-07',
        'tomorrow due:2026-09-08',
        'edge due:2026-09-14',
        'after due:2026-09-15',
        'undated',
      ], TodoSort.due);
      expect(shape(sections), [
        'due.overdue: older,yesterday',
        'due.today: today',
        'due.next7: tomorrow,edge',
        'due.later: after',
        'due.none: undated',
      ]);
    });

    test('empty sections are dropped', () {
      final sections = sectionsOf(const [
        'far due:2027-01-01',
        'undated',
      ], TodoSort.due);
      expect(shape(sections), ['due.later: far', 'due.none: undated']);
    });

    test('the section order does not depend on the input order', () {
      final sections = todoSections(
        entries(const [
          'undated',
          'later due:2026-12-01',
          'today due:2026-09-07',
          'late due:2026-09-01',
        ]),
        TodoSort.due,
        today,
      );
      expect(
        [for (final s in sections) s.id],
        ['due.overdue', 'due.today', 'due.later', 'due.none'],
      );
    });

    test('the time of day of "today" does not move a boundary', () {
      final sections = sectionsOf(
        const ['today due:2026-09-07', 'tomorrow due:2026-09-08'],
        TodoSort.due,
        now: DateTime(2026, 9, 7, 23, 59),
      );
      expect(shape(sections), ['due.today: today', 'due.next7: tomorrow']);
    });

    test('entries keep the order they arrive in', () {
      final sections = todoSections(
        entries(const [
          'b due:2026-09-09',
          'a due:2026-09-08',
          'c due:2026-09-10',
        ]),
        TodoSort.due,
        today,
      );
      expect(shape(sections), ['due.next7: b,a,c']);
    });

    test('count is the number of entries', () {
      final sections = sectionsOf(const [
        'a due:2026-09-01',
        'b due:2026-09-02',
      ], TodoSort.due);
      expect(sections.single.count, 2);
    });

    test('an empty list has no sections', () {
      expect(todoSections(const [], TodoSort.due, today), isEmpty);
      expect(todoSections(const [], TodoSort.priority, today), isEmpty);
      expect(todoSections(const [], TodoSort.creation, today), isEmpty);
    });
  });

  // Europe/Rome falls back on 2026-10-25: from 24 October, 168 hours later
  // is 30 October 23:00, so a clock-hour window drops the seventh calendar
  // day (#380, #957). Only a zone that falls back in that week shows it:
  // `TZ=Europe/Rome flutter test test/unit/todo_sections_test.dart`.
  final zoneFallsBack =
      DateTime(2026, 10, 24).timeZoneOffset !=
      DateTime(2026, 10, 26).timeZoneOffset;

  group('across a DST fall-back', () {
    test('holds seven calendar days, not 168 hours', () {
      final sections = sectionsOf(
        const [
          'sixth due:2026-10-30',
          'seventh due:2026-10-31',
          'eighth due:2026-11-01',
        ],
        TodoSort.due,
        now: DateTime(2026, 10, 24),
      );
      expect(shape(sections), [
        'due.next7: sixth,seventh',
        'due.later: eighth',
      ]);
    }, skip: zoneFallsBack ? null : 'needs TZ=Europe/Rome (see the comment)');

    test('a today on the change day still sees tomorrow as next7', () {
      final sections = sectionsOf(
        const ['today due:2026-10-25', 'tomorrow due:2026-10-26'],
        TodoSort.due,
        now: DateTime(2026, 10, 25),
      );
      expect(shape(sections), ['due.today: today', 'due.next7: tomorrow']);
    }, skip: zoneFallsBack ? null : 'needs TZ=Europe/Rome (see the comment)');
  });

  group('by priority', () {
    test('one section per letter present, A first, none last', () {
      final sections = sectionsOf(const [
        'plain',
        '(C) third',
        '(A) first',
        '(Z) last',
        '(A) again',
      ], TodoSort.priority);
      expect(shape(sections), [
        'priority.A: first,again',
        'priority.C: third',
        'priority.Z: last',
        'priority.none: plain',
      ]);
    });

    test('empty sections are dropped', () {
      final sections = sectionsOf(const ['(B) only'], TodoSort.priority);
      expect([for (final s in sections) s.id], ['priority.B']);
    });

    test('without any priority there is only the none section', () {
      final sections = sectionsOf(const ['a', 'b'], TodoSort.priority);
      expect(shape(sections), ['priority.none: a,b']);
    });
  });

  group('by creation date', () {
    test('a single flat section, in order', () {
      final sections = sectionsOf(const [
        '2026-09-01 old',
        '2026-09-05 new',
        'undated',
      ], TodoSort.creation);
      expect(shape(sections), ['all: new,old,undated']);
      expect(sections.single.id, todoAllSectionId);
    });
  });

  group('Done entries', () {
    test('the id is stable', () {
      expect(todoDoneSectionId, 'done');
    });

    test('newest completion first, undated last, later line breaks ties', () {
      final done = entries(const [
        'x 2026-09-01 oldest',
        'x 2026-09-05 newer first',
        'x no date at all',
        'x 2026-09-05 newer second',
        'x 2026-09-03 middle',
        'x another undated',
      ]);
      final sorted = sortDoneEntries(done);
      expect([for (final e in sorted) e.lineIndex], [3, 1, 4, 0, 5, 2]);
    });

    test('does not reorder the list it is given', () {
      final done = entries(const ['x 2026-09-01 a', 'x 2026-09-02 b']);
      sortDoneEntries(done);
      expect([for (final e in done) e.lineIndex], [0, 1]);
    });
  });
}
