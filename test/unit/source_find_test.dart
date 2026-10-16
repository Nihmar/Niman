// Find & replace over the unified surface's buffer (#245, phase 3): what the
// bar finds, where it lands, and what Replace and Replace all leave behind.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// A find over [text], with the caret at [caret], and no view: the controller
/// edits the buffer itself.
(SourceFindController, MarkdownSurfaceController) _find(
  String text, {
  int caret = 0,
}) {
  final surface = MarkdownSurfaceController(
    SourceBuffer.fromText(text),
    caret: caret,
  );
  final find = SourceFindController(surface: () => surface);
  addTearDown(find.dispose);
  return (find, surface);
}

void _type(SourceFindController find, String query) {
  find.findInput.text = query;
  find.search();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('finds every match, whatever the case, and selects the first', () {
    final (find, surface) = _find('Gatto, gatto e GATTO.');
    find.open();
    _type(find, 'gatto');
    expect(find.matchCount, 3);
    expect(find.matchIndex, 0);
    expect(surface.selection, const SelectionModel(anchor: 0, extent: 5));
  });

  test('the first match is the one at or after the caret', () {
    final (find, surface) = _find('uno due uno due uno', caret: 5);
    find.open();
    _type(find, 'uno');
    expect(find.matchIndex, 1);
    expect(surface.selection.start, 8);
  });

  test('the case button narrows it', () {
    final (find, _) = _find('Gatto, gatto e GATTO.');
    find.open();
    _type(find, 'gatto');
    find.toggleCaseSensitive();
    expect(find.matchCount, 1);
  });

  test('next and previous wrap around', () {
    final (find, surface) = _find('a b a b a');
    find.open();
    _type(find, 'a');
    find
      ..nextMatch()
      ..nextMatch();
    expect(surface.selection.start, 8);
    find.nextMatch();
    expect(surface.selection.start, 0, reason: 'past the last is the first');
    find.previousMatch();
    expect(surface.selection.start, 8, reason: 'before the first is the last');
  });

  test('Replace takes the current match and goes to the next', () {
    final (find, surface) = _find('cat cat cat');
    find
      ..open()
      ..replaceInput.text = 'cats';
    _type(find, 'cat');
    find.replaceMatch();
    expect(surface.buffer.text, 'cats cat cat');
    // Not the "cat" inside what was just put in.
    expect(surface.selection, const SelectionModel(anchor: 5, extent: 8));
    expect(find.matchCount, 3);
  });

  test('Replace all is one edit, and one undo puts it all back', () {
    final (find, surface) = _find('x-1\nx-2\nx-3\n');
    find
      ..open()
      ..replaceInput.text = 'y';
    _type(find, 'x');
    find.replaceAllMatches();
    expect(surface.buffer.text, 'y-1\ny-2\ny-3\n');
    expect(find.matchCount, 0);
    surface.history.undo(surface.buffer);
    expect(surface.buffer.text, 'x-1\nx-2\nx-3\n');
    expect(surface.history.canUndo, isFalse);
  });

  group('a long note is not joined, nor searched again whole (#1047)', () {
    String note(int lines) =>
        [for (var i = 0; i < lines; i++) 'line $i has a cat and more words']
            .join('\n');

    test('Replace all keeps the caret where the writer had it', () {
      final text = note(3000);
      final caret = text.indexOf('line 1500');
      // The match the search selects at the caret: where the writer is.
      final here = text.indexOf('cat', caret) + 3;
      final (find, surface) = _find(text, caret: caret);
      find
        ..open()
        ..replaceInput.text = 'dog'
        ..findInput.text = 'cat'
        ..search()
        ..replaceAllMatches();
      expect(surface.buffer.text, text.replaceAll('cat', 'dog'));
      expect(surface.selection.start, here, reason: 'dog is as long as cat');
      final (second, other) = _find(text, caret: caret);
      second
        ..open()
        ..replaceInput.text = 'a longer word'
        ..findInput.text = 'cat'
        ..search()
        ..replaceAllMatches();
      expect(
        other.selection.start,
        here + 1501 * ('a longer word'.length - 3),
        reason: 'moved by the matches before it, not sent to the first one',
      );
    });

    test('Replace all keeps only the lines that changed in the history', () {
      final text = [
        for (var i = 0; i < 4000; i++)
          'line $i has a ${i % 100 == 0 ? 'cat' : 'dog'} and more words',
      ].join('\n');
      final (find, surface) = _find(text);
      find
        ..open()
        ..replaceInput.text = 'owl'
        ..findInput.text = 'cat'
        ..search()
        ..replaceAllMatches();
      expect(surface.history.length, 1);
      // 40 changed lines, both sides: not the span, twice.
      expect(surface.history.units, lessThan(40 * 2 * 45));
      surface.history.undo(surface.buffer);
      expect(surface.buffer.text, text);
      surface.history.redo(surface.buffer);
      expect(surface.buffer.text, text.replaceAll('cat', 'owl'));
    });

    test('Replace reads its own line again, not the note', () {
      final text = note(20000);
      final (find, surface) = _find(text);
      find
        ..open()
        ..replaceInput.text = 'dog'
        ..findInput.text = 'cat'
        ..search();
      expect(find.matchCount, 20000);
      final read = find.linesRead;
      find.replaceMatch();
      expect(
        find.linesRead - read,
        lessThan(5),
        reason: 'the matches after it were moved, not found again',
      );
      expect(find.matchCount, 19999);
      expect(find.matchIndex, 0);
      expect(surface.selection.start, text.indexOf('cat', 14));
      // What it kept is what a search from scratch finds.
      final kept = [for (var i = 0; i < find.matchCount; i++) i].length;
      final (fresh, _) = _find(surface.buffer.text);
      fresh.findInput.text = 'cat';
      fresh.search();
      expect(find.matchCount, fresh.matchCount);
      expect(kept, fresh.matchCount);
    });

    test('a replacement that makes a match with its neighbours is found', () {
      final (find, surface) = _find('ca cat\nca');
      find
        ..open()
        ..replaceInput.text = ''
        ..findInput.text = 'cat'
        ..search()
        ..replaceMatch();
      // `ca ` + `` leaves `ca ` : no new match, but 'cat' typed around one:
      expect(surface.buffer.text, 'ca \nca');
      expect(find.matchCount, 0);
    });

    test('a long note is searched in slices, and its edit stales a scan', () {
      final text = note(60000);
      expect(text.length, greaterThan(1 << 20));
      final (find, _) = _find(text);
      find.findInput.text = 'cat';
      find.open();
      expect(find.matchCount, 0, reason: 'nothing yet: the slices come after');
      fakeAsync((async) {
        find.search();
        async.elapse(const Duration(milliseconds: 250));
      });
      expect(find.slices, greaterThan(1));
      expect(find.matchCount, 60000);
    });
  });

  test('an edit is followed a moment later, without moving the caret', () {
    fakeAsync((async) {
      final surface = MarkdownSurfaceController(SourceBuffer.fromText('ab ab'));
      final find = SourceFindController(surface: () => surface)..open();
      _type(find, 'ab');
      expect(find.matchCount, 2);
      surface
        ..placeCaret(0)
        ..replaceRange(5, 5, ' ab');
      find.noteEdited();
      expect(find.matchCount, 2, reason: 'not yet');
      async.elapse(const Duration(milliseconds: 300));
      expect(find.matchCount, 3);
      expect(surface.selection.isCollapsed, isTrue);
      find.dispose();
    });
  });

  test('a step on a note edited since the search finds it again first', () {
    final (find, surface) = _find('ab ab');
    find.open();
    _type(find, 'ab');
    surface.replaceRange(0, 0, 'ab ');
    find.nextMatch();
    // Three matches now; the step went from a fresh search, not stale
    // offsets.
    expect(find.matchCount, 3);
    expect(
      surface.buffer.substring(surface.selection.start, surface.selection.end),
      'ab',
    );
  });

  test('within gives a line its matches, clipped and local', () {
    final (find, _) = _find('foo bar\nbar foo\n');
    find.open();
    _type(find, 'foo');
    expect(find.within(0, 7).toList(), <(int, int, bool)>[(0, 3, true)]);
    expect(find.within(8, 15).toList(), <(int, int, bool)>[(4, 7, false)]);
    expect(find.within(1, 7).toList(), <(int, int, bool)>[(0, 2, true)]);
  });

  test('closing drops the matches', () {
    final (find, _) = _find('foo foo');
    find.open();
    _type(find, 'foo');
    find.close();
    expect(find.matchCount, 0);
    expect(find.within(0, 7), isEmpty);
    expect(find.visible, isFalse);
  });

  test('opening on a selection searches for it', () {
    final (find, surface) = _find('uno due tre due');
    surface.select(const SelectionModel(anchor: 4, extent: 7));
    find.open();
    expect(find.findInput.text, 'due');
    expect(find.matchCount, 2);
  });
}
