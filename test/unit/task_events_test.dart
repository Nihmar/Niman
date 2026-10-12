// #730 phase 2: a lone `+project`/`@context` in the search box, and the
// rows the files in memory answer with. Pure: the models in, the rows out.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';

/// One day with three events: a project, a context and an aside.
const String _busyDay =
    '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library. '
    '13:30-14 call with Marta @phone rem:13:15. '
    '18-19 jogging @park (if dry +thesis).';

/// The mockups' file, headed by a year and a month goal.
const List<String> _calendarLines = [
  '2026  The year of the move +home',
  '2026-10  Finish the thesis draft +thesis',
  '2026-10-05 w41  Reading week',
  _busyDay,
  '2026-10-13 w42 Tue  10-1130 seminar v1.2 review +thesis.',
  '2026-10-14 w42 Wed  8-9 breakfast +homemade.',
];

/// The mockups' tasks.
const List<String> _todoLines = [
  'Send chapter 2 to supervisor +thesis due:2026-10-12',
  'Book the defence room +thesis @phone',
  'x 2026-10-14 Send the draft +thesis',
  '+thesis on its own, no text at all',
  'A task with nothing to match',
];

List<CalendarEntry> get _calendar => [
  for (var i = 0; i < _calendarLines.length; i++)
    CalendarEntry(lineIndex: i, line: parseCalendarLine(_calendarLines[i])),
];

List<TodoEntry> get _todos => [
  for (var i = 0; i < _todoLines.length; i++)
    TodoEntry(lineIndex: i, task: parseTodoLine(_todoLines[i])),
];

void main() {
  group('the lone token', () {
    test('is a project or a context, on its own', () {
      expect(taskEventQuery('+thesis'), '+thesis');
      expect(taskEventQuery('@phone'), '@phone');
      expect(taskEventQuery('  +thesis  '), '+thesis');
    });

    test('is nothing else', () {
      expect(taskEventQuery(''), isNull);
      expect(taskEventQuery('+'), isNull);
      expect(taskEventQuery('@'), isNull);
      expect(taskEventQuery('+thesis chapter'), isNull);
      expect(taskEventQuery('chapter +thesis'), isNull);
      expect(taskEventQuery('#family'), isNull);
      expect(taskEventQuery('thesis'), isNull);
      expect(taskEventQuery('status = draft'), isNull);
    });

    test('keeps what is written, however odd', () {
      expect(taskEventQuery('+thesis.'), '+thesis.');
      expect(taskEventQuery('+Thesis'), '+Thesis');
    });
  });

  group('the rows', () {
    test('come as events, then goals, then open tasks', () {
      final hits = taskEventHits('+thesis', tasks: _todos, calendar: _calendar);
      expect(hits.map((hit) => hit.lineIndex), [3, 4, 1, 0, 1, 3]);
      expect(hits.map((hit) => hit.kind), [
        TaskEventKind.event,
        TaskEventKind.event,
        TaskEventKind.goal,
        TaskEventKind.task,
        TaskEventKind.task,
        TaskEventKind.task,
      ]);
      expect(hits[0].event!.event.text, 'thesis chapter 3 +thesis @library');
      expect(hits[1].event!.event.text, 'seminar v1.2 review +thesis');
      expect(hits[2].goal!.goalText, 'Finish the thesis draft +thesis');
      expect(hits[3].task!.description, contains('Send chapter 2'));
      expect(hits[5].task!.description, contains('on its own'));
    });

    test('a context answers with contexts, and only theirs', () {
      final hits = taskEventHits('@phone', tasks: _todos, calendar: _calendar);
      expect(hits.map((hit) => hit.kind), [
        TaskEventKind.event,
        TaskEventKind.task,
      ]);
      expect(hits[0].event!.event.text, 'call with Marta @phone rem:13:15');
      expect(hits[1].task!.description, 'Book the defence room +thesis @phone');
    });

    test('a token inside an aside is not a token (#730)', () {
      final hits = taskEventHits(
        '+thesis',
        tasks: const <TodoEntry>[],
        calendar: _calendar,
      );
      final events = hits.where((hit) => hit.kind == TaskEventKind.event);
      expect(
        events.map((hit) => hit.event!.event.text),
        isNot(contains(contains('jogging'))),
      );
    });

    test('the goals come week, then month, then year', () {
      final lines = [
        '2026  The year +thesis',
        '2026-10  The month +thesis',
        '2026-10-05 w41  The week +thesis',
      ];
      final hits = taskEventHits(
        '+thesis',
        tasks: const <TodoEntry>[],
        calendar: [
          for (var i = 0; i < lines.length; i++)
            CalendarEntry(lineIndex: i, line: parseCalendarLine(lines[i])),
        ],
      );
      expect(hits.map((hit) => hit.goal!.goalText), [
        'The week +thesis',
        'The month +thesis',
        'The year +thesis',
      ]);
    });

    test('a token is matched whole: +home is not +homemade', () {
      expect(
        taskEventHits(
          '+home',
          tasks: _todos,
          calendar: _calendar,
        ).map((hit) => hit.goal?.goalText),
        ['The year of the move +home'],
      );
      expect(
        taskEventHits(
          '+homemade',
          tasks: _todos,
          calendar: _calendar,
        ).single.event!.event.text,
        'breakfast +homemade',
      );
    });

    test('a completed task is not a row', () {
      final hits = taskEventHits(
        '+thesis',
        tasks: _todos,
        calendar: const <CalendarEntry>[],
      );
      expect(hits, hasLength(3));
      expect(hits.map((hit) => hit.lineIndex), isNot(contains(2)));
      expect(hits.map((hit) => hit.task!.completed), everyElement(isFalse));
    });

    test('the token is read exactly: +thesis is not +Thesis', () {
      expect(
        taskEventHits('+Thesis', tasks: _todos, calendar: _calendar),
        isEmpty,
      );
      expect(
        taskEventHits('+thes', tasks: _todos, calendar: _calendar),
        isEmpty,
      );
      expect(
        taskEventHits('@Phone', tasks: _todos, calendar: _calendar),
        isEmpty,
      );
    });

    test('anything that is not a lone token answers nothing', () {
      for (final token in ['', '+', '#family', 'thesis', '+thesis extra']) {
        expect(
          taskEventHits(token, tasks: _todos, calendar: _calendar),
          isEmpty,
          reason: token,
        );
      }
    });

    test("a day the row is about: the event's, the goal's, the due", () {
      final hits = taskEventHits('+thesis', tasks: _todos, calendar: _calendar);
      expect(hits[0].day, DateTime(2026, 10, 12));
      expect(hits[2].day, DateTime(2026, 10));
      expect(hits[3].day, DateTime(2026, 10, 12));
      expect(hits.where((hit) => hit.task != null).map((hit) => hit.day), [
        DateTime(2026, 10, 12),
        isNull,
        isNull,
      ]);
    });
  });
}
