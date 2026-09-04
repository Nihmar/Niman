import 'dart:io';
import 'dart:math';

import 'package:copist/src/editor/folding.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wrapping', () {
    test('an empty line is one row', () {
      final buffer = LineBuffer.fromText('');
      final model = RowModel(buffer, columns: 40);
      expect(model.rowCount, 1);
      expect(model.lineAndStartColumn(0), (0, 0));
    });

    test('a short line is one row', () {
      final buffer = LineBuffer.fromText('hello');
      final model = RowModel(buffer, columns: 40);
      expect(model.rowCount, 1);
    });

    test('a long line wraps at the grid width', () {
      final buffer = LineBuffer.fromText('x' * 100);
      final model = RowModel(buffer, columns: 30);
      expect(model.rowCount, 4);
      expect(model.lineAndStartColumn(0), (0, 0));
      expect(model.lineAndStartColumn(2), (0, 60));
      expect(model.lineAndStartColumn(3), (0, 90));
    });

    test('lines accumulate rows', () {
      final buffer = LineBuffer.fromText('ab\nc\n${'d' * 61}');
      final model = RowModel(buffer, columns: 30);
      // 1 + 1 + 3 rows.
      expect(model.rowCount, 5);
      expect(model.rowOfLine(0), 0);
      expect(model.rowOfLine(1), 1);
      expect(model.rowOfLine(2), 2);
      expect(model.lineAndStartColumn(4), (2, 60));
    });

    test('columns must be positive', () {
      final buffer = LineBuffer.fromText('a');
      expect(() => RowModel(buffer, columns: 0), throwsAssertionError);
    });
  });

  group('row to line mapping', () {
    test('round-trips every row of a wrapped sample', () {
      final buffer = LineBuffer.fromText(
        'ab\n${'c' * 95}\n\n${'def' * 40}',
      );
      final model = RowModel(buffer, columns: 30);
      for (var row = 0; row < model.rowCount; row++) {
        final (line, col) = model.lineAndStartColumn(row);
        expect(col % model.columns, 0);
        expect(buffer.lineLength(line), greaterThanOrEqualTo(col));
        expect(model.rowOfLine(line) + col ~/ model.columns, row);
      }
    });

    test('rejects out-of-range rows and lines', () {
      final buffer = LineBuffer.fromText('a\nb');
      final model = RowModel(buffer, columns: 10);
      expect(() => model.lineAndStartColumn(-1), throwsArgumentError);
      expect(
        () => model.lineAndStartColumn(model.rowCount),
        throwsArgumentError,
      );
      expect(() => model.rowOfLine(2), throwsArgumentError);
    });
  });

  group('sync after edits', () {
    test('matches a fresh model after random edits', () {
      final rand = Random(42);
      final buffer = LineBuffer.fromText('a b\n${'x' * 70}\n\nlast');
      final model = RowModel(buffer, columns: 10);
      for (var i = 0; i < 300; i++) {
        final length = buffer.textLength;
        final start = rand.nextInt(length + 1);
        final end = start + rand.nextInt(length - start + 1);
        buffer.replace(start, end, _randomText(rand, 8));
        model.sync();
        final fresh = RowModel(buffer, columns: 10);
        expect(model.rowCount, fresh.rowCount);
        final step = max(1, model.rowCount ~/ 40);
        for (var row = 0; row < model.rowCount; row += step) {
          expect(model.lineAndStartColumn(row), fresh.lineAndStartColumn(row));
        }
      }
    });

    test('sync is cheap enough for a keystroke on a large buffer', () {
      final text = File('test/fixtures/markdown/fixture-1mb.md')
          .readAsStringSync();
      final buffer = LineBuffer.fromText(text);
      final model = RowModel(buffer, columns: 80);
      final bufferLength = buffer.textLength;
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        buffer.replace(bufferLength, bufferLength, '\n');
        model.sync();
        buffer.delete(bufferLength, buffer.textLength);
        model.sync();
      }
      final ms = sw.elapsedMilliseconds;
      expect(model.rowCount, greaterThan(0));
      expect(ms, lessThan(1000));
    });
  });

  group('scale', () {
    test('builds and queries the 1 MB fixture quickly', () {
      final text = File('test/fixtures/markdown/fixture-1mb.md')
          .readAsStringSync();
      final buffer = LineBuffer.fromText(text);
      final sw = Stopwatch()..start();
      final model = RowModel(buffer, columns: 80);
      final buildMs = sw.elapsedMilliseconds;
      final rand = Random(1);
      final lookups = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        model.lineAndStartColumn(rand.nextInt(model.rowCount));
      }
      final lookupMs = lookups.elapsedMilliseconds;
      expect(buildMs, lessThan(500));
      expect(lookupMs, lessThan(100));
    });
  });

  group('folding (setLines)', () {
    test('wraps only the visible lines', () {
      final buffer = LineBuffer.fromText('ab\nc\n${'d' * 61}\nef');
      // lines: 0 'ab'(2), 1 'c'(1), 2 'd'*61 (3 rows), 3 'ef'(2); col 30.
      final all = RowModel(buffer, columns: 30);
      expect(all.rowCount, 6);
      // hide line 2 (the 3-row one): visible [0,1,3].
      final model = RowModel(buffer, columns: 30, lines: [0, 1, 3]);
      expect(model.rowCount, 3);
      expect(model.lines, [0, 1, 3]);
      expect(model.rowOfLine(0), 0);
      expect(model.rowOfLine(1), 1);
      expect(model.rowOfLine(3), 2);
      expect(model.lineAndStartColumn(0), (0, 0));
      expect(model.lineAndStartColumn(1), (1, 0));
      expect(model.lineAndStartColumn(2), (3, 0));
    });

    test('rowOfLine throws for a folded line', () {
      final buffer = LineBuffer.fromText('a\nb\nc');
      final model = RowModel(
        buffer,
        columns: 10,
        lines: [0, 2],
      ); // line 1 folded
      expect(() => model.rowOfLine(1), throwsArgumentError);
      expect(model.rowOfLine(0), 0);
      expect(model.rowOfLine(2), 1);
    });

    test('rows map back to visible lines only', () {
      final buffer = LineBuffer.fromText('ab\n${'c' * 95}\n\n${'def' * 40}');
      final model = RowModel(
        buffer,
        columns: 30,
        lines: [0, 2, 3],
      ); // fold line 1
      final visible = <int>{0, 2, 3};
      for (var row = 0; row < model.rowCount; row++) {
        final (line, col) = model.lineAndStartColumn(row);
        expect(visible.contains(line), isTrue);
        expect(col % model.columns, 0);
        expect(buffer.lineLength(line), greaterThanOrEqualTo(col));
      }
    });

    test('sync resets the visible set to every line', () {
      final buffer = LineBuffer.fromText('a\nb\nc\nd');
      final model = RowModel(buffer, columns: 10, lines: [0, 2]);
      expect(model.visibleLineCount, 2);
      model.sync();
      expect(model.visibleLineCount, 4);
      expect(model.lines, [0, 1, 2, 3]);
    });

    test('wraps the FoldState visible set', () {
      final buffer = LineBuffer.fromText(
        '# A\nx\n## A1\ny\n## A2\nz\n# B\nw',
      );
      const outline = [
        OutlineEntry(line: 0, level: 1, text: 'A'),
        OutlineEntry(line: 2, level: 2, text: 'A1'),
        OutlineEntry(line: 4, level: 2, text: 'A2'),
        OutlineEntry(line: 6, level: 1, text: 'B'),
      ];
      final folds = FoldState(outline, buffer.lineCount, folded: {0});
      // A (line 0) hides [1,6) -> visible [0,6,7].
      expect(folds.visibleLines(), [0, 6, 7]);
      final model = RowModel(buffer, columns: 40, lines: folds.visibleLines());
      expect(model.lines, [0, 6, 7]);
      for (var row = 0; row < model.rowCount; row++) {
        final (line, _) = model.lineAndStartColumn(row);
        expect({0, 6, 7}.contains(line), isTrue);
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
