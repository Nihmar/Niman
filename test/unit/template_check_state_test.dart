// The template checker's state for the live surface (T-TPL-09): the note is
// read once the writer pauses rather than on the keystroke, and the problems
// it finds are what the editor marks and the status row counts.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/check_state.dart';

/// A template with one mistake the checker can fix and one it cannot: an
/// unknown placeholder, and a `pad:` whose width is not a number.
const String _source = '{{titlex}}\n\n{{title|pad:wide}}\n';

/// A state that has read [source] already, the way one is handed to the
/// surface when a template opens.
TemplateCheck _checked(String source) => TemplateCheck()..run(source);

void main() {
  test('nothing is read on a keystroke, and a burst is one pass', () {
    fakeAsync((async) {
      var reads = 0;
      String read() {
        reads++;
        return _source;
      }

      final check = TemplateCheck();
      expect(check.problemCount, 0, reason: 'nothing is known yet');

      // Two keystrokes in a row: neither of them reads the note.
      for (var key = 0; key < 2; key++) {
        check.schedule(read);
      }
      async.elapse(const Duration(milliseconds: 249));
      expect(reads, 0, reason: 'the writer has not paused');

      check.schedule(read);
      async.elapse(const Duration(milliseconds: 249));
      expect(reads, 0, reason: 'the last keystroke restarted the pause');

      async.elapse(const Duration(milliseconds: 1));
      expect(reads, 1, reason: 'three keystrokes, one pass over the note');
      expect(check.problemCount, 2);
      expect(check.hasProblems, isTrue);
      check.dispose();
    });
  });

  test('a note that has not changed is not checked again', () {
    var notifications = 0;
    final check = _checked(_source);
    expect(check.problemCount, 2);

    check.addListener(() => notifications++);
    expect(notifications, 0, reason: 'the reader was not there for that pass');

    check.run(_source);
    expect(notifications, 0, reason: 'the same text, the same problems');
    check.dispose();
  });

  test('a clean template reports nothing at all', () {
    var notifications = 0;
    final check = _checked('{{title}} on {{date:YYYY-MM-DD}}\n');
    expect(check.errors, isEmpty);
    expect(check.problemCount, 0);
    expect(check.hasProblems, isFalse);

    check.addListener(() => notifications++);
    expect(notifications, 0);
    // The same state, handed a template that is broken: the count follows the
    // note it was last given, and that is what the surface repaints for.
    check.run(_source);
    expect(notifications, 1);
    expect(check.problemCount, 2);
    check.dispose();
  });

  test('a window of the note gets its own problems, at its own offsets', () {
    final check = _checked('one\n{{titlex}} here\n');
    expect(check.problemCount, 1);

    // The second line: `{{titlex}}` starts at 4 and is ten characters long.
    final problems = check.inRange(4, 4 + '{{titlex}} here'.length);
    expect(problems, hasLength(1));
    final (range, error) = problems.single;
    expect(range.start, 0, reason: 'local to the line, not to the note');
    expect(range.end, 10);
    expect(error.suggestion, '{{title}}');
    expect(error.parameters, <String>['titlex']);

    // A window that holds none of it: the first line.
    expect(check.inRange(0, 3), isEmpty);
    check.dispose();
  });

  test('the caret is answered for the span it is in, and the one it ends', () {
    final check = _checked('{{titlex}} tail\n');

    expect(check.at(0)?.suggestion, '{{title}}', reason: 'inside the span');
    expect(check.at(9)?.suggestion, '{{title}}', reason: 'its last character');
    expect(
      check.at(10)?.suggestion,
      '{{title}}',
      reason: 'where the caret rests after the placeholder is typed',
    );
    expect(check.at(11), isNull, reason: 'past the span, on the next word');
    check.dispose();
  });

  test('a span the checker cannot fix is reported with no suggestion', () {
    final check = _checked('{{title|pad:wide}}\n');
    expect(check.problemCount, 1, reason: 'a width only the author knows');

    final error = check.at(2);
    expect(error, isNotNull);
    expect(error?.suggestion, isNull, reason: 'nothing safe to write');
    check.dispose();
  });

  test('disposing cancels the pause', () {
    fakeAsync((async) {
      var reads = 0;
      TemplateCheck()
        ..schedule(() {
          reads++;
          return _source;
        })
        ..dispose();

      async.elapse(const Duration(seconds: 5));
      expect(
        reads,
        0,
        reason: 'the note is never read for a state that is gone',
      );
    });
  });
}
