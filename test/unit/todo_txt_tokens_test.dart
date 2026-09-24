// A task list's colours in the editor, read by the grammar the Todo tab
// parses todo.txt with.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/todo/todo_txt_tokens.dart';

List<String> _runs(String line) => [
  for (final token in todoTxtTokens(line))
    '${token.kind.name} ${line.substring(token.start, token.end)}',
];

void main() {
  test('the files coloured as task lists', () {
    expect(isTodoTxtFile('todo.txt'), isTrue);
    expect(isTodoTxtFile('Done.TXT'), isTrue);
    expect(isTodoTxtFile('todo.md'), isFalse);
    expect(isTodoTxtFile('my todo.txt'), isFalse);
  });

  test('a task: priority, date, projects, contexts, tags, key:value', () {
    expect(
      _runs(
        '(A) 2026-09-24 Call +Home @phone about #bills due:2026-09-30 '
        'rem:2026-09-29T09:00',
      ),
      [
        'todoPriority (A)',
        'todoDate 2026-09-24',
        'todoProject +Home',
        'todoContext @phone',
        'tag #bills',
        'todoKeyValue due:2026-09-30',
        'todoKeyValue rem:2026-09-29T09:00',
      ],
    );
  });

  test('a completed task is one run, the whole line', () {
    const line = 'x 2026-09-24 2026-09-20 Paid +Home';
    expect(todoTxtTokens(line), [
      const Token(TokenKind.todoDone, 0, line.length),
    ]);
  });

  test('what the parser reads as text stays text', () {
    // A sigil glued to a word, a priority not at the head, a lone sigil,
    // an uppercase X: all description text to the Todo tab.
    expect(_runs('Buy a+b C# (B) + @ X done'), isEmpty);
    // A URL is a `key:value` to the parser (`https` and the rest), and
    // coloured as one.
    expect(_runs('Read https://example.com'), [
      'todoKeyValue https://example.com',
    ]);
    expect(_runs('  (C) indented'), ['todoPriority (C)']);
    expect(_runs(''), isEmpty);
  });

  test('a date is a date only at the head', () {
    expect(_runs('Pay 2026-09-24'), isEmpty);
    expect(_runs('2026-09-24 Pay'), ['todoDate 2026-09-24']);
  });
}
