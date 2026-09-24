// Where the caret goes when a key is pressed (#245, phase 3): the logical
// motions, which are pure functions of the note and therefore testable here —
// no device, no widget, no keyboard.
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
