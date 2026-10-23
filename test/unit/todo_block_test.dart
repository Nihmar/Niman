// The query a `todo` block holds (#1152): how its lines are read, which of
// them are errors, and which tasks the query lists and in what order.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link_hits.dart';
import 'package:niman/src/todo/todo_block_due.dart';
import 'package:niman/src/todo/todo_block_error.dart';
import 'package:niman/src/todo/todo_block_keys.dart';
import 'package:niman/src/todo/todo_block_parser.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/todo/todo_block_run.dart';
import 'package:niman/src/todo/todo_store.dart';

final DateTime _today = DateTime(2026, 10, 20);

List<TodoEntry> _entries(List<String> lines) => [
  for (var i = 0; i < lines.length; i++)
    TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
];

/// The descriptions of [entries], for a list to compare.
List<String> _words(List<TodoEntry> entries) => [
  for (final entry in entries) entry.task.description.split(' ').first,
];

void main() {
  group('reading a block', () {
    test('an empty block is the open tasks that link the note', () {
      final block = TodoBlock.parse('');
      expect(block.hasErrors, isFalse);
      expect(block.query.link, isA<LinkThis>());
      expect(block.query.done, TodoBlockDone.no);
      expect(block.query.sort, TodoBlockSort.due);
    });

    test('blank lines and the spaces round a line are ignored', () {
      final block = TodoBlock.parse('\n   project:   house   \n\n\t tag : a\n');
      expect(block.hasErrors, isFalse);
      expect(block.query.projects, ['house']);
      expect(block.query.tags, ['a']);
    });

    test('link stays this whatever else the block filters by', () {
      final block = TodoBlock.parse('project: house\ndue: today\nsort: file');
      expect(block.query.link, isA<LinkThis>());
    });

    test('link reads this, any and a note', () {
      expect(TodoBlock.parse('link: any').query.link, isA<LinkAny>());
      expect(TodoBlock.parse('link: this').query.link, isA<LinkThis>());
      final note = TodoBlock.parse('link: [[House/Repairs#Boiler|x]]').query;
      expect((note.link as LinkNote).target, 'House/Repairs');
    });

    test('project, context and tag take the sigil or not, and repeat', () {
      final block = TodoBlock.parse(
        'project: +house\nproject: garden\ncontext: @phone\ntag: #urgent',
      );
      expect(block.hasErrors, isFalse);
      expect(block.query.projects, ['house', 'garden']);
      expect(block.query.contexts, ['phone']);
      expect(block.query.tags, ['urgent']);
      expect(block.query.tokens, {'+house', '+garden', '@phone', '#urgent'});
    });

    test('keys are read in any case', () {
      final block = TodoBlock.parse('Project: house\nDONE: All\nSort: FILE');
      expect(block.hasErrors, isFalse);
      expect(block.query.done, TodoBlockDone.all);
      expect(block.query.sort, TodoBlockSort.file);
    });

    test('priority reads a letter and a range', () {
      var query = TodoBlock.parse('priority: a').query;
      expect((query.priorityFrom, query.priorityTo), ('A', 'A'));
      query = TodoBlock.parse('priority: A-B').query;
      expect((query.priorityFrom, query.priorityTo), ('A', 'B'));
      expect(query.priorityMatches('A'), isTrue);
      expect(query.priorityMatches('C'), isFalse);
      expect(query.priorityMatches(null), isFalse);
      expect(TodoBlock.parse('').query.priorityMatches(null), isTrue);
    });
  });

  group('errors', () {
    test('an unknown key is an error with its line and the nearest key', () {
      final block = TodoBlock.parse('project: house\nprio: A');
      expect(block.hasErrors, isTrue);
      final error = block.errors.single;
      expect(error.kind, TodoBlockErrorKind.unknownKey);
      expect(error.line, 2);
      expect(error.key, 'prio');
      expect(error.suggestion, 'priority');
      // What the good lines say is kept, for the head to tell.
      expect(block.query.projects, ['house']);
    });

    test('lines are counted from 1, blank lines counted', () {
      final block = TodoBlock.parse('\n\nwhat: x');
      expect(block.errors.single.line, 3);
    });

    test('the nearest key', () {
      expect(nearestTodoBlockKey('prio'), 'priority');
      expect(nearestTodoBlockKey('proj'), 'project');
      expect(nearestTodoBlockKey('projet'), 'project');
      expect(nearestTodoBlockKey('tags'), 'tag');
      expect(nearestTodoBlockKey('contxt'), 'context');
      expect(nearestTodoBlockKey('donee'), 'done');
      expect(nearestTodoBlockKey('Priority'), 'priority');
      // Too far, too short, or two keys equally started.
      expect(nearestTodoBlockKey('banana'), isNull);
      expect(nearestTodoBlockKey('x'), isNull);
      expect(nearestTodoBlockKey('p'), isNull);
      expect(TodoBlock.parse('banana: 1').errors.single.suggestion, isNull);
    });

    test('a line without a colon', () {
      final error = TodoBlock.parse('project house').errors.single;
      expect(error.kind, TodoBlockErrorKind.noColon);
      expect(error.key, 'project house');
    });

    test('a key with no value', () {
      final error = TodoBlock.parse('due:').errors.single;
      expect(error.kind, TodoBlockErrorKind.missingValue);
      expect(error.key, 'due');
    });

    test('a value the key cannot read', () {
      for (final line in [
        'link: [[]]',
        'link: here',
        'link: [[Note',
        'due: soon',
        'due: <=7d',
        'due: 2026-13-01',
        'due: 2026-02-30',
        'due: 2026-11-07..2026-11-01',
        'priority: AB',
        'priority: B-A',
        'priority: 1',
        'done: maybe',
        'sort: size',
        'project: two words',
        'project: +',
        'tag: a#b',
      ]) {
        final block = TodoBlock.parse(line);
        expect(block.errors.map((e) => e.kind), [
          TodoBlockErrorKind.badValue,
        ], reason: line);
        expect(block.errors.single.expected, isNotEmpty, reason: line);
      }
    });

    test('a key given twice that takes one value', () {
      final block = TodoBlock.parse('due: today\ndue: overdue\nsort: file');
      expect(block.errors.single.kind, TodoBlockErrorKind.repeatedKey);
      expect(block.errors.single.line, 2);
      // The first one stands.
      expect(block.query.due, isA<DueToday>());
    });

    test('every bad line is reported, in order', () {
      final block = TodoBlock.parse('what: 1\ndue: soon\nproject: house');
      expect(block.errors.map((e) => e.line), [1, 2]);
    });
  });

  group('due', () {
    bool listed(String value, DateTime? due) =>
        TodoBlockDue.parse(value)!.matches(due, _today);

    test('today and overdue', () {
      expect(listed('today', DateTime(2026, 10, 20)), isTrue);
      expect(listed('today', DateTime(2026, 10, 21)), isFalse);
      expect(listed('today', null), isFalse);
      expect(listed('overdue', DateTime(2026, 10, 19)), isTrue);
      expect(listed('overdue', DateTime(2026, 10, 20)), isFalse);
      expect(listed('overdue', null), isFalse);
    });

    test('<=+Nd is today and N days on, and everything overdue', () {
      expect(listed('<=+7d', DateTime(2026, 10)), isTrue);
      expect(listed('<=+7d', DateTime(2026, 10, 27)), isTrue);
      expect(listed('<=+7d', DateTime(2026, 10, 28)), isFalse);
      expect(listed('<=+0d', DateTime(2026, 10, 20)), isTrue);
      expect(listed('<=+0d', DateTime(2026, 10, 21)), isFalse);
      expect(listed('<=+7d', null), isFalse);
    });

    test('a date, and a range of dates', () {
      expect(listed('2026-11-02', DateTime(2026, 11, 2)), isTrue);
      expect(listed('2026-11-02', DateTime(2026, 11, 3)), isFalse);
      expect(listed('2026-11-01..2026-11-07', DateTime(2026, 11)), isTrue);
      expect(listed('2026-11-01..2026-11-07', DateTime(2026, 11, 7)), isTrue);
      expect(listed('2026-11-01..2026-11-07', DateTime(2026, 11, 8)), isFalse);
      expect(listed('2026-11-01 .. 2026-11-07', DateTime(2026, 11, 4)), isTrue);
    });
  });

  group('running a block', () {
    final todo = _entries([
      '(B) Pay the bill +house due:2026-10-25',
      'Call the plumber +house @phone due:2026-10-22',
      '(A) Renew the insurance +house due:2026-10-18',
      'Water the plants #garden',
      '',
      '(C) Sort the garage +house @home due:2026-11-30',
    ]);
    final done = _entries([
      'x 2026-10-10 2026-10-01 Fix the tap +house due:2026-10-09',
      'x 2026-10-12 2026-10-02 Buy paint +house',
    ]);
    final snapshot = TodoSnapshot(todo: todo, done: done);
    // The note's own tasks: the plumber and the bill, then one done.
    NoteTasks tasksFor(String path) => switch (path) {
      'House/Repairs.md' => NoteTasks(
        open: [todo[0], todo[1]],
        done: [done[0]],
      ),
      'Other.md' => NoteTasks(open: [todo[3]], done: const []),
      _ => NoteTasks.none,
    };

    List<String> open(String source, {String? named}) => _words(
      runTodoBlock(
        TodoBlock.parse(source).query,
        snapshot: snapshot,
        tasksFor: tasksFor,
        notePath: 'House/Repairs.md',
        namedPath: named,
        today: _today,
      ).open,
    );

    NoteTasks run(String source, {String? named}) => runTodoBlock(
      TodoBlock.parse(source).query,
      snapshot: snapshot,
      tasksFor: tasksFor,
      notePath: 'House/Repairs.md',
      namedPath: named,
      today: _today,
    );

    test('link this is the default: the tasks that link the note', () {
      expect(open(''), ['Call', 'Pay']);
      expect(open('project: house'), ['Call', 'Pay']);
      expect(open('project: garden'), isEmpty);
    });

    test('link any lists every task but the blank lines', () {
      expect(open('link: any'), ['Renew', 'Call', 'Pay', 'Sort', 'Water']);
    });

    test("link to a note lists that note's tasks, none when it is none", () {
      expect(open('link: [[Other]]', named: 'Other.md'), ['Water']);
      expect(open('link: [[Nope]]'), isEmpty);
    });

    test('project, context and tag must all match', () {
      expect(open('link: any\nproject: house\ncontext: phone'), ['Call']);
      expect(
        open('link: any\nproject: house\ncontext: phone\ncontext: home'),
        isEmpty,
      );
      expect(open('link: any\ntag: garden'), ['Water']);
      expect(open('link: any\nproject: +house\ncontext: @home'), ['Sort']);
    });

    test('due', () {
      expect(open('link: any\ndue: overdue'), ['Renew']);
      expect(open('link: any\ndue: <=+7d'), ['Renew', 'Call', 'Pay']);
      expect(open('link: any\ndue: 2026-10-22'), ['Call']);
      expect(open('link: any\ndue: 2026-10-22..2026-10-25'), ['Call', 'Pay']);
    });

    test('priority', () {
      expect(open('link: any\npriority: A'), ['Renew']);
      expect(open('link: any\npriority: A-B'), ['Renew', 'Pay']);
    });

    test('done: no is the open tasks, yes the done ones, all both', () {
      var tasks = run('done: yes');
      expect(tasks.open, isEmpty);
      expect(_words(tasks.done), ['Fix']);
      tasks = run('done: all');
      expect(_words(tasks.open), ['Call', 'Pay']);
      expect(_words(tasks.done), ['Fix']);
      tasks = run('link: any\ndone: all');
      expect(tasks.done, hasLength(2));
      expect(run('').done, isEmpty);
    });

    test("sort: due by default, then priority or the file's order", () {
      expect(open('link: any'), ['Renew', 'Call', 'Pay', 'Sort', 'Water']);
      expect(open('link: any\nsort: priority'), [
        'Renew',
        'Pay',
        'Sort',
        'Call',
        'Water',
      ]);
      expect(open('link: any\nsort: file'), [
        'Pay',
        'Call',
        'Renew',
        'Water',
        'Sort',
      ]);
    });

    test('the same lines list the same tasks, each time', () {
      expect(open('link: any\ndue: <=+30d'), open('link: any\ndue: <=+30d'));
    });
  });
}
