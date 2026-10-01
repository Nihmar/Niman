// Where the caret goes when a key is pressed (#245, phase 3): the logical
// motions, which are pure functions of the note and therefore testable here —
// no device, no widget, no keyboard.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The caret [at] over [text], moved by [motion].
int _moved(String text, int at, CaretMotion motion, {bool extend = false}) {
  final buffer = SourceBuffer.fromText(text);
  return moveCaret(
    SelectionModel.at(at),
    motion,
    buffer: buffer,
    extend: extend,
  ).extent;
}

void main() {
  test('a character at a time, over grapheme clusters', () {
    // An emoji is one press, not two: moving by code units would land inside
    // it.
    const text = 'a👨‍👩‍👧b';
    expect(_moved(text, 0, CaretMotion.characterRight), 'a'.length);
    expect(
      _moved(text, 'a'.length, CaretMotion.characterRight),
      'a👨‍👩‍👧'.length,
      reason: 'the whole family is one cluster',
    );
    expect(
      _moved(text, text.length, CaretMotion.characterLeft),
      'a👨‍👩‍👧'.length,
    );
  });

  test('the ends are walls, not errors', () {
    expect(_moved('ciao', 0, CaretMotion.characterLeft), 0);
    expect(_moved('ciao', 4, CaretMotion.characterRight), 4);
    expect(_moved('', 0, CaretMotion.wordLeft), 0);
    expect(_moved('', 0, CaretMotion.lineEnd), 0);
  });

  test('a word at a time, the way editors do it', () {
    const text = 'due parole, snake_case_name fine';
    // From the end of `parole`: back over the space, onto the word's start.
    expect(_moved(text, 10, CaretMotion.wordLeft), 4);
    // From the start of `parole`: forward to the end of the word, not its
    // start.
    expect(_moved(text, 4, CaretMotion.wordRight), 10);
    // Punctuation is skipped rather than landed on, and `_` is a word
    // character.
    expect(_moved(text, 11, CaretMotion.wordRight), 27);
    // `snake_case_name` starts at 12: the comma and the space are skipped, and
    // the underscores keep the word together.
    expect(_moved(text, 27, CaretMotion.wordLeft), 12);
    expect(_moved(text, text.length, CaretMotion.wordLeft), 28);
  });

  test('at the head of a line, Ctrl+Left is the line above, its end', () {
    // A caret at the head of a line — past the indentation, the quote marks and
    // a list item's marker and box — is where `Ctrl+←` leaves the line for the
    // one above, rather than skipping back over the marker, the spaces and the
    // line above's closing punctuation into its last word (#528).
    const above = 'lo deve sapere il chiamante (davvero)';
    const end = above.length;
    const head = end + 1;
    const text = '$above\n  - [ ] La funzionalita';
    final body = text.indexOf('La funzionalita');
    for (final at in <int>[
      head, // the line's own start
      head + 2, // among the leading spaces
      head + 5, // inside the marker, past the `[`
      body, // the head of the text, after the marker and its box
    ]) {
      expect(
        _moved(text, at, CaretMotion.wordLeft),
        end,
        reason: 'from $at, the head of the line',
      );
    }
    // Mid-word it is still the word motion, and it never reaches the line
    // above.
    final inside = text.indexOf('funzionalita') + 4;
    expect(
      _moved(text, inside, CaretMotion.wordLeft),
      text.indexOf('funzionalita'),
    );
  });

  test('the head of a line is its head whatever its shape', () {
    // A plain line, an indented one, an ordered item, a checked task and a
    // quoted one: a line's text starts past all of it, and `Ctrl+←` there
    // answers the line above.
    const above = 'riga precedente';
    const end = above.length;
    for (final line in <String>[
      'seconda',
      '    seconda',
      '1. seconda',
      '10) seconda',
      '- [x] seconda',
      '> seconda',
      '> > seconda',
    ]) {
      final text = '$above\n$line';
      expect(
        _moved(text, text.length - 'seconda'.length, CaretMotion.wordLeft),
        end,
        reason: 'the head of `$line`',
      );
    }
    // The first line has nothing above it: the motion is the wall at 0.
    expect(_moved('solo', 0, CaretMotion.wordLeft), 0);
    // A blank line answers the end of the line above, and so on down.
    const blank = 'prima\n\nseconda';
    expect(_moved(blank, blank.indexOf('seconda'), CaretMotion.wordLeft), 6);
    expect(_moved(blank, 6, CaretMotion.wordLeft), 5);
  });

  test('at the end of a line, Ctrl+Right is the line below, its head', () {
    // The twin of the head rule: the caret at the end of a line's text goes to
    // the head of the line below, not to the end of its first word (#528).
    const above = 'lo deve sapere il chiamante)';
    const end = above.length;
    const text = '$above\n  - [ ] La funzionalita';
    final head = text.indexOf('La funzionalita');
    expect(_moved(text, end, CaretMotion.wordRight), head);
    // Mid-word it is still the word motion.
    expect(_moved(text, head, CaretMotion.wordRight), head + 'La'.length);
    // The head and the end are each other's inverse.
    expect(_moved(text, head, CaretMotion.wordLeft), end);
    // The last line has nothing below it: the motion is the wall at the end.
    expect(_moved(above, end, CaretMotion.wordRight), end);
  });

  test(
    'the end of a line answers the head of the next, whatever its shape',
    () {
      const first = 'riga';
      for (final line in <String>[
        'seconda',
        '    seconda',
        '1. seconda',
        '10) seconda',
        '- [x] seconda',
        '> seconda',
        '> > seconda',
      ]) {
        final text = '$first\n$line';
        expect(
          _moved(text, first.length, CaretMotion.wordRight),
          text.length - 'seconda'.length,
          reason: 'the end of `$first` into `$line`',
        );
      }
    },
  );

  test('shift extends the line motion the same way', () {
    const text = 'il chiamante\n- [ ] La';
    final buffer = SourceBuffer.fromText(text);
    final selected = moveCaret(
      const SelectionModel.at(19),
      CaretMotion.wordLeft,
      buffer: buffer,
      extend: true,
    );
    expect(selected.anchor, 19);
    expect(selected.extent, 'il chiamante'.length);
  });

  test('the line motions respect the note, not the screen', () {
    const text = 'prima riga\n    indentata\nultima';
    expect(_moved(text, 5, CaretMotion.lineEnd), 10);
    expect(_moved(text, 20, CaretMotion.lineStart), 11);
    expect(
      _moved(text, 20, CaretMotion.lineTextStart),
      15,
      reason: 'past the four spaces the line is indented by',
    );
    expect(_moved(text, 5, CaretMotion.documentStart), 0);
    expect(_moved(text, 5, CaretMotion.documentEnd), text.length);
    // The last line has no terminator, and lineEnd knows it.
    expect(_moved(text, text.length, CaretMotion.lineEnd), text.length);
  });

  test('a double click selects the word under the offset', () {
    const text = 'due parole, snake_case_name fine';
    expect(wordRangeAt(text, 5), (4, 10), reason: 'inside `parole`');
    expect(wordRangeAt(text, 4), (4, 10), reason: 'at its first letter');
    expect(wordRangeAt(text, 9), (4, 10), reason: 'at its last letter');
    expect(wordRangeAt(text, 13), (
      12,
      27,
    ), reason: 'an underscore is a word character, so the name selects whole');
    expect(
      wordRangeAt(text, 10),
      (10, 11),
      reason:
          'a comma is not a word: it selects itself, not the nothing after it',
    );
    expect(wordRangeAt(text, text.length), (28, 32), reason: 'the last word');
    expect(wordRangeAt('', 0), (
      0,
      1,
    ), reason: 'an empty note selects nothing much');
  });

  test('a selection never cuts a grapheme cluster in half', () {
    // The range is what the selection, the clipboard and the platform
    // `TextSelection` carry, so half of a surrogate pair is not a range a copy
    // can survive a UTF-8 round trip (#376).
    const pair = 'a🙂b';
    expect(wordRangeAt(pair, 1), (1, 3), reason: "the pair's first unit");
    expect(wordRangeAt(pair, 2), (1, 3), reason: "the pair's second unit");
    expect(wordRangeAt(pair, 0), (0, 1), reason: 'the word before it');
    expect(wordRangeAt(pair, 3), (3, 4), reason: 'the word after it');
    expect(wordRangeAt(pair, pair.length), (
      3,
      4,
    ), reason: 'past the end, the word the caret just finished');
    expect(wordRangeAt('a🙂', 3), (
      1,
      3,
    ), reason: 'the trailing emoji, not the low half of it');
    // A letter that is itself astral is one code point and one cluster, and a
    // word character like any other.
    expect(wordRangeAt('𐐷b', 0), (
      0,
      3,
    ), reason: 'a Deseret letter and the `b` after it are one word');
    // An accent that trails the last letter of a word sits in that letter's
    // cluster, so the range takes the cluster whole rather than stopping
    // between the two.
    expect(wordRangeAt('cafe\u0301', 1), (
      0,
      5,
    ), reason: 'the combined `é` the word ends in');
    // The word selection and the character motions agree on the same offset:
    // the range's ends are where an arrow key press lands, from either side of
    // the pair. #376
    expect(_moved(pair, 2, CaretMotion.characterLeft), wordRangeAt(pair, 2).$1);
    expect(
      _moved(pair, 1, CaretMotion.characterRight),
      wordRangeAt(pair, 1).$2,
    );
  });

  test('every answer of wordRangeAt lands between clusters', () {
    // Words, a pair, a ZWJ family, an astral letter and an accent that follows
    // its letter: from any offset in the line, both ends of the range stand on
    // a cluster boundary and neither is inside a cluster.
    const text = 'due cafe\u0301🙂 👨‍👩‍👧𐐷_x fine';
    final boundaries = <int>{0};
    var at = 0;
    for (final unit in text.characters) {
      at += unit.length;
      boundaries.add(at);
    }
    for (var offset = 0; offset <= text.length; offset++) {
      final (start, end) = wordRangeAt(text, offset);
      expect(start, lessThanOrEqualTo(end), reason: 'at $offset');
      expect(boundaries, contains(start), reason: 'start at $offset');
      expect(boundaries, contains(end), reason: 'end at $offset');
    }
  });

  test("the reveal's word is the run of non-whitespace, markers and all", () {
    // Deliberately not `wordRangeAt`: the run is what the per-word reveal
    // compares a marker against, and it has to *contain* the syntax that
    // delimits the word — otherwise the `**` a writer is editing stays hidden
    // while the caret is inside the word they mark.
    expect(runAround('a **bold** b', 5), (2, 10), reason: 'inside `bold`');
    expect(runAround('a **bold** b', 4), (
      2,
      10,
    ), reason: 'at the first letter, past the markers');
    expect(runAround('a **bold** b', 8), (
      2,
      10,
    ), reason: 'at the closing pair, which is part of the run');
    expect(runAround('# Titolo', 3), (2, 8), reason: 'the title, `#` or not');
    expect(runAround('due parole', 2), (
      0,
      3,
    ), reason: 'the run before the space ends at it');
    expect(runAround('due parole', 3), (
      3,
      4,
    ), reason: 'a space itself is the one-character run to be in');
    expect(runAround('due parole', 10), (
      4,
      10,
    ), reason: 'at the end, the run the caret just finished');
    expect(runAround('', 0), (0, 0), reason: 'an empty line has no run');
    expect(runAround('  ', 1), (
      1,
      2,
    ), reason: 'whitespace is not a word, but it is a range');
  });

  test('extend holds the anchor, which is what shift is', () {
    const text = 'una riga di testo';
    final buffer = SourceBuffer.fromText(text);
    final selected = moveCaret(
      const SelectionModel.at(4),
      CaretMotion.wordRight,
      buffer: buffer,
      extend: true,
    );
    expect(selected.anchor, 4);
    expect(selected.extent, 8, reason: 'the end of `riga`, before the space');
    expect(selected.isCollapsed, isFalse);
    expect(selected.start, 4);
    expect(selected.end, 8);
  });

  test('a motion from a selection moves its moving end', () {
    const text = 'una riga di testo';
    final buffer = SourceBuffer.fromText(text);
    final selected = moveCaret(
      const SelectionModel(anchor: 4, extent: 9),
      CaretMotion.characterLeft,
      buffer: buffer,
    );
    expect(
      selected.extent,
      8,
      reason: 'the caret moves and the selection collapses to it',
    );
    expect(selected.isCollapsed, isTrue);
  });
}
