// #700: the notes shown, to go back and forward through.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/workspace/note_history.dart';

void main() {
  NoteHistory through(List<String> paths) {
    final history = NoteHistory();
    paths.forEach(history.shown);
    return history;
  }

  test('goes back and forward through the notes shown', () {
    final history = through(['a.md', 'b.md', 'c.md']);
    expect(history.back(), 'b.md');
    expect(history.back(), 'a.md');
    expect(history.back(), isNull, reason: 'nothing before the first');
    expect(history.current, 'a.md');
    expect(history.forward(), 'b.md');
    expect(history.forward(), 'c.md');
    expect(history.forward(), isNull);
  });

  test('the note a step shows, shown, is no new step', () {
    final history = through(['a.md', 'b.md'])
      ..back()
      ..shown('a.md');
    expect(history.next, 'b.md', reason: 'what is ahead stays');
  });

  test('a note shown after going back drops what was ahead', () {
    final history = through(['a.md', 'b.md', 'c.md'])
      ..back()
      ..back()
      ..shown('d.md');
    expect(history.next, isNull);
    expect(history.back(), 'a.md');
  });

  test('showing the current note again is no step', () {
    final history = through(['a.md', 'a.md', 'b.md', 'b.md']);
    expect(history.back(), 'a.md');
    expect(history.back(), isNull);
  });

  test('a deleted note, or a folder, leaves it, and no step to the same '
      'note twice is left behind', () {
    final history = through(['a.md', 'x/1.md', 'a.md', 'x/2.md', 'b.md'])
      ..forget('x');
    expect(history.back(), 'a.md');
    expect(history.back(), isNull, reason: 'a, a collapsed to one step');
  });

  test("a rename or a move is followed, a folder's notes with it", () {
    final history = through(['a.md', 'x/1.md', 'b.md'])
      ..moved('x', 'y')
      ..moved('a.md', 'z.md');
    expect(history.back(), 'y/1.md');
    expect(history.back(), 'z.md');
  });

  test('keeps at most its capacity behind', () {
    final history = through([
      for (var i = 0; i <= NoteHistory.capacity + 10; i++) '$i.md',
    ]);
    var steps = 0;
    while (history.back() != null) {
      steps++;
    }
    expect(steps, NoteHistory.capacity);
  });
}
