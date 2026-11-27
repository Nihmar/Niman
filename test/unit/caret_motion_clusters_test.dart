// The logical motions over text whose characters are more than one code unit
// (#1346, #1347): accents written as a letter and a mark, scripts whose
// syllables carry marks, letters outside the BMP, and clusters longer than
// any window.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

int _moved(String text, int at, CaretMotion motion) => moveCaret(
  SelectionModel.at(at),
  motion,
  buffer: SourceBuffer.fromText(text),
).extent;

void main() {
  // `cafés` written as `cafe` + a combining acute + `s`.
  const cafes = 'cafés au lait';

  test('a letter with its accent after it is a word character', () {
    expect(isWordChar('é'), isTrue);
    expect(wordRangeAt(cafes, 1), (0, 6), reason: 'the `s` is the word too');
    expect(wordRangeAt(cafes, 4), (0, 6), reason: 'on the accent itself');
    expect(_moved(cafes, 0, CaretMotion.wordRight), 6);
    expect(_moved(cafes, 6, CaretMotion.wordLeft), 0);
    expect(_moved(cafes, 3, CaretMotion.wordRight), 6);
    expect(_moved(cafes, 5, CaretMotion.wordLeft), 0);
  });

  test('Thai and Devanagari syllables are one word, the space ends it', () {
    const thai = 'สวัสดี ครับ';
    expect(_moved(thai, 0, CaretMotion.wordRight), 6);
    expect(_moved(thai, 6, CaretMotion.wordRight), thai.length);
    expect(_moved(thai, thai.length, CaretMotion.wordLeft), 7);
    expect(wordRangeAt(thai, 2), (0, 6));
    const hindi = 'हिन्दी भाषा';
    expect(_moved(hindi, 0, CaretMotion.wordRight), 6);
    expect(_moved(hindi, 6, CaretMotion.wordRight), hindi.length);
    expect(_moved(hindi, hindi.length, CaretMotion.wordLeft), 7);
    expect(wordRangeAt(hindi, 8), (7, hindi.length));
  });

  test('a letter outside the BMP is part of its word', () {
    const text = '\u{20BB7}野家 x';
    expect(wordRangeAt(text, 2), (0, 4));
    expect(wordRangeAt(text, 1), (0, 4), reason: 'from the middle of a pair');
    expect(_moved(text, 0, CaretMotion.wordRight), 4);
    expect(_moved(text, 4, CaretMotion.wordLeft), 0);
  });

  test('a cluster of any length is one press, either way', () {
    for (final marks in <int>[64, 65, 200, 1000]) {
      final text = 'a${'́' * marks}';
      expect(_moved(text, text.length, CaretMotion.characterLeft), 0);
      expect(_moved(text, 0, CaretMotion.characterRight), text.length);
      expect(_moved(text, text.length, CaretMotion.wordLeft), 0);
      expect(_moved(text, 0, CaretMotion.wordRight), text.length);
    }
  });

  test('a long chain of joined people is one press and does not throw', () {
    final chain = List.filled(40, '👨').join('‍');
    final text = 'x$chain';
    expect(_moved(text, text.length, CaretMotion.characterLeft), 1);
    expect(_moved(text, 1, CaretMotion.characterRight), text.length);
  });

  test('flags pair from the first indicator of a run', () {
    for (final flags in <int>[41, 42]) {
      final text = 'a${'🇮' * flags}';
      // An even run ends on a whole flag, an odd one on a lone indicator.
      expect(
        _moved(text, text.length, CaretMotion.characterLeft),
        text.length - (flags.isEven ? 4 : 2),
        reason: '$flags indicators',
      );
    }
  });

  test('from the middle of a pair the caret leaves it whole', () {
    const text = 'a😀b';
    expect(_moved(text, 2, CaretMotion.characterLeft), 1);
    expect(_moved(text, 2, CaretMotion.characterRight), 3);
  });

  test('a word a megabyte long is crossed in one press, quickly', () {
    final word = 'é' * 500000;
    final text = ' $word ';
    final timer = Stopwatch()..start();
    expect(_moved(text, 1, CaretMotion.wordRight), text.length - 1);
    expect(_moved(text, text.length - 1, CaretMotion.wordLeft), 1);
    timer.stop();
    // A backstop, not a design ceiling: a press that read two substrings per
    // code unit took seconds here.
    expect(timer.elapsedMilliseconds, lessThan(3000));
  });
}
