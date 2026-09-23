// The source buffer: byte-faithful round-trip, the offset↔line index, and the
// edit path. The random-edit test at the end compares every result against a
// plain `String`, which is the only model that cannot share a bug with it.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A document with something for every branch of the layout.
const String _mixed = 'one\ntwo\r\nthree\tfour\r\nfive';

/// Every line's offset, as a naive scan would give it.
List<int> _naiveOffsets(String text) {
  final offsets = <int>[0];
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) offsets.add(i + 1);
  }
  return offsets;
}

void main() {
  group('a note read from its text', () {
    // The lines are views of the text they were read from until a chunk is
    // written to (`LineChunk`): every line, terminator and length has to be
    // what a split of the text says, across chunks, and an edit has to
    // leave the text the edit says.
    /// Lines of every terminator, a lone `\r` as content, over three chunks.
    String note() {
      final random = Random(7);
      final out = StringBuffer('\uFEFFfirst\r\n');
      for (var at = 0; at < 2600; at++) {
        out
          ..write('line $at${random.nextInt(4) == 0 ? '\r' : ''} x')
          ..write(switch (random.nextInt(3)) {
            0 => '\n',
            1 => '\r\n',
            _ => '\n\n',
          });
      }
      return (out..write('last\r')).toString();
    }

    /// Checks [buffer] line by line against [text] split by hand.
    void agrees(SourceBuffer buffer, String text) {
      final lines = <String>[];
      final ends = <String>[];
      var start = 0;
      while (true) {
        final at = text.indexOf('\n', start);
        if (at < 0) {
          lines.add(text.substring(start));
          ends.add('');
          break;
        }
        final cr = at > start && text.codeUnitAt(at - 1) == 0x0D;
        lines.add(text.substring(start, cr ? at - 1 : at));
        ends.add(cr ? '\r\n' : '\n');
        start = at + 1;
      }
      expect(buffer.lineCount, lines.length);
      for (var at = 0; at < lines.length; at++) {
        expect(buffer.lineAt(at), lines[at], reason: 'line $at');
        expect(buffer.terminatorAt(at), ends[at], reason: 'end of $at');
        expect(buffer.lineLengthAt(at), lines[at].length, reason: '$at');
      }
      expect(buffer.text, text);
      expect(buffer.length, text.length);
    }

    test('reads every line and terminator back as written', () {
      final text = note();
      agrees(SourceBuffer.fromText(text), text);
      for (final small in ['', '\n', 'a', 'a\n', '\r\n', 'a\r', '\r']) {
        agrees(SourceBuffer.fromText(small), small);
      }
    });

    test('an edit across a chunk boundary leaves the text it says', () {
      var text = note();
      final buffer = SourceBuffer.fromText(text);
      final snapshot = buffer.snapshot();
      final before = text;
      for (final (start, end, inserted) in <(int, int, String)>[
        (buffer.offsetOfLine(1023), buffer.offsetOfLine(1026), 'a\nb'),
        (buffer.offsetOfLine(2047) + 2, buffer.offsetOfLine(2048) + 1, 'z'),
        (10, 12, 'one line'),
        (buffer.offsetOfLine(3000), buffer.offsetOfLine(3000), 'new\n'),
      ]) {
        buffer.replaceRange(start, end, inserted);
        text = text.replaceRange(start, end, inserted);
        agrees(buffer, text);
      }
      agrees(snapshot, before);
    });
  });

  group('snapshot', () {
    test('holds the text as it was, whatever the buffer does next', () {
      final buffer = SourceBuffer.fromText('uno\r\ndue\ntre');
      final snapshot = buffer.snapshot();
      buffer
        ..replaceRange(0, 3, 'UNO\nnuova')
        ..replaceRange(buffer.length, buffer.length, '\nquattro');
      expect(snapshot.text, 'uno\r\ndue\ntre');
      expect(snapshot.lineCount, 3);
      expect(snapshot.offsetOfLine(2), 9);
      expect(buffer.text, 'UNO\nnuova\r\ndue\ntre\nquattro');
    });

    test('is the same buffer as reading its text again', () {
      final buffer = SourceBuffer.fromText('# a\n\nb\r\nc');
      final snapshot = buffer.snapshot();
      final again = SourceBuffer.fromText(buffer.text);
      expect(snapshot.text, again.text);
      expect(snapshot.lineCount, again.lineCount);
      for (var line = 0; line < again.lineCount; line++) {
        expect(snapshot.lineAt(line), again.lineAt(line));
        expect(snapshot.offsetOfLine(line), again.offsetOfLine(line));
      }
      // And editing the snapshot leaves the buffer alone.
      snapshot.replaceRange(0, 0, 'x');
      expect(buffer.text, '# a\n\nb\r\nc');
    });
  });

  group('reading', () {
    test('an empty string is one empty line', () {
      final buffer = SourceBuffer.fromText('');
      expect(buffer.lineCount, 1);
      expect(buffer.length, 0);
      expect(buffer.lineAt(0), '');
      expect(buffer.terminatorAt(0), '');
      expect(buffer.text, '');
      expect(buffer.eol, '\n');
    });

    test(
      'round-trips LF, CRLF, mixed, tabs and a missing final terminator',
      () {
        for (final text in <String>[
          '',
          '\n',
          '\n\n\n',
          'a',
          'a\n',
          'a\nb',
          'a\nb\n',
          'one\ntwo\n',
          'one\r\ntwo\r\n',
          'one\r\ntwo\nthree\r\n',
          '\tindented\n\t\tdeeper\n',
          'trailing spaces  \nand a hard break  \n',
          'no final newline',
        ]) {
          expect(SourceBuffer.fromText(text).text, text, reason: text);
        }
      },
    );

    test('a byte-order mark stays in the first line', () {
      final buffer = SourceBuffer.fromText('\uFEFF# Title\nbody');
      expect(buffer.hasBom, isTrue);
      expect(buffer.text, '\uFEFF# Title\nbody');
      expect(buffer.lineAt(0), '\uFEFF# Title');
      // Absolute offsets, so the mark is one code unit wide at the start.
      expect(buffer.offsetOfLine(1), 9);
    });

    test('a file without a mark says so', () {
      expect(SourceBuffer.fromText('a').hasBom, isFalse);
    });

    test('the terminator is kept per line', () {
      final buffer = SourceBuffer.fromText('a\r\nb\nc\r\n');
      expect(buffer.terminatorAt(0), '\r\n');
      expect(buffer.terminatorAt(1), '\n');
      expect(buffer.terminatorAt(2), '\r\n');
      expect(buffer.terminatorAt(3), '');
      expect(buffer.lineCount, 4);
      expect(buffer.eol, '\r\n', reason: 'CRLF is the majority');
    });

    test('the dominant terminator is a majority, not the first one seen', () {
      expect(SourceBuffer.fromText('a\nb\nc\r\n').eol, '\n');
      expect(SourceBuffer.fromText('a\r\nb\r\nc\n').eol, '\r\n');
      expect(SourceBuffer.fromText('a').eol, '\n', reason: 'the default');
    });
  });

  group('the index', () {
    test('line offsets match a naive scan', () {
      for (final text in <String>[_mixed, 'a\nb\nc', '\n', '', 'a\r\nb']) {
        final buffer = SourceBuffer.fromText(text);
        final offsets = _naiveOffsets(text);
        expect(buffer.lineCount, offsets.length, reason: text);
        for (var i = 0; i < offsets.length; i++) {
          expect(buffer.offsetOfLine(i), offsets[i], reason: '$text line $i');
        }
        expect(buffer.offsetOfLine(buffer.lineCount), text.length);
      }
    });

    test('every offset finds its line, and every line its offsets', () {
      final buffer = SourceBuffer.fromText(_mixed);
      for (var offset = 0; offset < buffer.length; offset++) {
        final line = buffer.lineOf(offset);
        final start = buffer.offsetOfLine(line);
        final end =
            start +
            buffer.lineAt(line).length +
            buffer.terminatorAt(line).length;
        expect(offset, greaterThanOrEqualTo(start));
        expect(offset, lessThan(end), reason: 'offset $offset');
      }
      expect(buffer.lineOf(buffer.length), buffer.lineCount - 1);
      for (var line = 0; line < buffer.lineCount; line++) {
        expect(buffer.lineOf(buffer.offsetOfLine(line)), line);
      }
    });

    test('columnOf and offsetAt are inverses inside a line', () {
      final buffer = SourceBuffer.fromText(_mixed);
      for (var line = 0; line < buffer.lineCount; line++) {
        final start = buffer.offsetOfLine(line);
        for (var column = 0; column <= buffer.lineAt(line).length; column++) {
          expect(buffer.columnOf(start + column), column);
          expect(buffer.offsetAt(line, column), start + column);
        }
      }
    });

    test('offsetAt clamps a column past the line into the line', () {
      final buffer = SourceBuffer.fromText('ab\ncd');
      expect(
        buffer.offsetAt(0, 99),
        2,
        reason: 'the end of `ab`, not the start of `cd`',
      );
      expect(buffer.offsetAt(0, -5), 0);
    });

    test('an offset inside a terminator belongs to the line it ends', () {
      final buffer = SourceBuffer.fromText('ab\r\ncd');
      expect(buffer.lineOf(2), 0, reason: r'the \r');
      expect(buffer.lineOf(3), 0, reason: r'the \n');
      expect(buffer.lineOf(4), 1);
      expect(buffer.columnOf(3), 3, reason: 'past the line, and honestly so');
    });
  });

  group('caretOffset', () {
    test('an offset inside a CRLF is the end of its line', () {
      final buffer = SourceBuffer.fromText('ab\r\ncd\nef');
      expect(buffer.caretOffset(2), 2, reason: 'before the pair');
      expect(buffer.caretOffset(3), 2, reason: r'between \r and \n');
      expect(buffer.caretOffset(4), 4, reason: 'the next line');
      expect(buffer.caretOffset(6), 6, reason: 'before an LF');
      expect(buffer.caretOffset(7), 7, reason: 'after it');
    });

    test('an offset outside the note is its nearest end', () {
      final buffer = SourceBuffer.fromText('ab');
      expect(buffer.caretOffset(-3), 0);
      expect(buffer.caretOffset(9), 2);
    });
  });

  group('substring', () {
    test('inside a line, across lines, and over a terminator', () {
      final buffer = SourceBuffer.fromText(_mixed);
      expect(buffer.substring(0, 3), 'one');
      expect(buffer.substring(4, 7), 'two');
      expect(buffer.substring(3, 5), '\nt');
      expect(buffer.substring(4, 15), 'two\r\nthree\t');
      expect(buffer.substring(0, 0), '');
      expect(buffer.substring(0, buffer.length), _mixed);
    });

    test('the last line with no terminator still comes back', () {
      final buffer = SourceBuffer.fromText('a\nb');
      expect(buffer.substring(2, 3), 'b');
    });
  });

  group('editing', () {
    test('a verbatim replacement keeps its own line endings', () {
      // What an undo puts back is what the note held, mixed endings and all.
      final buffer = SourceBuffer.fromText('a\r\nz\r\n')
        ..replaceRange(3, 4, 'b\nc', verbatim: true);
      expect(buffer.text, 'a\r\nb\nc\r\n');
      final normalised = SourceBuffer.fromText('a\r\nz\r\n')
        ..replaceRange(3, 4, 'b\nc');
      expect(
        normalised.text,
        'a\r\nb\r\nc\r\n',
        reason: 'the default rewrites',
      );
    });

    test('an offset inside a CRLF is moved out of it', () {
      final buffer = SourceBuffer.fromText('ab\r\ncd');
      expect(buffer.snapOutOfTerminator(3), 2, reason: 'back to the line end');
      expect(buffer.snapOutOfTerminator(3, forward: true), 4);
      expect(buffer.snapOutOfTerminator(2), 2, reason: 'a line end is fine');
      expect(buffer.snapOutOfTerminator(4), 4, reason: 'a line start is too');
    });

    test('an insertion inside a line', () {
      final buffer = SourceBuffer.fromText('hello world')..insert(5, ',');
      expect(buffer.text, 'hello, world');
      expect(buffer.revision, 1);
    });

    test('an insertion at the start and at the end', () {
      final buffer = SourceBuffer.fromText('ab')..insert(0, 'X');
      expect(buffer.text, 'Xab');
      buffer.insert(buffer.length, 'Y');
      expect(buffer.text, 'XabY');
    });

    test('a deletion inside a line', () {
      final buffer = SourceBuffer.fromText('hello')..delete(1, 3);
      expect(buffer.text, 'hlo');
    });

    test('a newline splits a line, and the terminator follows the file', () {
      final lf = SourceBuffer.fromText('ab\ncd')..insert(2, '\n');
      expect(lf.text, 'ab\n\ncd');
      expect(lf.lineCount, 3);

      final crlf = SourceBuffer.fromText('ab\r\ncd')..insert(2, '\n');
      expect(crlf.text, 'ab\r\n\r\ncd', reason: r'an inserted \n becomes CRLF');
      expect(crlf.terminatorAt(0), '\r\n');
      expect(crlf.terminatorAt(1), '\r\n');
    });

    test('deleting a terminator joins two lines', () {
      final buffer = SourceBuffer.fromText('ab\ncd')..delete(2, 3);
      expect(buffer.text, 'abcd');
      expect(buffer.lineCount, 1);
    });

    test('joining lines keeps the terminator that followed', () {
      final buffer = SourceBuffer.fromText('a\nb\nc')..delete(1, 2);
      expect(buffer.text, 'ab\nc');
      expect(buffer.lineCount, 2);
    });

    test('deleting across a terminator takes the next line too', () {
      // `[1, 3)` is `\nb`: line 0's terminator and line 1's only character.
      // The merged line keeps the terminator that followed the region.
      final buffer = SourceBuffer.fromText('a\nb\nc')..delete(1, 3);
      expect(buffer.text, 'a\nc');
      expect(buffer.lineCount, 2);
    });

    test('a replacement spanning lines', () {
      // `[2, 7)` is `e\ntwo`, so `on` + `X` + `\nthree`.
      final buffer = SourceBuffer.fromText('one\ntwo\nthree')
        ..replaceRange(2, 7, 'X');
      expect(buffer.text, 'onX\nthree');
    });

    test('pasting several lines at once', () {
      final buffer = SourceBuffer.fromText('start\nend')
        ..insert(6, 'a\nb\nc\n');
      expect(buffer.text, 'start\na\nb\nc\nend');
      expect(buffer.lineCount, 5);
    });

    test('a terminator inserted at the very end', () {
      final buffer = SourceBuffer.fromText('abc')..insert(3, '\n');
      expect(buffer.text, 'abc\n');
      expect(buffer.lineCount, 2);
      expect(buffer.lineAt(1), '');
    });

    test('replacing the whole document', () {
      final buffer = SourceBuffer.fromText('one\ntwo');
      buffer.replaceRange(0, buffer.length, 'x\ny\nz');
      expect(buffer.text, 'x\ny\nz');
      expect(buffer.lineCount, 3);
    });

    test('emptying the document leaves one empty line', () {
      final buffer = SourceBuffer.fromText('one\ntwo\n');
      buffer.delete(0, buffer.length);
      expect(buffer.text, '');
      expect(buffer.lineCount, 1);
      expect(buffer.length, 0);
    });

    test('a no-op edit changes nothing and does not bump the revision', () {
      final buffer = SourceBuffer.fromText('ab')..replaceRange(1, 1, '');
      expect(buffer.text, 'ab');
      expect(buffer.revision, 0);
    });

    test('the inserted text is normalised, the existing text is not', () {
      final buffer = SourceBuffer.fromText('a\r\nb\r\nc')..insert(1, 'X\r\nY');
      expect(buffer.text, 'aX\r\nY\r\nb\r\nc');
      expect(buffer.revision, 1);
    });

    test('every line offset still answers after an edit', () {
      final buffer = SourceBuffer.fromText('one\ntwo\nthree\nfour')
        ..replaceRange(3, 9, 'X\nY');
      for (var line = 0; line < buffer.lineCount; line++) {
        expect(buffer.lineOf(buffer.offsetOfLine(line)), line);
      }
      expect(buffer.text, 'oneX\nYhree\nfour');
    });
  });

  test('random edits agree with a plain string', () {
    final random = Random(20260921);
    final alphabet = <String>['a', 'b', ' ', '\n', 'à', '🜁', '\t'];
    for (var round = 0; round < 120; round++) {
      var model = _randomText(random, alphabet);
      final buffer = SourceBuffer.fromText(model);
      var revision = 0;
      for (var step = 0; step < 12; step++) {
        final start = model.isEmpty ? 0 : random.nextInt(model.length + 1);
        final end = model.isEmpty
            ? 0
            : start + random.nextInt(model.length - start + 1);
        final inserted = random.nextInt(4) == 0
            ? ''
            : _randomText(random, alphabet);
        if (start == end && inserted.isEmpty) continue;

        model = model.replaceRange(start, end, inserted);
        buffer.replaceRange(start, end, inserted);
        revision++;

        expect(buffer.text, model, reason: 'round $round step $step');
        expect(buffer.length, model.length);
        expect(buffer.revision, revision);
        final offsets = _naiveOffsets(model);
        expect(buffer.lineCount, offsets.length);
        for (var line = 0; line < offsets.length; line++) {
          expect(buffer.offsetOfLine(line), offsets[line]);
        }
        for (var offset = 0; offset <= model.length; offset++) {
          final line = buffer.lineOf(offset);
          expect(buffer.offsetOfLine(line), lessThanOrEqualTo(offset));
        }
      }
    }
  });
}

/// A short random document from [alphabet], with no `\r`, so the buffer's
/// insert normalisation cannot differ from the plain string's.
String _randomText(Random random, List<String> alphabet) {
  final length = random.nextInt(24);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }
  return buffer.toString();
}
