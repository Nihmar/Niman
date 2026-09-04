import 'dart:io';
import 'dart:math';

import 'package:copist/src/editor/line_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineBuffer.fromText', () {
    test('empty text is a single empty line', () {
      final buffer = LineBuffer.fromText('');
      expect(buffer.lineCount, 1);
      expect(buffer.textLength, 0);
      expect(buffer.text, '');
      expect(buffer.isEmpty, isTrue);
    });

    test('splits on newlines and round-trips the text', () {
      const source = 'a\nbb\n\nccc';
      final buffer = LineBuffer.fromText(source);
      expect(buffer.lineCount, 4);
      expect(buffer.text, source);
      expect(buffer.lineLength(0), 1);
      expect(buffer.lineLength(1), 2);
      expect(buffer.lineLength(2), 0);
      expect(buffer.lineLength(3), 3);
      expect(buffer.isEmpty, isFalse);
    });

    test('a trailing newline adds a final empty line', () {
      final buffer = LineBuffer.fromText('a\n');
      expect(buffer.lineCount, 2);
      expect(buffer.textLength, 2);
      expect(buffer.text, 'a\n');
    });

    test('counts UTF-16 code units, not code points', () {
      final buffer = LineBuffer.fromText('a😀');
      expect(buffer.lineLength(0), 3);
      expect(buffer.textLength, 3);
    });

    test(r'keeps \r as line content (CRLF is a load-path concern)', () {
      final buffer = LineBuffer.fromText('a\r\n');
      expect(buffer.lineCount, 2);
      expect(buffer.lineLength(0), 2);
    });
  });

  group('offsets', () {
    const source = 'ab\ncde\nf';

    test('offsetOf builds full-text offsets', () {
      final buffer = LineBuffer.fromText(source);
      expect(buffer.offsetOf(0, 0), 0);
      expect(buffer.offsetOf(1, 0), 3);
      expect(buffer.offsetOf(2, 0), 7);
      expect(buffer.textLength, 8);
    });

    test('locationOf and offsetOf round-trip every position', () {
      final buffer = LineBuffer.fromText(source);
      for (var offset = 0; offset <= buffer.textLength; offset++) {
        final (line, col) = buffer.locationOf(offset);
        expect(buffer.offsetOf(line, col), offset);
      }
    });

    test('textLength maps to the end of the last line', () {
      final buffer = LineBuffer.fromText(source);
      expect(buffer.locationOf(buffer.textLength), (2, 1));
    });

    test('locationOf rejects out-of-range offsets', () {
      final buffer = LineBuffer.fromText(source);
      expect(() => buffer.locationOf(-1), throwsArgumentError);
      expect(
        () => buffer.locationOf(buffer.textLength + 1),
        throwsArgumentError,
      );
    });
  });

  group('replace', () {
    test('inserts into the middle of a line', () {
      final buffer = LineBuffer.fromText('hello world');
      expect((buffer..replace(5, 6, '-')).text, 'hello-world');
    });

    test('a lone newline splits a line', () {
      final buffer = LineBuffer.fromText('abcd');
      expect((buffer..replace(2, 2, '\n')).lineCount, 2);
      expect(buffer.text, 'ab\ncd');
    });

    test('deleting across lines merges them', () {
      final buffer = LineBuffer.fromText('aa\nbb\ncc');
      expect((buffer..replace(2, 6, '')).text, 'aacc');
      expect(buffer.lineCount, 1);
    });

    test('a multi-line insertion re-splits the region', () {
      final buffer = LineBuffer.fromText('a b c');
      expect((buffer..replace(1, 3, 'X\nY')).text, 'aX\nY c');
    });

    test('replaces the whole buffer', () {
      final buffer = LineBuffer.fromText('old\nold');
      final length = buffer.textLength;
      expect((buffer..replace(0, length, 'new')).text, 'new');
    });

    test('appends at the end and inserts at the start', () {
      final buffer = LineBuffer.fromText('b');
      expect(
        (buffer
              ..replace(0, 0, 'a')
              ..replace(buffer.textLength, buffer.textLength, 'c'))
            .text,
        'abc',
      );
    });

    test('a no-op replace changes nothing', () {
      final buffer = LineBuffer.fromText('same');
      expect((buffer..replace(1, 1, '')).text, 'same');
    });

    test('rejects out-of-range edits', () {
      final buffer = LineBuffer.fromText('ab');
      expect(() => buffer.replace(-1, 1, 'x'), throwsArgumentError);
      expect(() => buffer.replace(1, 0, 'x'), throwsArgumentError);
      expect(() => buffer.replace(1, 3, 'x'), throwsArgumentError);
    });
  });

  group('insert and delete', () {
    test('insert at both ends', () {
      final buffer = LineBuffer.fromText('bc');
      expect(
        (buffer
              ..insert(0, 'a')
              ..insert(buffer.textLength, 'd'))
            .text,
        'abcd',
      );
    });

    test('delete is replace with the empty string', () {
      final buffer = LineBuffer.fromText('abcdef');
      expect((buffer..delete(2, 4)).text, 'abef');
    });
  });

  group('randomized edits (buffer == reference)', () {
    test('500 random edits match a string reference', () {
      final rand = Random(0xC0FFEE);
      final buffer = LineBuffer.fromText('one\ntwo\nthree');
      var reference = 'one\ntwo\nthree';
      for (var i = 0; i < 500; i++) {
        final length = reference.length;
        final start = rand.nextInt(length + 1);
        final end = start + rand.nextInt(length - start + 1);
        final insertion = _randomText(rand, 6);
        final head = reference.substring(0, start);
        final tail = reference.substring(end);
        buffer.replace(start, end, insertion);
        reference = '$head$insertion$tail';
        expect(buffer.textLength, reference.length);
        if (i % 100 == 0) {
          expect(buffer.text, reference);
        }
      }
      expect(buffer.text, reference);
    });

    test('edits on the 200 KB fixture match a string reference', () {
      final text = File('test/fixtures/markdown/fixture-200kb.md')
          .readAsStringSync();
      final buffer = LineBuffer.fromText(text);
      final rand = Random(7);
      var reference = text;
      final clock = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        final start = rand.nextInt(reference.length);
        final head = reference.substring(0, start);
        final tail = reference.substring(start);
        buffer.insert(start, 'x');
        reference = '${head}x$tail';
      }
      final editsMs = clock.elapsedMilliseconds;
      expect(buffer.text, reference);
      expect(editsMs, lessThan(1000));
    });
  });

  group('scale', () {
    test('builds a 1 MB buffer quickly', () {
      final text = File('test/fixtures/markdown/fixture-1mb.md')
          .readAsStringSync();
      final clock = Stopwatch()..start();
      final buffer = LineBuffer.fromText(text);
      final ms = clock.elapsedMilliseconds;
      expect(buffer.textLength, text.length);
      expect(ms, lessThan(1000));
    });
  });

  group('substring', () {
    test('extracts a single-line range', () {
      final buffer = LineBuffer.fromText('hello world');
      expect(buffer.substring(0, 5), 'hello');
      expect(buffer.substring(6, 11), 'world');
    });

    test('joins with newlines across lines', () {
      final buffer = LineBuffer.fromText('one\ntwo\nthree');
      expect(buffer.substring(2, 10), 'e\ntwo\nth');
      expect(buffer.substring(0, buffer.textLength), 'one\ntwo\nthree');
    });

    test('is empty when start == end', () {
      final buffer = LineBuffer.fromText('hello');
      expect(buffer.substring(2, 2), '');
    });

    test('matches String.substring over random ranges', () {
      final rand = Random(0x5E);
      final text = _randomText(rand, 2000);
      final buffer = LineBuffer.fromText(text);
      for (var i = 0; i < 200; i++) {
        final a = rand.nextInt(text.length + 1);
        final b = a + rand.nextInt(text.length + 1 - a);
        expect(buffer.substring(a, b), text.substring(a, b));
      }
    });
  });
}

String _randomText(Random rand, int maxUnits) {
  const alphabet = ['a', 'b', 'c', ' ', '#', '\n', '_'];
  final out = StringBuffer();
  for (var i = 0; i < rand.nextInt(maxUnits + 1); i++) {
    out.write(alphabet[rand.nextInt(alphabet.length)]);
  }
  return out.toString();
}
