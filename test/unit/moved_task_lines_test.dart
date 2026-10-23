// Move to tasks (#1152): the lines a batch of checkbox items becomes.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/moved_task_lines.dart';

void main() {
  final today = DateTime(2026, 10, 23, 14, 30);

  test('an open item is a task with the creation date and the link', () {
    final lines = movedTaskLines(
      items: [(text: 'Replace the **bathroom** tap', checked: false)],
      link: '[[Repairs]]',
      today: today,
    );
    expect(lines.todo, ['2026-10-23 Replace the **bathroom** tap [[Repairs]]']);
    expect(lines.done, isEmpty);
  });

  test('a ticked item is completed today, created today', () {
    final lines = movedTaskLines(
      items: [(text: 'Fix the light', checked: true)],
      link: '[[Repairs]]',
      today: today,
    );
    expect(lines.todo, isEmpty);
    expect(lines.done, ['x 2026-10-23 2026-10-23 Fix the light [[Repairs]]']);
  });

  test('the items keep their order within each file', () {
    final lines = movedTaskLines(
      items: [
        (text: 'one', checked: false),
        (text: 'two', checked: true),
        (text: 'three', checked: false),
      ],
      link: '[[N]]',
      today: today,
    );
    expect(lines.todo, ['2026-10-23 one [[N]]', '2026-10-23 three [[N]]']);
    expect(lines.done, ['x 2026-10-23 2026-10-23 two [[N]]']);
  });
}
