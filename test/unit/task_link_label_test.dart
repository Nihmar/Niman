import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/task_link_label.dart';

void main() {
  group('taskPlainText', () {
    test('a wikilink reads as the note it names, never as [[…]]', () {
      expect(
        taskPlainText('Call the plumber [[House/Repairs]] due:2026-10-24'),
        'Call the plumber Repairs',
      );
    });

    test('a heading or a block follows the name, as on a chip', () {
      expect(
        taskPlainText('Order [[Repairs#Boiler]] and [[Repairs#^b7]]'),
        'Order Repairs › Boiler and Repairs › ^b7',
      );
    });

    test('an alias is shown as written, even one that reads like a tag', () {
      expect(
        taskPlainText('Pay [[Budget 2026|the electrician +work]] +home'),
        'Pay the electrician +work',
      );
    });

    test('a Markdown link reads as its text, else its note', () {
      expect(
        taskPlainText('See [the list](House/Repairs.md) and [](Ideas.md)'),
        'See the list and Ideas',
      );
    });

    test(
      'with markers the projects and contexts stay, the link still reads',
      () {
        expect(
          taskPlainText(
            '(A) Call [[Repairs]] +house @phone due:2026-10-24',
            markers: true,
          ),
          '(A) Call Repairs +house @phone',
        );
      },
    );

    test('a line with no link is the display text it was', () {
      expect(taskPlainText('Book the dentist +health'), 'Book the dentist');
    });

    test('a web link is left alone', () {
      expect(
        taskPlainText('Read [docs](https://example.org)'),
        'Read [docs](https://example.org)',
      );
    });
  });
}
