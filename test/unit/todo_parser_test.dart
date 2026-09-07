// T-TD-01 AC: todo.txt parser — the reference line, edge cases (uppercase
// `X`, no space after `x`, missing creation date, `due:` at line end,
// unicode/emoji, trailing whitespace, CRLF) and byte-stable round-trips.
import 'package:copist/src/todo/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reference line', () {
    const line =
        'x (A) 2016-05-20 2016-04-30 measure space for +chapelShelving '
        '@chapel due:2016-05-30';

    test('parses every field of the description.svg line', () {
      final task = parseTodoLine(line);
      expect(task.completed, isTrue);
      expect(task.priority, 'A');
      expect(task.completionDate, DateTime(2016, 5, 20));
      expect(task.creationDate, DateTime(2016, 4, 30));
      expect(
        task.description,
        'measure space for +chapelShelving @chapel due:2016-05-30',
      );
      expect(task.projects, ['chapelShelving']);
      expect(task.contexts, ['chapel']);
      expect(task.due, DateTime(2016, 5, 30));
      expect(task.missingCreationDate, isFalse);
    });

    test('untouched line round-trips byte-stable', () {
      expect(parseTodoLine(line).toLine(), line);
    });
  });

  group('completion mark', () {
    test('uppercase X is description, not completion', () {
      final task = parseTodoLine('X call mom');
      expect(task.completed, isFalse);
      expect(task.description, 'X call mom');
      expect(task.toLine(), 'X call mom');
    });

    test('x glued to text is description', () {
      final task = parseTodoLine('xfoo');
      expect(task.completed, isFalse);
      expect(task.description, 'xfoo');
    });

    test('bare x is description', () {
      final task = parseTodoLine('x');
      expect(task.completed, isTrue);
      expect(task.description, isEmpty);
    });

    test('x plus spaces is a completed empty task', () {
      final task = parseTodoLine('x   ');
      expect(task.completed, isTrue);
      expect(task.description, isEmpty);
      expect(task.toLine(), 'x   ');
    });

    test('x without dates completes with an empty description', () {
      final task = parseTodoLine('x tidy room');
      expect(task.completed, isTrue);
      expect(task.completionDate, isNull);
      expect(task.creationDate, isNull);
      expect(task.description, 'tidy room');
    });
  });

  group('priority', () {
    test('incomplete priority + creation', () {
      final task = parseTodoLine('(B) 2016-04-30 measure space');
      expect(task.completed, isFalse);
      expect(task.priority, 'B');
      expect(task.creationDate, DateTime(2016, 4, 30));
      expect(task.description, 'measure space');
    });

    test('lowercase priority is description', () {
      final task = parseTodoLine('(a) foo');
      expect(task.priority, isNull);
      expect(task.description, '(a) foo');
    });

    test('multi-letter parens are description', () {
      final task = parseTodoLine('(AA) foo');
      expect(task.priority, isNull);
      expect(task.description, '(AA) foo');
    });

    test('priority glued to text is description', () {
      final task = parseTodoLine('(A)foo');
      expect(task.priority, isNull);
      expect(task.description, '(A)foo');
    });

    test('priority Z parses', () {
      expect(parseTodoLine('(Z) foo').priority, 'Z');
    });
  });

  group('dates', () {
    test('completion without creation is flagged but preserved', () {
      final task = parseTodoLine('x 2016-05-20 measure space');
      expect(task.completed, isTrue);
      expect(task.completionDate, DateTime(2016, 5, 20));
      expect(task.creationDate, isNull);
      expect(task.missingCreationDate, isTrue);
      expect(task.toLine(), 'x 2016-05-20 measure space');
    });

    test('impossible dates stay description text', () {
      final task = parseTodoLine('x 2020-13-99 foo');
      expect(task.completionDate, isNull);
      expect(task.creationDate, isNull);
      expect(task.description, '2020-13-99 foo');
    });

    test('Feb 30 stays description text', () {
      final task = parseTodoLine('2021-02-30 foo');
      expect(task.creationDate, isNull);
      expect(task.description, '2021-02-30 foo');
    });

    test('Feb 29 parses on a leap year', () {
      final task = parseTodoLine('2020-02-29 foo');
      expect(task.creationDate, DateTime(2020, 2, 29));
    });

    test('a second date on an incomplete line stays description', () {
      final task = parseTodoLine('(A) 2020-01-02 2020-02-03 foo');
      expect(task.creationDate, DateTime(2020, 1, 2));
      expect(task.description, '2020-02-03 foo');
    });

    test('non-padded dates stay description text', () {
      final task = parseTodoLine('2020-1-1 foo');
      expect(task.creationDate, isNull);
      expect(task.description, '2020-1-1 foo');
    });
  });

  group('tokens and key/values', () {
    test('due at line end is plain text', () {
      final task = parseTodoLine('call mom due:');
      expect(task.due, isNull);
      expect(task.keyValues, isEmpty);
      expect(task.toLine(), 'call mom due:');
    });

    test('malformed due value is an unknown tag', () {
      final task = parseTodoLine('call mom due:tomorrow');
      expect(task.due, isNull);
      expect(task.keyValues, hasLength(1));
      expect(task.keyValues.single.token, 'due:tomorrow');
    });

    test('rem timestamp parses as local wall-clock time', () {
      final task = parseTodoLine('call mom rem:2026-09-07T10:30');
      expect(task.reminder, DateTime(2026, 9, 7, 10, 30));
      expect(task.keyValues, isEmpty);
      expect(task.toLine(), 'call mom rem:2026-09-07T10:30');
    });

    test('malformed rem value is an unknown tag', () {
      final task = parseTodoLine('call mom rem:soon');
      expect(task.reminder, isNull);
      expect(task.keyValues.single.token, 'rem:soon');
    });

    test('rec: is an unknown tag preserved verbatim', () {
      final task = parseTodoLine('water plants rec:+1d due:2026-09-08');
      expect(task.keyValues.single.token, 'rec:+1d');
      expect(task.due, DateTime(2026, 9, 8));
      expect(
        task.toLine(),
        'water plants rec:+1d due:2026-09-08',
      );
    });

    test('arbitrary key/values are kept in order', () {
      final task = parseTodoLine('foo bar:1 baz:two bar:3');
      expect(
        [for (final kv in task.keyValues) kv.token],
        ['bar:1', 'baz:two', 'bar:3'],
      );
    });

    test('first valid due wins; later ones are unknown tags', () {
      final task = parseTodoLine('foo due:2026-01-02 due:2026-02-03');
      expect(task.due, DateTime(2026, 1, 2));
      expect(task.keyValues.single.token, 'due:2026-02-03');
    });

    test('sigils inside words are not tokens', () {
      final task = parseTodoLine('mail a+b to a@b about C#');
      expect(task.projects, isEmpty);
      expect(task.contexts, isEmpty);
      expect(task.hashtags, isEmpty);
    });

    test('hashtags parse anywhere in the description', () {
      final task = parseTodoLine('read #book +lib @home #book');
      expect(task.hashtags, ['book', 'book']);
      expect(task.projects, ['lib']);
      expect(task.contexts, ['home']);
    });
  });

  group('unicode, whitespace, line endings', () {
    test('unicode and emoji survive parsing', () {
      const line =
          'x (B) 2026-01-02 2026-01-01 café ☕ +café @żółć #tag-émoji 🎉';
      final task = parseTodoLine(line);
      expect(task.priority, 'B');
      expect(task.projects, ['café']);
      expect(task.contexts, ['żółć']);
      expect(task.hashtags, ['tag-émoji']);
      expect(task.toLine(), line);
    });

    test('trailing whitespace round-trips byte-stable', () {
      const line = 'call mom +errands   ';
      expect(parseTodoLine(line).toLine(), line);
      expect(parseTodoLine(line).description, 'call mom +errands');
    });

    test('CRLF terminator is stripped for parsing', () {
      final task = parseTodoLine('call mom\r');
      expect(task.description, 'call mom');
      expect(task.toLine(), 'call mom');
    });

    test('indented lines still parse as tasks', () {
      final task = parseTodoLine('  (B) foo');
      expect(task.priority, 'B');
      expect(task.description, 'foo');
      expect(task.toLine(), '  (B) foo');
    });

    test('empty line parses to an empty description', () {
      final task = parseTodoLine('');
      expect(task.completed, isFalse);
      expect(task.description, isEmpty);
      expect(task.toLine(), isEmpty);
    });
  });

  group('check / uncheck', () {
    test('checking prepends today and keeps creation and priority', () {
      final line = completeTodoLine(
        '(A) 2026-01-01 call mom +errands',
        DateTime(2026, 9, 7, 15, 30),
      );
      expect(line, 'x (A) 2026-09-07 2026-01-01 call mom +errands');
    });

    test('checking drops the time part of today', () {
      expect(
        completeTodoLine('foo', DateTime(2026, 9, 7, 23, 59)),
        'x 2026-09-07 foo',
      );
    });

    test('checking is idempotent', () {
      const line = 'x 2026-09-06 foo';
      expect(completeTodoLine(line, DateTime(2026, 9, 7)), line);
    });

    test('unchecking strips the completion mark and date', () {
      expect(
        uncompleteTodoLine('x (A) 2026-09-07 2026-01-01 call mom'),
        '(A) 2026-01-01 call mom',
      );
    });

    test('unchecking a dateless done line restores the text', () {
      expect(uncompleteTodoLine('x tidy room'), 'tidy room');
    });

    test('unchecking is idempotent', () {
      const line = '(A) 2026-01-01 foo';
      expect(uncompleteTodoLine(line), line);
    });

    test('check/uncheck round-trips through the store format', () {
      const open = '(B) 2026-03-01 write report +work @office due:2026-04-01';
      final done = completeTodoLine(open, DateTime(2026, 3, 5));
      expect(
        done,
        'x (B) 2026-03-05 2026-03-01 write report +work @office due:2026-04-01',
      );
      expect(uncompleteTodoLine(done), open);
    });
  });

  group('withKeyValueTag', () {
    test('replaces an existing tag where it stands', () {
      expect(
        withKeyValueTag('call due:2026-09-01 mom', 'due', '2026-09-08'),
        'call mom due:2026-09-08',
      );
    });

    test('appends a missing tag', () {
      expect(
        withKeyValueTag('call mom', 'due', '2026-09-08'),
        'call mom due:2026-09-08',
      );
    });

    test('removes every occurrence with a null value', () {
      expect(
        withKeyValueTag('a due:2026-09-01 b due:2026-09-02', 'due', null),
        'a b',
      );
    });

    test('keeps unknown tags verbatim', () {
      expect(
        withKeyValueTag(
          'water rec:+1d plants due:2026-09-01 foo:bar',
          'due',
          '2026-09-08',
        ),
        'water rec:+1d plants foo:bar due:2026-09-08',
      );
    });

    test('tag-only description reduces to the tag or nothing', () {
      expect(withKeyValueTag('', 'due', '2026-09-08'), 'due:2026-09-08');
      expect(withKeyValueTag('due:2026-09-01', 'due', null), isEmpty);
    });

    test('a bare key counts as the slot and is replaced', () {
      expect(
        withKeyValueTag('call due:', 'due', '2026-09-08'),
        'call due:2026-09-08',
      );
    });
  });

  group('formatTodoLine', () {
    test('builds a canonical line', () {
      expect(
        formatTodoLine(
          completed: true,
          priority: 'C',
          completionDate: DateTime(2026, 5, 20),
          creationDate: DateTime(2026, 4, 30),
          description: '  spaced out  ',
        ),
        'x (C) 2026-05-20 2026-04-30 spaced out',
      );
    });

    test('rejects a completion date on an incomplete task', () {
      expect(
        () => formatTodoLine(
          completed: false,
          completionDate: DateTime(2026, 5, 20),
          description: 'foo',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a malformed priority', () {
      expect(
        () => formatTodoLine(
          completed: false,
          priority: 'a',
          description: 'foo',
        ),
        throwsArgumentError,
      );
      expect(
        () => formatTodoLine(
          completed: false,
          priority: 'AA',
          description: 'foo',
        ),
        throwsArgumentError,
      );
    });

    test('formats dates and stamps', () {
      expect(formatTodoDate(DateTime(2026, 1, 2)), '2026-01-02');
      expect(
        formatTodoStamp(DateTime(2026, 1, 2, 3, 4)),
        '2026-01-02T03:04',
      );
    });
  });

  group('withoutToken', () {
    test('removes every whole-word occurrence', () {
      expect(
        withoutToken('buy +groceries and +groceries @home', '+groceries'),
        'buy and @home',
      );
    });

    test('never eats longer tokens sharing the prefix', () {
      expect(
        withoutToken('big +projectX here', '+project'),
        'big +projectX here',
      );
    });

    test('sigils inside words are left alone', () {
      expect(withoutToken('mail a+b here', '+b'), 'mail a+b here');
    });

    test('unknown tags remove like any word', () {
      expect(withoutToken('water rec:+1d plants', 'rec:+1d'), 'water plants');
    });

    test('a bare sigil changes nothing', () {
      expect(withoutToken('buy milk', '+'), 'buy milk');
    });
  });
}
