// What the find bar acts on (#1330, #1331, #1357, #1370): the matches of the
// query that is in the bar now, all of them for Replace all, and a note opened
// from a search result read a line at a time.
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// A find over [text], with no view: the controller edits the buffer itself.
(SourceFindController, MarkdownSurfaceController) _find(String text) {
  final surface = MarkdownSurfaceController(SourceBuffer.fromText(text));
  final find = SourceFindController(surface: () => surface);
  addTearDown(find.dispose);
  return (find, surface);
}

void _type(SourceFindController find, String query) {
  find.findInput.text = query;
  find.search();
}

/// A note past the megabyte from which the matches follow the query late.
String _long() =>
    [for (var i = 0; i < 60000; i++) 'foo line $i has a bar and more words']
        .join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("the matches are the query's that is in the bar (#1330)", () {
    test('Replace all right after the query changed acts on the new one', () {
      final text = _long();
      expect(text.length, greaterThan(1 << 20));
      final (find, surface) = _find(text);
      fakeAsync((async) {
        find
          ..open()
          ..replaceInput.text = 'BAZ';
        _type(find, 'foo');
        async.elapse(const Duration(milliseconds: 400));
        expect(find.matchCount, 60000);
        // The query is changed and Replace all is pressed at once.
        _type(find, 'bar');
        find.replaceAllMatches();
      });
      expect(surface.buffer.text, text.replaceAll('bar', 'BAZ'));
      expect(surface.buffer.text, contains('foo line 0'), reason: 'not foo');
    });

    test('Next and Replace go to the query now in the bar', () {
      final text = _long();
      final (find, surface) = _find(text);
      fakeAsync((async) {
        find.open();
        _type(find, 'foo');
        async.elapse(const Duration(milliseconds: 400));
        _type(find, 'bar');
        find.nextMatch();
        final selected = surface.buffer.substring(
          surface.selection.start,
          surface.selection.end,
        );
        expect(selected, 'bar');
        _type(find, 'more');
        find
          ..replaceInput.text = 'less'
          ..replaceMatch();
      });
      expect(surface.buffer.text, contains('and less words'));
      expect(surface.buffer.text, contains('foo line 0'));
    });

    test('the case button changes the matches Replace all acts on', () {
      final (find, surface) = _find('Cat cat CAT');
      find
        ..open()
        ..replaceInput.text = 'x';
      _type(find, 'cat');
      find
        ..toggleCaseSensitive()
        ..replaceAllMatches();
      expect(surface.buffer.text, 'Cat x CAT');
    });
  });

  group("Replace all is the whole note's (#1331)", () {
    test('past the 100 000 matches the bar lists, all of them', () {
      final text = List.filled(150000, 'x').join('\n');
      final (find, surface) = _find(text);
      find
        ..open()
        ..replaceInput.text = 'yy';
      _type(find, 'x');
      expect(find.matchCount, 100000, reason: 'the bar counts no further');
      find.replaceAllMatches();
      expect(surface.buffer.text, List.filled(150000, 'yy').join('\n'));
      expect(find.matchCount, 0);
      surface.undo();
      expect(surface.buffer.text, text);
      surface.redo();
      expect(surface.buffer.length, 150000 * 3 - 1);
    });

    test('in a note of mixed line endings they stay as they were', () {
      const text = 'a cat\r\nb cat\nc cat\r\n';
      final (find, surface) = _find(text);
      find
        ..open()
        ..replaceInput.text = 'dog';
      _type(find, 'cat');
      find.replaceAllMatches();
      expect(surface.buffer.text, 'a dog\r\nb dog\nc dog\r\n');
      surface.undo();
      expect(surface.buffer.text, text);
    });

    test('a replace that ignores case keeps what each match was', () {
      final (find, surface) = _find('Cat cat CAT');
      find
        ..open()
        ..replaceInput.text = 'x';
      _type(find, 'cat');
      find.replaceAllMatches();
      expect(surface.buffer.text, 'x x x');
      surface.undo();
      expect(surface.buffer.text, 'Cat cat CAT');
    });
  });

  group('the query is one line (#1370)', () {
    test('a query with a line break finds nothing', () {
      final (find, _) = _find('one\ntwo\none\ntwo');
      find.open();
      _type(find, 'one\ntwo');
      expect(find.matchCount, 0);
    });
  });

  group('a search result opens the note without joining it (#1357)', () {
    test('the first line that holds a term is the match', () {
      final (find, surface) = _find('alpha\nsome BETA here\nalpha beta\n');
      find.openFinding(<String>['beta', 'alpha']);
      // `alpha` is on the first line, `beta` only on the second.
      expect(find.findInput.text, 'alpha');
      expect(surface.selection, const SelectionModel(anchor: 0, extent: 5));
      final (other, second) = _find('x\nsome BETA here\nalpha beta\n');
      other.openFinding(<String>['alpha', 'beta']);
      expect(other.findInput.text, 'beta', reason: 'a line earlier');
      expect(second.selection.start, 7);
    });

    test('a note with none of the terms opens as it was', () {
      final (find, surface) = _find('nothing here');
      find.openFinding(<String>['absent']);
      expect(find.visible, isFalse);
      expect(surface.selection.isCollapsed, isTrue);
    });

    test('it agrees with a regex over the joined note', () {
      final random = Random(1357);
      const words = ['alpha', 'Beta', 'gamma', 'delta', 'x', 'é', 'ǅ'];
      for (var round = 0; round < 200; round++) {
        final text = [
          for (var line = 0; line < 1 + random.nextInt(8); line++)
            [
              for (var w = 0; w < random.nextInt(5); w++)
                words[random.nextInt(words.length)],
            ].join(' '),
        ].join('\n');
        final terms = <String>[
          for (var t = 0; t < 1 + random.nextInt(3); t++)
            words[random.nextInt(words.length)],
        ];
        String? best;
        var bestAt = -1;
        for (final term in terms) {
          final found = RegExp(
            RegExp.escape(term),
            caseSensitive: false,
            unicode: true,
          ).firstMatch(text);
          if (found != null && (bestAt < 0 || found.start < bestAt)) {
            best = term;
            bestAt = found.start;
          }
        }
        final (find, _) = _find(text);
        find.openFinding(terms);
        expect(
          find.visible ? find.findInput.text : null,
          best,
          reason: '"$text" for $terms',
        );
      }
    });
  });
}
